import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ttrpg_audio_player/data/services/audio_file_picker.dart';

/// Picker that returns [files] and records what it was asked for.
class FakeFilePicker extends FilePicker with MockPlatformInterfaceMixin {
  final List<PlatformFile> files;
  FileType? type;
  List<String>? allowedExtensions;
  bool? allowMultiple;

  FakeFilePicker(this.files);

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    this.type = type;
    this.allowedExtensions = allowedExtensions;
    this.allowMultiple = allowMultiple;
    return files.isEmpty ? null : FilePickerResult(files);
  }
}

void main() {
  late Directory temp;
  late Directory cache;
  late Directory docs;

  PlatformFile cached(String name) {
    final file = File(p.join(cache.path, name))..writeAsStringSync('audio $name');
    return PlatformFile(name: name, path: file.path, size: file.lengthSync());
  }

  setUp(() {
    temp = Directory.systemTemp.createTempSync('dndisc_picker_');
    cache = Directory(p.join(temp.path, 'cache'))..createSync();
    docs = Directory(p.join(temp.path, 'docs'))..createSync();
    AudioFilePicker.debugDocumentsDirectory = () async => docs;
  });

  tearDown(() {
    AudioFilePicker.debugIsAndroid = null;
    AudioFilePicker.debugDocumentsDirectory = null;
    temp.deleteSync(recursive: true);
  });

  group('On Android', () {
    setUp(() => AudioFilePicker.debugIsAndroid = true);

    test('asks for any audio, since an M4A filter by extension greys M4A out, and keeps only playable formats', () async {
      final picker = FakeFilePicker([cached('Tavern.m4a'), cached('Rain.flac'), cached('Notes.amr')]);
      FilePicker.platform = picker;

      final picked = await AudioFilePicker.pick(multiple: true);

      expect(picker.type, FileType.audio);
      expect(picker.allowedExtensions, isNull);
      expect(picker.allowMultiple, isTrue);
      expect(picked.paths.map(p.basename), ['Tavern.m4a', 'Rain.flac']);
      expect(picked.skipped, 1);
    });

    test('copies each file out of the picker cache into the app storage under its own name', () async {
      FilePicker.platform = FakeFilePicker([cached('Tavern.m4a'), cached('Tavern.mp3')]);

      final picked = await AudioFilePicker.pick(multiple: true);

      for (final path in picked.paths) {
        expect(p.isWithin(p.join(docs.path, AudioFilePicker.importedFolder), path), isTrue, reason: path);
        expect(File(path).existsSync(), isTrue);
      }
      expect(File(picked.paths.first).readAsStringSync(), 'audio Tavern.m4a');
      expect(picked.paths.map(p.basename), ['Tavern.m4a', 'Tavern.mp3']);

      // The kept copies survive the system clearing the cache.
      cache.deleteSync(recursive: true);
      expect(picked.paths.every((path) => File(path).existsSync()), isTrue);
    });

    test('two files with the same name do not overwrite each other', () async {
      FilePicker.platform = FakeFilePicker([cached('Theme.m4a')]);
      final first = await AudioFilePicker.pick();
      File(p.join(cache.path, 'Theme.m4a')).writeAsStringSync('another theme');
      final second = await AudioFilePicker.pick();

      expect(first.paths.single, isNot(second.paths.single));
      expect(File(first.paths.single).readAsStringSync(), 'audio Theme.m4a');
      expect(File(second.paths.single).readAsStringSync(), 'another theme');
    });
  });

  group('On the desktop', () {
    setUp(() => AudioFilePicker.debugIsAndroid = false);

    test('filters by extension in the picker and uses the files where they are', () async {
      final picker = FakeFilePicker([cached('Tavern.m4a')]);
      FilePicker.platform = picker;

      final picked = await AudioFilePicker.pick();

      expect(picker.type, FileType.custom);
      expect(picker.allowedExtensions, contains('m4a'));
      expect(picked.paths.single, p.join(cache.path, 'Tavern.m4a'));
      expect(docs.listSync(), isEmpty);
    });

    test('returns nothing when the picker is cancelled', () async {
      FilePicker.platform = FakeFilePicker([]);
      final picked = await AudioFilePicker.pick();
      expect(picked.paths, isEmpty);
      expect(picked.skipped, 0);
    });
  });
}
