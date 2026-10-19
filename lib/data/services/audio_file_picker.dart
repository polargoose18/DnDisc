import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/logger_service.dart';
import 'media_library_service.dart';

/// Audio files picked by the user, ready to play.
typedef PickedAudio = ({List<String> paths, int skipped});

/// Opens the system file picker for audio the library can play.
///
/// On Android two things differ from the desktop:
/// * the picker filters by MIME type and maps extensions on its own, so a
///   custom filter greys out M4A (offered as `audio/mp4`); it asks for any
///   audio and the extension is checked here instead;
/// * the picker hands out a copy in the app's cache, which the system may
///   clear, so each file is copied to the app's own storage first.
abstract class AudioFilePicker {
  /// Folder for files copied out of the picker's cache (Android).
  static const String importedFolder = 'audio_library/imported';

  @visibleForTesting
  static bool? debugIsAndroid;

  @visibleForTesting
  static Future<Directory> Function()? debugDocumentsDirectory;

  static bool get _android => debugIsAndroid ?? (!kIsWeb && Platform.isAndroid);

  /// Paths of the chosen files, and how many were left out because the
  /// library does not play their format.
  static Future<PickedAudio> pick({bool multiple = false}) async {
    final android = _android;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: multiple,
      type: android ? FileType.audio : FileType.custom,
      allowedExtensions: android ? null : MediaLibraryService.supportedExtensions,
    );
    if (result == null) return (paths: const <String>[], skipped: 0);

    final paths = <String>[];
    var skipped = 0;
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      if (!MediaLibraryService.isSupportedFile(file.name)) {
        skipped++;
        continue;
      }
      paths.add(android ? await keep(path, file.name) : path);
    }
    return (paths: paths, skipped: skipped);
  }

  /// Copies [cachedPath] into the app's storage under its original [name]
  /// (one folder per file, so the name and the track title stay as they
  /// were) and returns the new path.
  static Future<String> keep(String cachedPath, String name) async {
    final docs = await (debugDocumentsDirectory ?? getApplicationDocumentsDirectory)();
    final folder = Directory(p.join(docs.path, importedFolder, const Uuid().v4()));
    await folder.create(recursive: true);
    final target = p.join(folder.path, p.basename(name));
    await File(cachedPath).copy(target);
    LoggerService().info('AudioFilePicker: Kept a copy of $name', details: target);
    return target;
  }
}
