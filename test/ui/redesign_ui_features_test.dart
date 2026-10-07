import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_en.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/data/services/settings_service.dart';
import 'package:ttrpg_audio_player/data/services/theme_service.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/services/shortcut_service.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';
import 'package:ttrpg_audio_player/ui/screens/main_dashboard_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/settings_screen.dart';
import 'package:ttrpg_audio_player/ui/widgets/scene_backdrop_header.dart';
import 'package:ttrpg_audio_player/ui/widgets/ambient_mixer_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/soundboard_grid.dart';
import 'package:ttrpg_audio_player/ui/widgets/sticky_mini_player.dart';
import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';

class _FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  _FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempPath;
  }
}

Widget _createTestApp({
  required Widget child,
  AudioEngineService? audioEngine,
  SceneService? sceneService,
  ThemeService? themeService,
  SettingsService? settingsService,
  Size screenSize = const Size(1280, 900),
}) {
  final settings = settingsService ?? SettingsService();
  final engine = audioEngine ?? AudioEngineService(settings: settings);
  final themes = themeService ?? ThemeService();
  final scenes = sceneService ?? SceneService(autoLoad: false);
  final shortcuts = ShortcutService(audioEngine: engine);
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
    child: MaterialApp(
      theme: themes.currentThemeData,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(
        child: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatabaseService dbService;
  final l10n = AppLocalizationsEn();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('redesign_ui_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
    await dbService.database;
  });

  tearDown(() async {
    try {
      await dbService.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Theme Palette Specification Tests', () {
    test('should provide warm espresso background and antique gold primary in deepDark preset', () {
      // Arrange & Act
      const theme = AppThemes.deepDark;

      // Assert
      expect(theme.backgroundColor, equals(0xFF151210));
      expect(theme.surfaceColor, equals(0xFF1E1916));
      expect(theme.cardColor, equals(0xFF29221D));
      expect(theme.primaryColor, equals(0xFFD4A373));
      expect(theme.textPrimaryColor, equals(0xFFF5EFE6));
      expect(theme.isDark, isTrue);
    });
  });

  group('Active Music Intensity Level Pills Tests', () {
    testWidgets('should switch music mode intensity when intensity level pills are tapped in SceneBackdropHeader', (tester) async {
      // Arrange
      final sceneService = SceneService(autoLoad: false);
      final engine = AudioEngineService();
      final scene = SceneModel(
        id: 'sc_enchanted_grove',
        name: 'Enchanted Grove',
        description: 'Misty trees and ancient whispers',
      );
      await tester.runAsync(() async {
        await sceneService.createScene(scene);
        await sceneService.activateScene(scene);
      });

      await tester.pumpWidget(
        _createTestApp(
          sceneService: sceneService,
          audioEngine: engine,
          child: const SceneBackdropHeader(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - initial state
      expect(find.text('Enchanted Grove'), findsOneWidget);
      expect(find.text('${l10n.intensityLevel}:'), findsOneWidget);
      expect(find.text(l10n.musicModeOff), findsOneWidget);
      expect(find.text(l10n.intensityCalm), findsOneWidget);
      expect(find.text(l10n.intensitySuspense), findsOneWidget);
      expect(find.text(l10n.intensityBattle), findsOneWidget);
      expect(find.text(l10n.intensityBoss), findsOneWidget);

      // Act - Tap Calm mode
      await tester.tap(find.text(l10n.intensityCalm));
      await tester.pumpAndSettle();

      // Assert
      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.calm));

      // Act - Tap Suspense mode
      await tester.tap(find.text(l10n.intensitySuspense));
      await tester.pumpAndSettle();

      // Assert
      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.suspense));

      // Act - Tap Battle mode
      await tester.tap(find.text(l10n.intensityBattle));
      await tester.pumpAndSettle();

      // Assert
      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.battle));

      // Act - Tap Boss mode
      await tester.tap(find.text(l10n.intensityBoss));
      await tester.pumpAndSettle();

      // Assert
      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.boss));

      engine.dispose();
    });

    testWidgets('should render borderless SceneBackdropHeader with transparent background and centered title when scene is active', (tester) async {
      // Arrange
      final sceneService = SceneService(autoLoad: false);
      final engine = AudioEngineService();
      final scene = SceneModel(
        id: 'sc_borderless_test',
        name: 'Dragon Mountain',
        description: 'Smoking craters and obsidian stones',
      );
      await tester.runAsync(() async {
        await sceneService.createScene(scene);
        await sceneService.activateScene(scene);
      });

      // Act
      await tester.pumpWidget(
        _createTestApp(
          sceneService: sceneService,
          audioEngine: engine,
          child: const SceneBackdropHeader(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Dragon Mountain'), findsOneWidget);
      expect(find.text(l10n.currentSceneBadge), findsNothing);
      expect(find.byIcon(Icons.theater_comedy_rounded), findsNothing);

      // Verify borderless & transparent container decoration
      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.transparent,
      );
      expect(containerFinder, findsOneWidget);
      final container = tester.widget<Container>(containerFinder);
      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.border, isNull);

      engine.dispose();
    });
  });

  group('Stepped Ambient Intensity Controls Tests', () {
    testWidgets('should adjust layer volume using stepped intensity pills [ I | II | III ]', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      engine.ambientBus.addLayer(
        const AmbientLayer(
          id: 'amb_forest_brook',
          title: 'Forest Brook',
          filePath: '/dummy/brook.mp3',
          isActive: true,
          volume: 0.2,
        ),
      );

      await tester.pumpWidget(
        _createTestApp(
          audioEngine: engine,
          child: const SingleChildScrollView(
            child: AmbientMixerPanel(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - layer rendered
      expect(find.text('Forest Brook'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);
      expect(find.text('II'), findsOneWidget);
      expect(find.text('III'), findsOneWidget);

      // Act - Tap Step II (0.66)
      await tester.tap(find.text('II'));
      await tester.pumpAndSettle();

      // Assert
      expect(engine.ambientBus.layers.first.volume, closeTo(0.66, 0.05));

      // Act - Tap Step III (1.0)
      await tester.tap(find.text('III'));
      await tester.pumpAndSettle();

      // Assert
      expect(engine.ambientBus.layers.first.volume, closeTo(1.0, 0.05));

      engine.dispose();
    });
  });

  group('Desktop Shell & Persistent Dock Tests', () {
    testWidgets('should render DnDisc brand title and docked bottom player on desktop screen', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final engine = AudioEngineService();

      // Act
      await tester.pumpWidget(
        _createTestApp(
          audioEngine: engine,
          screenSize: const Size(1280, 900),
          child: const MainDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.appTitle), findsOneWidget);
      expect(find.text(l10n.tabGmDashboard), findsOneWidget);
      expect(find.text(l10n.tabLibrary), findsOneWidget);
      expect(find.text(l10n.tabSettings), findsOneWidget);
      expect(find.text(l10n.tabCatalog), findsOneWidget);
      expect(find.byType(StickyMiniPlayer), findsOneWidget);

      engine.dispose();
    });

    testWidgets('should switch to media library tab when desktop sidebar navigation item is clicked', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final engine = AudioEngineService();

      await tester.pumpWidget(
        _createTestApp(
          audioEngine: engine,
          screenSize: const Size(1280, 900),
          child: const MainDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text(l10n.tabLibrary));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const ValueKey('library_search_input')), findsOneWidget);

      engine.dispose();
    });

    testWidgets('should render compact StickyMiniPlayer without overflow on narrow mobile screens (< 400px)', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final engine = AudioEngineService();

      // Act
      await tester.pumpWidget(
        _createTestApp(
          audioEngine: engine,
          screenSize: const Size(360, 640),
          child: const StickyMiniPlayer(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(StickyMiniPlayer), findsOneWidget);
      expect(find.text(l10n.noMusic), findsOneWidget);
      expect(find.byIcon(Icons.dangerous_rounded), findsOneWidget);

      engine.dispose();
    });

    testWidgets('should collapse and expand desktop sidebar when sidebar toggle button is clicked', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final engine = AudioEngineService();

      await tester.pumpWidget(
        _createTestApp(
          audioEngine: engine,
          screenSize: const Size(1280, 900),
          child: const MainDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - initially expanded with title and collapse button
      expect(find.byKey(const ValueKey('sidebar_collapse_toggle_btn')), findsOneWidget);
      expect(find.text(l10n.tabGmDashboard), findsOneWidget);

      // Act - Collapse
      await tester.tap(find.byKey(const ValueKey('sidebar_collapse_toggle_btn')));
      await tester.pumpAndSettle();

      // Assert - collapsed state: expand button present, labels hidden
      expect(find.byKey(const ValueKey('sidebar_expand_toggle_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('sidebar_collapse_toggle_btn')), findsNothing);

      // Act - Expand again
      await tester.tap(find.byKey(const ValueKey('sidebar_expand_toggle_btn')));
      await tester.pumpAndSettle();

      // Assert - back to expanded
      expect(find.byKey(const ValueKey('sidebar_collapse_toggle_btn')), findsOneWidget);
      expect(find.text(l10n.tabGmDashboard), findsOneWidget);

      engine.dispose();
    });

    testWidgets('should navigate to settings when clicking the last navigation item', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final engine = AudioEngineService();

      await tester.pumpWidget(
        _createTestApp(
          audioEngine: engine,
          screenSize: const Size(1280, 900),
          child: const MainDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tap Settings (the 4th item)
      await tester.tap(find.text(l10n.tabSettings));
      await tester.pumpAndSettle();

      // Assert - Settings screen is shown
      expect(find.byType(SettingsScreen), findsOneWidget);

      engine.dispose();
    });
  });

  group('Square SFX Buttons Tests', () {
    testWidgets('should render square aspect ratio grid cells for soundboard triggers', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      engine.sfxBus.addTrigger(
        const SfxTrigger(
          id: 'sfx_test_horn',
          title: 'Battle Horn',
          filePath: '/test/horn.mp3',
        ),
      );

      await tester.pumpWidget(
        _createTestApp(
          audioEngine: engine,
          child: const SingleChildScrollView(
            child: SoundboardGrid(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - SFX button has 1.0 aspect ratio
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
      final grid = tester.widget<GridView>(gridFinder);
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.childAspectRatio, equals(1.0));

      engine.dispose();
    });
  });
}
