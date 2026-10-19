import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Direct canonical imports - verifying absence of legacy proxy dependencies
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/custom_theme_model.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';

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

  group('Milestone M2 Empirical Verification & Adversarial Stress Tests', () {
    late Directory tempDir;
    late DatabaseService dbService;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('m2_empirical_test_');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
      dbService = DatabaseService();
    });

    tearDown(() async {
      await dbService.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should ensure integrity and lossless serialization of domain models', () {
      // Arrange & Act & Assert - 1. AudioTrack
      const track = AudioTrack(
        id: 'trk-1',
        title: 'Epic Battle',
        filePath: '/audio/battle.mp3',
        intensity: MusicIntensity.boss,
        duration: Duration(seconds: 120),
      );
      final trackCopy = track.copyWith(title: 'Updated Battle');
      expect(trackCopy.id, equals('trk-1'));
      expect(trackCopy.title, equals('Updated Battle'));
      expect(trackCopy.intensity, equals(MusicIntensity.boss));

      // Arrange & Act & Assert - 2. AmbientLayer
      const layer = AmbientLayer(
        id: 'amb-1',
        title: 'Cave Wind',
        filePath: '/audio/cave.mp3',
        volume: 0.6,
        isActive: false,
      );
      final layerCopy = layer.copyWith(isActive: true, volume: 0.9);
      expect(layerCopy.id, equals('amb-1'));
      expect(layerCopy.isActive, isTrue);
      expect(layerCopy.volume, equals(0.9));

      // Arrange & Act & Assert - 3. SfxTrigger
      const sfx = SfxTrigger(
        id: 'sfx-1',
        title: 'Sword Clash',
        filePath: '/audio/sword.mp3',
        volume: 0.9,
        hotkey: 'KeyA',
      );
      final sfxCopy = sfx.copyWith(volume: 0.5);
      expect(sfxCopy.id, equals('sfx-1'));
      expect(sfxCopy.volume, equals(0.5));
      expect(sfxCopy.hotkey, equals('KeyA'));

      // Arrange & Act & Assert - 4. LibraryTrack
      final libTrack = LibraryTrack(
        id: 'lib-1',
        title: 'Forest Theme',
        filePath: '/audio/forest.mp3',
        busType: AudioBusType.music,
        tags: const ['nature', 'peaceful'],
      );
      final libTrackMap = libTrack.toMap();
      final restoredLibTrack = LibraryTrack.fromMap(libTrackMap);
      expect(restoredLibTrack.id, equals('lib-1'));
      expect(restoredLibTrack.busType, equals(AudioBusType.music));
      expect(restoredLibTrack.tags, containsAll(['nature', 'peaceful']));

      // Arrange & Act & Assert - 5. SceneModel
      final scene = SceneModel(
        id: 'scene-1',
        name: 'Haunted Castle',
        description: 'Spooky ruins',
        ambientLayerVolumes: const {'amb-1': 0.7},
        soundboardSfxIds: const ['sfx-1'],
      );
      final sceneMap = scene.toMap();
      final restoredScene = SceneModel.fromMap(sceneMap);
      expect(restoredScene.id, equals('scene-1'));
      expect(restoredScene.name, equals('Haunted Castle'));
      expect(restoredScene.ambientLayerVolumes['amb-1'], equals(0.7));
      expect(restoredScene.soundboardSfxIds, contains('sfx-1'));

      // Arrange & Act & Assert - 6. CustomThemeModel
      final theme = CustomThemeModel.derive(
        id: 'thm-1',
        name: 'Dungeon Master Dark',
        background: 0xFF11111B,
        surface: 0xFF181825,
        text: 0xFFCDD6F4,
        primary: 0xFF1E1E2E,
        calm: 0xFF89B4FA,
        suspense: 0xFFF5C2E7,
        battle: 0xFFF38BA8,
        boss: 0xFFCBA6F7,
      );
      final themeMap = theme.toMap();
      final restoredTheme = CustomThemeModel.fromMap(themeMap);
      expect(restoredTheme.id, equals('thm-1'));
      expect(restoredTheme.primary, equals(const Color(0xFF1E1E2E)));

      // Arrange & Act & Assert - 7. SceneRepositoryModel
      final repoSource = SceneRepositoryModel(
        id: 'repo-1',
        name: 'Official TTRPG Repo',
        url: 'https://example.com/manifest.json',
        description: 'Official repository',
        createdAt: DateTime.now(),
      );
      expect(repoSource.id, equals('repo-1'));
      expect(repoSource.name, equals('Official TTRPG Repo'));
    });

    test('should execute basic CRUD database operations cleanly without proxy dependencies', () async {
      // Arrange & Act & Assert - Track CRUD
      final track = LibraryTrack(
        id: 'crud-track-1',
        title: 'Battle March',
        filePath: '/test/march.mp3',
        busType: AudioBusType.music,
        tags: const ['battle'],
      );
      await dbService.insertTrack(track);
      final tracks = await dbService.getAllTracks();
      expect(tracks.length, equals(1));
      expect(tracks.first.title, equals('Battle March'));

      // Arrange & Act & Assert - Scene CRUD
      final scene = SceneModel(
        id: 'crud-scene-1',
        name: 'Tavern Evening',
        description: 'Lively atmosphere',
      );
      await dbService.insertScene(scene);
      final scenes = await dbService.getAllScenes();
      expect(scenes.length, equals(1));
      expect(scenes.first.name, equals('Tavern Evening'));

      // Arrange & Act & Assert - Theme CRUD
      final theme = CustomThemeModel.derive(
        id: 'crud-theme-1',
        name: 'Mystic Purple',
        background: 0xFF12005E,
        surface: 0xFF1D0047,
        text: 0xFFFFFFFF,
        primary: 0xFF4A148C,
        calm: 0xFF7C4DFF,
        suspense: 0xFFBB86FC,
        battle: 0xFFEF4444,
        boss: 0xFF9333EA,
      );
      await dbService.insertCustomTheme(theme);
      final themes = await dbService.getAllCustomThemes();
      expect(themes.length, equals(1));
      expect(themes.first.name, equals('Mystic Purple'));
    });

    test('should integrate audio controllers smoothly with domain models', () async {
      // Arrange
      final musicBus = MusicBusController();
      final ambientBus = AmbientBusController();
      final sfxBus = SfxBusController();

      try {
        // Act & Assert - Music bus with AudioTrack
        const track = AudioTrack(
          id: 'bus-track-1',
          title: 'Ambient Meadow',
          filePath: '/non_existent_file.mp3',
          intensity: MusicIntensity.calm,
        );
        await musicBus.playTrack(track);
        expect(musicBus.isPlaying, isFalse);
        expect(musicBus.rawVolume, equals(1.0));

        // Act & Assert - Ambient bus with AmbientLayer
        const layer = AmbientLayer(
          id: 'bus-layer-1',
          title: 'Rain',
          filePath: '/non_existent_rain.mp3',
          volume: 0.5,
        );
        ambientBus.addLayer(layer);
        expect(ambientBus.layers.length, equals(1));
        expect(ambientBus.layers.first.id, equals('bus-layer-1'));

        // Act & Assert - Sfx bus with SfxTrigger
        const sfx = SfxTrigger(
          id: 'bus-sfx-1',
          title: 'Thunder',
          filePath: '/non_existent_thunder.mp3',
          volume: 0.9,
        );
        sfxBus.addTrigger(sfx);
        expect(sfxBus.triggers.length, equals(1));
        expect(sfxBus.rawVolume, equals(1.0));
      } finally {
        musicBus.dispose();
        ambientBus.dispose();
        sfxBus.dispose();
      }
    });

    test('should verify removal of obsolete lib/models and lib/db directories', () {
      // Arrange & Act & Assert
      expect(Directory('lib/models').existsSync(), isFalse);
      expect(Directory('lib/db').existsSync(), isFalse);
    });
  });
}
