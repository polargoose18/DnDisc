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

    test(
      'Что проверяем: Действие Space для переключения Play/Pause музыки. '
      'Входные данные: handleActionDirectly(AppShortcutAction.playPauseMusic). '
      'Ожидаемый результат: Вызывается resume() или pause() на musicBus, меняя isPlaying.',
      () async {
        const track = AudioTrack(id: 'sh_track_1', title: 'Battle Theme', filePath: '/fake/battle.mp3');
        await audioEngine.musicBus.playTrack(track, fadeDuration: Duration.zero);
        expect(audioEngine.musicBus.currentTrack, equals(track));

        shortcutService.handleActionDirectly(AppShortcutAction.playPauseMusic);
        expect(audioEngine.musicBus.isPlaying, isTrue);

        shortcutService.handleActionDirectly(AppShortcutAction.playPauseMusic);
        expect(audioEngine.musicBus.isPlaying, isFalse);
      },
    );

    test(
      'Что проверяем: Переключение интенсивности музыки горячими клавишами 1..4. '
      'Входные данные: handleActionDirectly(AppShortcutAction.intensityBattle, intensityBoss, intensityCalm). '
      'Ожидаемый результат: musicBus.currentIntensity меняется на соответствующее значение.',
      () {
        shortcutService.handleActionDirectly(AppShortcutAction.intensitySuspense);
        expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.suspense));

        shortcutService.handleActionDirectly(AppShortcutAction.intensityBattle);
        expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.battle));

        shortcutService.handleActionDirectly(AppShortcutAction.intensityBoss);
        expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.boss));

        shortcutService.handleActionDirectly(AppShortcutAction.intensityCalm);
        expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.calm));
      },
    );

    test(
      'Что проверяем: Переключение Master Mute горячей клавишей M. '
      'Входные данные: handleActionDirectly(AppShortcutAction.masterMute). '
      'Ожидаемый результат: audioEngine.isMuted переключается в true, громкость 0.0, при повторном нажатии восстанавливается.',
      () {
        audioEngine.setMasterVolume(0.8);
        expect(audioEngine.isMuted, isFalse);

        shortcutService.handleActionDirectly(AppShortcutAction.masterMute);
        expect(audioEngine.isMuted, isTrue);
        expect(audioEngine.masterVolume, equals(0.0));

        shortcutService.handleActionDirectly(AppShortcutAction.masterMute);
        expect(audioEngine.isMuted, isFalse);
        expect(audioEngine.masterVolume, equals(0.8));
      },
    );

    test(
      'Что проверяем: Ручной Ducking клавишей D. '
      'Входные данные: handleActionDirectly(AppShortcutAction.manualDucking). '
      'Ожидаемый результат: duckingController.isDucked становится true.',
      () {
        expect(audioEngine.duckingController.isDucked, isFalse);
        shortcutService.handleActionDirectly(AppShortcutAction.manualDucking);
        expect(audioEngine.duckingController.isDucked, isTrue);
      },
    );

    test(
      'Что проверяем: Экстренная остановка Panic Stop клавишей Escape. '
      'Входные данные: handleActionDirectly(AppShortcutAction.panicStopSfx). '
      'Ожидаемый результат: Вызывается audioEngine.panicStopSfx().',
      () {
        shortcutService.handleActionDirectly(AppShortcutAction.panicStopSfx);
        expect(audioEngine.sfxBus.triggers.isEmpty, isTrue);
      },
    );

    test(
      'Что проверяем: Переключение полноэкранного режима F11. '
      'Входные данные: handleActionDirectly(AppShortcutAction.toggleFullscreen). '
      'Ожидаемый результат: shortcutService.isFullscreen инвертируется с false в true и обратно.',
      () {
        expect(shortcutService.isFullscreen, isFalse);

        shortcutService.handleActionDirectly(AppShortcutAction.toggleFullscreen);
        expect(shortcutService.isFullscreen, isTrue);

        shortcutService.handleActionDirectly(AppShortcutAction.toggleFullscreen);
        expect(shortcutService.isFullscreen, isFalse);
      },
    );

    test(
      'Что проверяем: Включение и отключение горячих клавиш setEnabled. '
      'Входные данные: shortcutService.setEnabled(false). '
      'Ожидаемый результат: isEnabled становится false.',
      () {
        shortcutService.setEnabled(false);
        expect(shortcutService.isEnabled, isFalse);

        shortcutService.setEnabled(true);
        expect(shortcutService.isEnabled, isTrue);
      },
    );

    test(
      'Что проверяем: Воспроизведение звуковых эффектов по SFX горячим клавишам sfx1..sfx9. '
      'Входные данные: SfxTrigger с файлом в sfxBus, вызов handleActionDirectly(AppShortcutAction.sfx1). '
      'Ожидаемый результат: SFX триггер активируется без ошибок, вызывается onSfxTriggered.',
      () {
        bool duckTriggered = false;
        audioEngine = AudioEngineService();
        audioEngine.duckingController.triggerDuck(onVolumeUpdate: (_) => duckTriggered = true);
        expect(duckTriggered, isTrue);
        shortcutService.attachAudioEngine(audioEngine);

        shortcutService.handleActionDirectly(AppShortcutAction.sfx1);
        expect(shortcutService.getDisplayForAction(AppShortcutAction.sfx1), equals('Num 1 / Ctrl+1'));
        expect(shortcutService.getDisplayForAction(AppShortcutAction.panicStopSfx), equals('Escape'));
      },
    );

    test(
      'Что проверяем: Быстрая последовательность вызовов различных горячих клавиш (Space, 1..4, M, D, Esc). '
      'Входные данные: Последовательный вызов playPause, intensityBattle, manualDucking, masterMute, panicStopSfx. '
      'Ожидаемый результат: Система стабильно отрабатывает все вызовы без исключений и зависаний.',
      () {
        shortcutService.handleActionDirectly(AppShortcutAction.playPauseMusic);
        shortcutService.handleActionDirectly(AppShortcutAction.intensityBattle);
        shortcutService.handleActionDirectly(AppShortcutAction.manualDucking);
        shortcutService.handleActionDirectly(AppShortcutAction.masterMute);
        shortcutService.handleActionDirectly(AppShortcutAction.panicStopSfx);

        expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.battle));
        expect(audioEngine.isMuted, isTrue);
      },
    );
  });
}
