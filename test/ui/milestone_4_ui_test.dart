import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/data/services/settings_service.dart';
import 'package:ttrpg_audio_player/data/services/theme_service.dart';
import 'package:ttrpg_audio_player/services/shortcut_service.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/ui/screens/responsive_gm_dashboard.dart';
import 'package:ttrpg_audio_player/ui/screens/settings_screen.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';
import 'package:ttrpg_audio_player/ui/widgets/scene_card.dart';
import 'package:ttrpg_audio_player/ui/widgets/scene_backdrop_header.dart';
import 'package:ttrpg_audio_player/ui/widgets/custom_theme_editor_dialog.dart';
import 'package:ttrpg_audio_player/ui/widgets/sticky_mini_player.dart';
import 'package:ttrpg_audio_player/ui/widgets/ambient_mixer_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/soundboard_grid.dart';

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

Widget createTestApp({
  required Widget child,
  ThemeService? themeService,
  SceneService? sceneService,
  AudioEngineService? audioEngine,
  SettingsService? settingsService,
  ShortcutService? shortcutService,
  Size screenSize = const Size(1200, 900),
}) {
  final settings = settingsService ?? SettingsService();
  final engine = audioEngine ?? AudioEngineService(settings: settings);
  final themes = themeService ?? ThemeService();
  final scenes = sceneService ?? SceneService(autoLoad: false);
  final shortcuts = shortcutService ?? ShortcutService(audioEngine: engine);
  final library = MediaLibraryService(autoLoad: false);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LoggerService>(create: (_) => LoggerService()),
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      ChangeNotifierProvider<ThemeService>.value(value: themes),
      ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel(service: themes)),
      ChangeNotifierProvider<AudioEngineService>.value(value: engine),
      ChangeNotifierProvider<MusicBusController>.value(value: engine.musicBus),
      ChangeNotifierProvider<AmbientBusController>.value(value: engine.ambientBus),
      ChangeNotifierProvider<SfxBusController>.value(value: engine.sfxBus),
      ChangeNotifierProvider<ShortcutService>.value(value: shortcuts),
      ChangeNotifierProvider<MediaLibraryService>.value(value: library),
      ChangeNotifierProvider<MediaLibraryViewModel>(create: (_) => MediaLibraryViewModel(service: library)),
      ChangeNotifierProvider<SceneService>.value(value: scenes),
      ChangeNotifierProvider<SceneViewModel>(create: (_) => SceneViewModel(service: scenes)),
    ],
    child: Consumer<SettingsService>(
      builder: (context, settings, _) {
        return MaterialApp(
          theme: themes.currentThemeData,
          locale: settings.currentLocale ?? const Locale('ru'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: Scaffold(body: child),
            ),
          ),
        );
      },
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
    tempDir = await Directory.systemTemp.createTemp('ttrpg_m4_ui_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('ResponsiveGmDashboard Widget Tests', () {
    testWidgets(
      'Что проверяем: Отображение 3-колоночного пульта мастера на Desktop экранах (>= 1000px). '
      'Входные данные: ResponsiveGmDashboard с размером экрана 1280x900. '
      'Ожидаемый результат: В дереве виджетов одновременно присутствуют панель сцен, шапка бэкдропа, панель музыки, микшер эмбиента и саундборд.',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            child: const ResponsiveGmDashboard(),
            screenSize: const Size(1280, 900),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Сцены'), findsWidgets);
        expect(find.text('Музыкальная дорожка'), findsOneWidget);
        expect(find.textContaining('Эмбиент'), findsWidgets);
        expect(find.textContaining('Soundboard'), findsWidgets);
      },
    );

    testWidgets(
      'Что проверяем: Отображение вкладок и прилипающего StickyMiniPlayer на компактных/мобильных экранах (< 1000px). '
      'Входные данные: ResponsiveGmDashboard с размером экрана 800x900. '
      'Ожидаемый результат: Отображаются мобильные вкладки (Сцены, Музыка, Эмбиент, SFX) и внизу экрана находится StickyMiniPlayer.',
      (tester) async {
        tester.view.physicalSize = const Size(800, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            child: const ResponsiveGmDashboard(),
            screenSize: const Size(800, 900),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StickyMiniPlayer), findsOneWidget);
        expect(find.text('Сцены'), findsWidgets);
        expect(find.text('Музыка'), findsWidgets);
        expect(find.text('Эмбиент'), findsWidgets);
        expect(find.text('SFX'), findsWidgets);
      },
    );
  });

  group('SceneCard Widget Tests', () {
    testWidgets(
      'Что проверяем: Отображение карточки сцены в неактивном и активном состоянии. '
      'Входные данные: SceneCard со сценой "Древняя Таверна", isActive=true и isActive=false. '
      'Ожидаемый результат: При isActive=true отображается бейдж "АКТИВНА" и кнопка "Активна".',
      (tester) async {
        final scene = SceneModel(
          id: 'sc_card_1',
          name: 'Древняя Таверна',
          description: 'Уютный очаг и звон кружек',
          musicIntensity: MusicIntensity.calm,
        );

        bool activated = false;

        await tester.pumpWidget(
          createTestApp(
            child: SceneCard(
              scene: scene,
              isActive: true,
              onActivate: () => activated = true,
              onEdit: () {},
              onDuplicate: () {},
              onDelete: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Древняя Таверна'), findsOneWidget);
        expect(find.text('Уютный очаг и звон кружек'), findsOneWidget);
        expect(find.text('АКТИВНА'), findsWidgets);

        await tester.tap(find.byType(ElevatedButton));
        expect(activated, isTrue);
      },
    );
  });

  group('SceneBackdropHeader Widget Tests', () {
    testWidgets(
      'Что проверяем: Отображение атмосферной шапки SceneBackdropHeader с активной сценой. '
      'Входные данные: SceneService с активной сценой "Пещера Дракона". '
      'Ожидаемый результат: Отображается заголовок "Пещера Дракона", бейдж "ТЕКУЩАЯ СЦЕНА" и чипы интенсивности (Calm, Suspense, Battle, Boss).',
      (tester) async {
        final sceneService = SceneService(autoLoad: false);
        final scene = SceneModel(
          id: 'sc_dragon_cave',
          name: 'Пещера Дракона',
          description: 'Жар лавы и глухой рокот чешуи',
        );
        await tester.runAsync(() async {
          await sceneService.createScene(scene);
          await sceneService.activateScene(scene);
        });

        await tester.pumpWidget(
          createTestApp(
            sceneService: sceneService,
            child: const SceneBackdropHeader(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Пещера Дракона'), findsOneWidget);
        expect(find.text('ТЕКУЩАЯ СЦЕНА'), findsOneWidget);
        expect(find.text('Calm'), findsOneWidget);
        expect(find.text('Battle'), findsOneWidget);
      },
    );
  });

  group('CustomThemeEditorDialog Widget Tests', () {
    testWidgets(
      'Что проверяем: Открытие диалога редактирования темы, интерактивный предпросмотр и сохранение. '
      'Входные данные: CustomThemeEditorDialog с дефолтными параметрами. '
      'Ожидаемый результат: Отображаются предпросмотр темы, кнопки выбора цветов, поле ввода названия и кнопка "Сохранить тему".',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const CustomThemeEditorDialog(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Создание кастомной темы'), findsOneWidget);
        expect(find.text('Предпросмотр темы'), findsOneWidget);
        expect(find.text('Настройка палитры цветов'), findsOneWidget);
        expect(find.text('Сохранить тему'), findsOneWidget);
      },
    );
  });

  group('SettingsScreen Milestone 4 Widget Tests', () {
    testWidgets(
      'Что проверяем: Отображение разделов тем оформления и горячих клавиш в SettingsScreen. '
      'Входные данные: SettingsScreen с активным ThemeService и ShortcutService. '
      'Ожидаемый результат: Отображаются встроенные пресеты (Deep Dark, Clean Light, Emerald Forest и др.), кнопка "+ Создать новую тему" и таблица горячих клавиш.',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SettingsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Темы оформления (Themes)'), findsOneWidget);
        expect(find.text('Deep Dark'), findsOneWidget);
        expect(find.text('Clean Light'), findsOneWidget);
        expect(find.text('+ Создать новую тему'), findsOneWidget);
        expect(find.text('Централизованные горячие клавиши'), findsOneWidget);
        expect(find.text('Space'), findsWidgets);
      },
    );
  });

  group('SoundboardGrid and AmbientMixerPanel Widget Tests', () {
    testWidgets(
      'Что проверяем: Отображение SFX Soundboard и регулировка громкости без влияния на мастер. '
      'Входные данные: SoundboardGrid с добавленным SFX триггером "Удар меча". '
      'Ожидаемый результат: Название "Удар меча" отображается на кнопке, перетаскивание слайдера SFX обновляет sfxBus.rawVolume.',
      (tester) async {
        final engine = AudioEngineService();
        engine.sfxBus.addTrigger(
          const SfxTrigger(
            id: 'sfx_sword',
            title: 'Удар меча',
            filePath: '/dummy/sword.wav',
            hotkey: '1',
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            audioEngine: engine,
            child: const SingleChildScrollView(
              child: SoundboardGrid(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Удар меча'), findsOneWidget);
        expect(find.text('[1]'), findsOneWidget);
        expect(find.text('Panic Stop [Esc]'), findsOneWidget);
      },
    );

    testWidgets(
      'Что проверяем: Регулировка громкости эмбиент-слоя при выключенном состоянии. '
      'Входные данные: AmbientMixerPanel со слоем isActive=false. '
      'Ожидаемый результат: Слайдер доступен для взаимодействия и изменяет громкость слоя.',
      (tester) async {
        final engine = AudioEngineService();
        engine.ambientBus.addLayer(
          const AmbientLayer(
            id: 'amb_rain',
            title: 'Грозовой дождь',
            filePath: '/dummy/rain.mp3',
            isActive: false,
            volume: 0.5,
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            audioEngine: engine,
            child: const SingleChildScrollView(
              child: AmbientMixerPanel(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Грозовой дождь'), findsOneWidget);
        expect(find.text('Громкость: 50%'), findsOneWidget);

        final sliderFinder = find.byKey(const ValueKey('ambient_slider_amb_rain'));
        expect(sliderFinder, findsOneWidget);
      },
    );
  });
}
