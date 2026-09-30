import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
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

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_db_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('DatabaseService Integration Tests', () {
    test('should insert and retrieve library track when inserted into SQLite database', () async {
      // Arrange
      final track = LibraryTrack(
        id: 'db-1',
        title: 'Epic Adventure',
        filePath: '/music/epic.mp3',
        busType: AudioBusType.music,
        intensity: MusicIntensity.battle,
        tags: const ['Battle', 'Epic'],
        colorHex: 0xFF9C27B0,
      );

      // Act
      await dbService.insertTrack(track);
      final tracks = await dbService.getAllTracks();

      // Assert
      expect(tracks.length, equals(1));
      expect(tracks.first.id, equals('db-1'));
      expect(tracks.first.title, equals('Epic Adventure'));
      expect(tracks.first.busType, equals(AudioBusType.music));
      expect(tracks.first.intensity, equals(MusicIntensity.battle));
      expect(tracks.first.tags, equals(['Battle', 'Epic']));
    });

    test('should filter tracks by bus type when getTracksByBus is queried', () async {
      // Arrange
      final t1 = LibraryTrack(id: '1', title: 'Music Track', filePath: '/m.mp3', busType: AudioBusType.music);
      final t2 = LibraryTrack(id: '2', title: 'Forest Ambience', filePath: '/a.mp3', busType: AudioBusType.ambient);
      final t3 = LibraryTrack(id: '3', title: 'Sword SFX', filePath: '/s.wav', busType: AudioBusType.sfx);

      await dbService.insertTrack(t1);
      await dbService.insertTrack(t2);
      await dbService.insertTrack(t3);

      // Act
      final ambientTracks = await dbService.getTracksByBus(AudioBusType.ambient);

      // Assert
      expect(ambientTracks.length, equals(1));
      expect(ambientTracks.first.title, equals('Forest Ambience'));
    });

    test('should match tracks by title and tags when search query is executed', () async {
      // Arrange
      final t1 = LibraryTrack(id: 's1', title: 'Tavern Party', filePath: '/1.mp3', busType: AudioBusType.music, tags: const ['Ale']);
      final t2 = LibraryTrack(id: 's2', title: 'Peaceful Night', filePath: '/2.mp3', busType: AudioBusType.ambient, tags: const ['Tavern', 'Cozy']);
      final t3 = LibraryTrack(id: 's3', title: 'Dungeon Ambience', filePath: '/3.mp3', busType: AudioBusType.ambient, tags: const ['Dark']);

      await dbService.insertTrack(t1);
      await dbService.insertTrack(t2);
      await dbService.insertTrack(t3);

      // Act
      final searchResults = await dbService.searchTracks('Tavern');

      // Assert
      expect(searchResults.length, equals(2));
    });

    test('should apply both keyword and bus filter when searching with filterBus parameter', () async {
      // Arrange
      final t1 = LibraryTrack(id: 's1', title: 'Tavern Party', filePath: '/1.mp3', busType: AudioBusType.music, tags: const ['Ale']);
      final t2 = LibraryTrack(id: 's2', title: 'Peaceful Night', filePath: '/2.mp3', busType: AudioBusType.ambient, tags: const ['Tavern', 'Cozy']);

      await dbService.insertTrack(t1);
      await dbService.insertTrack(t2);

      // Act
      final musicResults = await dbService.searchTracks('Tavern', filterBus: AudioBusType.music);
      final nonExistentResults = await dbService.searchTracks('NonExistentQuery');

      // Assert
      expect(musicResults.length, equals(1));
      expect(musicResults.first.id, equals('s1'));
      expect(nonExistentResults, isEmpty);
    });

    test('should update existing track record in database when updateTrack is called', () async {
      // Arrange
      final track = LibraryTrack(id: 'u1', title: 'Old Title', filePath: '/old.mp3', busType: AudioBusType.music);
      await dbService.insertTrack(track);

      // Act
      final updated = track.copyWith(title: 'Renamed Track');
      await dbService.updateTrack(updated);
      final all = await dbService.getAllTracks();

      // Assert
      expect(all.length, equals(1));
      expect(all.first.title, equals('Renamed Track'));
    });

    test('should delete track record by id when deleteTrack is called', () async {
      // Arrange
      final track = LibraryTrack(id: 'd1', title: 'To Delete', filePath: '/del.mp3', busType: AudioBusType.sfx);
      await dbService.insertTrack(track);
      expect((await dbService.getAllTracks()).length, equals(1));

      // Act
      await dbService.deleteTrack('d1');

      // Assert
      expect((await dbService.getAllTracks()), isEmpty);
    });

    test('should perform full CRUD operations for SceneModel in SQLite database', () async {
      // Arrange
      final scene = SceneModel(
        id: 'scene-db-1',
        name: 'Mystic Forest',
        description: 'Rustling leaves and ancient magic',
        colorHex: 0xFF4CAF50,
        musicTrackId: 'm-forest',
        musicIntensity: MusicIntensity.calm,
        ambientLayerVolumes: {'leaves': 0.7, 'wind': 0.5},
        soundboardSfxIds: ['sfx-branch'],
        imagePath: '/covers/forest.jpg',
      );

      // Act & Assert - 1. Insert & GetAll
      await dbService.insertScene(scene);
      final allScenes = await dbService.getAllScenes();
      expect(allScenes.length, equals(1));
      expect(allScenes.first.name, equals('Mystic Forest'));
      expect(allScenes.first.ambientLayerVolumes, equals({'leaves': 0.7, 'wind': 0.5}));
      expect(allScenes.first.imagePath, equals('/covers/forest.jpg'));

      // Act & Assert - 2. GetById
      final found = await dbService.getSceneById('scene-db-1');
      expect(found, isNotNull);
      expect(found!.id, equals('scene-db-1'));

      // Act & Assert - 3. Update
      final updated = scene.copyWith(name: 'Ancient Mystic Forest');
      await dbService.updateScene(updated);
      final updatedScenes = await dbService.getAllScenes();
      expect(updatedScenes.first.name, equals('Ancient Mystic Forest'));

      // Act & Assert - 4. Delete
      await dbService.deleteScene('scene-db-1');
      expect((await dbService.getAllScenes()), isEmpty);
      expect((await dbService.getSceneById('scene-db-1')), isNull);
    });

    test('should perform full CRUD operations for CustomThemeModel in SQLite database', () async {
      // Arrange
      const theme = CustomThemeModel(
        id: 'theme-db-1',
        name: 'Crimson Abyss',
        isDark: true,
        primaryColor: 0xFFE11D48,
        secondaryColor: 0xFFFB7185,
        backgroundColor: 0xFF140B0E,
        surfaceColor: 0xFF221116,
        cardColor: 0xFF2D161C,
        accentColor: 0xFFF43F5E,
        textPrimaryColor: 0xFFFFF1F2,
        textSecondaryColor: 0xFFFDA4AF,
        duckingBadgeColor: 0xFFEA580C,
        battleIntensityColor: 0xFFFF2E63,
        bossIntensityColor: 0xFF880808,
      );

      // Act & Assert - 1. Insert & GetAll
      await dbService.insertCustomTheme(theme);
      final allThemes = await dbService.getAllCustomThemes();
      expect(allThemes.length, equals(1));
      expect(allThemes.first.name, equals('Crimson Abyss'));
      expect(allThemes.first.primaryColor, equals(0xFFE11D48));

      // Act & Assert - 2. GetById
      final found = await dbService.getCustomThemeById('theme-db-1');
      expect(found, isNotNull);
      expect(found!.id, equals('theme-db-1'));
      expect(found.bossIntensityColor, equals(0xFF880808));

      // Act & Assert - 3. Update
      final updated = theme.copyWith(name: 'Crimson Catacombs');
      await dbService.updateCustomTheme(updated);
      final updatedThemes = await dbService.getAllCustomThemes();
      expect(updatedThemes.first.name, equals('Crimson Catacombs'));

      // Act & Assert - 4. Delete
      await dbService.deleteCustomTheme('theme-db-1');
      expect((await dbService.getAllCustomThemes()), isEmpty);
      expect((await dbService.getCustomThemeById('theme-db-1')), isNull);
    });
  });
}
