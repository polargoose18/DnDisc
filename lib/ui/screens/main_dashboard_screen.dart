import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../audio/audio_engine_service.dart';
import '../../services/settings_service.dart';
import '../widgets/logger_console_drawer.dart';
import 'responsive_gm_dashboard.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'repository_catalog_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const LoggerConsoleDrawer(),
      appBar: AppBar(
        title: Text(l10n?.appTitle ?? 'TTRPG Audio Master'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.dashboard_rounded), text: l10n?.tabGmDashboard ?? 'Панель Мастера'),
            Tab(icon: const Icon(Icons.library_music_rounded), text: l10n?.tabLibrary ?? 'Общая Библиотека'),
            Tab(icon: const Icon(Icons.settings_rounded), text: l10n?.tabSettings ?? 'Настройки'),
            Tab(icon: const Icon(Icons.grid_view_rounded), text: 'Каталог'),
          ],
        ),
        actions: [
          // Manual Ducking Button
          Consumer<AudioEngineService>(
            builder: (context, engine, _) {
              return IconButton(
                icon: const Icon(Icons.volume_down_rounded),
                tooltip: l10n?.manualDuckingTooltip ?? 'Ручной Ducking [D]',
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
                    tooltip: engine.isMuted
                        ? (l10n?.unmuteTooltip ?? 'Включить звук [M]')
                        : (l10n?.muteTooltip ?? 'Заглушить [M]'),
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
          // Log Console
          Consumer<SettingsService>(
            builder: (context, settings, _) {
              if (!settings.showLogConsoleIcon) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.terminal_rounded, color: Colors.amberAccent),
                tooltip: l10n?.logConsoleTooltip ?? 'Открыть консоль логов и отладки',
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

          // Tab 4: Repository Catalog
          RepositoryCatalogScreen(),
        ],
      ),
    );
  }
}
