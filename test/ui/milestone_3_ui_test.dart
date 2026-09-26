import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/services/media_library_service.dart';
import 'package:ttrpg_audio_player/services/settings_service.dart';
import 'package:ttrpg_audio_player/services/scene_service.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
import 'package:ttrpg_audio_player/db/database_service.dart';
import 'package:ttrpg_audio_player/models/scene_model.dart';

import 'package:ttrpg_audio_player/ui/widgets/scene_selector_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/create_edit_scene_dialog.dart';
import 'package:ttrpg_audio_player/ui/screens/settings_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/main_dashboard_screen.dart';

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

Widget createM3TestableWidget(Widget child, {
  AudioEngineService? engine,
  MediaLibraryService? library,
  SettingsService? settings,
  SceneService? sceneService,
  LoggerService? logger,
}) {
  final eng = engine ?? AudioEngineService();
  final log = logger ?? LoggerService();
  final set = settings ?? SettingsService();
  final scn = sceneService ?? SceneService(autoLoad: false);
  final lib = library ?? MediaLibraryService(autoLoad: false);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LoggerService>.value(value: log),
      ChangeNotifierProvider<SettingsService>.value(value: set),
      ChangeNotifierProvider<AudioEngineService>.value(value: eng),
      ChangeNotifierProvider<MusicBusController>.value(value: eng.musicBus),
      ChangeNotifierProvider<AmbientBusController>.value(value: eng.ambientBus),
      ChangeNotifierProvider<SfxBusController>.value(value: eng.sfxBus),
      ChangeNotifierProvider<SceneService>.value(value: scn),
      ChangeNotifierProvider<MediaLibraryService>.value(value: lib),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
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
    tempDir = await Directory.systemTemp.createTemp('ttrpg_m3_ui_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('SceneSelectorPanel Widget Tests', () {
    testWidgets(
      'Что проверяем: Отображение пустого состояния панели сцен. '
      'Входные данные: SceneSelectorPanel без созданных сцен. '
      'Ожидаемый результат: Отображается заголовок "Атмосферные Сцены" и подсказка "Сцены пока не созданы".',
      (WidgetTester tester) async {
        final sceneService = SceneService(autoLoad: false);
        await tester.runAsync(() async => await sceneService.loadScenes());

        await tester.pumpWidget(createM3TestableWidget(
          const SceneSelectorPanel(),
          sceneService: sceneService,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Атмосферные Сцены'), findsOneWidget);
        expect(find.text('Создать сцену'), findsOneWidget);
        expect(find.textContaining('Сцены пока не созданы'), findsOneWidget);

        sceneService.dispose();
      },
    );

    testWidgets(
      'Что проверяем: Отображение карточки сцены и клик для активации. '
      'Входные данные: Панель со сценой "Пещера Дракона", клик по карточке. '
      'Ожидаемый результат: activeSceneId обновляется, карточка помечается как "АКТИВНА".',
      (WidgetTester tester) async {
        final sceneService = SceneService(autoLoad: false);
        final library = MediaLibraryService(autoLoad: false);
        final engine = AudioEngineService();

        final scene = SceneModel(
          id: 'sc-dragon',
          name: 'Пещера Дракона',
          description: 'Жар лавы и тяжелое дыхание',
          colorHex: 0xFFF44336,
        );

        await tester.runAsync(() async {
          await library.loadTracks();
          await sceneService.loadScenes();
          await sceneService.createScene(scene);
        });

        await tester.pumpWidget(createM3TestableWidget(
          const SceneSelectorPanel(),
          sceneService: sceneService,
          library: library,
          engine: engine,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Пещера Дракона'), findsOneWidget);
        expect(find.text('Включить'), findsOneWidget);

        // Нажимаем на карточку для активации сцены
        await tester.runAsync(() async {
          await tester.tap(find.text('Пещера Дракона'));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(sceneService.activeSceneId, equals('sc-dragon'));
        expect(find.text('АКТИВНА'), findsOneWidget);

        sceneService.dispose();
        library.dispose();
        engine.dispose();
      },
    );
  });

  group('CreateEditSceneDialog Widget Tests', () {
    testWidgets(
      'Что проверяем: Создание новой сцены через диалог CreateEditSceneDialog с фильтрацией поиска. '
      'Входные данные: Ввод названия "Тронный Зал", поиск трека и нажатие кнопки "Создать". '
      'Ожидаемый результат: Диалог закрывается и возвращает объект SceneModel с name="Тронный Зал".',
      (WidgetTester tester) async {
        final library = MediaLibraryService(autoLoad: false);
        await tester.runAsync(() async => await library.loadTracks());
        SceneModel? returnedScene;

        await tester.pumpWidget(
          createM3TestableWidget(
            Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    returnedScene = await showDialog<SceneModel>(
                      context: ctx,
                      builder: (_) => const CreateEditSceneDialog(),
                    );
                  },
                  child: const Text('Open Scene Dialog'),
                ),
              ),
            ),
            library: library,
          ),
        );

        await tester.tap(find.text('Open Scene Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Создание новой сцены'), findsOneWidget);

        // Вводим название сцены
        await tester.enterText(
          find.widgetWithText(TextField, 'Название сцены *'),
          'Тронный Зал',
        );
        await tester.pumpAndSettle();

        // Проверяем наличие полей поиска для каждого канала
        expect(find.widgetWithText(TextField, 'Поиск музыки по названию или тегам...'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Поиск эмбиента по названию или тегам...'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Поиск SFX по названию или тегам...'), findsOneWidget);

        // Нажимаем "Создать"
        await tester.tap(find.text('Создать'));
        await tester.pumpAndSettle();

        expect(returnedScene, isNotNull);
        expect(returnedScene!.name, equals('Тронный Зал'));

        library.dispose();
      },
    );
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets(
      'Что проверяем: Отображение параметров и управление слайдерами и переключателями в SettingsScreen. '
      'Входные данные: SettingsScreen с дефолтными настройками. '
      'Ожидаемый результат: Отображаются разделы интерфейса, фейдов, даккинга и кнопки экспорта/импорта.',
      (WidgetTester tester) async {
        final settings = SettingsService();
        final library = MediaLibraryService(autoLoad: false);
        final sceneService = SceneService(autoLoad: false);
        await tester.runAsync(() async {
          await library.loadTracks();
          await sceneService.loadScenes();
        });

        await tester.pumpWidget(createM3TestableWidget(
          const SettingsScreen(),
          settings: settings,
          library: library,
          sceneService: sceneService,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Настройки звукового движка'), findsOneWidget);
        expect(find.text('Интерфейс и панель управления'), findsOneWidget);
        expect(find.text('Отображать иконку консоли логов'), findsOneWidget);
        expect(find.text('Плавные переходы (Fade Engine)'), findsOneWidget);
        expect(find.text('Авто-приглушение музыки при SFX (Ducking)'), findsOneWidget);
        expect(find.text('Пакеты Пресетов (ZIP Архивы)'), findsOneWidget);
        expect(find.text('Импорт пресета (ZIP)'), findsOneWidget);
        expect(find.text('Экспорт пресета в ZIP'), findsOneWidget);

        // Проверяем переключение иконки логов
        final logSwitch = find.widgetWithText(SwitchListTile, 'Отображать иконку консоли логов');
        await tester.scrollUntilVisible(logSwitch, 200);
        expect(logSwitch, findsOneWidget);
        await tester.tap(logSwitch);
        await tester.pumpAndSettle();
        expect(settings.showLogConsoleIcon, isFalse);

        // Проверяем изменение значения фейда музыки через сервис
        settings.setMusicFadeMs(2500);
        await tester.pumpAndSettle();

        expect(find.textContaining('2500 мс'), findsOneWidget);

        settings.dispose();
        library.dispose();
        sceneService.dispose();
      },
    );
  });

  group('MainDashboardScreen 3-Tab Integration Tests', () {
    testWidgets(
      'Что проверяем: Навигация между 3 вкладками главного экрана. '
      'Входные данные: Клик по вкладкам "Панель Мастера", "Общая Библиотека", "Настройки". '
      'Ожидаемый результат: Все 3 вкладки корректно переключаются и отображают соответствующие экраны.',
      (WidgetTester tester) async {
        final engine = AudioEngineService();
        final library = MediaLibraryService(autoLoad: false);
        final sceneService = SceneService(autoLoad: false);
        final settings = SettingsService();
        await tester.runAsync(() async {
          await library.loadTracks();
          await sceneService.loadScenes();
        });

        await tester.pumpWidget(createM3TestableWidget(
          const MainDashboardScreen(),
          engine: engine,
          library: library,
          sceneService: sceneService,
          settings: settings,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Панель Мастера'), findsOneWidget);
        expect(find.text('Общая Библиотека'), findsOneWidget);
        expect(find.text('Настройки'), findsOneWidget);

        // 1. Вкладка Настройки
        await tester.tap(find.text('Настройки'));
        await tester.pumpAndSettle();
        expect(find.text('Настройки звукового движка'), findsOneWidget);

        // 2. Вкладка Библиотека
        await tester.tap(find.text('Общая Библиотека'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('library_search_input')), findsOneWidget);

        // 3. Возврат на Панель Мастера
        await tester.tap(find.text('Панель Мастера'));
        await tester.pumpAndSettle();
        expect(find.text('Атмосферные Сцены'), findsOneWidget);

        engine.dispose();
        library.dispose();
        sceneService.dispose();
        settings.dispose();
      },
    );
  });
}
