import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/audio_engine_service.dart';
import '../widgets/scene_selector_panel.dart';
import '../widgets/music_player_panel.dart';
import '../widgets/ambient_mixer_panel.dart';
import '../widgets/soundboard_grid.dart';
import '../widgets/logger_console_drawer.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const LoggerConsoleDrawer(),
      appBar: AppBar(
        title: const Text('TTRPG Audio Master'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Панель Мастера'),
            Tab(icon: Icon(Icons.library_music_rounded), text: 'Общая Библиотека'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Настройки'),
          ],
        ),
        actions: [
          Consumer<AudioEngineService>(
            builder: (context, engine, _) {
              return Row(
                children: [
                  const Icon(Icons.volume_up),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: engine.masterVolume,
                      onChanged: (val) => engine.setMasterVolume(val),
                    ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.terminal_rounded, color: Colors.amberAccent),
            tooltip: 'Открыть консоль логов и отладки',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Live GM Mixer Dashboard with SceneSelector
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SceneSelectorPanel(),
                  MusicPlayerPanel(),
                  AmbientMixerPanel(),
                  SoundboardGrid(),
                ],
              ),
            ),
          ),

          // Tab 2: Central Media Library
          LibraryScreen(),

          // Tab 3: Settings & Preset Manager
          SettingsScreen(),
        ],
      ),
    );
  }
}
