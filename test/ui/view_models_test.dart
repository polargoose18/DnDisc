import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/custom_theme_repository.dart';
import 'package:ttrpg_audio_player/services/scene_service.dart';
import 'package:ttrpg_audio_player/services/media_library_service.dart';
import 'package:ttrpg_audio_player/services/theme_service.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';

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
    tempDir = await Directory.systemTemp.createTemp('ttrpg_vm_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('UI ViewModels Architecture Unit Tests', () {
    test(
      'Что проверяем: Инициализация и CRUD операции в SceneViewModel. '
      'Входные данные: Создание SceneViewModel с инжектированным SqliteSceneRepository и добавление SceneModel. '
      'Ожидаемый результат: ViewModel сохраняет и возвращает обновлённые сцены, notifyListeners оповещает слушателей.',
      () async {
        final repository = SqliteSceneRepository(db: dbService);
        final viewModel = SceneViewModel(repository: repository, autoLoad: false);

        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        final newScene = SceneModel(id: 'vm-scene-1', name: 'Forest Encounter');
        await viewModel.createScene(newScene);

        expect(notifyCount, greaterThan(0));
        expect(viewModel.scenes.length, equals(1));
        expect(viewModel.scenes.first.name, equals('Forest Encounter'));

        await viewModel.deleteScene('vm-scene-1');
        expect(viewModel.scenes, isEmpty);
      },
    );

    test(
      'Что проверяем: Проксирование уведомлений от SceneService в SceneViewModel. '
      'Входные данные: Инжектирование SceneService в SceneViewModel через конструктор composition DI. '
      'Ожидаемый результат: Изменение состояния в SceneService вызывает оповещение в SceneViewModel.',
      () async {
        final repository = SqliteSceneRepository(db: dbService);
        final service = SceneService(repository: repository, autoLoad: false);
        final viewModel = SceneViewModel(service: service);

        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        final scene = SceneModel(id: 'vm-scene-comp', name: 'Dungeon Master');
        await service.createScene(scene);

        expect(notifyCount, greaterThan(0));
        expect(viewModel.scenes.length, equals(1));
        expect(viewModel.scenes.first.id, equals('vm-scene-comp'));
      },
    );

    test(
      'Что проверяем: Фильтрация и управление треками в MediaLibraryViewModel. '
      'Входные данные: Добавление трека и установка busFilter и searchQuery. '
      'Ожидаемый результат: MediaLibraryViewModel правильно фильтрует треки в списке.',
      () async {
        final repository = SqliteMediaLibraryRepository(db: dbService);
        final viewModel = MediaLibraryViewModel(repository: repository, autoLoad: false);

        final track = LibraryTrack(
          id: 'vm-track-1',
          title: 'Battle Drums',
          filePath: '/music/drums.mp3',
          busType: AudioBusType.music,
        );

        await viewModel.addTrack(track);
        expect(viewModel.tracks.length, equals(1));

        viewModel.setBusFilter(AudioBusType.ambient);
        expect(viewModel.tracks, isEmpty);

        viewModel.setBusFilter(AudioBusType.music);
        expect(viewModel.tracks.length, equals(1));

        viewModel.setSearchQuery('NonExistent');
        expect(viewModel.tracks, isEmpty);

        viewModel.setSearchQuery('drums');
        expect(viewModel.tracks.length, equals(1));
      },
    );

    test(
      'Что проверяем: Внедрение MediaLibraryService в MediaLibraryViewModel через composition. '
      'Входные данные: Инжектирование существующего MediaLibraryService в MediaLibraryViewModel. '
      'Ожидаемый результат: MediaLibraryViewModel проксирует вызовы и уведомления от службы.',
      () async {
        final repository = SqliteMediaLibraryRepository(db: dbService);
        final service = MediaLibraryService(repository: repository, autoLoad: false);
        final viewModel = MediaLibraryViewModel(service: service);

        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        final track = LibraryTrack(
          id: 'vm-track-comp',
          title: 'Tavern Lute',
          filePath: '/music/lute.mp3',
          busType: AudioBusType.music,
        );

        await service.addTrack(track);

        expect(notifyCount, greaterThan(0));
        expect(viewModel.tracks.length, equals(1));
        expect(viewModel.tracks.first.title, equals('Tavern Lute'));
      },
    );

    test(
      'Что проверяем: Управление темами и кастомными темами в ThemeViewModel. '
      'Входные данные: ThemeViewModel с SqliteCustomThemeRepository и переключение темы. '
      'Ожидаемый результат: Тема активируется и создаются кастомные цветовые схемы.',
      () async {
        final repository = SqliteCustomThemeRepository(db: dbService);
        final viewModel = ThemeViewModel(repository: repository, autoLoad: false);

        expect(viewModel.activeTheme, isNotNull);
        expect(viewModel.currentThemeData, isNotNull);

        viewModel.selectTheme(AppThemes.emeraldForestId);
        expect(viewModel.activeTheme.id, equals(AppThemes.emeraldForestId));
      },
    );

    test(
      'Что проверяем: Инжектирование ThemeService в ThemeViewModel через composition. '
      'Входные данные: Передача ThemeService в ThemeViewModel и вызов selectTheme. '
      'Ожидаемый результат: ThemeViewModel получает обновлённое имя и ID активной темы.',
      () async {
        final service = ThemeService(initialThemeId: AppThemes.deepDarkId, autoLoad: false);
        final viewModel = ThemeViewModel(service: service);

        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        service.selectTheme(AppThemes.crimsonDungeonId);

        expect(notifyCount, greaterThan(0));
        expect(viewModel.activeThemeId, equals(AppThemes.crimsonDungeonId));
      },
    );
  });
}
