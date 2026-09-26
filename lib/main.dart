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
              ChangeNotifierProvider<MediaLibraryService>(create: (_) => MediaLibraryService()),
              ChangeNotifierProvider<SceneService>(create: (_) => SceneService()),
            ],
            child: MaterialApp(
              title: 'TTRPG Audio Master',
              debugShowCheckedModeBanner: false,
              themeMode: ThemeMode.dark,
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorSchemeSeed: Colors.deepPurple,
                scaffoldBackgroundColor: const Color(0xFF121218),
                cardTheme: const CardThemeData(
                  color: Color(0xFF1E1E2A),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF181824),
                  elevation: 0,
                ),
              ),
              home: const MainDashboardScreen(),
            ),
          );
        },
      ),
    );
  }
}
