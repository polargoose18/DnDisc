import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/data/services/settings_service.dart';
import 'package:ttrpg_audio_player/data/services/theme_service.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
import 'package:ttrpg_audio_player/services/shortcut_service.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/theme/ds_theme.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/repository_view_model.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/ui/screens/library_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/main_dashboard_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/responsive_gm_dashboard.dart';
import 'package:ttrpg_audio_player/ui/widgets/sticky_mini_player.dart';
import 'package:ttrpg_audio_player/ui/widgets/music_player_panel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  _FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}

Widget _buildMinimalistTestApp({
  required AudioEngineService audioEngine,
  required Widget child,
  Size screenSize = const Size(1280, 900),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LoggerService>(create: (_) => LoggerService()),
      ChangeNotifierProvider<SettingsService>(
        create: (_) => SettingsService(dbService: DatabaseService(), autoLoad: false),
      ),
      ChangeNotifierProvider<ThemeService>(
        create: (_) => ThemeService(dbService: DatabaseService()),
      ),
      ChangeNotifierProxyProvider<ThemeService, ThemeViewModel>(
        create: (context) => ThemeViewModel(service: context.read<ThemeService>()),
        update: (context, service, viewModel) => viewModel ?? ThemeViewModel(service: service),
      ),
      ChangeNotifierProvider<AudioEngineService>.value(value: audioEngine),
      ChangeNotifierProvider<MusicBusController>.value(value: audioEngine.musicBus),
      ChangeNotifierProvider<AmbientBusController>.value(value: audioEngine.ambientBus),
      ChangeNotifierProvider<SfxBusController>.value(value: audioEngine.sfxBus),
      ChangeNotifierProvider<ShortcutService>(
        create: (_) => ShortcutService(audioEngine: audioEngine),
      ),
      ChangeNotifierProvider<MediaLibraryService>(
        create: (_) => MediaLibraryService(autoLoad: false),
      ),
      ChangeNotifierProxyProvider<MediaLibraryService, MediaLibraryViewModel>(
        create: (context) => MediaLibraryViewModel(service: context.read<MediaLibraryService>()),
        update: (context, service, viewModel) => viewModel ?? MediaLibraryViewModel(service: service),
      ),
      ChangeNotifierProvider<SceneService>(
        create: (_) => SceneService(autoLoad: false),
      ),
      ChangeNotifierProxyProvider<SceneService, SceneViewModel>(
        create: (context) => SceneViewModel(service: context.read<SceneService>()),
        update: (context, service, viewModel) => viewModel ?? SceneViewModel(service: service),
      ),
      ChangeNotifierProxyProvider<SettingsService, RepositoryViewModel>(
        create: (context) => RepositoryViewModel(settingsService: context.read<SettingsService>()),
        update: (context, settings, viewModel) =>
            viewModel ?? RepositoryViewModel(settingsService: settings),
      ),
    ],
    child: Consumer<ThemeViewModel>(
      builder: (context, themeViewModel, _) {
        return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: themeViewModel.currentThemeData,
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: Scaffold(body: child),
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
    tempDir = await Directory.systemTemp.createTemp('minimalism_test_');
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

  group('Minimalism UI Redesign Tests', () {
    testWidgets('should omit bottom music player bar when rendering MainDashboardScreen on desktop', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final engine = AudioEngineService();

      // Act
      await tester.pumpWidget(
        _buildMinimalistTestApp(
          audioEngine: engine,
          screenSize: const Size(1280, 900),
          child: const MainDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(StickyMiniPlayer), findsNothing);
      expect(find.byType(MainDashboardScreen), findsOneWidget);

      engine.dispose();
    });

    testWidgets('should omit bottom music player bar when rendering ResponsiveGmDashboard on compact screens', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final engine = AudioEngineService();

      // Act
      await tester.pumpWidget(
        _buildMinimalistTestApp(
          audioEngine: engine,
          screenSize: const Size(600, 800),
          child: const ResponsiveGmDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(StickyMiniPlayer), findsNothing);
      expect(find.byType(ResponsiveGmDashboard), findsOneWidget);

      engine.dispose();
    });

    testWidgets('should render music controls cleanly in MusicPlayerPanel without bottom bar dependencies', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final engine = AudioEngineService();

      // Act
      await tester.pumpWidget(
        _buildMinimalistTestApp(
          audioEngine: engine,
          screenSize: const Size(800, 600),
          child: const MusicPlayerPanel(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const ValueKey('music_play_pause_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('music_volume_slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('music_intensity_wrap')), findsNothing);

      engine.dispose();
    });

    testWidgets('should maintain all preset color values exactly when theme data is generated', (tester) async {
      // Arrange
      const deepDark = AppThemes.deepDark;
      const cleanLight = AppThemes.cleanLight;
      const parchment = AppThemes.ancientParchment;

      // Act & Assert
      expect(deepDark.primaryColor, 0xFFD4A373);
      expect(deepDark.backgroundColor, 0xFF14110F);
      expect(cleanLight.primaryColor, 0xFF2563EB);
      expect(cleanLight.backgroundColor, 0xFFF8FAFC);
      expect(parchment.primaryColor, 0xFFD4A373);
      expect(parchment.backgroundColor, 0xFF17120E);

      final themeData = deepDark.toThemeData();
      expect(themeData.brightness, Brightness.dark);
      expect(themeData.scaffoldBackgroundColor, const Color(0xFF14110F));
      expect(themeData.cardTheme.elevation, 0);
    });

    testWidgets('should provide a single IBM Plex Sans family across the textTheme hierarchy', (tester) async {
      // Arrange
      const theme = AppThemes.deepDark;

      // Act
      final themeData = theme.toThemeData();

      // Assert
      expect(themeData.textTheme.titleLarge?.fontFamily, DsTheme.sansFamily);
      expect(themeData.textTheme.bodyMedium?.fontFamily, DsTheme.sansFamily);
      expect(themeData.textTheme.displayLarge?.fontFamily, DsTheme.sansFamily);
    });

    testWidgets('should render library track cards with theme-adaptive colors under Clean Light theme', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      late MediaLibraryService libraryService;
      final track = LibraryTrack(
        id: 'track-light-1',
        title: 'Sunlit Melody',
        filePath: '/sunlit.mp3',
        busType: AudioBusType.music,
        durationMs: 120000,
        tags: const ['calm', 'acoustic'],
      );

      await tester.runAsync(() async {
        libraryService = MediaLibraryService(autoLoad: false);
        await libraryService.addTrack(track);
      });

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LoggerService>(create: (_) => LoggerService()),
            ChangeNotifierProvider<SettingsService>(
              create: (_) => SettingsService(dbService: DatabaseService(), autoLoad: false),
            ),
            ChangeNotifierProvider<ThemeService>(
              create: (_) {
                final svc = ThemeService(dbService: DatabaseService());
                svc.selectTheme(AppThemes.cleanLightId);
                return svc;
              },
            ),
            ChangeNotifierProxyProvider<ThemeService, ThemeViewModel>(
              create: (context) => ThemeViewModel(service: context.read<ThemeService>()),
              update: (context, service, viewModel) => viewModel ?? ThemeViewModel(service: service),
            ),
            ChangeNotifierProvider<AudioEngineService>.value(value: engine),
            ChangeNotifierProvider<MusicBusController>.value(value: engine.musicBus),
            ChangeNotifierProvider<AmbientBusController>.value(value: engine.ambientBus),
            ChangeNotifierProvider<SfxBusController>.value(value: engine.sfxBus),
            ChangeNotifierProvider<MediaLibraryService>.value(value: libraryService),
            ChangeNotifierProxyProvider<MediaLibraryService, MediaLibraryViewModel>(
              create: (context) => MediaLibraryViewModel(service: context.read<MediaLibraryService>()),
              update: (context, service, viewModel) => viewModel ?? MediaLibraryViewModel(service: service),
            ),
          ],
          child: Consumer<ThemeViewModel>(
            builder: (context, themeViewModel, _) {
              return MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('en'),
                theme: themeViewModel.currentThemeData,
                home: const Scaffold(body: LibraryScreen()),
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Assert
      final titleFinder = find.text('Sunlit Melody');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.color, AppThemes.cleanLight.textPrimary);

      final durationTextFinder = find.text('02:00');
      expect(durationTextFinder, findsOneWidget);
      final durationWidget = tester.widget<Text>(durationTextFinder);
      expect(durationWidget.style?.color, AppThemes.cleanLight.textSecondary);
      expect(durationWidget.style?.fontFamily, DsTheme.monoFamily);

      libraryService.dispose();
      engine.dispose();
    });

    testWidgets('should configure clean minimalist cardTheme, tabBarTheme, and dividerTheme in ThemeData', (tester) async {
      // Arrange
      const theme = AppThemes.deepDark;

      // Act
      final themeData = theme.toThemeData();

      // Assert
      expect(themeData.cardTheme.elevation, 0);
      expect(themeData.cardTheme.shadowColor, Colors.transparent);
      expect(themeData.tabBarTheme.labelStyle?.fontFamily, DsTheme.sansFamily);
      expect(themeData.tabBarTheme.dividerColor, Colors.transparent);
      expect(themeData.dividerTheme.thickness, 1.0);
    });
  });
}
