import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/db/database_service.dart';
import 'package:ttrpg_audio_player/services/scene_service.dart';
import 'package:ttrpg_audio_player/services/media_library_service.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/models/scene_model.dart';
import 'package:ttrpg_audio_player/models/library_track.dart';
import 'package:ttrpg_audio_player/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/models/sfx_trigger.dart';
import 'package:ttrpg_audio_player/models/audio_track.dart';

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
    test(
      'Что проверяем: Создание, загрузка, обновление и удаление сцен в SceneService. '
      'Входные данные: Вызовы createScene, updateScene и deleteScene. '
      'Ожидаемый результат: Список scenes корректно отражает все изменения и сохраняется в SQLite.',
      () async {
        final sceneService = SceneService();
        await sceneService.loadScenes();

        expect(sceneService.scenes, isEmpty);

        final scene = SceneModel(
          id: 'sc-1',
          name: 'Таверна',
          description: 'Теплый камин и лютня',
          colorHex: 0xFF9C27B0,
        );

        await sceneService.createScene(scene);
        expect(sceneService.scenes.length, equals(1));
        expect(sceneService.scenes.first.name, equals('Таверна'));

        final updated = scene.copyWith(name: 'Шумная Таверна');
        await sceneService.updateScene(updated);
        expect(sceneService.scenes.first.name, equals('Шумная Таверна'));

        await sceneService.deleteScene('sc-1');
        expect(sceneService.scenes, isEmpty);

        sceneService.dispose();
      },
    );

    test(
      'Что проверяем: Комплексная активация сцены (activateScene). '
      'Входные данные: Сцена с привязанной музыкой, 2 эмбиент-слоями и 1 SFX триггером. '
      'Ожидаемый результат: Запуск музыки в MusicBus, настройка слоев в AmbientBus, регистрация SFX в SfxBus, activeSceneId=id сцены.',
      () async {
        final sceneService = SceneService();
        final mediaLibrary = MediaLibraryService();
        final audioEngine = AudioEngineService();

        // Подготовим библиотеку треков
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
          name: 'Таверна Веселый Гоблин',
          musicTrackId: 'tr-music-1',
          musicIntensity: MusicIntensity.calm,
          ambientLayerVolumes: {
            'tr-amb-1': 0.7,
            'tr-amb-2': 0.5,
          },
          soundboardSfxIds: ['tr-sfx-1'],
        );

        await sceneService.createScene(scene);

        // Активируем сцену
        await sceneService.activateScene(
          scene,
          audioEngine: audioEngine,
          mediaLibrary: mediaLibrary,
          fadeDuration: Duration.zero,
        );

        expect(sceneService.activeSceneId, equals('scene-tavern'));
        expect(sceneService.activeScene?.name, equals('Таверна Веселый Гоблин'));
        expect(audioEngine.musicBus.currentTrack?.id, equals('tr-music-1'));
        expect(audioEngine.musicBus.isPlaying, isFalse); // Does not auto-play immediately
        expect(audioEngine.ambientBus.layers.length, equals(2));
        expect(audioEngine.ambientBus.layers.every((l) => !l.isActive), isTrue); // Does not auto-play immediately
        expect(audioEngine.ambientBus.layers.firstWhere((l) => l.id == 'tr-amb-1').volume, equals(0.7));
        expect(audioEngine.ambientBus.layers.firstWhere((l) => l.id == 'tr-amb-2').volume, equals(0.5));
        expect(audioEngine.sfxBus.triggers.any((t) => t.id == 'tr-sfx-1'), isTrue);

        mediaLibrary.dispose();
        sceneService.dispose();
        audioEngine.dispose();
      },
    );

    test(
      'Что проверяем: Сохранение постоянных (isPersistent) эмбиент-слоев и SFX при смене сцены. '
      'Входные данные: Постоянный слой "Campfire" и SFX "Dice Roll", смена сцены на пустую. '
      'Ожидаемый результат: Постоянный слой и SFX триггер сохраняются в шинах, непостоянные удаляются.',
      () async {
        final sceneService = SceneService();
        final mediaLibrary = MediaLibraryService();
        final audioEngine = AudioEngineService();

        // Добавим постоянный и непостоянный слои в AmbientBus
        audioEngine.ambientBus.addLayer(
          const AmbientLayer(id: 'camp-persistent', title: 'Campfire', filePath: '/fake/camp.mp3', isPersistent: true),
        );
        audioEngine.ambientBus.addLayer(
          const AmbientLayer(id: 'rain-temp', title: 'Rain', filePath: '/fake/rain.mp3', isPersistent: false),
        );

        // Добавим постоянный и непостоянный SFX
        audioEngine.sfxBus.addTrigger(
          const SfxTrigger(id: 'dice-persistent', title: 'Dice Roll', filePath: '/fake/dice.wav', isPersistent: true),
        );
        audioEngine.sfxBus.addTrigger(
          const SfxTrigger(id: 'scream-temp', title: 'Scream', filePath: '/fake/scream.wav', isPersistent: false),
        );

        // Сцена без музыки и звуков
        final quietScene = SceneModel(
          id: 'scene-quiet',
          name: 'Тишина',
          musicTrackId: null,
          ambientLayerVolumes: {},
          soundboardSfxIds: [],
        );

        await sceneService.activateScene(
          quietScene,
          audioEngine: audioEngine,
          mediaLibrary: mediaLibrary,
          fadeDuration: Duration.zero,
        );

        // Постоянный эмбиент остался, временный удален
        expect(audioEngine.ambientBus.layers.any((l) => l.id == 'camp-persistent'), isTrue);
        expect(audioEngine.ambientBus.layers.any((l) => l.id == 'rain-temp'), isFalse);

        // Постоянный SFX остался, временный удален
        expect(audioEngine.sfxBus.triggers.any((t) => t.id == 'dice-persistent'), isTrue);
        expect(audioEngine.sfxBus.triggers.any((t) => t.id == 'scream-temp'), isFalse);
        expect(audioEngine.musicBus.currentTrack, isNull);

        mediaLibrary.dispose();
        sceneService.dispose();
        audioEngine.dispose();
      },
    );
  });
}
