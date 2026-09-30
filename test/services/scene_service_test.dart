import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';

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
    tempDir = await Directory.systemTemp.createTemp('ttrpg_scene_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('SceneService Unit & Integration Tests', () {
    test('should manage scene lifecycle (create, load, update, and delete) in SceneService', () async {
      // Arrange
      final sceneService = SceneService();
      await sceneService.loadScenes();
      expect(sceneService.scenes, isEmpty);

      final scene = SceneModel(
        id: 'sc-1',
        name: 'Tavern',
        description: 'Warm fireplace and lute music',
        colorHex: 0xFF9C27B0,
      );

      // Act & Assert - Create
      await sceneService.createScene(scene);
      expect(sceneService.scenes.length, equals(1));
      expect(sceneService.scenes.first.name, equals('Tavern'));

      // Act & Assert - Update
      final updated = scene.copyWith(name: 'Noisy Tavern');
      await sceneService.updateScene(updated);
      expect(sceneService.scenes.first.name, equals('Noisy Tavern'));

      // Act & Assert - Delete
      await sceneService.deleteScene('sc-1');
      expect(sceneService.scenes, isEmpty);

      sceneService.dispose();
    });

    test('should activate scene by configuring music bus, ambient layers, and SFX triggers', () async {
      // Arrange
      final sceneService = SceneService();
      final mediaLibrary = MediaLibraryService();
      final audioEngine = AudioEngineService();

      final musicTrack = LibraryTrack(
        id: 'tr-music-1',
        title: 'Tavern Lute',
        filePath: '/fake/lute.mp3',
        busType: AudioBusType.music,
        intensity: MusicIntensity.calm,
      );
      final ambTrack1 = LibraryTrack(
        id: 'tr-amb-1',
        title: 'Fireplace',
        filePath: '/fake/fire.mp3',
        busType: AudioBusType.ambient,
      );
      final ambTrack2 = LibraryTrack(
        id: 'tr-amb-2',
        title: 'Crowd Chatter',
        filePath: '/fake/crowd.mp3',
        busType: AudioBusType.ambient,
      );
      final sfxTrack = LibraryTrack(
        id: 'tr-sfx-1',
        title: 'Beer Clink',
        filePath: '/fake/clink.wav',
        busType: AudioBusType.sfx,
      );

      await mediaLibrary.addTrack(musicTrack);
      await mediaLibrary.addTrack(ambTrack1);
      await mediaLibrary.addTrack(ambTrack2);
      await mediaLibrary.addTrack(sfxTrack);

      final scene = SceneModel(
        id: 'scene-tavern',
        name: 'Jolly Goblin Tavern',
        musicTrackId: 'tr-music-1',
        musicIntensity: MusicIntensity.calm,
        ambientLayerVolumes: {
          'tr-amb-1': 0.7,
          'tr-amb-2': 0.5,
        },
        soundboardSfxIds: ['tr-sfx-1'],
      );

      await sceneService.createScene(scene);

      // Act
      await sceneService.activateScene(
        scene,
        audioEngine: audioEngine,
        mediaLibrary: mediaLibrary,
        fadeDuration: Duration.zero,
      );

      // Assert
      expect(sceneService.activeSceneId, equals('scene-tavern'));
      expect(sceneService.activeScene?.name, equals('Jolly Goblin Tavern'));
      expect(audioEngine.musicBus.currentTrack?.id, equals('tr-music-1'));
      expect(audioEngine.musicBus.isPlaying, isFalse);
      expect(audioEngine.ambientBus.layers.length, equals(2));
      expect(audioEngine.ambientBus.layers.every((l) => !l.isActive), isTrue);
      expect(audioEngine.ambientBus.layers.firstWhere((l) => l.id == 'tr-amb-1').volume, equals(0.7));
      expect(audioEngine.ambientBus.layers.firstWhere((l) => l.id == 'tr-amb-2').volume, equals(0.5));
      expect(audioEngine.sfxBus.triggers.any((t) => t.id == 'tr-sfx-1'), isTrue);

      mediaLibrary.dispose();
      sceneService.dispose();
      audioEngine.dispose();
    });

    test('should preserve persistent ambient layers and SFX triggers across scene transitions', () async {
      // Arrange
      final sceneService = SceneService();
      final mediaLibrary = MediaLibraryService();
      final audioEngine = AudioEngineService();

      // Add persistent and temporary ambient layers
      audioEngine.ambientBus.addLayer(
        const AmbientLayer(id: 'camp-persistent', title: 'Campfire', filePath: '/fake/camp.mp3', isPersistent: true),
      );
      audioEngine.ambientBus.addLayer(
        const AmbientLayer(id: 'rain-temp', title: 'Rain', filePath: '/fake/rain.mp3', isPersistent: false),
      );

      // Add persistent and temporary SFX triggers
      audioEngine.sfxBus.addTrigger(
        const SfxTrigger(id: 'dice-persistent', title: 'Dice Roll', filePath: '/fake/dice.wav', isPersistent: true),
      );
      audioEngine.sfxBus.addTrigger(
        const SfxTrigger(id: 'scream-temp', title: 'Scream', filePath: '/fake/scream.wav', isPersistent: false),
      );

      final quietScene = SceneModel(
        id: 'scene-quiet',
        name: 'Silence',
        musicTrackId: null,
        ambientLayerVolumes: {},
        soundboardSfxIds: [],
      );

      // Act
      await sceneService.activateScene(
        quietScene,
        audioEngine: audioEngine,
        mediaLibrary: mediaLibrary,
        fadeDuration: Duration.zero,
      );

      // Assert - persistent ambient retained, temporary removed
      expect(audioEngine.ambientBus.layers.any((l) => l.id == 'camp-persistent'), isTrue);
      expect(audioEngine.ambientBus.layers.any((l) => l.id == 'rain-temp'), isFalse);

      // Assert - persistent SFX retained, temporary removed
      expect(audioEngine.sfxBus.triggers.any((t) => t.id == 'dice-persistent'), isTrue);
      expect(audioEngine.sfxBus.triggers.any((t) => t.id == 'scream-temp'), isFalse);
      expect(audioEngine.musicBus.currentTrack, isNull);

      mediaLibrary.dispose();
      sceneService.dispose();
      audioEngine.dispose();
    });
  });
}
