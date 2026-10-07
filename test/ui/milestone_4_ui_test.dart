import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_en.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
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
          locale: settings.currentLocale ?? const Locale('en'),
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
  final l10n = AppLocalizationsEn();

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
    testWidgets('should render 3-column GM dashboard layout on desktop screens (>= 1000px)', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Act
      await tester.pumpWidget(
        createTestApp(
          child: const ResponsiveGmDashboard(),
          screenSize: const Size(1280, 900),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining(l10n.scenes), findsWidgets);
      expect(find.text(l10n.musicTrack), findsOneWidget);
      expect(find.textContaining(l10n.ambient), findsWidgets);
      expect(find.textContaining(l10n.soundboardTitle), findsWidgets);
    });

    testWidgets('should display tabs and StickyMiniPlayer on compact and mobile screens (< 1000px)', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Act
      await tester.pumpWidget(
        createTestApp(
          child: const ResponsiveGmDashboard(),
          screenSize: const Size(800, 900),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(StickyMiniPlayer), findsOneWidget);
      expect(find.text(l10n.scenes), findsWidgets);
      expect(find.text(l10n.music), findsWidgets);
      expect(find.text(l10n.ambient), findsWidgets);
      expect(find.text(l10n.sfx), findsWidgets);
    });
  });

  group('SceneCard Widget Tests', () {
    testWidgets('should display active badge and trigger activation callback when clicked', (tester) async {
      // Arrange
      final scene = SceneModel(
        id: 'sc_card_1',
        name: 'Ancient Tavern',
        description: 'Cozy hearth and clinking mugs',
        musicIntensity: MusicIntensity.calm,
      );

      bool activated = false;

      // Act
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

      // Assert
      expect(find.text('Ancient Tavern'), findsOneWidget);
      expect(find.text('Cozy hearth and clinking mugs'), findsOneWidget);
      expect(find.text(l10n.activeBadge), findsWidgets);

      await tester.tap(find.byType(ElevatedButton));
      expect(activated, isTrue);
    });
  });

  group('SceneBackdropHeader Widget Tests', () {
    testWidgets('should render active scene header title and intensity chips', (tester) async {
      // Arrange
      final sceneService = SceneService(autoLoad: false);
      final scene = SceneModel(
        id: 'sc_dragon_cave',
        name: 'Dragon Cave',
        description: 'Heat of lava and heavy breathing',
      );
      await tester.runAsync(() async {
        await sceneService.createScene(scene);
        await sceneService.activateScene(scene);
      });

      // Act
      await tester.pumpWidget(
        createTestApp(
          sceneService: sceneService,
          child: const SceneBackdropHeader(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Dragon Cave'), findsOneWidget);
      expect(find.text(l10n.currentSceneBadge), findsNothing);
      expect(find.text(l10n.intensityCalm), findsOneWidget);
      expect(find.text(l10n.intensityBattle), findsOneWidget);
    });
  });

  group('CustomThemeEditorDialog Widget Tests', () {
    testWidgets('should render theme editor dialog controls and color customization sections', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestApp(
          child: const CustomThemeEditorDialog(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.createCustomThemeTitle), findsOneWidget);
      expect(find.text(l10n.themePreviewTitle), findsOneWidget);
      expect(find.text(l10n.colorPaletteConfig), findsOneWidget);
      expect(find.text(l10n.saveThemeBtn), findsOneWidget);
    });
  });

  group('SettingsScreen Milestone 4 Widget Tests', () {
    testWidgets('should render theme presets section and shortcut key bindings table', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestApp(
          child: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.themesTitle), findsOneWidget);
      expect(find.text(AppThemes.deepDark.name), findsOneWidget);
      expect(find.text(AppThemes.cleanLight.name), findsOneWidget);
      expect(find.text(l10n.createThemeBtn), findsOneWidget);
      expect(find.text(l10n.hotkeysTitle), findsOneWidget);
      expect(find.text('Space'), findsWidgets);
    });
  });

  group('SoundboardGrid and AmbientMixerPanel Widget Tests', () {
    testWidgets('should render SFX soundboard triggers and display hotkey badges', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      engine.sfxBus.addTrigger(
        const SfxTrigger(
          id: 'sfx_sword',
          title: 'Sword Strike',
          filePath: '/dummy/sword.wav',
          hotkey: '1',
        ),
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          audioEngine: engine,
          child: const SingleChildScrollView(
            child: SoundboardGrid(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sword Strike'), findsOneWidget);
      expect(find.text('[1]'), findsOneWidget);
      expect(find.text(l10n.panicStopBtn), findsOneWidget);
    });

    testWidgets('should allow volume slider interaction on inactive ambient layer', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      engine.ambientBus.addLayer(
        const AmbientLayer(
          id: 'amb_rain',
          title: 'Storm Rain',
          filePath: '/dummy/rain.mp3',
          isActive: false,
          volume: 0.5,
        ),
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          audioEngine: engine,
          child: const SingleChildScrollView(
            child: AmbientMixerPanel(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Storm Rain'), findsOneWidget);
      expect(find.text('${l10n.volume}: 50%'), findsOneWidget);

      final sliderFinder = find.byKey(const ValueKey('ambient_slider_amb_rain'));
      expect(sliderFinder, findsOneWidget);
    });
  });
}
