import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/audio/fade_controller.dart';
import 'package:ttrpg_audio_player/audio/ducking_controller.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/models/audio_track.dart';
import 'package:ttrpg_audio_player/models/ambient_layer.dart';

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

    test(
      'Что проверяем: Мгновенное завершение фейда при нулевой длительности. '
      'Входные данные: startFade с from=0.0, to=0.8 и duration=Duration.zero. '
      'Ожидаемый результат: currentValue сразу становится 0.8, isFading=false, вызываются onUpdate и onComplete.',
      () {
        double updatedVal = 0.0;
        bool completed = false;

        fader.startFade(
          from: 0.0,
          to: 0.8,
          duration: Duration.zero,
          onUpdate: (val) => updatedVal = val,
          onComplete: () => completed = true,
        );

        expect(fader.currentValue, equals(0.8));
        expect(fader.isFading, isFalse);
        expect(updatedVal, equals(0.8));
        expect(completed, isTrue);
      },
    );

    test(
      'Что проверяем: Плавная пошаговая интерполяция громкости за тики таймера. '
      'Входные данные: startFade с from=0.0 до to=1.0 за 100мс с шагом 20мс. '
      'Ожидаемый результат: isFading=true во время перехода, затем по завершении currentValue=1.0 и вызывается onComplete.',
      () async {
        final values = <double>[];
        bool completed = false;

        fader.startFade(
          from: 0.0,
          to: 1.0,
          duration: const Duration(milliseconds: 100),
          stepInterval: const Duration(milliseconds: 20),
          onUpdate: (val) => values.add(val),
          onComplete: () => completed = true,
        );

        expect(fader.isFading, isTrue);
        expect(values.first, equals(0.0));

        await Future.delayed(const Duration(milliseconds: 250));

        expect(fader.isFading, isFalse);
        expect(fader.currentValue, equals(1.0));
        expect(completed, isTrue);
        expect(values.length, greaterThan(3));
        expect(values.last, equals(1.0));
      },
    );

    test(
      'Что проверяем: Остановка фейда вручную методом stop(). '
      'Входные данные: Запуск фейда на 500мс и вызов fader.stop() через 50мс. '
      'Ожидаемый результат: isFading сбрасывается в false, таймер останавливается.',
      () async {
        fader.startFade(
          from: 0.0,
          to: 1.0,
          duration: const Duration(milliseconds: 500),
          onUpdate: (_) {},
        );

        expect(fader.isFading, isTrue);
        await Future.delayed(const Duration(milliseconds: 50));

        fader.stop();
        expect(fader.isFading, isFalse);
      },
    );
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

    test(
      'Что проверяем: Плавная кривая атаки и затухания в DuckingController. '
      'Входные данные: triggerDuck с attackDuration=60мс и releaseDuration=120мс. '
      'Ожидаемый результат: Постепенное снижение громкости до 0.3, а затем плавный возврат к 1.0.',
      () async {
        final history = <double>[];

        duckingController.triggerDuck(
          onVolumeUpdate: (val) => history.add(val),
          holdDuration: const Duration(milliseconds: 50),
        );

        expect(duckingController.isDucked, isTrue);

        // Ждем завершения фазы атаки (60ms)
        await Future.delayed(const Duration(milliseconds: 90));
        expect(duckingController.currentMultiplier, closeTo(0.3, 0.05));

        // Ждем завершения hold (50ms) + release (120ms)
        await Future.delayed(const Duration(milliseconds: 220));
        expect(duckingController.isDucked, isFalse);
        expect(duckingController.currentMultiplier, equals(1.0));
      },
    );

    test(
      'Что проверяем: Динамическое обновление параметров даккинга через updateSettings. '
      'Входные данные: updateSettings(duckMultiplier: 0.2, attack: 100ms, release: 200ms). '
      'Ожидаемый результат: Поля duckedVolumeMultiplier, attackDuration и releaseDuration обновлены.',
      () {
        duckingController.updateSettings(
          duckMultiplier: 0.2,
          attack: const Duration(milliseconds: 100),
          release: const Duration(milliseconds: 200),
        );

        expect(duckingController.duckedVolumeMultiplier, equals(0.2));
        expect(duckingController.attackDuration, equals(const Duration(milliseconds: 100)));
        expect(duckingController.releaseDuration, equals(const Duration(milliseconds: 200)));
      },
    );

    test(
      'Что проверяем: Сброс состояния даккинга методом reset(). '
      'Входные данные: triggerDuck() и немедленный вызов reset(). '
      'Ожидаемый результат: isDucked=false, currentMultiplier=1.0, колбэк получает 1.0.',
      () {
        double currentVal = 0.0;
        duckingController.triggerDuck(onVolumeUpdate: (m) => currentVal = m);
        expect(duckingController.isDucked, isTrue);

        duckingController.reset(onVolumeUpdate: (m) => currentVal = m);
        expect(duckingController.isDucked, isFalse);
        expect(duckingController.currentMultiplier, equals(1.0));
        expect(currentVal, equals(1.0));
      },
    );
  });

  group('MusicBusController Fade Tests', () {
    late MusicBusController musicBus;

    setUp(() {
      musicBus = MusicBusController();
    });

    tearDown(() {
      musicBus.dispose();
    });

    test(
      'Что проверяем: Плавная пауза и возобновление в MusicBusController. '
      'Входные данные: pause(fadeDuration: 50ms) и resume(fadeDuration: 50ms). '
      'Ожидаемый результат: fadeMultiplier плавно снижается до 0.0 при паузе и нарастает до 1.0 при resume.',
      () async {
        const track = AudioTrack(id: 't1', title: 'Song 1', filePath: '/fake/song1.mp3');
        await musicBus.playTrack(track, fadeDuration: Duration.zero);

        await musicBus.pause(fadeDuration: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 80));

        expect(musicBus.isPlaying, isFalse);

        await musicBus.resume(fadeDuration: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 80));

        expect(musicBus.isPlaying, isTrue);
        expect(musicBus.fadeMultiplier, equals(1.0));
      },
    );

    test(
      'Что проверяем: Плавная остановка трека stop(fadeDuration: 50ms). '
      'Входные данные: Воспроизведение трека и вызов stop(fadeDuration: 50ms). '
      'Ожидаемый результат: По завершении таймера currentTrack=null, isPlaying=false, fadeMultiplier=1.0.',
      () async {
        const track = AudioTrack(id: 't2', title: 'Song 2', filePath: '/fake/song2.mp3');
        await musicBus.playTrack(track, fadeDuration: Duration.zero);

        await musicBus.stop(fadeDuration: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 80));

        expect(musicBus.isPlaying, isFalse);
        expect(musicBus.currentTrack, isNull);
        expect(musicBus.fadeMultiplier, equals(1.0));
      },
    );
  });

  group('AmbientBusController Fade Tests', () {
    late AmbientBusController ambientBus;

    setUp(() {
      ambientBus = AmbientBusController();
    });

    tearDown(() {
      ambientBus.dispose();
    });

    test(
      'Что проверяем: Плавное включение и выключение эмбиент слоя (toggleLayer). '
      'Входные данные: toggleLayer с fadeDuration=50ms. '
      'Ожидаемый результат: isActive слоя меняется на true, затем на false.',
      () async {
        const layer = AmbientLayer(id: 'amb-fade-1', title: 'Forest', filePath: '/fake/forest.mp3');
        ambientBus.addLayer(layer);

        await ambientBus.toggleLayer('amb-fade-1', fadeDuration: const Duration(milliseconds: 50));
        expect(ambientBus.layers.first.isActive, isTrue);

        await ambientBus.toggleLayer('amb-fade-1', fadeDuration: const Duration(milliseconds: 50));
        expect(ambientBus.layers.first.isActive, isFalse);
      },
    );

    test(
      'Что проверяем: Плавное изменение громкости слоя (setLayerVolume с fadeDuration). '
      'Входные данные: setLayerVolume("amb-fade-2", 0.4, fadeDuration: 50ms). '
      'Ожидаемый результат: volume слоя устанавливается в 0.4.',
      () {
        const layer = AmbientLayer(id: 'amb-fade-2', title: 'Caves', filePath: '/fake/caves.mp3', volume: 0.9);
        ambientBus.addLayer(layer);

        ambientBus.setLayerVolume('amb-fade-2', 0.4, fadeDuration: const Duration(milliseconds: 50));
        expect(ambientBus.layers.first.volume, equals(0.4));
      },
    );
  });
}
