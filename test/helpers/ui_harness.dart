import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/data/services/settings_service.dart';
import 'package:ttrpg_audio_player/data/services/theme_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
import 'package:ttrpg_audio_player/services/shortcut_service.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/ui/design/toast.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/repository_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';
import 'fakes.dart';

class _FakePathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

/// Opens a throw-away SQLite database in a temp folder. Call from `setUp`,
/// and `tearDownUiTestDb` from `tearDown`.
Future<Directory> setUpUiTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final dir = await Directory.systemTemp.createTemp('ttrpg_ui_test_');
  PathProviderPlatform.instance = _FakePathProvider(dir.path);
  return dir;
}

Future<void> tearDownUiTestDb(Directory dir) async {
  await DatabaseService().close();
  try {
    if (await dir.exists()) await dir.delete(recursive: true);
  } catch (_) {}
}

LibraryTrack testTrack(
  String id,
  String title,
  AudioBusType bus, {
  int seconds = 60,
  String? icon,
  List<String> tags = const [],
  String? path,
}) =>
    LibraryTrack(
      id: id,
      title: title,
      filePath: path ?? '/missing/$id.mp3',
      busType: bus,
      durationMs: seconds * 1000,
      iconName: icon,
      tags: tags,
    );

/// All the services and view models the screens read, wired like `main.dart`.
class UiTestEnv {
  final AudioEngineService engine;
  final MediaLibraryService library;
  final SceneService scenes;
  final SettingsService settings;
  final ThemeService themes;
  final ToastController toasts = ToastController();
  RepositoryViewModel? repositoryViewModel;

  UiTestEnv({String themeId = AppThemes.deepDarkId, bool showToasts = true})
      : settings = SettingsService(),
        themes = ThemeService(initialThemeId: themeId),
        library = MediaLibraryService(autoLoad: false),
        scenes = SceneService(autoLoad: false),
        engine = AudioEngineService();

  MusicBusController get music => engine.musicBus;
  AmbientBusController get ambient => engine.ambientBus;
  SfxBusController get sfx => engine.sfxBus;

  Future<void> addTracks(WidgetTester tester, List<LibraryTrack> tracks) async {
    await tester.runAsync(() async {
      for (final t in tracks) {
        await library.addTrack(t);
      }
    });
  }

  Future<void> addScenes(WidgetTester tester, List<SceneModel> list) async {
    await tester.runAsync(() async {
      for (final s in list) {
        await scenes.createScene(s);
      }
    });
  }

  /// [child] inside providers, localisation and the active theme.
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoggerService>.value(value: LoggerService()),
        ChangeNotifierProvider<ToastController>.value(value: toasts),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<ThemeService>.value(value: themes),
        ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel(service: themes)),
        ChangeNotifierProvider<AudioEngineService>.value(value: engine),
        ChangeNotifierProvider<MusicBusController>.value(value: engine.musicBus),
        ChangeNotifierProvider<AmbientBusController>.value(value: engine.ambientBus),
        ChangeNotifierProvider<SfxBusController>.value(value: engine.sfxBus),
        ChangeNotifierProvider<ShortcutService>(create: (_) => ShortcutService(audioEngine: engine)),
        ChangeNotifierProvider<MediaLibraryService>.value(value: library),
        ChangeNotifierProvider<MediaLibraryViewModel>(create: (_) => MediaLibraryViewModel(service: library)),
        ChangeNotifierProvider<SceneService>.value(value: scenes),
        ChangeNotifierProvider<SceneViewModel>(create: (_) => SceneViewModel(service: scenes)),
        ChangeNotifierProvider<RepositoryViewModel>(
          create: (_) => repositoryViewModel ?? RepositoryViewModel(sourceRepository: FakeSourceRepo([]), settingsService: settings),
        ),
      ],
      child: Consumer2<ThemeViewModel, SettingsService>(
        builder: (context, themeVm, settings, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeVm.currentThemeData,
          locale: settings.currentLocale ?? locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => ToastHost(closeLabel: 'Close', child: child ?? const SizedBox.shrink()),
          home: child,
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, Widget child, {Size size = const Size(1440, 900), Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Desktop behaviour: hover and keyboard focus highlights are active.
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
    await tester.pumpWidget(wrap(child, locale: locale));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

AppLocalizations l10nOf(WidgetTester tester, [Type? widgetType]) =>
    AppLocalizations.of(tester.element(find.byType(widgetType ?? Scaffold).first))!;

/// Lets menus, dialogs and other routes finish their enter or exit animation
/// (the first frame only starts the animation).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Like [settle] for flows that wait on the database or other real IO. Each
/// await in the code under test needs the real event loop and then a fake
/// microtask flush, so the two alternate for a few rounds.
Future<void> settleIo(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
  }
  await settle(tester);
}
