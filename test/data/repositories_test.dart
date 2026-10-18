import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/custom_theme_repository.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/custom_theme_model.dart';

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
  late MediaLibraryRepository mediaRepo;
  late SceneRepository sceneRepo;
  late CustomThemeRepository themeRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_repo_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
    mediaRepo = SqliteMediaLibraryRepository(db: dbService);
    sceneRepo = SqliteSceneRepository(db: dbService);
    themeRepo = SqliteCustomThemeRepository(db: dbService);
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('Data Repositories Unit Tests', () {
    test('should insert, query, search, update, and delete tracks via SqliteMediaLibraryRepository', () async {
      // Arrange
      final track = LibraryTrack(
        id: 'repo-track-1',
        title: 'Dungeon March',
        filePath: '/music/march.mp3',
        busType: AudioBusType.music,
        intensity: MusicIntensity.battle,
        tags: const ['Dungeon'],
      );

      // Act & Assert - Insert & GetAll
      await mediaRepo.insertTrack(track);
      final all = await mediaRepo.getAllTracks();
      expect(all.length, equals(1));
      expect(all.first.id, equals('repo-track-1'));

      // Act & Assert - GetById
      final fetched = await mediaRepo.getTrackById('repo-track-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Dungeon March'));

      // Act & Assert - Search
      final search = await mediaRepo.searchTracks('Dungeon');
      expect(search.length, equals(1));

      // Act & Assert - Update
      final updated = track.copyWith(title: 'Updated March');
      await mediaRepo.updateTrack(updated);
      final checkUpdated = await mediaRepo.getTrackById('repo-track-1');
      expect(checkUpdated!.title, equals('Updated March'));

      // Act & Assert - Delete
      await mediaRepo.deleteTrack('repo-track-1');
      expect(await mediaRepo.getAllTracks(), isEmpty);
    });

    test('should perform full CRUD lifecycle on SceneModel via SqliteSceneRepository', () async {
      // Arrange
      final scene = SceneModel(
        id: 'repo-scene-1',
        name: 'Tavern Brawl',
        description: 'Fun battle scene',
      );

      // Act & Assert - Insert & GetAll
      await sceneRepo.insertScene(scene);
      final scenes = await sceneRepo.getAllScenes();
      expect(scenes.length, equals(1));
      expect(scenes.first.name, equals('Tavern Brawl'));

      // Act & Assert - GetById
      final fetched = await sceneRepo.getSceneById('repo-scene-1');
      expect(fetched, isNotNull);

      // Act & Assert - Update
      final updated = scene.copyWith(name: 'Epic Tavern Brawl');
      await sceneRepo.updateScene(updated);
      final checkUpdated = await sceneRepo.getSceneById('repo-scene-1');
      expect(checkUpdated!.name, equals('Epic Tavern Brawl'));

      // Act & Assert - Delete
      await sceneRepo.deleteScene('repo-scene-1');
      expect(await sceneRepo.getAllScenes(), isEmpty);
    });

    test('should perform full CRUD lifecycle on CustomThemeModel via SqliteCustomThemeRepository', () async {
      // Arrange
      final theme = CustomThemeModel.derive(
        id: 'repo-theme-1',
        name: 'Cyberpunk Red',
        background: 0xFF0A0A10,
        surface: 0xFF12121C,
        text: 0xFFFFFFFF,
        primary: 0xFFFF0055,
        calm: 0xFF00FFFF,
        suspense: 0xFFFF0055,
        battle: 0xFFE8744F,
        boss: 0xFFE0485E,
      );

      // Act & Assert - Insert & GetAll
      await themeRepo.insertCustomTheme(theme);
      final themes = await themeRepo.getAllCustomThemes();
      expect(themes.length, equals(1));
      expect(themes.first.name, equals('Cyberpunk Red'));

      // Act & Assert - GetById
      final fetched = await themeRepo.getCustomThemeById('repo-theme-1');
      expect(fetched, isNotNull);

      // Act & Assert - Update
      final updated = theme.copyWith(name: 'Cyberpunk Neon Red');
      await themeRepo.updateCustomTheme(updated);
      final checkUpdated = await themeRepo.getCustomThemeById('repo-theme-1');
      expect(checkUpdated!.name, equals('Cyberpunk Neon Red'));

      // Act & Assert - Delete
      await themeRepo.deleteCustomTheme('repo-theme-1');
      expect(await themeRepo.getAllCustomThemes(), isEmpty);
    });
  });
}
