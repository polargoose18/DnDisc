import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ducking_controller.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MusicBusController Unit Tests', () {
    late MusicBusController musicBus;

    setUp(() {
      musicBus = MusicBusController();
    });

    tearDown(() {
      musicBus.dispose();
    });

    test('should initialize with default idle state when constructed', () {
      // Arrange & Act
      // Initialized in setUp

      // Assert
      expect(musicBus.currentTrack, isNull);
      expect(musicBus.isPlaying, isFalse);
      expect(musicBus.rawVolume, equals(1.0));
      expect(musicBus.effectiveVolume, equals(1.0));
      expect(musicBus.currentIntensity, equals(MusicIntensity.calm));
    });

    test('should update intensity and notify listeners only when intensity actually changes', () {
      // Arrange
      int notifyCount = 0;
      musicBus.addListener(() => notifyCount++);

      // Act
      musicBus.setIntensity(MusicIntensity.boss);

      // Assert
      expect(musicBus.currentIntensity, equals(MusicIntensity.boss));
      expect(notifyCount, equals(1));

      // Act - repeat call with identical value
      musicBus.setIntensity(MusicIntensity.boss);

      // Assert - no additional notification
      expect(notifyCount, equals(1));
    });

    test('should clamp raw and effective volume within [0.0, 1.0] when out-of-bounds values are set', () {
      // Arrange & Act
      musicBus.setVolume(0.7);

      // Assert
      expect(musicBus.rawVolume, equals(0.7));
      expect(musicBus.effectiveVolume, equals(0.7));

      // Act & Assert lower bound
      musicBus.setVolume(-0.5);
      expect(musicBus.rawVolume, equals(0.0));

      // Act & Assert upper bound
      musicBus.setVolume(1.5);
      expect(musicBus.rawVolume, equals(1.0));
    });

    test('should calculate effective volume correctly when ducking multiplier is updated', () {
      // Arrange
      musicBus.setVolume(0.8);

      // Act
      musicBus.updateDuckingMultiplier(0.4);

      // Assert
      expect(musicBus.rawVolume, equals(0.8));
      expect(musicBus.effectiveVolume, closeTo(0.32, 0.001));
    });

    test('should update current track metadata but remain paused when playing non-existent file', () async {
      // Arrange
      const track = AudioTrack(
        id: 'missing-1',
        title: 'Ghost Song',
        filePath: '/non_existent_path_12345.mp3',
        intensity: MusicIntensity.suspense,
      );

      // Act
      await musicBus.playTrack(track);

      // Assert
      expect(musicBus.currentTrack, equals(track));
      expect(musicBus.currentIntensity, equals(MusicIntensity.suspense));
      expect(musicBus.isPlaying, isFalse);
    });

    test('should correctly transition playback state when pause, resume, and stop are invoked', () async {
      // Arrange
      const track = AudioTrack(
        id: 'dummy',
        title: 'Dummy Track',
        filePath: '/fake/dummy.mp3',
      );
      await musicBus.playTrack(track);

      // Act & Assert - Pause
      await musicBus.pause();
      expect(musicBus.isPlaying, isFalse);

      // Act & Assert - Resume
      await musicBus.resume();
      expect(musicBus.isPlaying, isTrue);

      // Act & Assert - Stop
      await musicBus.stop();
      expect(musicBus.isPlaying, isFalse);
      expect(musicBus.currentTrack, isNull);
    });

    test('should remain in idle state when resume is called without an active track', () async {
      // Arrange & Act
      await musicBus.resume();

      // Assert
      expect(musicBus.isPlaying, isFalse);
      expect(musicBus.currentTrack, isNull);
    });
  });

  group('AmbientBusController Unit Tests', () {
    late AmbientBusController ambientBus;

    setUp(() {
      ambientBus = AmbientBusController();
    });

    tearDown(() {
      ambientBus.dispose();
    });

    test('should ignore duplicate layer additions when layer ID already exists', () {
      // Arrange
      const layer = AmbientLayer(id: 'rain-1', title: 'Rain', filePath: '/rain.mp3');

      // Act
      ambientBus.addLayer(layer);
      ambientBus.addLayer(layer);

      // Assert
      expect(ambientBus.layers.length, equals(1));
    });

    test('should toggle active state of ambient layer when toggleLayer is invoked', () async {
      // Arrange
      const layer = AmbientLayer(id: 'rain-1', title: 'Rain', filePath: '/rain.mp3', isActive: false);
      ambientBus.addLayer(layer);

      // Act - activate
      await ambientBus.toggleLayer('rain-1');

      // Assert
      expect(ambientBus.layers.firstWhere((l) => l.id == 'rain-1').isActive, isTrue);

      // Act - deactivate
      await ambientBus.toggleLayer('rain-1');

      // Assert
      expect(ambientBus.layers.firstWhere((l) => l.id == 'rain-1').isActive, isFalse);
    });

    test('should handle non-existent layer ID gracefully when toggling or adjusting volume', () async {
      // Arrange
      const layer = AmbientLayer(id: 'rain-1', title: 'Rain', filePath: '/rain.mp3');
      ambientBus.addLayer(layer);

      // Act
      await ambientBus.toggleLayer('non-existent');
      ambientBus.setLayerVolume('non-existent', 0.5);

      // Assert
      expect(ambientBus.layers.first.isActive, isFalse);
      expect(ambientBus.layers.first.volume, equals(0.8));
    });

    test('should update and clamp individual layer volume when setLayerVolume is called', () {
      // Arrange
      const layer = AmbientLayer(id: 'rain-1', title: 'Rain', filePath: '/rain.mp3', volume: 0.8);
      ambientBus.addLayer(layer);

      // Act & Assert valid range
      ambientBus.setLayerVolume('rain-1', 0.35);
      expect(ambientBus.layers.first.volume, equals(0.35));

      // Act & Assert clamped upper bound
      ambientBus.setLayerVolume('rain-1', 1.5);
      expect(ambientBus.layers.first.volume, equals(1.0));
    });

    test('should clamp ambient master volume to [0.0, 1.0] when out-of-range value is supplied', () {
      // Arrange & Act
      ambientBus.setMasterVolume(-0.5);

      // Assert
      expect(ambientBus.masterVolume, equals(0.0));

      // Act & Assert
      ambientBus.setMasterVolume(1.8);
      expect(ambientBus.masterVolume, equals(1.0));
    });

    test('should deactivate all layers when stopAllLayers is called', () async {
      // Arrange
      const l1 = AmbientLayer(id: 'l1', title: 'Rain', filePath: '/r.mp3', isActive: true);
      const l2 = AmbientLayer(id: 'l2', title: 'Wind', filePath: '/w.mp3', isActive: true);
      const l3 = AmbientLayer(id: 'l3', title: 'Birds', filePath: '/b.mp3', isActive: false);

      ambientBus.addLayer(l1);
      ambientBus.addLayer(l2);
      ambientBus.addLayer(l3);

      // Act
      await ambientBus.stopAllLayers();

      // Assert
      expect(ambientBus.layers.every((l) => !l.isActive), isTrue);
    });
  });

  group('SfxBusController Unit Tests', () {
    late SfxBusController sfxBus;
    bool callbackFired = false;

    setUp(() {
      callbackFired = false;
      sfxBus = SfxBusController(
        onSfxTriggered: () {
          callbackFired = true;
        },
      );
    });

    test('should register trigger and invoke callback when triggerSfx is executed', () async {
      // Arrange
      const trigger = SfxTrigger(id: 'sword-1', title: 'Sword', filePath: '/sfx/sword.wav');
      sfxBus.addTrigger(trigger);

      expect(sfxBus.triggers.length, equals(1));

      // Act
      await sfxBus.triggerSfx('sword-1');

      // Assert
      expect(callbackFired, isTrue);
    });

    test('should not fire trigger callback when trigger ID does not exist', () async {
      // Arrange & Act
      await sfxBus.triggerSfx('non-existent-id');

      // Assert
      expect(callbackFired, isFalse);
    });

    test('should calculate effective volume correctly from raw and master volumes', () {
      // Arrange & Act
      sfxBus.setVolume(0.7);
      sfxBus.setMasterVolume(0.5);

      // Assert
      expect(sfxBus.rawVolume, equals(0.7));
      expect(sfxBus.masterVolume, equals(0.5));
      expect(sfxBus.effectiveVolume, closeTo(0.35, 0.001));

      // Act & Assert clamping
      sfxBus.setVolume(-0.2);
      expect(sfxBus.rawVolume, equals(0.0));
      sfxBus.setVolume(1.5);
      expect(sfxBus.rawVolume, equals(1.0));
    });

    test('should clamp master volume to [0.0, 1.0] when setMasterVolume is called', () {
      // Arrange & Act
      sfxBus.setMasterVolume(0.6);

      // Assert
      expect(sfxBus.masterVolume, equals(0.6));

      // Act & Assert
      sfxBus.setMasterVolume(-0.2);
      expect(sfxBus.masterVolume, equals(0.0));
    });
  });

  group('DuckingController Unit Tests', () {
    late DuckingController duckingController;

    setUp(() {
      duckingController = DuckingController(
        duckedVolumeMultiplier: 0.4,
        releaseDuration: const Duration(milliseconds: 100),
      );
    });

    tearDown(() {
      duckingController.dispose();
    });

    test('should lower volume multiplier immediately and restore it after release duration', () async {
      // Arrange
      double currentMultiplier = 1.0;

      // Act
      duckingController.triggerDuck(
        onVolumeUpdate: (m) => currentMultiplier = m,
        holdDuration: Duration.zero,
      );

      // Assert
      expect(duckingController.isDucked, isTrue);
      expect(currentMultiplier, equals(0.4));

      // Wait for releaseDuration (100ms) to complete with buffer
      await Future.delayed(const Duration(milliseconds: 250));

      expect(duckingController.isDucked, isFalse);
      expect(currentMultiplier, equals(1.0));
    });

    test('should reset release timer and keep ducking active when triggered repeatedly', () async {
      // Arrange
      double currentMultiplier = 1.0;

      // Act
      duckingController.triggerDuck(
        onVolumeUpdate: (m) => currentMultiplier = m,
        holdDuration: Duration.zero,
      );

      expect(duckingController.isDucked, isTrue);
      expect(currentMultiplier, equals(0.4));

      await Future.delayed(const Duration(milliseconds: 50));
      duckingController.triggerDuck(
        onVolumeUpdate: (m) => currentMultiplier = m,
        holdDuration: Duration.zero,
      );

      // Assert - still ducked after original period
      await Future.delayed(const Duration(milliseconds: 60));
      expect(duckingController.isDucked, isTrue);

      // Assert - restored after full reset duration
      await Future.delayed(const Duration(milliseconds: 150));
      expect(duckingController.isDucked, isFalse);
      expect(currentMultiplier, equals(1.0));
    });
  });

  group('AudioEngineService Integrated Controller Tests', () {
    late AudioEngineService engine;

    setUp(() {
      engine = AudioEngineService();
    });

    tearDown(() {
      engine.dispose();
    });

    test('should initialize facade and all underlying sub-controllers', () {
      // Arrange & Act & Assert
      expect(engine.isInitialized, isTrue);
      expect(engine.masterVolume, equals(1.0));
      expect(engine.musicBus, isNotNull);
      expect(engine.ambientBus, isNotNull);
      expect(engine.sfxBus, isNotNull);
      expect(engine.duckingController, isNotNull);
    });

    test('should trigger automatic music ducking when SFX is fired through AudioEngineService', () async {
      // Arrange
      const trigger = SfxTrigger(id: 'sfx-duck-test', title: 'Roar', filePath: '/roar.mp3');
      engine.sfxBus.addTrigger(trigger);

      expect(engine.musicBus.effectiveVolume, equals(1.0));

      // Act
      await engine.sfxBus.triggerSfx('sfx-duck-test');

      // Assert
      expect(engine.duckingController.isDucked, isTrue);
      expect(engine.musicBus.effectiveVolume, equals(0.4));
    });

    test('should propagate master volume change to all audio buses', () {
      // Arrange & Act
      engine.setMasterVolume(0.5);

      // Assert
      expect(engine.masterVolume, equals(0.5));
      expect(engine.musicBus.masterVolume, equals(0.5));
      expect(engine.musicBus.effectiveVolume, equals(0.5));
      expect(engine.ambientBus.masterVolume, equals(0.5));
      expect(engine.sfxBus.masterVolume, equals(0.5));
    });
  });
}
