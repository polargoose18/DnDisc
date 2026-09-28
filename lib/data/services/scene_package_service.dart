import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../../data/repositories/media_library_repository.dart';
import '../../data/repositories/scene_repository.dart';
import 'database_service.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/scene_model.dart';
import '../../services/logger_service.dart';

class ScenePackageImportResult {
  final SceneModel scene;
  final List<LibraryTrack> importedTracks;

  const ScenePackageImportResult({
    required this.scene,
    required this.importedTracks,
  });
}

class ScenePackImportResult {
  final String title;
  final String? description;
  final List<SceneModel> importedScenes;
  final List<LibraryTrack> importedTracks;

  const ScenePackImportResult({
    required this.title,
    this.description,
    required this.importedScenes,
    required this.importedTracks,
  });
}

class ScenePackageService {
  final MediaLibraryRepository _mediaRepo;
  final SceneRepository _sceneRepo;

  ScenePackageService({
    DatabaseService? db,
    MediaLibraryRepository? mediaLibraryRepository,
    SceneRepository? sceneRepository,
  })  : _mediaRepo = mediaLibraryRepository ?? SqliteMediaLibraryRepository(db: db),
        _sceneRepo = sceneRepository ?? SqliteSceneRepository(db: db);

  void _logStdout(String msg) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    stdout.writeln('[$timeStr] $msg');
  }

  void _logStderr(String msg) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    stderr.writeln('[$timeStr] $msg');
  }

  Future<File> exportSingleScene({
    required SceneModel scene,
    required String exportZipPath,
  }) async {
    _logStdout('ScenePackageService: Exporting single scene "${scene.name}" (ID: ${scene.id})');
    LoggerService().info('ScenePackageService: Exporting single scene "${scene.name}" (ID: ${scene.id})');

    final archive = Archive();
    final trackIds = <String>{};

    if (scene.musicTrackId != null && scene.musicTrackId!.isNotEmpty) {
      trackIds.add(scene.musicTrackId!);
    }
    trackIds.addAll(scene.ambientLayerVolumes.keys);
    trackIds.addAll(scene.soundboardSfxIds);

    final exportedTracksData = <Map<String, dynamic>>[];

    for (final trackId in trackIds) {
      final track = await _mediaRepo.getTrackById(trackId);
      if (track == null) {
        _logStderr('ScenePackageService: Track with ID $trackId not found in media library');
        LoggerService().warning('ScenePackageService: Track with ID $trackId not found in media library');
        continue;
      }

      final file = File(track.filePath);
      if (!file.existsSync()) {
        _logStderr('ScenePackageService: Audio file does not exist: ${track.filePath}');
        LoggerService().warning('ScenePackageService: Audio file does not exist: ${track.filePath}');
        continue;
      }

      final ext = p.extension(track.filePath);
      final filename = '${track.id}$ext';
      final archiveRelativePath = 'audio/$filename';

      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(archiveRelativePath, bytes.length, bytes));

      final trackMap = track.toMap();
      trackMap['file_path'] = archiveRelativePath;
      exportedTracksData.add(trackMap);
    }

    final sceneMap = scene.toMap();
    if (scene.imagePath != null && scene.imagePath!.isNotEmpty) {
      final imgFile = File(scene.imagePath!);
      if (imgFile.existsSync()) {
        final imgBasename = p.basename(scene.imagePath!);
        final imgArchiveRelativePath = 'images/$imgBasename';
        final bytes = await imgFile.readAsBytes();
        archive.addFile(ArchiveFile(imgArchiveRelativePath, bytes.length, bytes));
        sceneMap['image_path'] = imgArchiveRelativePath;
      } else {
        sceneMap['image_path'] = null;
      }
    }

    final manifest = {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'scene': sceneMap,
      'tracks': exportedTracksData,
    };

    final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
    archive.addFile(ArchiveFile.string('scene.json', manifestJson));

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    final outputFile = File(exportZipPath);
    if (!outputFile.parent.existsSync()) {
      await outputFile.parent.create(recursive: true);
    }

    await outputFile.writeAsBytes(zipData);
    _logStdout('ScenePackageService: Successfully exported scene "${scene.name}" to $exportZipPath (${zipData.length} bytes)');
    LoggerService().info('ScenePackageService: Successfully exported scene "${scene.name}" to $exportZipPath (${zipData.length} bytes)');

    return outputFile;
  }

  Future<ScenePackageImportResult> importSingleScenePackage({
    required String zipFilePath,
    required String destinationAudioDir,
  }) async {
    _logStdout('ScenePackageService: Importing scene package from $zipFilePath');
    LoggerService().info('ScenePackageService: Importing scene package from $zipFilePath');

    final zipFile = File(zipFilePath);
    if (!zipFile.existsSync()) {
      final err = 'Scene ZIP file not found at: $zipFilePath';
      _logStderr(err);
      LoggerService().error(err);
      throw FileSystemException(err, zipFilePath);
    }

    final bytes = await zipFile.readAsBytes();
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes);

    var manifestFile = archive.findFile('scene.json');
    manifestFile ??= archive.findFile('preset.json');

    if (manifestFile == null) {
      const err = 'Invalid scene package: missing scene.json manifest.';
      _logStderr(err);
      LoggerService().error(err);
      throw const FormatException(err);
    }

    final manifestContent = utf8.decode(manifestFile.content as List<int>);
    final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

    final rawScene = manifest['scene'] ?? (manifest['scenes'] is List && (manifest['scenes'] as List).isNotEmpty ? manifest['scenes'][0] : null);
    if (rawScene == null) {
      const err = 'Invalid scene package: missing scene data in manifest.';
      _logStderr(err);
      LoggerService().error(err);
      throw const FormatException(err);
    }

    final rawTracks = manifest['tracks'] as List<dynamic>? ?? [];

    final destDir = Directory(destinationAudioDir);
    if (!destDir.existsSync()) {
      await destDir.create(recursive: true);
    }
    final normalizedDestDir = p.normalize(p.absolute(destinationAudioDir));

    final extractedFilesMap = <String, String>{};

    for (final file in archive.files) {
      if (!file.isFile) continue;

      final filename = p.basename(file.name);
      if (filename == 'scene.json' || filename == 'preset.json' || filename.startsWith('.')) {
        continue;
      }

      final normalizedRelPath = p.normalize(file.name);
      final destFilePath = p.normalize(p.absolute(p.join(destinationAudioDir, file.name)));
      if (!destFilePath.startsWith(normalizedDestDir)) {
        final err = 'Zip Slip security error: File "${file.name}" attempts to extract outside target directory.';
        _logStderr(err);
        LoggerService().error(err);
        throw FormatException(err);
      }

      final extractedFile = File(destFilePath);
      if (!extractedFile.parent.existsSync()) {
        await extractedFile.parent.create(recursive: true);
      }
      await extractedFile.writeAsBytes(file.content as List<int>);

      extractedFilesMap[file.name] = destFilePath;
      extractedFilesMap[file.name.replaceAll('\\', '/')] = destFilePath;
      extractedFilesMap[file.name.replaceAll('/', '\\')] = destFilePath;
      extractedFilesMap[normalizedRelPath] = destFilePath;
      extractedFilesMap[filename] = destFilePath;
    }

    final importedTracks = <LibraryTrack>[];
    for (final rawTrack in rawTracks) {
      final map = Map<String, dynamic>.from(rawTrack as Map);
      final relPath = map['file_path'] as String? ?? '';
      final baseName = p.basename(relPath);
      final absolutePath = extractedFilesMap[relPath] ??
          extractedFilesMap[relPath.replaceAll('\\', '/')] ??
          extractedFilesMap[relPath.replaceAll('/', '\\')] ??
          extractedFilesMap[baseName] ??
          p.join(destinationAudioDir, baseName);

      map['file_path'] = absolutePath;
      final track = LibraryTrack.fromMap(map);
      importedTracks.add(track);
    }

    if (importedTracks.isNotEmpty) {
      await _mediaRepo.insertTracksBatch(importedTracks);
    }

    final sceneMap = Map<String, dynamic>.from(rawScene as Map);
    final sceneRelImgPath = sceneMap['image_path'] as String?;
    if (sceneRelImgPath != null && sceneRelImgPath.isNotEmpty) {
      final imgBaseName = p.basename(sceneRelImgPath);
      final absoluteImgPath = extractedFilesMap[sceneRelImgPath] ??
          extractedFilesMap[sceneRelImgPath.replaceAll('\\', '/')] ??
          extractedFilesMap[sceneRelImgPath.replaceAll('/', '\\')] ??
          extractedFilesMap[imgBaseName] ??
          p.join(destinationAudioDir, sceneRelImgPath);

      if (File(absoluteImgPath).existsSync()) {
        sceneMap['image_path'] = absoluteImgPath;
      } else {
        final fallbackImgPath = p.join(destinationAudioDir, 'images', imgBaseName);
        if (File(fallbackImgPath).existsSync()) {
          sceneMap['image_path'] = fallbackImgPath;
        } else {
          final rootFallbackPath = p.join(destinationAudioDir, imgBaseName);
          if (File(rootFallbackPath).existsSync()) {
            sceneMap['image_path'] = rootFallbackPath;
          }
        }
      }
    }

    final importedScene = SceneModel.fromMap(sceneMap);
    await _sceneRepo.insertScene(importedScene);

    _logStdout('ScenePackageService: Successfully imported scene "${importedScene.name}" (${importedTracks.length} tracks registered)');
    LoggerService().info(
      'ScenePackageService: Successfully imported scene "${importedScene.name}"',
      details: '${importedTracks.length} tracks registered in library.',
    );

    return ScenePackageImportResult(
      scene: importedScene,
      importedTracks: importedTracks,
    );
  }

  Future<File> exportPackPackage({
    required List<SceneModel> scenes,
    required String exportZipPath,
    String? title,
    String? description,
  }) async {
    final titleStr = title ?? 'Scene Pack';
    _logStdout('ScenePackageService: Exporting ${scenes.length} scenes to pack "$titleStr"');
    LoggerService().info('ScenePackageService: Exporting ${scenes.length} scenes to pack "$titleStr"');

    final archive = Archive();
    final trackIds = <String>{};

    for (final scene in scenes) {
      if (scene.musicTrackId != null && scene.musicTrackId!.isNotEmpty) {
        trackIds.add(scene.musicTrackId!);
      }
      trackIds.addAll(scene.ambientLayerVolumes.keys);
      trackIds.addAll(scene.soundboardSfxIds);
    }

    final exportedTracksData = <Map<String, dynamic>>[];
    final processedTrackIds = <String>{};

    for (final trackId in trackIds) {
      if (processedTrackIds.contains(trackId)) continue;
      processedTrackIds.add(trackId);

      final track = await _mediaRepo.getTrackById(trackId);
      if (track == null) {
        _logStderr('ScenePackageService: Track with ID $trackId not found in media library');
        LoggerService().warning('ScenePackageService: Track with ID $trackId not found in media library');
        continue;
      }

      final file = File(track.filePath);
      if (!file.existsSync()) {
        _logStderr('ScenePackageService: Audio file does not exist: ${track.filePath}');
        LoggerService().warning('ScenePackageService: Audio file does not exist: ${track.filePath}');
        continue;
      }

      final ext = p.extension(track.filePath);
      final filename = '${track.id}$ext';
      final archiveRelativePath = 'audio/$filename';

      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(archiveRelativePath, bytes.length, bytes));

      final trackMap = track.toMap();
      trackMap['file_path'] = archiveRelativePath;
      exportedTracksData.add(trackMap);
    }

    final exportedScenesData = <Map<String, dynamic>>[];
    for (final scene in scenes) {
      final sceneMap = scene.toMap();
      if (scene.imagePath != null && scene.imagePath!.isNotEmpty) {
        final imgFile = File(scene.imagePath!);
        if (imgFile.existsSync()) {
          final imgBasename = p.basename(scene.imagePath!);
          final imgArchiveRelativePath = 'images/$imgBasename';
          final bytes = await imgFile.readAsBytes();
          archive.addFile(ArchiveFile(imgArchiveRelativePath, bytes.length, bytes));
          sceneMap['image_path'] = imgArchiveRelativePath;
        } else {
          sceneMap['image_path'] = null;
        }
      }
      exportedScenesData.add(sceneMap);
    }

    final manifest = {
      'version': '1.0',
      'title': titleStr,
      'description': description,
      'exported_at': DateTime.now().toIso8601String(),
      'scenes': exportedScenesData,
      'tracks': exportedTracksData,
    };

    final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
    archive.addFile(ArchiveFile.string('pack.json', manifestJson));

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    final outputFile = File(exportZipPath);
    if (!outputFile.parent.existsSync()) {
      await outputFile.parent.create(recursive: true);
    }

    await outputFile.writeAsBytes(zipData);
    _logStdout('ScenePackageService: Successfully exported pack "$titleStr" to $exportZipPath (${zipData.length} bytes)');
    LoggerService().info('ScenePackageService: Successfully exported pack "$titleStr" to $exportZipPath');

    return outputFile;
  }

  Future<ScenePackImportResult> importPackPackage({
    required String zipFilePath,
    required String destinationAudioDir,
  }) async {
    _logStdout('ScenePackageService: Importing scene pack from $zipFilePath');
    LoggerService().info('ScenePackageService: Importing scene pack from $zipFilePath');

    final zipFile = File(zipFilePath);
    if (!zipFile.existsSync()) {
      final err = 'Pack ZIP file not found at: $zipFilePath';
      _logStderr(err);
      LoggerService().error(err);
      throw FileSystemException(err, zipFilePath);
    }

    final bytes = await zipFile.readAsBytes();
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes);

    var manifestFile = archive.findFile('pack.json');
    manifestFile ??= archive.findFile('preset.json');
    manifestFile ??= archive.findFile('scene.json');

    if (manifestFile == null) {
      const err = 'Invalid scene pack package: missing pack.json manifest.';
      _logStderr(err);
      LoggerService().error(err);
      throw const FormatException(err);
    }

    final manifestContent = utf8.decode(manifestFile.content as List<int>);
    final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

    final title = manifest['title'] as String? ?? manifest['name'] as String? ?? 'Imported Pack';
    final description = manifest['description'] as String?;
    final rawScenes = manifest['scenes'] as List<dynamic>? ?? [];
    final rawTracks = manifest['tracks'] as List<dynamic>? ?? [];

    final destDir = Directory(destinationAudioDir);
    if (!destDir.existsSync()) {
      await destDir.create(recursive: true);
    }
    final normalizedDestDir = p.normalize(p.absolute(destinationAudioDir));

    final extractedFilesMap = <String, String>{};

    for (final file in archive.files) {
      if (!file.isFile) continue;

      final filename = p.basename(file.name);
      if (filename == 'pack.json' || filename == 'scene.json' || filename == 'preset.json' || filename.startsWith('.')) {
        continue;
      }

      final normalizedRelPath = p.normalize(file.name);
      final destFilePath = p.normalize(p.absolute(p.join(destinationAudioDir, file.name)));
      if (!destFilePath.startsWith(normalizedDestDir)) {
        final err = 'Zip Slip security error: File "${file.name}" attempts to extract outside target directory.';
        _logStderr(err);
        LoggerService().error(err);
        throw FormatException(err);
      }

      final extractedFile = File(destFilePath);
      if (!extractedFile.parent.existsSync()) {
        await extractedFile.parent.create(recursive: true);
      }
      await extractedFile.writeAsBytes(file.content as List<int>);

      extractedFilesMap[file.name] = destFilePath;
      extractedFilesMap[file.name.replaceAll('\\', '/')] = destFilePath;
      extractedFilesMap[file.name.replaceAll('/', '\\')] = destFilePath;
      extractedFilesMap[normalizedRelPath] = destFilePath;
      extractedFilesMap[filename] = destFilePath;
    }

    final importedTracks = <LibraryTrack>[];
    for (final rawTrack in rawTracks) {
      final map = Map<String, dynamic>.from(rawTrack as Map);
      final relPath = map['file_path'] as String? ?? '';
      final baseName = p.basename(relPath);
      final absolutePath = extractedFilesMap[relPath] ??
          extractedFilesMap[relPath.replaceAll('\\', '/')] ??
          extractedFilesMap[relPath.replaceAll('/', '\\')] ??
          extractedFilesMap[baseName] ??
          p.join(destinationAudioDir, baseName);

      map['file_path'] = absolutePath;
      final track = LibraryTrack.fromMap(map);
      importedTracks.add(track);
    }

    if (importedTracks.isNotEmpty) {
      await _mediaRepo.insertTracksBatch(importedTracks);
    }

    final importedScenes = <SceneModel>[];
    for (final rawScene in rawScenes) {
      final sceneMap = Map<String, dynamic>.from(rawScene as Map);
      final sceneRelImgPath = sceneMap['image_path'] as String?;
      if (sceneRelImgPath != null && sceneRelImgPath.isNotEmpty) {
        final imgBaseName = p.basename(sceneRelImgPath);
        final absoluteImgPath = extractedFilesMap[sceneRelImgPath] ??
            extractedFilesMap[sceneRelImgPath.replaceAll('\\', '/')] ??
            extractedFilesMap[sceneRelImgPath.replaceAll('/', '\\')] ??
            extractedFilesMap[imgBaseName] ??
            p.join(destinationAudioDir, sceneRelImgPath);

        if (File(absoluteImgPath).existsSync()) {
          sceneMap['image_path'] = absoluteImgPath;
        } else {
          final fallbackImgPath = p.join(destinationAudioDir, 'images', imgBaseName);
          if (File(fallbackImgPath).existsSync()) {
            sceneMap['image_path'] = fallbackImgPath;
          } else {
            final rootFallbackPath = p.join(destinationAudioDir, imgBaseName);
            if (File(rootFallbackPath).existsSync()) {
              sceneMap['image_path'] = rootFallbackPath;
            }
          }
        }
      }

      final importedScene = SceneModel.fromMap(sceneMap);
      await _sceneRepo.insertScene(importedScene);
      importedScenes.add(importedScene);
    }

    _logStdout('ScenePackageService: Successfully imported pack "$title" (${importedScenes.length} scenes, ${importedTracks.length} tracks)');
    LoggerService().info('ScenePackageService: Successfully imported pack "$title" (${importedScenes.length} scenes, ${importedTracks.length} tracks)');

    return ScenePackImportResult(
      title: title,
      description: description,
      importedScenes: importedScenes,
      importedTracks: importedTracks,
    );
  }
}
