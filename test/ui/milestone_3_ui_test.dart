import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/data/services/settings_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
import 'package:ttrpg_audio_player/data/services/theme_service.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';

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
  ThemeService? themeService,
}) {
  final eng = engine ?? AudioEngineService();
  final log = logger ?? LoggerService();
  final set = settings ?? SettingsService();
  final scn = sceneService ?? SceneService(autoLoad: false);
  final lib = library ?? MediaLibraryService(autoLoad: false);
  final thm = themeService ?? ThemeService(autoLoad: false);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LoggerService>.value(value: log),
      ChangeNotifierProvider<SettingsService>.value(value: set),
      ChangeNotifierProvider<AudioEngineService>.value(value: eng),
      ChangeNotifierProvider<MusicBusController>.value(value: eng.musicBus),
      ChangeNotifierProvider<AmbientBusController>.value(value: eng.ambientBus),
      ChangeNotifierProvider<SfxBusController>.value(value: eng.sfxBus),
      ChangeNotifierProvider<SceneService>.value(value: scn),
      ChangeNotifierProvider<SceneViewModel>(create: (_) => SceneViewModel(service: scn)),
      ChangeNotifierProvider<MediaLibraryService>.value(value: lib),
      ChangeNotifierProvider<MediaLibraryViewModel>(create: (_) => MediaLibraryViewModel(service: lib)),
      ChangeNotifierProvider<ThemeService>.value(value: thm),
      ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel(service: thm)),
    ],
    child: Consumer<SettingsService>(
      builder: (context, set, _) {
        return MaterialApp(
          locale: set.currentLocale ?? const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
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
    tempDir = await Directory.systemTemp.createTemp('ttrpg_m3_ui_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('SceneSelectorPanel Widget Tests', () {
    testWidgets('should render empty state placeholder and create button when no scenes exist', (WidgetTester tester) async {
      // Arrange
      final sceneService = SceneService(autoLoad: false);
      await tester.runAsync(() async => await sceneService.loadScenes());

      // Act
      await tester.pumpWidget(createM3TestableWidget(
        const SceneSelectorPanel(),
        sceneService: sceneService,
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();

      // Assert
      expect(find.text(l10n.scenesTitle), findsOneWidget);
      expect(find.text(l10n.createSceneBtn), findsOneWidget);
      expect(find.textContaining(l10n.noScenesHint), findsOneWidget);

      sceneService.dispose();
    });

    testWidgets('should activate scene and update active scene card badge on card click', (WidgetTester tester) async {
      // Arrange
      final sceneService = SceneService(autoLoad: false);
      final library = MediaLibraryService(autoLoad: false);
      final engine = AudioEngineService();
      final l10n = AppLocalizationsEn();

      final scene = SceneModel(
        id: 'sc-dragon',
        name: 'Dragon Cave',
        description: 'Lava heat and heavy breathing',
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

      expect(find.text('Dragon Cave'), findsOneWidget);
      expect(find.text(l10n.enableSceneBtn), findsOneWidget);

      // Act
      await tester.runAsync(() async {
        await tester.tap(find.text('Dragon Cave'));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(sceneService.activeSceneId, equals('sc-dragon'));
      expect(find.text(l10n.activeBadge), findsWidgets);

      sceneService.dispose();
      library.dispose();
      engine.dispose();
    });
  });

  group('CreateEditSceneDialog Widget Tests', () {
    testWidgets('should create and return SceneModel when form fields are filled and submitted', (WidgetTester tester) async {
      // Arrange
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

      final l10n = AppLocalizationsEn();

      expect(find.text(l10n.createSceneTitle), findsOneWidget);

      // Act
      await tester.enterText(
        find.widgetWithText(TextField, l10n.sceneNameLabel),
        'Throne Room',
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, l10n.searchMusicHint), findsOneWidget);
      expect(find.widgetWithText(TextField, l10n.searchAmbientHint), findsOneWidget);
      expect(find.widgetWithText(TextField, l10n.searchSfxHint), findsOneWidget);

      await tester.tap(find.text(l10n.create));
      await tester.pumpAndSettle();

      // Assert
      expect(returnedScene, isNotNull);
      expect(returnedScene!.name, equals('Throne Room'));

      library.dispose();
    });

    testWidgets('should apply active palette surface and card colors to scene dialog when clean light theme is active', (WidgetTester tester) async {
      // Arrange
      final library = MediaLibraryService(autoLoad: false);
      final themeService = ThemeService(autoLoad: false, initialThemeId: AppThemes.cleanLightId);
      themeService.selectTheme(AppThemes.cleanLightId);

      await tester.pumpWidget(
        createM3TestableWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<SceneModel>(
                  context: ctx,
                  builder: (_) => const CreateEditSceneDialog(),
                ),
                child: const Text('Open Scene Dialog'),
              ),
            ),
          ),
          library: library,
          themeService: themeService,
        ),
      );

      // Act
      await tester.tap(find.text('Open Scene Dialog'));
      await tester.pumpAndSettle();

      // Assert
      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);
      final dialogWidget = tester.widget<Dialog>(dialogFinder);
      expect(dialogWidget.backgroundColor, equals(AppThemes.cleanLight.surface));

      final l10n = AppLocalizationsEn();
      final nameFieldFinder = find.widgetWithText(TextField, l10n.sceneNameLabel);
      expect(nameFieldFinder, findsOneWidget);
      final nameFieldWidget = tester.widget<TextField>(nameFieldFinder);
      expect(nameFieldWidget.decoration?.fillColor, equals(AppThemes.cleanLight.surfaceRaised));

      library.dispose();
      themeService.dispose();
    });

    testWidgets('should apply active palette surface and card colors to scene dialog when deep dark theme is active', (WidgetTester tester) async {
      // Arrange
      final library = MediaLibraryService(autoLoad: false);
      final themeService = ThemeService(autoLoad: false, initialThemeId: AppThemes.deepDarkId);
      themeService.selectTheme(AppThemes.deepDarkId);

      await tester.pumpWidget(
        createM3TestableWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<SceneModel>(
                  context: ctx,
                  builder: (_) => const CreateEditSceneDialog(),
                ),
                child: const Text('Open Scene Dialog'),
              ),
            ),
          ),
          library: library,
          themeService: themeService,
        ),
      );

      // Act
      await tester.tap(find.text('Open Scene Dialog'));
      await tester.pumpAndSettle();

      // Assert
      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);
      final dialogWidget = tester.widget<Dialog>(dialogFinder);
      expect(dialogWidget.backgroundColor, equals(AppThemes.deepDark.surface));

      final l10n = AppLocalizationsEn();
      final nameFieldFinder = find.widgetWithText(TextField, l10n.sceneNameLabel);
      expect(nameFieldFinder, findsOneWidget);
      final nameFieldWidget = tester.widget<TextField>(nameFieldFinder);
      expect(nameFieldWidget.decoration?.fillColor, equals(AppThemes.deepDark.surfaceRaised));

      library.dispose();
      themeService.dispose();
    });

    testWidgets('should adapt scene dialog colors and swatches when theme palette is custom preset like ancient parchment', (WidgetTester tester) async {
      // Arrange
      final library = MediaLibraryService(autoLoad: false);
      final themeService = ThemeService(autoLoad: false, initialThemeId: AppThemes.ancientParchmentId);
      themeService.selectTheme(AppThemes.ancientParchmentId);

      await tester.pumpWidget(
        createM3TestableWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<SceneModel>(
                  context: ctx,
                  builder: (_) => const CreateEditSceneDialog(),
                ),
                child: const Text('Open Scene Dialog'),
              ),
            ),
          ),
          library: library,
          themeService: themeService,
        ),
      );

      // Act
      await tester.tap(find.text('Open Scene Dialog'));
      await tester.pumpAndSettle();

      // Assert
      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);
      final dialogWidget = tester.widget<Dialog>(dialogFinder);
      expect(dialogWidget.backgroundColor, equals(AppThemes.ancientParchment.surface));

      final l10n = AppLocalizationsEn();
      final nameFieldFinder = find.widgetWithText(TextField, l10n.sceneNameLabel);
      expect(nameFieldFinder, findsOneWidget);
      final nameFieldWidget = tester.widget<TextField>(nameFieldFinder);
      expect(nameFieldWidget.decoration?.fillColor, equals(AppThemes.ancientParchment.surfaceRaised));

      library.dispose();
      themeService.dispose();
    });

    testWidgets('should resolve active palette when only ThemeService is provided without ThemeViewModel', (WidgetTester tester) async {
      // Arrange
      final library = MediaLibraryService(autoLoad: false);
      final themeService = ThemeService(autoLoad: false, initialThemeId: AppThemes.cleanLightId);
      themeService.selectTheme(AppThemes.cleanLightId);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MediaLibraryService>.value(value: library),
            ChangeNotifierProvider<MediaLibraryViewModel>(create: (_) => MediaLibraryViewModel(service: library)),
            ChangeNotifierProvider<ThemeService>.value(value: themeService),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showDialog<SceneModel>(
                    context: ctx,
                    builder: (_) => const CreateEditSceneDialog(),
                  ),
                  child: const Text('Open Scene Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Open Scene Dialog'));
      await tester.pumpAndSettle();

      // Assert
      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);
      final dialogWidget = tester.widget<Dialog>(dialogFinder);
      expect(dialogWidget.backgroundColor, equals(AppThemes.cleanLight.surface));

      library.dispose();
      themeService.dispose();
    });

    testWidgets('should derive palette from Theme.of(context) ThemeData when no theme providers exist in tree', (WidgetTester tester) async {
      // Arrange
      final library = MediaLibraryService(autoLoad: false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MediaLibraryService>.value(value: library),
            ChangeNotifierProvider<MediaLibraryViewModel>(create: (_) => MediaLibraryViewModel(service: library)),
          ],
          child: MaterialApp(
            theme: AppThemes.cleanLight.toThemeData(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showDialog<SceneModel>(
                    context: ctx,
                    builder: (_) => const CreateEditSceneDialog(),
                  ),
                  child: const Text('Open Scene Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Open Scene Dialog'));
      await tester.pumpAndSettle();

      // Assert
      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);
      final dialogWidget = tester.widget<Dialog>(dialogFinder);
      expect(dialogWidget.backgroundColor, equals(AppThemes.cleanLight.surface));

      library.dispose();
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('should render audio engine and UI settings controls in SettingsScreen', (WidgetTester tester) async {
      // Arrange
      final settings = SettingsService();
      final library = MediaLibraryService(autoLoad: false);
      final sceneService = SceneService(autoLoad: false);
      final l10n = AppLocalizationsEn();
      await tester.runAsync(() async {
        await library.loadTracks();
        await sceneService.loadScenes();
      });

      // Act
      await tester.pumpWidget(createM3TestableWidget(
        const SettingsScreen(),
        settings: settings,
        library: library,
        sceneService: sceneService,
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.settingsTitle), findsOneWidget);
      expect(find.text(l10n.interfaceTitle), findsOneWidget);
      expect(find.text(l10n.showLogConsoleTitle), findsOneWidget);
      expect(find.text(l10n.fadeEngineTitle), findsOneWidget);
      expect(find.text(l10n.duckingTitle), findsOneWidget);

      // Act & Assert - Toggle log switch
      final logSwitch = find.widgetWithText(SwitchListTile, l10n.showLogConsoleTitle);
      await tester.scrollUntilVisible(logSwitch, 200);
      expect(logSwitch, findsOneWidget);
      await tester.tap(logSwitch);
      await tester.pumpAndSettle();
      expect(settings.showLogConsoleIcon, isFalse);

      // Act & Assert - Music fade update
      settings.setMusicFadeMs(2500);
      await tester.pumpAndSettle();
      expect(find.textContaining('2500 ms'), findsOneWidget);

      settings.dispose();
      library.dispose();
      sceneService.dispose();
    });

    testWidgets('should display custom audio storage path and reset to default on button tap', (WidgetTester tester) async {
      // Arrange
      final settings = SettingsService(customDownloadDirectory: 'C:/AudioVault');
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

      final l10n = AppLocalizationsEn();

      final cardFinder = find.byKey(const ValueKey('catalog_storage_settings_card'));
      await tester.scrollUntilVisible(cardFinder, 200);
      expect(cardFinder, findsOneWidget);
      expect(find.text(l10n.catalogStorageTitle), findsOneWidget);
      expect(find.text('C:/AudioVault'), findsOneWidget);

      // Act
      final resetBtn = find.byKey(const ValueKey('reset_download_dir_button'));
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Assert
      expect(settings.customDownloadDirectory, isNull);
      expect(find.textContaining(l10n.defaultStoragePath), findsOneWidget);

      settings.dispose();
      library.dispose();
      sceneService.dispose();
    });
  });

  group('MainDashboardScreen 3-Tab Integration Tests', () {
    testWidgets('should switch between all 3 main dashboard tabs correctly', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      final library = MediaLibraryService(autoLoad: false);
      final sceneService = SceneService(autoLoad: false);
      final settings = SettingsService();
      final l10n = AppLocalizationsEn();
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

      expect(find.text(l10n.tabGmDashboard), findsOneWidget);
      expect(find.text(l10n.tabLibrary), findsOneWidget);
      expect(find.text(l10n.tabSettings), findsOneWidget);

      // Act & Assert - 1. Settings tab
      await tester.tap(find.text(l10n.tabSettings));
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsTitle), findsOneWidget);

      // Act & Assert - 2. Library tab
      await tester.tap(find.text(l10n.tabLibrary));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library_search_input')), findsOneWidget);

      // Act & Assert - 3. Dashboard tab
      await tester.tap(find.text(l10n.tabGmDashboard));
      await tester.pumpAndSettle();
      expect(find.byType(SceneSelectorPanel), findsOneWidget);
      expect(find.text(l10n.createSceneBtn), findsOneWidget);

      engine.dispose();
      library.dispose();
      sceneService.dispose();
      settings.dispose();
    });
  });

  group('Language Selection UI Tests', () {
    testWidgets('should re-render localized section titles when interface language is toggled in SettingsService', (WidgetTester tester) async {
      // Arrange
      final settings = SettingsService();
      final library = MediaLibraryService(autoLoad: false);
      final sceneService = SceneService(autoLoad: false);
      final l10n = AppLocalizationsEn();

      await tester.pumpWidget(createM3TestableWidget(
        const SettingsScreen(),
        settings: settings,
        library: library,
        sceneService: sceneService,
      ));
      await tester.pumpAndSettle();

      final dropdownFinder = find.byKey(const ValueKey('language_selector_dropdown'));
      await tester.scrollUntilVisible(dropdownFinder, 200);
      await tester.pumpAndSettle();

      expect(dropdownFinder, findsOneWidget);
      expect(find.text(l10n.language), findsOneWidget);

      // Act - English
      settings.setAppLanguage('en');
      await tester.pumpAndSettle();

      // Assert - English titles
      expect(find.text(l10n.language), findsOneWidget);
      expect(find.text(l10n.settingsTitle), findsOneWidget);
      expect(find.text(l10n.fadeEngineTitle), findsOneWidget);
      expect(find.text(l10n.duckingTitle), findsOneWidget);
      expect(find.text(l10n.themesTitle), findsOneWidget);
      expect(find.text(l10n.hotkeysTitle), findsOneWidget);

      // Act - Russian
      settings.setAppLanguage('ru');
      await tester.pumpAndSettle();

      // Assert - Russian locale updated
      expect(settings.currentLocale?.languageCode, equals('ru'));
      expect(Localizations.localeOf(tester.element(find.byType(SettingsScreen))).languageCode, equals('ru'));

      settings.dispose();
      library.dispose();
      sceneService.dispose();
    });
  });
}
