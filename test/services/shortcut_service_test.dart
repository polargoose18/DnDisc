import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/services/shortcut_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShortcutService Unit Tests', () {
    late AudioEngineService audioEngine;
    late ShortcutService shortcutService;

    setUp(() {
      audioEngine = AudioEngineService();
      shortcutService = ShortcutService(audioEngine: audioEngine);
    });

    tearDown(() {
      shortcutService.dispose();
      audioEngine.dispose();
    });

    test('should toggle music playback state when playPauseMusic shortcut is invoked', () async {
      // Arrange
      const track = AudioTrack(id: 'sh_track_1', title: 'Battle Theme', filePath: '/fake/battle.mp3');
      await audioEngine.musicBus.playTrack(track, fadeDuration: Duration.zero);
      expect(audioEngine.musicBus.currentTrack, equals(track));

      // Act & Assert - Toggle pause
      shortcutService.handleActionDirectly(AppShortcutAction.playPauseMusic);
      expect(audioEngine.musicBus.isPlaying, isTrue);

      // Act & Assert - Toggle resume
      shortcutService.handleActionDirectly(AppShortcutAction.playPauseMusic);
      expect(audioEngine.musicBus.isPlaying, isFalse);
    });

    test('should switch music intensity when corresponding intensity shortcuts are invoked', () {
      // Arrange & Act & Assert - Suspense
      shortcutService.handleActionDirectly(AppShortcutAction.intensitySuspense);
      expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.suspense));

      // Arrange & Act & Assert - Battle
      shortcutService.handleActionDirectly(AppShortcutAction.intensityBattle);
      expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.battle));

      // Arrange & Act & Assert - Boss
      shortcutService.handleActionDirectly(AppShortcutAction.intensityBoss);
      expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.boss));

      // Arrange & Act & Assert - Calm
      shortcutService.handleActionDirectly(AppShortcutAction.intensityCalm);
      expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.calm));
    });

    test('should toggle master mute and restore previous volume level when masterMute action is triggered', () {
      // Arrange
      audioEngine.setMasterVolume(0.8);
      expect(audioEngine.isMuted, isFalse);

      // Act & Assert - Mute
      shortcutService.handleActionDirectly(AppShortcutAction.masterMute);
      expect(audioEngine.isMuted, isTrue);
      expect(audioEngine.masterVolume, equals(0.0));

      // Act & Assert - Unmute
      shortcutService.handleActionDirectly(AppShortcutAction.masterMute);
      expect(audioEngine.isMuted, isFalse);
      expect(audioEngine.masterVolume, equals(0.8));
    });

    test('should activate manual ducking when manualDucking action is dispatched', () {
      // Arrange
      expect(audioEngine.duckingController.isDucked, isFalse);

      // Act
      shortcutService.handleActionDirectly(AppShortcutAction.manualDucking);

      // Assert
      expect(audioEngine.duckingController.isDucked, isTrue);
    });

    test('should stop all active sound effects when panicStopSfx action is triggered', () {
      // Arrange & Act
      shortcutService.handleActionDirectly(AppShortcutAction.panicStopSfx);

      // Assert
      expect(audioEngine.sfxBus.triggers.isEmpty, isTrue);
    });

    test('should toggle fullscreen state when toggleFullscreen action is triggered', () {
      // Arrange
      expect(shortcutService.isFullscreen, isFalse);

      // Act & Assert - enter fullscreen
      shortcutService.handleActionDirectly(AppShortcutAction.toggleFullscreen);
      expect(shortcutService.isFullscreen, isTrue);

      // Act & Assert - exit fullscreen
      shortcutService.handleActionDirectly(AppShortcutAction.toggleFullscreen);
      expect(shortcutService.isFullscreen, isFalse);
    });

    test('should enable or disable shortcut processing when setEnabled is called', () {
      // Arrange & Act & Assert - Disable
      shortcutService.setEnabled(false);
      expect(shortcutService.isEnabled, isFalse);

      // Arrange & Act & Assert - Enable
      shortcutService.setEnabled(true);
      expect(shortcutService.isEnabled, isTrue);
    });

    test('should return correct display key combinations for actions', () {
      // Arrange
      bool duckTriggered = false;
      audioEngine = AudioEngineService();
      audioEngine.duckingController.triggerDuck(onVolumeUpdate: (_) => duckTriggered = true);
      expect(duckTriggered, isTrue);
      shortcutService.attachAudioEngine(audioEngine);

      // Act & Assert
      shortcutService.handleActionDirectly(AppShortcutAction.sfx1);
      expect(shortcutService.getDisplayForAction(AppShortcutAction.sfx1), equals('Num 1 / Ctrl+1'));
      expect(shortcutService.getDisplayForAction(AppShortcutAction.panicStopSfx), equals('Escape'));
    });

    test('should process rapid consecutive shortcut actions without errors or state inconsistency', () {
      // Arrange & Act
      shortcutService.handleActionDirectly(AppShortcutAction.playPauseMusic);
      shortcutService.handleActionDirectly(AppShortcutAction.intensityBattle);
      shortcutService.handleActionDirectly(AppShortcutAction.manualDucking);
      shortcutService.handleActionDirectly(AppShortcutAction.masterMute);
      shortcutService.handleActionDirectly(AppShortcutAction.panicStopSfx);

      // Assert
      expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.battle));
      expect(audioEngine.isMuted, isTrue);
    });
  });
}
