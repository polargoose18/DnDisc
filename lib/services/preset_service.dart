import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../db/database_service.dart';
import '../data/repositories/media_library_repository.dart';
import '../data/repositories/scene_repository.dart';
import '../domain/models/library_track.dart';
import '../domain/models/scene_model.dart';
import 'logger_service.dart';

class PresetImportResult {
  final String title;
  final String description;
  final List<LibraryTrack> importedTracks;
  final List<SceneModel> importedScenes;

  const PresetImportResult({
    required this.title,
    required this.description,
    required this.importedTracks,
    required this.importedScenes,
  });
}

class PresetService {
  final MediaLibraryRepository _mediaRepo;
  final SceneRepository _sceneRepo;

  PresetService({
    DatabaseService? db,
    MediaLibraryRepository? mediaLibraryRepository,
    SceneRepository? sceneRepository,
  })  : _mediaRepo = mediaLibraryRepository ?? SqliteMediaLibraryRepository(db: db),
        _sceneRepo = sceneRepository ?? SqliteSceneRepository(db: db);

  Future<File> exportPreset({
    required String exportZipPath,
    required String title,
    required String description,
    required List<SceneModel> scenes,
    required List<LibraryTrack> tracks,
  }) async {
    LoggerService().info('PresetService: Starting export for preset "$title"');

    final archive = Archive();
    final exportedTracksData = <Map<String, dynamic>>[];

    // 1. Pack Audio Files
    for (final track in tracks) {
      final file = File(track.filePath);
      if (!file.existsSync()) {
        LoggerService().warning(
          'PresetService: Audio file does not exist, skipping file packing',
          details: 'Track: ${track.title}, Path: ${track.filePath}',
        );
        continue;
      }

      final ext = p.extension(track.filePath);
      final filename = '${track.id}$ext';
      final archiveRelativePath = 'audio/$filename';

      final bytes = await file.readAsBytes();
      archive.addFile(
        ArchiveFile(archiveRelativePath, bytes.length, bytes),
      );

      final trackMap = track.toMap();
      trackMap['file_path'] = archiveRelativePath; // store relative path in manifest
      exportedTracksData.add(trackMap);
    }

    // 2. Build preset.json
    final manifest = {
      'title': title,
      'description': description,
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'tracks': exportedTracksData,
      'scenes': scenes.map((s) => s.toMap()).toList(),
    };

    final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
    archive.addFile(
      ArchiveFile.string('preset.json', manifestJson),
    );

    // 3. Compress to ZIP
    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    final outputFile = File(exportZipPath);
    if (!outputFile.parent.existsSync()) {
      await outputFile.parent.create(recursive: true);
    }

    await outputFile.writeAsBytes(zipData);
    LoggerService().info(
      'PresetService: Preset exported successfully!',
      details: 'Path: $exportZipPath (${zipData.length} bytes, ${tracks.length} tracks, ${scenes.length} scenes)',
    );

    return outputFile;
  }

  Future<PresetImportResult> importPreset({
    required String zipFilePath,
    required String destinationAudioDir,
  }) async {
    LoggerService().info('PresetService: Starting import from $zipFilePath');

    final zipFile = File(zipFilePath);
    if (!zipFile.existsSync()) {
      throw FileSystemException('Preset ZIP file not found', zipFilePath);
    }

    final bytes = await zipFile.readAsBytes();
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes);

    final manifestFile = archive.findFile('preset.json');
    if (manifestFile == null) {
      throw const FormatException('Invalid preset archive: missing preset.json manifest.');
    }

    final manifestContent = utf8.decode(manifestFile.content as List<int>);
    final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

    final title = manifest['title'] as String? ?? 'Untitled Preset';
    final description = manifest['description'] as String? ?? '';
    final rawTracks = manifest['tracks'] as List<dynamic>? ?? [];
    final rawScenes = manifest['scenes'] as List<dynamic>? ?? [];

    final destDir = Directory(destinationAudioDir);
    if (!destDir.existsSync()) {
      await destDir.create(recursive: true);
    }

    // 1. Extract audio files
    final extractedFilesMap = <String, String>{}; // relative path -> absolute path
    for (final file in archive.files) {
      if (file.isFile && file.name.startsWith('audio/')) {
        final filename = p.basename(file.name);
        final destFilePath = p.join(destinationAudioDir, filename);
        final extractedFile = File(destFilePath);
        await extractedFile.writeAsBytes(file.content as List<int>);
        extractedFilesMap[file.name] = destFilePath;
      }
    }

    // 2. Process and save Tracks
    final importedTracks = <LibraryTrack>[];
    for (final rawTrack in rawTracks) {
      final map = Map<String, dynamic>.from(rawTrack as Map);
      final relPath = map['file_path'] as String? ?? '';
      final absolutePath = extractedFilesMap[relPath] ?? p.join(destinationAudioDir, p.basename(relPath));

      map['file_path'] = absolutePath;
      final track = LibraryTrack.fromMap(map);
      await _mediaRepo.insertTrack(track);
      importedTracks.add(track);
    }

    // 3. Process and save Scenes
    final importedScenes = <SceneModel>[];
    for (final rawScene in rawScenes) {
      final map = Map<String, dynamic>.from(rawScene as Map);
      final scene = SceneModel.fromMap(map);
      await _sceneRepo.insertScene(scene);
      importedScenes.add(scene);
    }

    LoggerService().info(
      'PresetService: Successfully imported preset "$title"',
      details: '${importedTracks.length} tracks, ${importedScenes.length} scenes registered in SQLite.',
    );

    return PresetImportResult(
      title: title,
      description: description,
      importedTracks: importedTracks,
      importedScenes: importedScenes,
    );
  }
}
