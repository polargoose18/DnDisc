import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../data/repositories/media_library_repository.dart';
import '../db/database_service.dart';
import '../domain/models/library_track.dart';
import 'logger_service.dart';

class MediaPackageImportResult {
  final String title;
  final String? description;
  final List<LibraryTrack> importedTracks;

  const MediaPackageImportResult({
    required this.title,
    this.description,
    required this.importedTracks,
  });
}

class MediaPackageService {
  final MediaLibraryRepository _mediaRepo;

  MediaPackageService({
    DatabaseService? db,
    MediaLibraryRepository? mediaLibraryRepository,
  }) : _mediaRepo = mediaLibraryRepository ?? SqliteMediaLibraryRepository(db: db);

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

  Future<File> exportMediaPackage({
    required List<LibraryTrack> tracks,
    required String exportZipPath,
    String? title,
    String? description,
  }) async {
    final titleStr = title ?? 'Media Set';
    _logStdout('MediaPackageService: Exporting ${tracks.length} tracks to media package "$titleStr"');
    LoggerService().info('MediaPackageService: Exporting ${tracks.length} tracks to media package "$titleStr"');

    final archive = Archive();
    final exportedTracksData = <Map<String, dynamic>>[];

    for (final track in tracks) {
      final file = File(track.filePath);
      if (!file.existsSync()) {
        _logStderr('MediaPackageService: Audio file does not exist: ${track.filePath}');
        LoggerService().warning('MediaPackageService: Audio file does not exist: ${track.filePath}');
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

    final manifest = {
      'version': '1.0',
      'title': titleStr,
      'description': description,
      'exported_at': DateTime.now().toIso8601String(),
      'tracks': exportedTracksData,
    };

    final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
    archive.addFile(ArchiveFile.string('media.json', manifestJson));

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    final outputFile = File(exportZipPath);
    if (!outputFile.parent.existsSync()) {
      await outputFile.parent.create(recursive: true);
    }

    await outputFile.writeAsBytes(zipData);
    _logStdout('MediaPackageService: Successfully exported media package "$titleStr" to $exportZipPath (${zipData.length} bytes)');
    LoggerService().info('MediaPackageService: Successfully exported media package "$titleStr" to $exportZipPath');

    return outputFile;
  }

  Future<MediaPackageImportResult> importMediaPackage({
    required String zipFilePath,
    required String destinationAudioDir,
  }) async {
    _logStdout('MediaPackageService: Importing media package from $zipFilePath');
    LoggerService().info('MediaPackageService: Importing media package from $zipFilePath');

    final zipFile = File(zipFilePath);
    if (!zipFile.existsSync()) {
      final err = 'Media ZIP file not found at: $zipFilePath';
      _logStderr(err);
      LoggerService().error(err);
      throw FileSystemException(err, zipFilePath);
    }

    final bytes = await zipFile.readAsBytes();
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes);

    var manifestFile = archive.findFile('media.json');
    manifestFile ??= archive.findFile('scene.json');

    if (manifestFile == null) {
      const err = 'Invalid media package: missing media.json manifest.';
      _logStderr(err);
      LoggerService().error(err);
      throw const FormatException(err);
    }

    final manifestContent = utf8.decode(manifestFile.content as List<int>);
    final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

    final title = manifest['title'] as String? ?? manifest['name'] as String? ?? 'Imported Media Set';
    final description = manifest['description'] as String?;
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
      if (filename == 'media.json' || filename == 'scene.json' || filename.startsWith('.')) {
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

    _logStdout('MediaPackageService: Successfully imported media package "$title" (${importedTracks.length} tracks)');
    LoggerService().info('MediaPackageService: Successfully imported media package "$title" (${importedTracks.length} tracks)');

    return MediaPackageImportResult(
      title: title,
      description: description,
      importedTracks: importedTracks,
    );
  }
}
