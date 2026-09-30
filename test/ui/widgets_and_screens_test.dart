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
import 'package:ttrpg_audio_player/services/logger_service.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';

import 'package:ttrpg_audio_player/ui/widgets/music_player_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/ambient_mixer_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/soundboard_grid.dart';
import 'package:ttrpg_audio_player/ui/widgets/logger_console_drawer.dart';
import 'package:ttrpg_audio_player/ui/widgets/import_track_dialog.dart';
import 'package:ttrpg_audio_player/ui/screens/main_dashboard_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/library_screen.dart';
import 'package:ttrpg_audio_player/data/services/settings_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/data/services/theme_service.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';

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

Widget createTestableWidget(Widget child, {
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
      ChangeNotifierProvider<MediaLibraryViewModel>(create: (_) => MediaLibraryViewModel(service: lib)),
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
  final l10n = AppLocalizationsEn();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_ui_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    await DatabaseService().close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('MusicPlayerPanel Widget Tests', () {
    testWidgets('should display playback idle message and update intensity when intensity chip is clicked', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      await tester.pumpWidget(createTestableWidget(const MusicPlayerPanel(), engine: engine));

      expect(find.text(l10n.musicTrack), findsOneWidget);
      expect(find.text(l10n.musicNotPlaying), findsOneWidget);

      // Act
      await tester.tap(find.byKey(const ValueKey('chip_boss')));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert
      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.boss));
      engine.dispose();
    });

    testWidgets('should toggle playback and adjust volume slider in MusicPlayerPanel', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      await tester.pumpWidget(createTestableWidget(const MusicPlayerPanel(), engine: engine));

      // Act - Play/Pause tap
      await tester.tap(find.byKey(const ValueKey('music_play_pause_button')));
      await tester.pump(const Duration(milliseconds: 200));

      // Act - Volume Slider Drag
      await tester.drag(find.byKey(const ValueKey('music_volume_slider')), const Offset(-50, 0));
      await tester.pump(const Duration(milliseconds: 200));

      // Assert
      expect(engine.musicBus.rawVolume, lessThan(1.0));
      engine.dispose();
    });
  });

  group('AmbientMixerPanel Widget Tests', () {
    testWidgets('should display empty placeholder when no ambient layers are present', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();

      // Act
      await tester.pumpWidget(createTestableWidget(const AmbientMixerPanel(), engine: engine));

      // Assert
      expect(find.textContaining(l10n.noActiveAmbients), findsOneWidget);
      engine.dispose();
    });

    testWidgets('should render ambient layers and toggle active switch and stop all layers', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      engine.ambientBus.addLayer(const AmbientLayer(id: 'rain-l', title: 'Rain Ambience', filePath: '/rain.mp3', isActive: true));

      await tester.pumpWidget(createTestableWidget(const AmbientMixerPanel(), engine: engine));

      expect(find.textContaining(l10n.ambientLayers), findsOneWidget);
      expect(find.text('Rain Ambience'), findsOneWidget);
      expect(engine.ambientBus.layers.first.isActive, isTrue);

      // Act & Assert - Toggle switch
      await tester.tap(find.byKey(const ValueKey('ambient_switch_rain-l')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(engine.ambientBus.layers.first.isActive, isFalse);

      // Act & Assert - Stop all button
      await tester.tap(find.byKey(const ValueKey('ambient_stop_all_btn')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(engine.ambientBus.layers.every((l) => !l.isActive), isTrue);

      engine.dispose();
    });
  });

  group('SoundboardGrid Widget Tests', () {
    testWidgets('should render empty state message when soundboard has no triggers', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();

      // Act
      await tester.pumpWidget(createTestableWidget(const SoundboardGrid(), engine: engine));

      // Assert
      expect(find.textContaining(l10n.soundboardEmpty), findsOneWidget);
      engine.dispose();
    });

    testWidgets('should render SFX buttons and trigger audio ducking when clicked', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      engine.sfxBus.addTrigger(const SfxTrigger(id: 'sword-trig', title: 'Sword Strike', filePath: '/sword.wav', hotkey: '1'));

      await tester.pumpWidget(createTestableWidget(const SoundboardGrid(), engine: engine));

      expect(find.textContaining(l10n.soundboardTitle), findsOneWidget);
      expect(find.text('Sword Strike'), findsOneWidget);
      expect(find.text('[1]'), findsOneWidget);

      // Act
      await tester.tap(find.byKey(const ValueKey('sfx_btn_sword-trig')));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert
      expect(engine.duckingController.isDucked, isTrue);
      engine.dispose();
    });
  });

  group('LoggerConsoleDrawer Widget Tests', () {
    testWidgets('should display log entries and clear log history when clear icon is pressed', (WidgetTester tester) async {
      // Arrange
      final logger = LoggerService();
      logger.clear();

      await tester.pumpWidget(createTestableWidget(const LoggerConsoleDrawer(), logger: logger));
      logger.info('Test log entry');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.logConsoleTitle), findsOneWidget);
      expect(find.textContaining('Test log entry'), findsOneWidget);

      // Act
      await tester.tap(find.byTooltip(l10n.clearLogs));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.noLogs), findsOneWidget);
    });
  });

  group('EditTrackDialog Widget Tests', () {
    testWidgets('should edit track title and return updated LibraryTrack on save', (WidgetTester tester) async {
      // Arrange
      final track = LibraryTrack(
        id: 'edit-1',
        title: 'Old Name',
        filePath: '/track.mp3',
        busType: AudioBusType.music,
      );

      LibraryTrack? resultTrack;

      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () async {
                    resultTrack = await showDialog<LibraryTrack>(
                      context: ctx,
                      builder: (_) => EditTrackDialog(track: track),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n.editTrackTitle), findsOneWidget);

      // Act
      await tester.enterText(find.widgetWithText(TextField, 'Old Name'), 'New Name');
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(l10n.save));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert
      expect(resultTrack, isNotNull);
      expect(resultTrack!.title, equals('New Name'));
    });

    testWidgets('should return null when cancel button is clicked in EditTrackDialog', (WidgetTester tester) async {
      // Arrange
      final track = LibraryTrack(
        id: 'edit-2',
        title: 'Cancel Test',
        filePath: '/cancel.mp3',
        busType: AudioBusType.sfx,
      );

      LibraryTrack? resultTrack = track;

      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () async {
                    resultTrack = await showDialog<LibraryTrack>(
                      context: ctx,
                      builder: (_) => EditTrackDialog(track: track),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump(const Duration(milliseconds: 300));

      // Act
      await tester.tap(find.text(l10n.cancel));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert
      expect(resultTrack, isNull);
    });
  });

  group('MainDashboardScreen Widget Tests', () {
    testWidgets('should render dashboard tabs and open logger console drawer from header', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      late final MediaLibraryService library;
      await tester.runAsync(() async {
        library = MediaLibraryService();
        await library.loadTracks();
      });

      await tester.pumpWidget(
        createTestableWidget(
          const MainDashboardScreen(),
          engine: engine,
          library: library,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(l10n.appTitle), findsOneWidget);
      expect(find.text(l10n.tabGmDashboard), findsOneWidget);
      expect(find.text(l10n.tabLibrary), findsOneWidget);

      // Act & Assert - Switch to Library tab
      await tester.tap(find.text(l10n.tabLibrary));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library_search_input')), findsOneWidget);

      // Act & Assert - Open log drawer
      await tester.tap(find.byTooltip(l10n.logConsoleTooltip));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n.logConsoleTitle), findsOneWidget);

      library.dispose();
      engine.dispose();
    });
  });

  group('LibraryScreen Widget Tests', () {
    testWidgets('should render track card with quick send button and route audio to MusicBus', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      late final MediaLibraryService library;

      final track = LibraryTrack(
        id: 'lib-t1',
        title: 'Tavern Melodies',
        filePath: '/tavern.mp3',
        busType: AudioBusType.music,
      );

      await tester.runAsync(() async {
        library = MediaLibraryService();
        await library.addTrack(track);
      });

      await tester.pumpWidget(
        createTestableWidget(
          const LibraryScreen(),
          engine: engine,
          library: library,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tavern Melodies'), findsOneWidget);
      expect(find.byTooltip(l10n.dispatchToBus(track.busType.getLocalizedName(l10n))), findsOneWidget);

      // Act
      library.playTrackToEngine(track, engine);

      // Assert
      expect(engine.musicBus.currentTrack?.title, equals('Tavern Melodies'));

      library.dispose();
      engine.dispose();
    });

    testWidgets('should display empty placeholder when library contains no tracks', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      late final MediaLibraryService library;

      await tester.runAsync(() async {
        library = MediaLibraryService();
        await library.loadTracks();
      });

      // Act
      await tester.pumpWidget(
        createTestableWidget(
          const LibraryScreen(),
          engine: engine,
          library: library,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Assert
      expect(find.text(l10n.libraryEmpty), findsOneWidget);

      library.dispose();
      engine.dispose();
    });

    testWidgets('should remove track from library when delete button is pressed', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      late final MediaLibraryService library;

      final track = LibraryTrack(
        id: 'lib-del-1',
        title: 'Delete Me Track',
        filePath: '/del.mp3',
        busType: AudioBusType.sfx,
      );

      await tester.runAsync(() async {
        library = MediaLibraryService();
        await library.addTrack(track);
      });

      await tester.pumpWidget(
        createTestableWidget(
          const LibraryScreen(),
          engine: engine,
          library: library,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Delete Me Track'), findsOneWidget);

      // Act
      await tester.runAsync(() async {
        await library.deleteTrack(track.id);
      });
      await tester.pump();

      // Assert
      expect(library.tracks, isEmpty);

      library.dispose();
      engine.dispose();
    });

    testWidgets('should render formatted duration badges on track cards', (WidgetTester tester) async {
      // Arrange
      final engine = AudioEngineService();
      late final MediaLibraryService library;

      final track1 = LibraryTrack(
        id: 'track-dur-1',
        title: 'Epic Battle Theme',
        filePath: '/battle.mp3',
        busType: AudioBusType.music,
        durationMs: 141087,
      );
      final track2 = LibraryTrack(
        id: 'track-dur-2',
        title: 'Unknown Sound Effect',
        filePath: '/sfx.mp3',
        busType: AudioBusType.sfx,
        durationMs: 0,
      );

      await tester.runAsync(() async {
        library = MediaLibraryService();
        await library.addTrack(track1);
        await library.addTrack(track2);
      });

      // Act
      await tester.pumpWidget(
        createTestableWidget(
          const LibraryScreen(),
          engine: engine,
          library: library,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Assert
      expect(find.byKey(const ValueKey('library_track_duration_track-dur-1')), findsOneWidget);
      expect(find.text('02:21'), findsWidgets);

      expect(find.byKey(const ValueKey('library_track_duration_track-dur-2')), findsOneWidget);
      expect(find.text('--:--'), findsWidgets);

      library.dispose();
      engine.dispose();
    });
  });
}
