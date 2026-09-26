import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/db/database_service.dart';
import 'package:ttrpg_audio_player/services/preset_service.dart';
import 'package:ttrpg_audio_player/models/library_track.dart';
import 'package:ttrpg_audio_player/models/audio_track.dart';
import 'package:ttrpg_audio_player/models/scene_model.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempPath;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatabaseService dbService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_preset_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('PresetService Unit & Integration Tests', () {
    test(
      'Что проверяем: Экспорт и последующий импорт ZIP-пресета с реальными аудиофайлами. '
      'Входные данные: Тестовые файлы audio/music.mp3, audio/ambient.mp3, audio/sfx.mp3, 1 сцена. '
      'Ожидаемый результат: Создается валидный ZIP архив, который успешно распаковывается и регистрирует треки и сцены в SQLite.',
      () async {
        final presetService = PresetService(db: dbService);

        // Используем реальные файлы из репозитория
        final projectRoot = Directory.current.path;
        final musicFile = File(p.join(projectRoot, 'audio', 'music.mp3'));
        final ambFile = File(p.join(projectRoot, 'audio', 'ambient.mp3'));
        final sfxFile = File(p.join(projectRoot, 'audio', 'sfx.mp3'));

        expect(musicFile.existsSync(), isTrue, reason: 'audio/music.mp3 must exist');
        expect(ambFile.existsSync(), isTrue, reason: 'audio/ambient.mp3 must exist');
        expect(sfxFile.existsSync(), isTrue, reason: 'audio/sfx.mp3 must exist');

        final trackMusic = LibraryTrack(
          id: 'test-track-music',
          title: 'Music Sample',
          filePath: musicFile.path,
          busType: AudioBusType.music,
          intensity: MusicIntensity.calm,
          tags: ['test', 'sample'],
        );

        final trackAmb = LibraryTrack(
          id: 'test-track-amb',
          title: 'Ambient Sample',
          filePath: ambFile.path,
          busType: AudioBusType.ambient,
        );

        final trackSfx = LibraryTrack(
          id: 'test-track-sfx',
          title: 'SFX Sample',
          filePath: sfxFile.path,
          busType: AudioBusType.sfx,
        );

        final scene = SceneModel(
          id: 'test-scene-pack',
          name: 'Тестовая Сцена Пака',
          description: 'Сцена внутри экспортируемого архива',
          musicTrackId: 'test-track-music',
          musicIntensity: MusicIntensity.calm,
          ambientLayerVolumes: {'test-track-amb': 0.85},
          soundboardSfxIds: ['test-track-sfx'],
        );

        final exportZipPath = p.join(tempDir.path, 'exported_pack.zip');

        // 1. Export
        final exportedFile = await presetService.exportPreset(
          exportZipPath: exportZipPath,
          title: 'Curse of Strahd Audio Pack',
          description: 'Готовый аудио-пак для мрачной готической кампании',
          scenes: [scene],
          tracks: [trackMusic, trackAmb, trackSfx],
        );

        expect(exportedFile.existsSync(), isTrue);
        expect(exportedFile.lengthSync(), greaterThan(100));

        // 2. Import into separate destination
        final importAudioDir = p.join(tempDir.path, 'unpacked_audio');
        final importResult = await presetService.importPreset(
          zipFilePath: exportZipPath,
          destinationAudioDir: importAudioDir,
        );

        expect(importResult.title, equals('Curse of Strahd Audio Pack'));
        expect(importResult.importedTracks.length, equals(3));
        expect(importResult.importedScenes.length, equals(1));
        expect(importResult.importedScenes.first.name, equals('Тестовая Сцена Пака'));

        // Проверяем физическое извлечение файлов
        for (final tr in importResult.importedTracks) {
          expect(File(tr.filePath).existsSync(), isTrue);
        }

        // Проверяем запись в базу данных SQLite
        final dbTracks = await dbService.getAllTracks();
        final dbScenes = await dbService.getAllScenes();

        expect(dbTracks.length, equals(3));
        expect(dbScenes.length, equals(1));
        expect(dbScenes.first.ambientLayerVolumes['test-track-amb'], equals(0.85));
      },
    );

    test(
      'Что проверяем: Обработка ошибки импорта при отсутствии ZIP файла. '
      'Входные данные: Несуществующий путь /fake_path/missing.zip. '
      'Ожидаемый результат: Выбрасывается исключение FileSystemException.',
      () async {
        final presetService = PresetService(db: dbService);

        expect(
          () => presetService.importPreset(
            zipFilePath: '/fake_path/missing_archive.zip',
            destinationAudioDir: tempDir.path,
          ),
          throwsA(isA<FileSystemException>()),
        );
      },
    );

    test(
      'Что проверяем: Обработка ошибки при поврежденном архиве без preset.json. '
      'Входные данные: ZIP архив, содержащий только случайный текстовый файл. '
      'Ожидаемый результат: Выбрасывается FormatException с указанием отсутствия preset.json.',
      () async {
        final presetService = PresetService(db: dbService);

        // Создаем пустой zip
        final dummyZipPath = p.join(tempDir.path, 'corrupted.zip');
        final dummyFile = File(dummyZipPath);
        // Запишем пустые байты zip
        final archive = Archive();
        archive.addFile(ArchiveFile.string('readme.txt', 'hello world'));
        final encoded = ZipEncoder().encode(archive);
        await dummyFile.writeAsBytes(encoded);

        expect(
          () => presetService.importPreset(
            zipFilePath: dummyZipPath,
            destinationAudioDir: tempDir.path,
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
