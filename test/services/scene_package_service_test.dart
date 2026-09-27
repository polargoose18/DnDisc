import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/db/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/services/scene_package_service.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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
    tempDir = await Directory.systemTemp.createTemp('ttrpg_scene_pack_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('ScenePackageService Tests', () {
    test(
      'Что проверяем: Экспорт отдельной сцены exportSingleScene и импорт через importSingleScenePackage. '
      'Входные данные: 1 сцена, 2 привязанных трека (музыка и эмбиент). '
      'Ожидаемый результат: Создаётся валидный .scene.zip с scene.json, который импортируется и регистрирует сцену и её треки в БД.',
      () async {
        final packageService = ScenePackageService(db: dbService);

        final projectRoot = Directory.current.path;
        final musicFile = File(p.join(projectRoot, 'audio', 'music.mp3'));
        final ambFile = File(p.join(projectRoot, 'audio', 'ambient.mp3'));

        expect(musicFile.existsSync(), isTrue);
        expect(ambFile.existsSync(), isTrue);

        final track1 = LibraryTrack(
          id: 'scene-music-1',
          title: 'Dragon Music',
          filePath: musicFile.path,
          busType: AudioBusType.music,
        );

        final track2 = LibraryTrack(
          id: 'scene-amb-1',
          title: 'Cave Wind',
          filePath: ambFile.path,
          busType: AudioBusType.ambient,
        );

        await dbService.insertTrack(track1);
        await dbService.insertTrack(track2);

        final scene = SceneModel(
          id: 'dragon-lair-scene',
          name: 'Логово Дракона',
          description: 'Мрачная пещера с дыханием дракона',
          musicTrackId: track1.id,
          musicIntensity: MusicIntensity.battle,
          ambientLayerVolumes: {track2.id: 0.9},
        );

        await dbService.insertScene(scene);

        final zipPath = p.join(tempDir.path, 'dragon_lair.scene.zip');

        // Export
        final exportedFile = await packageService.exportSingleScene(
          scene: scene,
          exportZipPath: zipPath,
        );

        expect(exportedFile.existsSync(), isTrue);
        expect(exportedFile.lengthSync(), greaterThan(50));

        // Import into clean DB / dir
        final importDestDir = p.join(tempDir.path, 'imported_audio');
        final result = await packageService.importSingleScenePackage(
          zipFilePath: zipPath,
          destinationAudioDir: importDestDir,
        );

        expect(result.scene.id, equals('dragon-lair-scene'));
        expect(result.scene.name, equals('Логово Дракона'));
        expect(result.importedTracks.length, equals(2));

        for (final tr in result.importedTracks) {
          expect(File(tr.filePath).existsSync(), isTrue);
        }
      },
    );

    test(
      'Что проверяем: Исключение при импорте из несуществующего ZIP файла. '
      'Входные данные: zipFilePath="/invalid/path/nonexistent.scene.zip". '
      'Ожидаемый результат: Выбрасывается FileSystemException.',
      () async {
        final packageService = ScenePackageService(db: dbService);

        expect(
          () => packageService.importSingleScenePackage(
            zipFilePath: '/invalid/path/nonexistent.scene.zip',
            destinationAudioDir: tempDir.path,
          ),
          throwsA(isA<FileSystemException>()),
        );
      },
    );

    test(
      'Что проверяем: Исключение при импорте повреждённого ZIP без scene.json. '
      'Входные данные: ZIP архив с фейковым текстовым файлом. '
      'Ожидаемый результат: Выбрасывается FormatException.',
      () async {
        final packageService = ScenePackageService(db: dbService);

        final dummyZipPath = p.join(tempDir.path, 'invalid.scene.zip');
        final archive = Archive();
        archive.addFile(ArchiveFile.string('readme.txt', 'no scene json here'));
        final encoded = ZipEncoder().encode(archive);
        await File(dummyZipPath).writeAsBytes(encoded);

        expect(
          () => packageService.importSingleScenePackage(
            zipFilePath: dummyZipPath,
            destinationAudioDir: tempDir.path,
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'Что проверяем: Предотвращение уязвимости Zip Slip при попытке выхода за пределы целевой директории. '
      'Входные данные: ZIP архив со служебными путями "../../../evil.txt" и scene.json. '
      'Ожидаемый результат: Выбрасывается FormatException с ошибкой Zip Slip.',
      () async {
        final packageService = ScenePackageService(db: dbService);

        final evilZipPath = p.join(tempDir.path, 'evil.scene.zip');
        final archive = Archive();
        archive.addFile(ArchiveFile.string('scene.json', '{"scene": {"id": "1", "name": "Evil"}, "tracks": []}'));
        archive.addFile(ArchiveFile.string('../../evil.txt', 'malicious content'));
        final encoded = ZipEncoder().encode(archive);
        await File(evilZipPath).writeAsBytes(encoded);

        expect(
          () => packageService.importSingleScenePackage(
            zipFilePath: evilZipPath,
            destinationAudioDir: p.join(tempDir.path, 'extract_target'),
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
