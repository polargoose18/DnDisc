import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/custom_theme_repository.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/data/services/theme_service.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';

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
    tempDir = await Directory.systemTemp.createTemp('ttrpg_vm_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('UI ViewModels Architecture Unit Tests', () {
    test('should perform CRUD operations and notify listeners in SceneViewModel', () async {
      // Arrange
      final repository = SqliteSceneRepository(db: dbService);
      final viewModel = SceneViewModel(repository: repository, autoLoad: false);

      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      // Act & Assert - Create scene
      final newScene = SceneModel(id: 'vm-scene-1', name: 'Forest Encounter');
      await viewModel.createScene(newScene);

      expect(notifyCount, greaterThan(0));
      expect(viewModel.scenes.length, equals(1));
      expect(viewModel.scenes.first.name, equals('Forest Encounter'));

      // Act & Assert - Delete scene
      await viewModel.deleteScene('vm-scene-1');
      expect(viewModel.scenes, isEmpty);
    });

    test('should forward notifications from SceneService to SceneViewModel via composition DI', () async {
      // Arrange
      final repository = SqliteSceneRepository(db: dbService);
      final service = SceneService(repository: repository, autoLoad: false);
      final viewModel = SceneViewModel(service: service);

      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      // Act
      final scene = SceneModel(id: 'vm-scene-comp', name: 'Dungeon Master');
      await service.createScene(scene);

      // Assert
      expect(notifyCount, greaterThan(0));
      expect(viewModel.scenes.length, equals(1));
      expect(viewModel.scenes.first.id, equals('vm-scene-comp'));
    });

    test('should filter and search tracks appropriately in MediaLibraryViewModel', () async {
      // Arrange
      final repository = SqliteMediaLibraryRepository(db: dbService);
      final viewModel = MediaLibraryViewModel(repository: repository, autoLoad: false);

      final track = LibraryTrack(
        id: 'vm-track-1',
        title: 'Battle Drums',
        filePath: '/music/drums.mp3',
        busType: AudioBusType.music,
      );

      // Act & Assert - Add track
      await viewModel.addTrack(track);
      expect(viewModel.tracks.length, equals(1));

      // Act & Assert - Filter out by different bus
      viewModel.setBusFilter(AudioBusType.ambient);
      expect(viewModel.tracks, isEmpty);

      // Act & Assert - Filter match
      viewModel.setBusFilter(AudioBusType.music);
      expect(viewModel.tracks.length, equals(1));

      // Act & Assert - Search mismatch
      viewModel.setSearchQuery('NonExistent');
      expect(viewModel.tracks, isEmpty);

      // Act & Assert - Search match
      viewModel.setSearchQuery('drums');
      expect(viewModel.tracks.length, equals(1));
    });

    test('should proxy service notifications through MediaLibraryViewModel when service is injected', () async {
      // Arrange
      final repository = SqliteMediaLibraryRepository(db: dbService);
      final service = MediaLibraryService(repository: repository, autoLoad: false);
      final viewModel = MediaLibraryViewModel(service: service);

      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      // Act
      final track = LibraryTrack(
        id: 'vm-track-comp',
        title: 'Tavern Lute',
        filePath: '/music/lute.mp3',
        busType: AudioBusType.music,
      );
      await service.addTrack(track);

      // Assert
      expect(notifyCount, greaterThan(0));
      expect(viewModel.tracks.length, equals(1));
      expect(viewModel.tracks.first.title, equals('Tavern Lute'));
    });

    test('should manage and switch active themes in ThemeViewModel', () async {
      // Arrange
      final repository = SqliteCustomThemeRepository(db: dbService);
      final viewModel = ThemeViewModel(repository: repository, autoLoad: false);

      // Act & Assert - Initial state
      expect(viewModel.activeTheme, isNotNull);
      expect(viewModel.currentThemeData, isNotNull);

      // Act & Assert - Theme selection
      viewModel.selectTheme(AppThemes.ancientParchmentId);
      expect(viewModel.activeTheme.id, equals(AppThemes.ancientParchmentId));
    });

    test('should reflect active theme updates when ThemeService is injected into ThemeViewModel', () async {
      // Arrange
      final service = ThemeService(initialThemeId: AppThemes.deepDarkId, autoLoad: false);
      final viewModel = ThemeViewModel(service: service);

      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      // Act
      service.selectTheme(AppThemes.cleanLightId);

      // Assert
      expect(notifyCount, greaterThan(0));
      expect(viewModel.activeThemeId, equals(AppThemes.cleanLightId));
    });
  });
}
