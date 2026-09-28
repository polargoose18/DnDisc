import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/custom_theme_model.dart';

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
    tempDir = await Directory.systemTemp.createTemp('ttrpg_db_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('DatabaseService Integration Tests', () {
    test('Что проверяем: Инициализация БД SQLite и вставка записи (insertTrack). '
        'Входные данные: LibraryTrack c id="db-1", busType=music. '
        'Ожидаемый результат: getAllTracks() возвращает список из 1 записи с идентичными полями.', () async {
      final track = LibraryTrack(
        id: 'db-1',
        title: 'Epic Adventure',
        filePath: '/music/epic.mp3',
        busType: AudioBusType.music,
        intensity: MusicIntensity.battle,
        tags: const ['Бой', 'Эпос'],
        colorHex: 0xFF9C27B0,
      );

      await dbService.insertTrack(track);

      final tracks = await dbService.getAllTracks();
      expect(tracks.length, equals(1));
      expect(tracks.first.id, equals('db-1'));
      expect(tracks.first.title, equals('Epic Adventure'));
      expect(tracks.first.busType, equals(AudioBusType.music));
      expect(tracks.first.intensity, equals(MusicIntensity.battle));
      expect(tracks.first.tags, equals(['Бой', 'Эпос']));
    });

    test('Что проверяем: Фильтрация по шине (getTracksByBus). '
        'Входные данные: Три трека (music, ambient, sfx). '
        'Ожидаемый результат: getTracksByBus(ambient) возвращает только амбиент-треки.', () async {
      final t1 = LibraryTrack(id: '1', title: 'Music Track', filePath: '/m.mp3', busType: AudioBusType.music);
      final t2 = LibraryTrack(id: '2', title: 'Forest Ambience', filePath: '/a.mp3', busType: AudioBusType.ambient);
      final t3 = LibraryTrack(id: '3', title: 'Sword SFX', filePath: '/s.wav', busType: AudioBusType.sfx);

      await dbService.insertTrack(t1);
      await dbService.insertTrack(t2);
      await dbService.insertTrack(t3);

      final ambientTracks = await dbService.getTracksByBus(AudioBusType.ambient);
      expect(ambientTracks.length, equals(1));
      expect(ambientTracks.first.title, equals('Forest Ambience'));
    });

    test('Что проверяем: Поиск по названию и тегам (searchTracks). '
        'Входные данные: Поисковый запрос "Таверна". '
        'Ожидаемый результат: Находит трек, имеющий "Таверна" в тегах или названии.', () async {
      final t1 = LibraryTrack(id: 's1', title: 'Таверна Праздник', filePath: '/1.mp3', busType: AudioBusType.music, tags: const ['Пиво']);
      final t2 = LibraryTrack(id: 's2', title: 'Peaceful Night', filePath: '/2.mp3', busType: AudioBusType.ambient, tags: const ['Таверна', 'Уют']);
      final t3 = LibraryTrack(id: 's3', title: 'Dungeon Ambience', filePath: '/3.mp3', busType: AudioBusType.ambient, tags: const ['Мрак']);

      await dbService.insertTrack(t1);
      await dbService.insertTrack(t2);
      await dbService.insertTrack(t3);

      final searchResults = await dbService.searchTracks('Таверна');
      expect(searchResults.length, equals(2)); // t1 (title) & t2 (tags)
    });

    test('Что проверяем: Поиск с фильтрацией по шине (searchTracks с filterBus). '
        'Входные данные: Поисковый запрос "Таверна" с фильтром filterBus = AudioBusType.music. '
        'Ожидаемый результат: Находит только 1 музыкальный трек, амбиент-трек с тем же словом отфильтровывается.', () async {
      final t1 = LibraryTrack(id: 's1', title: 'Таверна Праздник', filePath: '/1.mp3', busType: AudioBusType.music, tags: const ['Пиво']);
      final t2 = LibraryTrack(id: 's2', title: 'Peaceful Night', filePath: '/2.mp3', busType: AudioBusType.ambient, tags: const ['Таверна', 'Уют']);

      await dbService.insertTrack(t1);
      await dbService.insertTrack(t2);

      final musicResults = await dbService.searchTracks('Таверна', filterBus: AudioBusType.music);
      expect(musicResults.length, equals(1));
      expect(musicResults.first.id, equals('s1'));

      final nonExistentResults = await dbService.searchTracks('НесуществующийЗапрос');
      expect(nonExistentResults, isEmpty);
    });

    test('Что проверяем: Обновление существующего трека (updateTrack). '
        'Входные данные: Измененный трек с тем же id="db-1" и новым названием "Renamed Track". '
        'Ожидаемый результат: Запись в БД обновляется без создания дубликатов.', () async {
      final track = LibraryTrack(id: 'u1', title: 'Old Title', filePath: '/old.mp3', busType: AudioBusType.music);
      await dbService.insertTrack(track);

      final updated = track.copyWith(title: 'Renamed Track');
      await dbService.updateTrack(updated);

      final all = await dbService.getAllTracks();
      expect(all.length, equals(1));
      expect(all.first.title, equals('Renamed Track'));
    });

    test('Что проверяем: Удаление трека по ID (deleteTrack). '
        'Входные данные: deleteTrack("d1"). '
        'Ожидаемый результат: Трек удаляется из базы данных.', () async {
      final track = LibraryTrack(id: 'd1', title: 'To Delete', filePath: '/del.mp3', busType: AudioBusType.sfx);
      await dbService.insertTrack(track);

      expect((await dbService.getAllTracks()).length, equals(1));

      await dbService.deleteTrack('d1');

      expect((await dbService.getAllTracks()), isEmpty);
    });

    test('Что проверяем: Вставка, чтение, обновление и удаление сцен (Scenes CRUD) в DatabaseService. '
        'Входные данные: SceneModel с музыкой, амбиентами и SFX. '
        'Ожидаемый результат: Корректное сохранение в SQLite, обновление и удаление.', () async {
      final scene = SceneModel(
        id: 'scene-db-1',
        name: 'Тайный Лес',
        description: 'Шорохи листвы и древняя магия',
        colorHex: 0xFF4CAF50,
        musicTrackId: 'm-forest',
        musicIntensity: MusicIntensity.calm,
        ambientLayerVolumes: {'leaves': 0.7, 'wind': 0.5},
        soundboardSfxIds: ['sfx-branch'],
        imagePath: '/covers/forest.jpg',
      );

      // 1. Insert
      await dbService.insertScene(scene);
      final allScenes = await dbService.getAllScenes();
      expect(allScenes.length, equals(1));
      expect(allScenes.first.name, equals('Тайный Лес'));
      expect(allScenes.first.ambientLayerVolumes, equals({'leaves': 0.7, 'wind': 0.5}));
      expect(allScenes.first.imagePath, equals('/covers/forest.jpg'));

      // 2. GetById
      final found = await dbService.getSceneById('scene-db-1');
      expect(found, isNotNull);
      expect(found!.id, equals('scene-db-1'));

      // 3. Update
      final updated = scene.copyWith(name: 'Древний Тайный Лес');
      await dbService.updateScene(updated);
      final updatedScenes = await dbService.getAllScenes();
      expect(updatedScenes.first.name, equals('Древний Тайный Лес'));

      // 4. Delete
      await dbService.deleteScene('scene-db-1');
      expect((await dbService.getAllScenes()), isEmpty);
      expect((await dbService.getSceneById('scene-db-1')), isNull);
    });

    test('Что проверяем: Вставка, чтение, обновление и удаление кастомных тем (Custom Themes CRUD) в DatabaseService. '
        'Входные данные: CustomThemeModel с полной палитрой цветов. '
        'Ожидаемый результат: Корректная запись в таблицу custom_themes, поиск по id, обновление и удаление.', () async {
      const theme = CustomThemeModel(
        id: 'theme-db-1',
        name: 'Crimson Abyss',
        isDark: true,
        primaryColor: 0xFFE11D48,
        secondaryColor: 0xFFFB7185,
        backgroundColor: 0xFF140B0E,
        surfaceColor: 0xFF221116,
        cardColor: 0xFF2D161C,
        accentColor: 0xFFF43F5E,
        textPrimaryColor: 0xFFFFF1F2,
        textSecondaryColor: 0xFFFDA4AF,
        duckingBadgeColor: 0xFFEA580C,
        battleIntensityColor: 0xFFFF2E63,
        bossIntensityColor: 0xFF880808,
      );

      // 1. Insert
      await dbService.insertCustomTheme(theme);
      final allThemes = await dbService.getAllCustomThemes();
      expect(allThemes.length, equals(1));
      expect(allThemes.first.name, equals('Crimson Abyss'));
      expect(allThemes.first.primaryColor, equals(0xFFE11D48));

      // 2. GetById
      final found = await dbService.getCustomThemeById('theme-db-1');
      expect(found, isNotNull);
      expect(found!.id, equals('theme-db-1'));
      expect(found.bossIntensityColor, equals(0xFF880808));

      // 3. Update
      final updated = theme.copyWith(name: 'Crimson Catacombs');
      await dbService.updateCustomTheme(updated);
      final updatedThemes = await dbService.getAllCustomThemes();
      expect(updatedThemes.first.name, equals('Crimson Catacombs'));

      // 4. Delete
      await dbService.deleteCustomTheme('theme-db-1');
      expect((await dbService.getAllCustomThemes()), isEmpty);
      expect((await dbService.getCustomThemeById('theme-db-1')), isNull);
    });
  });
}
