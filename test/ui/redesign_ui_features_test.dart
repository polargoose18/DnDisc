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
    test('should provide the design-system tokens in the deepDark preset', () {
      // Arrange & Act
      const theme = AppThemes.deepDark;

      // Assert
      expect(theme.backgroundColor, equals(0xFF14110F));
      expect(theme.surfaceColor, equals(0xFF1C1815));
      expect(theme.surfaceRaisedColor, equals(0xFF261F1B));
      expect(theme.primaryColor, equals(0xFFD4A373));
      expect(theme.textPrimaryColor, equals(0xFFF3ECE2));
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
      expect(find.text(l10n.musicModeOff), findsNothing);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Suspense'), findsOneWidget);
      expect(find.text('Battle'), findsOneWidget);
      expect(find.text('Boss'), findsOneWidget);

      // Act - Tap Calm mode
      await tester.tap(find.text('Calm'));
      await tester.pumpAndSettle();

      // Assert - intensity switched but playback did NOT start
      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.calm));
      expect(engine.musicBus.isPlaying, isFalse);

      // Act - Tap Suspense mode
      await tester.tap(find.text('Suspense'));
      await tester.pumpAndSettle();

      // Assert - intensity switched but playback did NOT start
      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.suspense));
      expect(engine.musicBus.isPlaying, isFalse);

      // Act - Tap Battle mode
      await tester.tap(find.text('Battle'));
      await tester.pumpAndSettle();

      // Assert - intensity switched but playback did NOT start
      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.battle));
      expect(engine.musicBus.isPlaying, isFalse);

      // Act - Tap Boss mode
      await tester.tap(find.text('Boss'));
      await tester.pumpAndSettle();

      // Assert - intensity switched but playback did NOT start
      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.boss));
      expect(engine.musicBus.isPlaying, isFalse);

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

  group('Ambient Mixer Controls Tests', () {
    testWidgets('should not display stepped intensity pills (I, II, III) and adjust volume via slider when layer is rendered', (tester) async {
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

      // Act
      await tester.pumpWidget(
        _createTestApp(
          audioEngine: engine,
          child: const SingleChildScrollView(
            child: AmbientMixerPanel(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - layer rendered and stepped intensity pills are removed
      expect(find.text('Forest Brook'), findsOneWidget);
      expect(find.text('I'), findsNothing);
      expect(find.text('II'), findsNothing);
      expect(find.text('III'), findsNothing);

      // Act - Adjust volume via slider
      final sliderFinder = find.byKey(const ValueKey('ambient_slider_amb_forest_brook'));
      expect(sliderFinder, findsOneWidget);
      await tester.drag(sliderFinder, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Assert - volume updated
      expect(engine.ambientBus.layers.first.volume, isNot(closeTo(0.2, 0.01)));

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
      expect(find.byType(StickyMiniPlayer), findsNothing);

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
      expect(find.byIcon(Icons.dangerous_rounded), findsNothing);

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

    testWidgets('should keep sidebar toggle button at exact same vertical Y position when toggling collapsed state', (tester) async {
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

      // Assert expanded toggle button position
      final collapseBtnFinder = find.byKey(const ValueKey('sidebar_collapse_toggle_btn'));
      expect(collapseBtnFinder, findsOneWidget);
      final expandedTopY = tester.getTopLeft(collapseBtnFinder).dy;

      // Act - Collapse
      await tester.tap(collapseBtnFinder);
      await tester.pumpAndSettle();

      // Assert collapsed toggle button position
      final expandBtnFinder = find.byKey(const ValueKey('sidebar_expand_toggle_btn'));
      expect(expandBtnFinder, findsOneWidget);
      final collapsedTopY = tester.getTopLeft(expandBtnFinder).dy;

      // Verify vertical Y position is unchanged (does NOT jump down)
      expect(collapsedTopY, equals(expandedTopY));

      engine.dispose();
    });

    testWidgets('should smoothly animate sidebar width without layout overflow during mid-animation frames', (tester) async {
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

      final collapseBtnFinder = find.byKey(const ValueKey('sidebar_collapse_toggle_btn'));
      expect(collapseBtnFinder, findsOneWidget);

      // Act & Assert mid-frame pumps during collapse
      await tester.tap(collapseBtnFinder);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final expandBtnFinder = find.byKey(const ValueKey('sidebar_expand_toggle_btn'));
      expect(expandBtnFinder, findsOneWidget);

      // Act & Assert mid-frame pumps during expand
      await tester.tap(expandBtnFinder);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Rapid toggle stress test
      await tester.tap(find.byKey(const ValueKey('sidebar_collapse_toggle_btn')));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.byKey(const ValueKey('sidebar_expand_toggle_btn')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

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

    testWidgets('should toggle persistent state when SFX button is long-pressed and omit loop/hotkey controls', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      engine.sfxBus.addTrigger(
        const SfxTrigger(
          id: 'sfx_test_clash',
          title: 'Sword Clash',
          filePath: '/test/clash.mp3',
          hotkey: '2',
          isPersistent: false,
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

      // Assert - initial state and absence of hotkey badge / loop icon
      expect(find.text('Sword Clash'), findsOneWidget);
      expect(find.text('[2]'), findsNothing);
      expect(find.byIcon(Icons.repeat_rounded), findsNothing);
      expect(engine.sfxBus.triggers.first.isPersistent, isFalse);

      // Act - long press on the SFX button
      await tester.longPress(find.byKey(const ValueKey('sfx_btn_sfx_test_clash')));
      await tester.pumpAndSettle();

      // Assert - persistence is now toggled to true
      expect(engine.sfxBus.triggers.first.isPersistent, isTrue);

      engine.dispose();
    });
  });
}
