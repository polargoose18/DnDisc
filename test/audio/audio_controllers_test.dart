import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ducking_controller.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/models/audio_track.dart';
import 'package:ttrpg_audio_player/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/models/sfx_trigger.dart';

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

    test('Что проверяем: Начальное состояние MusicBusController. '
        'Входные данные: Новый экземпляра MusicBusController. '
        'Ожидаемый результат: currentTrack=null, isPlaying=false, rawVolume=1.0, effectiveVolume=1.0, intensity=calm.', () {
      expect(musicBus.currentTrack, isNull);
      expect(musicBus.isPlaying, isFalse);
      expect(musicBus.rawVolume, equals(1.0));
      expect(musicBus.effectiveVolume, equals(1.0));
      expect(musicBus.currentIntensity, equals(MusicIntensity.calm));
    });

    test('Что проверяем: Изменение уровня интенсивности (setIntensity). '
        'Входные данные: setIntensity(MusicIntensity.boss). '
        'Ожидаемый результат: currentIntensity меняется на boss, вызывается notifyListeners. При повторной установке того же значения слушатели не извещаются.', () {
      int notifyCount = 0;
      musicBus.addListener(() => notifyCount++);

      musicBus.setIntensity(MusicIntensity.boss);

      expect(musicBus.currentIntensity, equals(MusicIntensity.boss));
      expect(notifyCount, equals(1));

      // Повторный вызов с той же интенсивностью
      musicBus.setIntensity(MusicIntensity.boss);
      expect(notifyCount, equals(1));
    });

    test('Что проверяем: Установка громкости (setVolume) и валидация диапазонов (clamp). '
        'Входные данные: setVolume(0.7) и выходящие за рамки значения (-0.5 и 1.5). '
        'Ожидаемый результат: Значение громкости ограничивается в интервале [0.0, 1.0].', () {
      musicBus.setVolume(0.7);
      expect(musicBus.rawVolume, equals(0.7));
      expect(musicBus.effectiveVolume, equals(0.7));

      musicBus.setVolume(-0.5);
      expect(musicBus.rawVolume, equals(0.0));

      musicBus.setVolume(1.5);
      expect(musicBus.rawVolume, equals(1.0));
    });

    test('Что проверяем: Расчет эффективной громкости при автоприглушении (updateDuckingMultiplier). '
        'Входные данные: rawVolume=0.8 и multiplier=0.4. '
        'Ожидаемый результат: effectiveVolume равен 0.8 * 0.4 = 0.32.', () {
      musicBus.setVolume(0.8);
      musicBus.updateDuckingMultiplier(0.4);

      expect(musicBus.rawVolume, equals(0.8));
      expect(musicBus.effectiveVolume, closeTo(0.32, 0.001));
    });

    test('Что проверяем: Обработка воспроизведения несуществующего локального файла. '
        'Входные данные: playTrack с несуществующим файлом /non_existent_file.mp3. '
        'Ожидаемый результат: currentTrack и intensity обновляются, но isPlaying остаётся false из-за отсутствия файла.', () async {
      const track = AudioTrack(
        id: 'missing-1',
        title: 'Ghost Song',
        filePath: '/non_existent_path_12345.mp3',
        intensity: MusicIntensity.suspense,
      );

      await musicBus.playTrack(track);

      expect(musicBus.currentTrack, equals(track));
      expect(musicBus.currentIntensity, equals(MusicIntensity.suspense));
      expect(musicBus.isPlaying, isFalse);
    });

    test('Что проверяем: Управление паузой, возобновлением и остановкой. '
        'Входные данные: Вызовы pause(), resume() и stop() при установленном треке. '
        'Ожидаемый результат: Состояние isPlaying и currentTrack корректно обновляются.', () async {
      const track = AudioTrack(
        id: 'dummy',
        title: 'Dummy Track',
        filePath: '/fake/dummy.mp3',
      );
      await musicBus.playTrack(track);

      await musicBus.pause();
      expect(musicBus.isPlaying, isFalse);

      await musicBus.resume();
      expect(musicBus.isPlaying, isTrue);

      await musicBus.stop();
      expect(musicBus.isPlaying, isFalse);
      expect(musicBus.currentTrack, isNull);
    });

    test('Что проверяем: Вызов resume() при отсутствии загруженного трека (currentTrack == null). '
        'Входные данные: Вызов resume() на свежем MusicBusController. '
        'Ожидаемый результат: isPlaying остаётся false, состояние не изменяется.', () async {
      await musicBus.resume();
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

    test('Что проверяем: Добавление слоев и предотвращение дубликатов по ID. '
        'Входные данные: Добавление слоя "Rain" дважды с одинаковым ID. '
        'Ожидаемый результат: В списке layers остаётся ровно один слой.', () {
      const layer = AmbientLayer(id: 'rain-1', title: 'Rain', filePath: '/rain.mp3');

      ambientBus.addLayer(layer);
      expect(ambientBus.layers.length, equals(1));

      ambientBus.addLayer(layer);
      expect(ambientBus.layers.length, equals(1));
    });

    test('Что проверяем: Переключение активности слоя (toggleLayer). '
        'Входные данные: Слой inactive=false, вызов toggleLayer("rain-1"). '
        'Ожидаемый результат: Флаг isActive меняется на true, а затем при повторном вызове - обратно на false.', () async {
      const layer = AmbientLayer(id: 'rain-1', title: 'Rain', filePath: '/rain.mp3', isActive: false);
      ambientBus.addLayer(layer);

      await ambientBus.toggleLayer('rain-1');
      expect(ambientBus.layers.firstWhere((l) => l.id == 'rain-1').isActive, isTrue);

      await ambientBus.toggleLayer('rain-1');
      expect(ambientBus.layers.firstWhere((l) => l.id == 'rain-1').isActive, isFalse);
    });

    test('Что проверяем: Вызов toggleLayer и setLayerVolume для несуществующего layerId. '
        'Входные данные: toggleLayer("non-existent") и setLayerVolume("non-existent", 0.5). '
        'Ожидаемый результат: Метод завершается без ошибок, список слоев не изменяется.', () async {
      const layer = AmbientLayer(id: 'rain-1', title: 'Rain', filePath: '/rain.mp3');
      ambientBus.addLayer(layer);

      await ambientBus.toggleLayer('non-existent');
      expect(ambientBus.layers.first.isActive, isFalse);

      ambientBus.setLayerVolume('non-existent', 0.5);
      expect(ambientBus.layers.first.volume, equals(0.8));
    });

    test('Что проверяем: Изменение индивидуальной громкости слоя (setLayerVolume). '
        'Входные данные: setLayerVolume("rain-1", 0.35). '
        'Ожидаемый результат: Громкость слоя обновилась до 0.35 с клампингом.', () {
      const layer = AmbientLayer(id: 'rain-1', title: 'Rain', filePath: '/rain.mp3', volume: 0.8);
      ambientBus.addLayer(layer);

      ambientBus.setLayerVolume('rain-1', 0.35);
      expect(ambientBus.layers.first.volume, equals(0.35));

      ambientBus.setLayerVolume('rain-1', 1.5);
      expect(ambientBus.layers.first.volume, equals(1.0));
    });

    test('Что проверяем: Установка мастер-громкости эмбиента с ограничением значений (clamp). '
        'Входные данные: setMasterVolume(-0.5) и setMasterVolume(1.8). '
        'Ожидаемый результат: masterVolume ограничивается [0.0, 1.0].', () {
      ambientBus.setMasterVolume(-0.5);
      expect(ambientBus.masterVolume, equals(0.0));

      ambientBus.setMasterVolume(1.8);
      expect(ambientBus.masterVolume, equals(1.0));
    });

    test('Что проверяем: Остановка всех активных слоёв (stopAllLayers). '
        'Входные данные: Три слоя, два из которых активны. Вызов stopAllLayers(). '
        'Ожидаемый результат: Все слои получают isActive=false.', () async {
      const l1 = AmbientLayer(id: 'l1', title: 'Rain', filePath: '/r.mp3', isActive: true);
      const l2 = AmbientLayer(id: 'l2', title: 'Wind', filePath: '/w.mp3', isActive: true);
      const l3 = AmbientLayer(id: 'l3', title: 'Birds', filePath: '/b.mp3', isActive: false);

      ambientBus.addLayer(l1);
      ambientBus.addLayer(l2);
      ambientBus.addLayer(l3);

      await ambientBus.stopAllLayers();

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

    test('Что проверяем: Регистрация триггеров SFX и запуск триггера с вызовом колбэка onSfxTriggered. '
        'Входные данные: Добавление SfxTrigger("sword-1") и вызов triggerSfx("sword-1"). '
        'Ожидаемый результат: Триггер добавлен, callbackFired=true.', () async {
      const trigger = SfxTrigger(id: 'sword-1', title: 'Sword', filePath: '/sfx/sword.wav');
      sfxBus.addTrigger(trigger);

      expect(sfxBus.triggers.length, equals(1));

      await sfxBus.triggerSfx('sword-1');
      expect(callbackFired, isTrue);
    });

    test('Что проверяем: Запуск триггера по несуществующему ID в SfxBusController. '
        'Входные данные: triggerSfx("non-existent-id"). '
        'Ожидаемый результат: Колбэк onSfxTriggered НЕ вызывается, ошибок не возникает.', () async {
      await sfxBus.triggerSfx('non-existent-id');
      expect(callbackFired, isFalse);
    });

    test('Что проверяем: Установка громкости шины SFX (setVolume) и расчет effectiveVolume. '
        'Входные данные: setVolume(0.7) и setMasterVolume(0.5). '
        'Ожидаемый результат: rawVolume=0.7, masterVolume=0.5, effectiveVolume=0.35.', () {
      sfxBus.setVolume(0.7);
      sfxBus.setMasterVolume(0.5);
      expect(sfxBus.rawVolume, equals(0.7));
      expect(sfxBus.masterVolume, equals(0.5));
      expect(sfxBus.effectiveVolume, closeTo(0.35, 0.001));

      sfxBus.setVolume(-0.2);
      expect(sfxBus.rawVolume, equals(0.0));
      sfxBus.setVolume(1.5);
      expect(sfxBus.rawVolume, equals(1.0));
    });

    test('Что проверяем: Установка общей мастер-громкости SFX (setMasterVolume). '
        'Входные данные: setMasterVolume(0.6). '
        'Ожидаемый результат: masterVolume становится 0.6 с учётом клампинга.', () {
      sfxBus.setMasterVolume(0.6);
      expect(sfxBus.masterVolume, equals(0.6));

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

    test('Что проверяем: Срабатывание даккинга и восстановление громкости по таймеру. '
        'Входные данные: Вызов triggerDuck() с колбэком отслеживания коэффициента. '
        'Ожидаемый результат: Сразу устанавливается isDucked=true и multiplier=0.4, спустя releaseDuration multiplier сбрасывается на 1.0, isDucked=false.', () async {
      double currentMultiplier = 1.0;

      duckingController.triggerDuck(
        onVolumeUpdate: (m) => currentMultiplier = m,
      );

      expect(duckingController.isDucked, isTrue);
      expect(currentMultiplier, equals(0.4));

      // Ждем истечения releaseDuration (100ms)
      await Future.delayed(const Duration(milliseconds: 150));

      expect(duckingController.isDucked, isFalse);
      expect(currentMultiplier, equals(1.0));
    });

    test('Что проверяем: Повторный триггер даккинга до истечения первого таймера (ре-триггер). '
        'Входные данные: Вызовы triggerDuck() дважды с интервалом в 50мс при releaseDuration 100мс. '
        'Ожидаемый результат: Таймер сбрасывается и даккинг остаётся активным дольше первого интервала.', () async {
      double currentMultiplier = 1.0;

      duckingController.triggerDuck(
        onVolumeUpdate: (m) => currentMultiplier = m,
      );

      expect(duckingController.isDucked, isTrue);
      expect(currentMultiplier, equals(0.4));

      await Future.delayed(const Duration(milliseconds: 50));
      duckingController.triggerDuck(
        onVolumeUpdate: (m) => currentMultiplier = m,
      );

      await Future.delayed(const Duration(milliseconds: 60));
      expect(duckingController.isDucked, isTrue);

      await Future.delayed(const Duration(milliseconds: 80));
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

    test('Что проверяем: Инициализация фасада AudioEngineService и подконтроллеров. '
        'Входные данные: Новый объект AudioEngineService. '
        'Ожидаемый результат: isInitialized=true, masterVolume=1.0, подконтроллеры инициализированы.', () {
      expect(engine.isInitialized, isTrue);
      expect(engine.masterVolume, equals(1.0));
      expect(engine.musicBus, isNotNull);
      expect(engine.ambientBus, isNotNull);
      expect(engine.sfxBus, isNotNull);
      expect(engine.duckingController, isNotNull);
    });

    test('Что проверяем: Автоматическое срабатывание даккинга музыки при триггере SFX через AudioEngineService. '
        'Входные данные: Добавление SFX триггера и запуск sfxBus.triggerSfx. '
        'Ожидаемый результат: MusicBus.effectiveVolume уменьшается до 40% (0.4) из-за даккинга.', () async {
      const trigger = SfxTrigger(id: 'sfx-duck-test', title: 'Roar', filePath: '/roar.mp3');
      engine.sfxBus.addTrigger(trigger);

      expect(engine.musicBus.effectiveVolume, equals(1.0));

      await engine.sfxBus.triggerSfx('sfx-duck-test');

      expect(engine.duckingController.isDucked, isTrue);
      expect(engine.musicBus.effectiveVolume, equals(0.4));
    });

    test('Что проверяем: Установка мастер-громкости движка (setMasterVolume). '
        'Входные данные: setMasterVolume(0.5). '
        'Ожидаемый результат: Громкость musicBus, ambientBus и sfxBus обновляется до 0.5, effectiveVolume музыки уменьшается пропорционально.', () {
      engine.setMasterVolume(0.5);

      expect(engine.masterVolume, equals(0.5));
      expect(engine.musicBus.masterVolume, equals(0.5));
      expect(engine.musicBus.effectiveVolume, equals(0.5));
      expect(engine.ambientBus.masterVolume, equals(0.5));
      expect(engine.sfxBus.masterVolume, equals(0.5));
    });
  });
}
