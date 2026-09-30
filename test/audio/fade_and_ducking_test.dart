import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/audio/fade_controller.dart';
import 'package:ttrpg_audio_player/audio/ducking_controller.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FadeController Unit Tests', () {
    late FadeController fader;

    setUp(() {
      fader = FadeController();
    });

    tearDown(() {
      fader.dispose();
    });

    test('should complete fade immediately when duration is zero', () {
      // Arrange
      double updatedVal = 0.0;
      bool completed = false;

      // Act
      fader.startFade(
        from: 0.0,
        to: 0.8,
        duration: Duration.zero,
        onUpdate: (val) => updatedVal = val,
        onComplete: () => completed = true,
      );

      // Assert
      expect(fader.currentValue, equals(0.8));
      expect(fader.isFading, isFalse);
      expect(updatedVal, equals(0.8));
      expect(completed, isTrue);
    });

    test('should smoothly interpolate volume over timer ticks when fading over time', () async {
      // Arrange
      final values = <double>[];
      bool completed = false;

      // Act
      fader.startFade(
        from: 0.0,
        to: 1.0,
        duration: const Duration(milliseconds: 100),
        stepInterval: const Duration(milliseconds: 20),
        onUpdate: (val) => values.add(val),
        onComplete: () => completed = true,
      );

      // Assert - actively fading
      expect(fader.isFading, isTrue);
      expect(values.first, equals(0.0));

      await Future.delayed(const Duration(milliseconds: 250));

      // Assert - completed
      expect(fader.isFading, isFalse);
      expect(fader.currentValue, equals(1.0));
      expect(completed, isTrue);
      expect(values.length, greaterThan(3));
      expect(values.last, equals(1.0));
    });

    test('should halt active fade and cancel timer when stop is called', () async {
      // Arrange
      fader.startFade(
        from: 0.0,
        to: 1.0,
        duration: const Duration(milliseconds: 500),
        onUpdate: (_) {},
      );

      expect(fader.isFading, isTrue);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      fader.stop();

      // Assert
      expect(fader.isFading, isFalse);
    });
  });

  group('Smooth Ducking Unit Tests', () {
    late DuckingController duckingController;

    setUp(() {
      duckingController = DuckingController(
        duckedVolumeMultiplier: 0.3,
        attackDuration: const Duration(milliseconds: 60),
        releaseDuration: const Duration(milliseconds: 120),
      );
    });

    tearDown(() {
      duckingController.dispose();
    });

    test('should apply smooth attack and release curves during ducking lifecycle', () async {
      // Arrange
      final history = <double>[];

      // Act
      duckingController.triggerDuck(
        onVolumeUpdate: (val) => history.add(val),
        holdDuration: const Duration(milliseconds: 50),
      );

      // Assert - ducking triggered
      expect(duckingController.isDucked, isTrue);

      // Wait for attack phase (60ms)
      await Future.delayed(const Duration(milliseconds: 90));
      expect(duckingController.currentMultiplier, closeTo(0.3, 0.05));

      // Wait for hold (50ms) + release (120ms)
      await Future.delayed(const Duration(milliseconds: 220));
      expect(duckingController.isDucked, isFalse);
      expect(duckingController.currentMultiplier, equals(1.0));
    });

    test('should dynamically update ducking timing and target multiplier when updateSettings is called', () {
      // Arrange & Act
      duckingController.updateSettings(
        duckMultiplier: 0.2,
        attack: const Duration(milliseconds: 100),
        release: const Duration(milliseconds: 200),
      );

      // Assert
      expect(duckingController.duckedVolumeMultiplier, equals(0.2));
      expect(duckingController.attackDuration, equals(const Duration(milliseconds: 100)));
      expect(duckingController.releaseDuration, equals(const Duration(milliseconds: 200)));
    });

    test('should restore full volume and clear ducking state immediately when reset is called', () {
      // Arrange
      double currentVal = 0.0;
      duckingController.triggerDuck(onVolumeUpdate: (m) => currentVal = m);
      expect(duckingController.isDucked, isTrue);

      // Act
      duckingController.reset(onVolumeUpdate: (m) => currentVal = m);

      // Assert
      expect(duckingController.isDucked, isFalse);
      expect(duckingController.currentMultiplier, equals(1.0));
      expect(currentVal, equals(1.0));
    });
  });

  group('MusicBusController Fade Tests', () {
    late MusicBusController musicBus;

    setUp(() {
      musicBus = MusicBusController();
    });

    tearDown(() {
      musicBus.dispose();
    });

    test('should smoothly fade out during pause and fade in during resume', () async {
      // Arrange
      const track = AudioTrack(id: 't1', title: 'Song 1', filePath: '/fake/song1.mp3');
      await musicBus.playTrack(track, fadeDuration: Duration.zero);

      // Act & Assert - Pause with fade
      await musicBus.pause(fadeDuration: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(musicBus.isPlaying, isFalse);

      // Act & Assert - Resume with fade
      await musicBus.resume(fadeDuration: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(musicBus.isPlaying, isTrue);
      expect(musicBus.fadeMultiplier, equals(1.0));
    });

    test('should smoothly fade out audio before resetting current track on stop', () async {
      // Arrange
      const track = AudioTrack(id: 't2', title: 'Song 2', filePath: '/fake/song2.mp3');
      await musicBus.playTrack(track, fadeDuration: Duration.zero);

      // Act
      await musicBus.stop(fadeDuration: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 80));

      // Assert
      expect(musicBus.isPlaying, isFalse);
      expect(musicBus.currentTrack, isNull);
      expect(musicBus.fadeMultiplier, equals(1.0));
    });
  });

  group('AmbientBusController Fade Tests', () {
    late AmbientBusController ambientBus;

    setUp(() {
      ambientBus = AmbientBusController();
    });

    tearDown(() {
      ambientBus.dispose();
    });

    test('should apply smooth fade transition when toggling ambient layer', () async {
      // Arrange
      const layer = AmbientLayer(id: 'amb-fade-1', title: 'Forest', filePath: '/fake/forest.mp3');
      ambientBus.addLayer(layer);

      // Act & Assert - Fade in
      await ambientBus.toggleLayer('amb-fade-1', fadeDuration: const Duration(milliseconds: 50));
      expect(ambientBus.layers.first.isActive, isTrue);

      // Act & Assert - Fade out
      await ambientBus.toggleLayer('amb-fade-1', fadeDuration: const Duration(milliseconds: 50));
      expect(ambientBus.layers.first.isActive, isFalse);
    });

    test('should adjust layer volume with specified fade duration', () {
      // Arrange
      const layer = AmbientLayer(id: 'amb-fade-2', title: 'Caves', filePath: '/fake/caves.mp3', volume: 0.9);
      ambientBus.addLayer(layer);

      // Act
      ambientBus.setLayerVolume('amb-fade-2', 0.4, fadeDuration: const Duration(milliseconds: 50));

      // Assert
      expect(ambientBus.layers.first.volume, equals(0.4));
    });
  });
}
