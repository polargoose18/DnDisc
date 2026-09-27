import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio/audio_engine_service.dart';
import 'audio/music_bus_controller.dart';
import 'audio/ambient_bus_controller.dart';
import 'audio/sfx_bus_controller.dart';
import 'services/media_library_service.dart';
import 'services/settings_service.dart';
import 'services/scene_service.dart';
import 'services/logger_service.dart';
import 'services/theme_service.dart';
import 'services/shortcut_service.dart';
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
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
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
              ChangeNotifierProvider<SceneService>(create: (_) => SceneService()),
            ],
            child: Consumer<ThemeService>(
              builder: (context, themeService, _) {
                return MaterialApp(
                  title: 'TTRPG Audio Master',
                  debugShowCheckedModeBanner: false,
                  theme: themeService.currentThemeData,
                  darkTheme: themeService.currentThemeData,
                  themeMode: themeService.activeTheme.isDark ? ThemeMode.dark : ThemeMode.light,
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
