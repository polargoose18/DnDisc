import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'audio/audio_engine_service.dart';
import 'audio/music_bus_controller.dart';
import 'audio/ambient_bus_controller.dart';
import 'audio/sfx_bus_controller.dart';
import 'data/services/media_library_service.dart';
import 'data/services/settings_service.dart';
import 'data/services/scene_service.dart';
import 'data/services/database_service.dart';
import 'services/logger_service.dart';
import 'data/services/theme_service.dart';
import 'services/shortcut_service.dart';
import 'ui/view_models/theme_view_model.dart';
import 'ui/view_models/media_library_view_model.dart';
import 'ui/view_models/scene_view_model.dart';
import 'ui/view_models/repository_view_model.dart';
import 'ui/screens/main_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TtrpgAudioPlayerApp());
}

class TtrpgAudioPlayerApp extends StatelessWidget {
  const TtrpgAudioPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoggerService>(create: (_) => LoggerService()),
        ChangeNotifierProvider<SettingsService>(create: (_) => SettingsService()),
        ChangeNotifierProvider<ThemeService>(
          create: (_) {
            final svc = ThemeService(dbService: DatabaseService());
            svc.loadActiveThemeId();
            return svc;
          },
        ),
        ChangeNotifierProxyProvider<ThemeService, ThemeViewModel>(
          create: (context) => ThemeViewModel(service: context.read<ThemeService>()),
          update: (context, service, viewModel) => viewModel ?? ThemeViewModel(service: service),
        ),
        ChangeNotifierProxyProvider<SettingsService, AudioEngineService>(
          create: (context) => AudioEngineService(settings: context.read<SettingsService>()),
          update: (context, settings, audioEngine) {
            audioEngine?.attachSettings(settings);
            return audioEngine ?? AudioEngineService(settings: settings);
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final audioEngine = context.read<AudioEngineService>();
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<MusicBusController>.value(value: audioEngine.musicBus),
              ChangeNotifierProvider<AmbientBusController>.value(value: audioEngine.ambientBus),
              ChangeNotifierProvider<SfxBusController>.value(value: audioEngine.sfxBus),
              ChangeNotifierProvider<ShortcutService>(
                create: (_) => ShortcutService(audioEngine: audioEngine),
              ),
              ChangeNotifierProvider<MediaLibraryService>(create: (_) => MediaLibraryService()),
              ChangeNotifierProxyProvider<MediaLibraryService, MediaLibraryViewModel>(
                create: (context) => MediaLibraryViewModel(service: context.read<MediaLibraryService>()),
                update: (context, service, viewModel) => viewModel ?? MediaLibraryViewModel(service: service),
              ),
              ChangeNotifierProvider<SceneService>(create: (_) => SceneService()),
              ChangeNotifierProxyProvider<SceneService, SceneViewModel>(
                create: (context) => SceneViewModel(service: context.read<SceneService>()),
                update: (context, service, viewModel) => viewModel ?? SceneViewModel(service: service),
              ),
              ChangeNotifierProvider<RepositoryViewModel>(create: (_) => RepositoryViewModel()),
            ],
            child: Consumer2<ThemeViewModel, SettingsService>(
              builder: (context, themeViewModel, settingsService, _) {
                return MaterialApp(
                  title: 'TTRPG Audio Master',
                  debugShowCheckedModeBanner: false,
                  theme: themeViewModel.currentThemeData,
                  darkTheme: themeViewModel.currentThemeData,
                  themeMode: themeViewModel.activeTheme.isDark ? ThemeMode.dark : ThemeMode.light,
                  locale: settingsService.currentLocale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  localeResolutionCallback: (locale, supportedLocales) {
                    if (locale != null) {
                      for (var supportedLocale in supportedLocales) {
                        if (supportedLocale.languageCode == locale.languageCode) {
                          return supportedLocale;
                        }
                      }
                    }
                    return const Locale('ru');
                  },
                  home: const MainDashboardScreen(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
