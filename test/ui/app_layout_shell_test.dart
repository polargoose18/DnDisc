import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/data/services/settings_service.dart';
import 'package:ttrpg_audio_player/data/services/theme_service.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_en.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/repository_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';
import 'package:ttrpg_audio_player/ui/widgets/app_layout_shell.dart';

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

Widget createTestableWidget(
  Widget child, {
  AudioEngineService? engine,
  MediaLibraryService? library,
  LoggerService? logger,
  SettingsService? settings,
  SceneService? sceneService,
}) {
  final eng = engine ?? AudioEngineService();
  final log = logger ?? LoggerService();
  final set = settings ?? SettingsService();
  final scn = sceneService ?? SceneService(autoLoad: false);
  final thm = ThemeService(autoLoad: false);
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
      ChangeNotifierProvider<SceneViewModel>(create: (_) => SceneViewModel(service: scn)),
      ChangeNotifierProvider<ThemeService>.value(value: thm),
      ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel(service: thm)),
      ChangeNotifierProvider<MediaLibraryService>.value(value: lib),
      ChangeNotifierProxyProvider<MediaLibraryService, MediaLibraryViewModel>(
        create: (_) => MediaLibraryViewModel(service: lib),
        update: (_, service, vm) => vm ?? MediaLibraryViewModel(service: service),
      ),
      ChangeNotifierProxyProvider<SettingsService, RepositoryViewModel>(
        create: (_) => RepositoryViewModel(settingsService: set),
        update: (_, s, vm) => vm ?? RepositoryViewModel(settingsService: s),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final l10n = AppLocalizationsEn();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_shell_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    await DatabaseService().close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('AppLayoutShell Layout & Navigation Tests', () {
    testWidgets('should render 3-column desktop layout and bottom master player when mounted', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Act
      await tester.pumpWidget(createTestableWidget(const AppLayoutShell()));
      await tester.pump();

      // Assert
      expect(find.byType(AppLayoutShell), findsOneWidget);
      expect(find.byType(SidebarTree), findsOneWidget);
      expect(find.byType(BottomMasterPlayer), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
      expect(find.byIcon(Icons.library_music_rounded), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });

    testWidgets('should toggle sidebar visibility when hamburger menu button is clicked', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(const AppLayoutShell()));
      await tester.pump();
      expect(find.byType(SidebarTree), findsOneWidget);

      // Act: Click hamburger to collapse sidebar
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Assert: Sidebar is now collapsed
      expect(find.byType(SidebarTree), findsNothing);

      // Act: Click hamburger again to re-open sidebar
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Assert: Sidebar is back
      expect(find.byType(SidebarTree), findsOneWidget);
    });

    testWidgets('should display dynamic collapse/expand tooltip on hamburger menu button when toggled', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(const AppLayoutShell()));
      await tester.pump();

      // Assert initially shows collapse tooltip
      expect(find.byTooltip(l10n.collapseSidebarTooltip), findsOneWidget);

      // Act: Tap hamburger to collapse
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Assert now shows expand tooltip
      expect(find.byTooltip(l10n.expandSidebarTooltip), findsOneWidget);
    });

    testWidgets('should switch displayed screen and notify callback when navigation rail item is tapped', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int selectedIndex = 0;
      await tester.pumpWidget(createTestableWidget(
        AppLayoutShell(
          onNavIndexChanged: (index) => selectedIndex = index,
        ),
      ));
      await tester.pump();

      // Act: Tap Settings icon (index 3)
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedIndex, 3);
      expect(find.text(l10n.settingsTitle), findsOneWidget);
    });

    testWidgets('should update navigation index and sidebar state when widget properties change in didUpdateWidget', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(
        const AppLayoutShell(
          initialNavIndex: 0,
          initialSidebarOpen: true,
        ),
      ));
      await tester.pump();
      expect(find.byType(SidebarTree), findsOneWidget);

      // Act: Update parent widget state
      await tester.pumpWidget(createTestableWidget(
        const AppLayoutShell(
          initialNavIndex: 3,
          initialSidebarOpen: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SidebarTree), findsNothing);
      expect(find.text(l10n.settingsTitle), findsOneWidget);
    });

    testWidgets('should render custom child widget when child parameter is provided', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const customContent = Text('Custom Stage Child Content');

      // Act
      await tester.pumpWidget(createTestableWidget(
        const AppLayoutShell(
          child: customContent,
        ),
      ));
      await tester.pump();

      // Assert
      expect(find.text('Custom Stage Child Content'), findsOneWidget);
    });

    testWidgets('should render without layout overflow on constrained window widths when custom child is provided', (tester) async {
      // Arrange: Narrow viewport (600x600)
      tester.view.physicalSize = const Size(600, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Act
      await tester.pumpWidget(createTestableWidget(const AppLayoutShell(
        initialSidebarOpen: false,
        child: SizedBox(),
      )));
      await tester.pump();

      // Assert: No RenderFlex overflow exception
      expect(tester.takeException(), isNull);
      expect(find.byType(AppLayoutShell), findsOneWidget);
      expect(find.byType(BottomMasterPlayer), findsOneWidget);
    });

    testWidgets('should render bottom master player without layout overflow on very narrow widths', (tester) async {
      // Arrange: Narrow viewport (420x200)
      tester.view.physicalSize = const Size(420, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Act
      await tester.pumpWidget(createTestableWidget(const BottomMasterPlayer()));
      await tester.pump();

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomMasterPlayer), findsOneWidget);
    });
  });

  group('SidebarTree Component Tests', () {
    testWidgets('should render app title with serif font when displayed', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestableWidget(
        const SizedBox(
          width: 250,
          child: SidebarTree(),
        ),
      ));
      await tester.pump();

      // Assert
      final titleFinder = find.text(l10n.appTitle);
      expect(titleFinder, findsOneWidget);

      final Text titleWidget = tester.widget(titleFinder);
      expect(titleWidget.style?.fontFamily, 'serif');
    });

    testWidgets('should expand and collapse scenes list when scenes category header is clicked', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestableWidget(
        const SizedBox(
          width: 250,
          child: SidebarTree(initiallyScenesExpanded: true),
        ),
      ));
      await tester.pump();

      expect(find.text(l10n.sceneTown), findsOneWidget);

      // Act: Collapse scenes
      await tester.tap(find.text(l10n.scenes));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.sceneTown), findsNothing);

      // Act: Re-expand scenes
      await tester.tap(find.text(l10n.scenes));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.sceneTown), findsOneWidget);
    });

    testWidgets('should trigger onSceneSelected and highlight item when scene item is tapped', (tester) async {
      // Arrange
      String? tappedSceneId;
      await tester.pumpWidget(createTestableWidget(
        SizedBox(
          width: 250,
          child: SidebarTree(
            onSceneSelected: (id) => tappedSceneId = id,
          ),
        ),
      ));
      await tester.pump();

      // Act: Tap "Enchanted Forest"
      await tester.tap(find.text(l10n.sceneEnchantedForest));
      await tester.pump();

      // Assert
      expect(tappedSceneId, 'enchanted_forest');
    });

    testWidgets('should reflect externally activated scene from SceneViewModel in SidebarTree', (tester) async {
      // Arrange
      final sceneService = SceneService(autoLoad: false);
      final sceneA = SceneModel(id: 'scene_a', name: 'Ancient Crypt');
      final sceneB = SceneModel(id: 'scene_b', name: 'Dragon Lair');
      await tester.runAsync(() async {
        await sceneService.createScene(sceneA);
        await sceneService.createScene(sceneB);
      });

      await tester.pumpWidget(createTestableWidget(
        const SizedBox(
          width: 250,
          child: SidebarTree(),
        ),
        sceneService: sceneService,
      ));
      await tester.pump();

      // Assert both real scenes are rendered
      expect(find.text('Ancient Crypt'), findsOneWidget);
      expect(find.text('Dragon Lair'), findsOneWidget);

      // Act: Externally activate Dragon Lair
      await tester.runAsync(() async {
        await sceneService.activateScene(sceneB);
      });
      await tester.pump();

      // Assert: SceneViewModel active state is honored
      expect(sceneService.activeSceneId, 'scene_b');
    });

    testWidgets('should expand and collapse media folders when media library header is clicked', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestableWidget(
        const SizedBox(
          width: 250,
          child: SidebarTree(initiallyMediaLibraryExpanded: true),
        ),
      ));
      await tester.pump();

      expect(find.text(l10n.categoryFoley), findsOneWidget);

      // Act: Collapse media library
      await tester.tap(find.text(l10n.tabLibrary));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.categoryFoley), findsNothing);
    });

    testWidgets('should trigger onFolderSelected callback and highlight folder when folder item is tapped', (tester) async {
      // Arrange
      String? tappedFolder;
      await tester.pumpWidget(createTestableWidget(
        SizedBox(
          width: 250,
          child: SidebarTree(
            onFolderSelected: (folder) => tappedFolder = folder,
          ),
        ),
      ));
      await tester.pump();

      // Act
      await tester.tap(find.text(l10n.categoryFoley));
      await tester.pump();

      // Assert
      expect(tappedFolder, 'foley');
    });
  });

  group('BottomMasterPlayer Component Tests', () {
    testWidgets('should display track title and playback status when music track is playing', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      engine.musicBus.setDefaultFadeDuration(Duration.zero);
      const track = AudioTrack(
        id: 'tr_test',
        title: 'Tavern Lute Melody',
        filePath: '/dummy.mp3',
      );

      // Act
      await tester.pumpWidget(createTestableWidget(
        const BottomMasterPlayer(),
        engine: engine,
      ));
      await tester.pump();

      // Initially no track
      expect(find.text(l10n.noMusic), findsOneWidget);

      // Set track and resume
      await engine.musicBus.playTrack(track, fadeDuration: Duration.zero);
      await engine.musicBus.resume(fadeDuration: Duration.zero);
      await tester.pump();

      // Assert
      expect(find.text('Tavern Lute Melody'), findsOneWidget);
      expect(find.text(l10n.playing), findsOneWidget);
    });

    testWidgets('should toggle playback between play and pause when playback button is tapped', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      engine.musicBus.setDefaultFadeDuration(Duration.zero);
      const track = AudioTrack(
        id: 'tr_test_2',
        title: 'Battle Theme',
        filePath: '/dummy2.mp3',
      );
      await engine.musicBus.playTrack(track, fadeDuration: Duration.zero);
      await engine.musicBus.resume(fadeDuration: Duration.zero);

      await tester.pumpWidget(createTestableWidget(
        const BottomMasterPlayer(),
        engine: engine,
      ));
      await tester.pump();

      expect(engine.musicBus.isPlaying, isTrue);

      // Act: Tap pause
      await tester.tap(find.byIcon(Icons.pause_circle_filled_rounded));
      await tester.pump();

      // Assert: Is paused
      expect(engine.musicBus.isPlaying, isFalse);

      // Act: Tap resume
      await tester.tap(find.byIcon(Icons.play_circle_fill_rounded));
      await tester.pump();

      // Assert: Is playing
      expect(engine.musicBus.isPlaying, isTrue);
    });

    testWidgets('should trigger manual ducking when ducking button is tapped', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      await tester.pumpWidget(createTestableWidget(
        const BottomMasterPlayer(),
        engine: engine,
      ));
      await tester.pump();

      // Act
      await tester.tap(find.byIcon(Icons.volume_down_rounded));
      await tester.pump();

      // Assert
      expect(engine.duckingController.isDucked, isTrue);

      engine.dispose();
    });

    testWidgets('should trigger panic stop SFX when panic stop button is tapped', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      await tester.pumpWidget(createTestableWidget(
        const BottomMasterPlayer(),
        engine: engine,
      ));
      await tester.pump();

      // Act: Tap panic stop
      await tester.tap(find.byIcon(Icons.dangerous_rounded));
      await tester.pump();

      // Assert
      expect(tester.takeException(), isNull);
      engine.dispose();
    });

    testWidgets('should update master volume text and trigger volume change when volume slider is dragged', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      await tester.pumpWidget(createTestableWidget(
        const BottomMasterPlayer(),
        engine: engine,
      ));
      await tester.pump();

      expect(find.text('100%'), findsOneWidget);

      // Act: Update master volume
      engine.setMasterVolume(0.5);
      await tester.pump();

      // Assert
      expect(find.text('50%'), findsOneWidget);
      expect(engine.masterVolume, 0.5);

      engine.dispose();
    });

    testWidgets('should toggle mute state when mute button is tapped', (tester) async {
      // Arrange
      final engine = AudioEngineService();
      await tester.pumpWidget(createTestableWidget(
        const BottomMasterPlayer(),
        engine: engine,
      ));
      await tester.pump();

      expect(engine.isMuted, isFalse);

      // Act: Mute
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();

      // Assert
      expect(engine.isMuted, isTrue);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

      // Act: Unmute
      await tester.tap(find.byIcon(Icons.volume_off_rounded));
      await tester.pump();

      // Assert
      expect(engine.isMuted, isFalse);
    });
  });
}
