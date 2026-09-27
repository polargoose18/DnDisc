import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/services/media_library_service.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/db/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
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
  late MediaLibraryService libraryService;
  late DatabaseService dbService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_lib_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
    libraryService = MediaLibraryService();
  });

  tearDown(() async {
    libraryService.dispose();
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('MediaLibraryService Unit Tests', () {
    test('Что проверяем: Начальная загрузка и работа методов добавления/удаления трека. '
        'Входные данные: addTrack() и deleteTrack(). '
        'Ожидаемый результат: Список tracks динамически пополняется и уменьшается, генерируются уведомления.', () async {
      await Future.delayed(const Duration(milliseconds: 50)); // дать завершиться конструктору

      expect(libraryService.tracks, isEmpty);

      final track = LibraryTrack(
        id: 't-1',
        title: 'Tavern Theme',
        filePath: '/music/tavern.mp3',
        busType: AudioBusType.music,
        tags: const ['Таверна'],
      );

      await libraryService.addTrack(track);

      expect(libraryService.tracks.length, equals(1));
      expect(libraryService.tracks.first.id, equals('t-1'));

      await libraryService.deleteTrack('t-1');
      expect(libraryService.tracks, isEmpty);
    });

    test('Что проверяем: Обновление параметров трека через MediaLibraryService (updateTrack). '
        'Входные данные: Существующий трек c id="t-mod", вызов updateTrack с новым названием "Modified Track". '
        'Ожидаемый результат: В списке libraryService.tracks название трека обновляется до "Modified Track".', () async {
      final track = LibraryTrack(
        id: 't-mod',
        title: 'Original Track',
        filePath: '/orig.mp3',
        busType: AudioBusType.music,
      );

      await libraryService.addTrack(track);
      expect(libraryService.tracks.first.title, equals('Original Track'));

      final updated = track.copyWith(title: 'Modified Track');
      await libraryService.updateTrack(updated);

      expect(libraryService.tracks.length, equals(1));
      expect(libraryService.tracks.first.title, equals('Modified Track'));
    });

    test('Что проверяем: Фильтрация по аудиошинам (setBusFilter). '
        'Входные данные: Добавление 3 треков (Music, Ambient, SFX) и установка фильтра setBusFilter(AudioBusType.ambient). '
        'Ожидаемый результат: Геттер tracks возвращает только 1 амбиент-трек.', () async {
      final t1 = LibraryTrack(id: '1', title: 'Music', filePath: '/m.mp3', busType: AudioBusType.music);
      final t2 = LibraryTrack(id: '2', title: 'Ambient', filePath: '/a.mp3', busType: AudioBusType.ambient);
      final t3 = LibraryTrack(id: '3', title: 'SFX', filePath: '/s.wav', busType: AudioBusType.sfx);

      await libraryService.addTrack(t1);
      await libraryService.addTrack(t2);
      await libraryService.addTrack(t3);

      expect(libraryService.tracks.length, equals(3));

      libraryService.setBusFilter(AudioBusType.ambient);
      expect(libraryService.activeBusFilter, equals(AudioBusType.ambient));
      expect(libraryService.tracks.length, equals(1));
      expect(libraryService.tracks.first.id, equals('2'));

      libraryService.setBusFilter(null);
      expect(libraryService.tracks.length, equals(3));
    });

    test('Что проверяем: Фильтрация по поисковому запросу (setSearchQuery) по названию и тегам. '
        'Входные данные: Трек с названием "Boss Fight" и тегом "Дракон". Поиск "дракон" и "boss". '
        'Ожидаемый результат: Поиск регистронезависимо находит соответствие по обоим критериям.', () async {
      final t1 = LibraryTrack(
        id: 'b1',
        title: 'Boss Fight',
        filePath: '/boss.mp3',
        busType: AudioBusType.music,
        tags: const ['Дракон', 'Финал'],
      );
      final t2 = LibraryTrack(
        id: 'b2',
        title: 'Calm Rain',
        filePath: '/rain.mp3',
        busType: AudioBusType.ambient,
      );

      await libraryService.addTrack(t1);
      await libraryService.addTrack(t2);

      libraryService.setSearchQuery('дракон');
      expect(libraryService.tracks.length, equals(1));
      expect(libraryService.tracks.first.id, equals('b1'));

      libraryService.setSearchQuery('BOSS');
      expect(libraryService.tracks.length, equals(1));

      libraryService.setSearchQuery('non_matching_search');
      expect(libraryService.tracks, isEmpty);
    });

    test('Что проверяем: Маршрутизация трека на соответственные аудио-шины (playTrackToEngine). '
        'Входные данные: Вызов playTrackToEngine для Music, Ambient и SFX треков в AudioEngineService. '
        'Ожидаемый результат: MusicBus получает currentTrack, AmbientBus добавляет слой, SfxBus добавляет триггер и активирует даккинг.', () async {
      final audioEngine = AudioEngineService();

      final musicTrack = LibraryTrack(
        id: 'm1',
        title: 'Music Track',
        filePath: '/music.mp3',
        busType: AudioBusType.music,
        intensity: MusicIntensity.battle,
      );
      final ambientTrack = LibraryTrack(
        id: 'a1',
        title: 'Ambient Track',
        filePath: '/ambient.mp3',
        busType: AudioBusType.ambient,
      );
      final sfxTrack = LibraryTrack(
        id: 's1',
        title: 'SFX Fireball',
        filePath: '/sfx.wav',
        busType: AudioBusType.sfx,
      );

      // Play Music
      libraryService.playTrackToEngine(musicTrack, audioEngine);
      expect(audioEngine.musicBus.currentTrack?.id, equals('m1'));
      expect(audioEngine.musicBus.currentIntensity, equals(MusicIntensity.battle));

      // Play Ambient
      libraryService.playTrackToEngine(ambientTrack, audioEngine);
      expect(audioEngine.ambientBus.layers.length, equals(1));
      expect(audioEngine.ambientBus.layers.first.id, equals('a1'));
      expect(audioEngine.ambientBus.layers.first.isActive, isTrue);

      // Play SFX
      libraryService.playTrackToEngine(sfxTrack, audioEngine);
      expect(audioEngine.sfxBus.triggers.length, equals(1));
      expect(audioEngine.sfxBus.triggers.first.id, equals('s1'));
      expect(audioEngine.duckingController.isDucked, isTrue);

      audioEngine.dispose();
    });
  });
}
