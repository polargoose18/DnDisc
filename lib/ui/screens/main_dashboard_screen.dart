import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/audio_engine_service.dart';
import '../../services/settings_service.dart';
import '../../services/shortcut_service.dart';
import '../widgets/logger_console_drawer.dart';
import 'responsive_gm_dashboard.dart';
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
          // Manual Ducking Button
          Consumer<AudioEngineService>(
            builder: (context, engine, _) {
              return IconButton(
                icon: const Icon(Icons.volume_down_rounded),
                tooltip: 'Ручной Ducking [D]',
                onPressed: () => engine.triggerManualDuck(),
              );
            },
          ),
          // Master Mute & Volume
          Consumer<AudioEngineService>(
            builder: (context, engine, _) {
              return Row(
                children: [
                  IconButton(
                    icon: Icon(engine.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                    tooltip: engine.isMuted ? 'Включить звук [M]' : 'Заглушить [M]',
                    color: engine.isMuted ? Colors.redAccent : null,
                    onPressed: () => engine.toggleMute(),
                  ),
                  SizedBox(
                    width: 140,
                    child: Slider(
                      value: engine.masterVolume,
                      onChanged: (val) => engine.setMasterVolume(val),
                    ),
                  ),
                  Text(
                    '${(engine.masterVolume * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                ],
              );
            },
          ),
          // Fullscreen Toggle
          Consumer<ShortcutService?>(
            builder: (context, shortcuts, _) {
              final isFull = shortcuts?.isFullscreen ?? false;
              return IconButton(
                icon: Icon(isFull ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                tooltip: 'Полноэкранный режим [F11]',
                onPressed: () => shortcuts?.handleActionDirectly(AppShortcutAction.toggleFullscreen),
              );
            },
          ),
          // Log Console
          Consumer<SettingsService>(
            builder: (context, settings, _) {
              if (!settings.showLogConsoleIcon) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.terminal_rounded, color: Colors.amberAccent),
                tooltip: 'Открыть консоль логов и отладки',
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Responsive GM Dashboard (Desktop 3-column / Mobile tabbed + MiniPlayer)
          ResponsiveGmDashboard(),

          // Tab 2: Central Media Library
          LibraryScreen(),

          // Tab 3: Settings & Preset Manager
          SettingsScreen(),
        ],
      ),
    );
  }
}
