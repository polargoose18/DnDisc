import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../audio/audio_engine_service.dart';
import '../../data/services/settings_service.dart';
import '../../ui/view_models/theme_view_model.dart';
import '../../theme/app_themes.dart';
import '../widgets/logger_console_drawer.dart';
import '../widgets/sticky_mini_player.dart';
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
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeViewModel = context.watch<ThemeViewModel?>();
    final activeTheme = themeViewModel?.activeTheme ?? AppThemes.deepDark;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    if (isDesktop) {
      return _buildDesktopLayout(activeTheme, l10n);
    } else {
      return _buildMobileLayout(activeTheme, l10n);
    }
  }

  Widget _buildDesktopLayout(dynamic activeTheme, AppLocalizations? l10n) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const LoggerConsoleDrawer(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar (DnDisc Style)
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: activeTheme.surface,
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1.0,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header: DnDisc
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: activeTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: activeTheme.primary.withValues(alpha: 0.4), width: 0.8),
                          ),
                          child: Icon(Icons.shield_moon_rounded, color: activeTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n?.appTitle ?? 'DnDisc',
                          style: TextStyle(
                            fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.6,
                            color: activeTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Navigation Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        _buildSidebarNavItem(
                          index: 0,
                          icon: Icons.dashboard_rounded,
                          label: l10n?.tabGmDashboard ?? 'GM Dashboard',
                          activeTheme: activeTheme,
                        ),
                        const SizedBox(height: 4),
                        _buildSidebarNavItem(
                          index: 1,
                          icon: Icons.library_music_rounded,
                          label: l10n?.tabLibrary ?? 'Media Library',
                          activeTheme: activeTheme,
                        ),
                        const SizedBox(height: 4),
                        _buildSidebarNavItem(
                          index: 2,
                          icon: Icons.settings_rounded,
                          label: l10n?.tabSettings ?? 'Settings',
                          activeTheme: activeTheme,
                        ),
                        const SizedBox(height: 4),
                        _buildSidebarNavItem(
                          index: 3,
                          icon: Icons.grid_view_rounded,
                          label: l10n?.tabCatalog ?? 'Catalog',
                          activeTheme: activeTheme,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Sidebar Bottom: Log Console Trigger & Version Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<SettingsService>(
                          builder: (context, settings, _) {
                            if (!settings.showLogConsoleIcon) return const SizedBox.shrink();
                            return IconButton(
                              icon: Icon(Icons.terminal_rounded, color: activeTheme.primary, size: 20),
                              tooltip: l10n?.logConsoleTooltip ?? 'Open log and debug console',
                              onPressed: () {
                                _scaffoldKey.currentState?.openEndDrawer();
                              },
                            );
                          },
                        ),
                        Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: activeTheme.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content View
          Expanded(
            child: Column(
              children: [
                // Desktop Header Bar with Controls
                _buildDesktopHeader(activeTheme, l10n),

                // Main Content Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      ResponsiveGmDashboard(),
                      LibraryScreen(),
                      SettingsScreen(),
                      RepositoryCatalogScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const StickyMiniPlayer(),
    );
  }

  Widget _buildDesktopHeader(dynamic activeTheme, AppLocalizations? l10n) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: activeTheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.grain_rounded, size: 16, color: activeTheme.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            _getDesktopSectionTitle(l10n),
            style: TextStyle(
              fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: activeTheme.textPrimary,
            ),
          ),
          const Spacer(),

          // Manual Ducking Button
          Consumer<AudioEngineService>(
            builder: (context, engine, _) {
              return IconButton(
                icon: Icon(
                  Icons.volume_down_rounded,
                  size: 20,
                  color: engine.duckingController.isDucked ? activeTheme.duckingBadge : activeTheme.textSecondary,
                ),
                tooltip: l10n?.manualDuckingTooltip ?? 'Manual Ducking [D]',
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
                    icon: Icon(
                      engine.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      size: 20,
                    ),
                    tooltip: engine.isMuted
                        ? (l10n?.unmuteTooltip ?? 'Unmute [M]')
                        : (l10n?.muteTooltip ?? 'Mute [M]'),
                    color: engine.isMuted ? Colors.redAccent : activeTheme.textSecondary,
                    onPressed: () => engine.toggleMute(),
                  ),
                  SizedBox(
                    width: 120,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: activeTheme.primary,
                        thumbColor: activeTheme.primary,
                      ),
                      child: Slider(
                        value: engine.masterVolume,
                        onChanged: (val) => engine.setMasterVolume(val),
                      ),
                    ),
                  ),
                  Text(
                    '${(engine.masterVolume * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activeTheme.textSecondary),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _getDesktopSectionTitle(AppLocalizations? l10n) {
    switch (_tabController.index) {
      case 0:
        return l10n?.sessionAudioDeck ?? 'Session Audio Deck';
      case 1:
        return l10n?.libraryTitle ?? 'Media Library';
      case 2:
        return l10n?.settingsTitle ?? 'Audio Engine Settings';
      case 3:
        return l10n?.catalogTitle ?? 'Catalog';
      default:
        return '';
    }
  }

  Widget _buildSidebarNavItem({
    required int index,
    required IconData icon,
    required String label,
    required dynamic activeTheme,
  }) {
    final isSelected = _tabController.index == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeTheme.primary.withValues(alpha: 0.4) : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeTheme.primary : activeTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? activeTheme.textPrimary : activeTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(dynamic activeTheme, AppLocalizations? l10n) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const LoggerConsoleDrawer(),
      appBar: AppBar(
        backgroundColor: activeTheme.surface,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: activeTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: activeTheme.primary.withValues(alpha: 0.4), width: 0.8),
              ),
              child: Icon(Icons.shield_moon_rounded, color: activeTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              l10n?.appTitle ?? 'DnDisc',
              style: TextStyle(
                fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
                fontWeight: FontWeight.bold,
                fontSize: 19,
                letterSpacing: 0.6,
                color: activeTheme.textPrimary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1.0),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: activeTheme.primary,
              indicatorWeight: 2.5,
              labelColor: activeTheme.primary,
              unselectedLabelColor: activeTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: [
                Tab(icon: const Icon(Icons.dashboard_rounded, size: 18), text: l10n?.tabGmDashboard ?? 'GM Dashboard'),
                Tab(icon: const Icon(Icons.library_music_rounded, size: 18), text: l10n?.tabLibrary ?? 'Media Library'),
                Tab(icon: const Icon(Icons.settings_rounded, size: 18), text: l10n?.tabSettings ?? 'Settings'),
                Tab(icon: const Icon(Icons.grid_view_rounded, size: 18), text: l10n?.tabCatalog ?? 'Catalog'),
              ],
            ),
          ),
        ),
        actions: [
          // Manual Ducking Button
          Consumer<AudioEngineService>(
            builder: (context, engine, _) {
              return IconButton(
                icon: Icon(
                  Icons.volume_down_rounded,
                  color: engine.duckingController.isDucked ? activeTheme.duckingBadge : activeTheme.textSecondary,
                ),
                tooltip: l10n?.manualDuckingTooltip ?? 'Manual Ducking [D]',
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
                        ? (l10n?.unmuteTooltip ?? 'Unmute [M]')
                        : (l10n?.muteTooltip ?? 'Mute [M]'),
                    color: engine.isMuted ? Colors.redAccent : activeTheme.textSecondary,
                    onPressed: () => engine.toggleMute(),
                  ),
                  SizedBox(
                    width: 100,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: activeTheme.primary,
                        thumbColor: activeTheme.primary,
                      ),
                      child: Slider(
                        value: engine.masterVolume,
                        onChanged: (val) => engine.setMasterVolume(val),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Log Console
          Consumer<SettingsService>(
            builder: (context, settings, _) {
              if (!settings.showLogConsoleIcon) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.terminal_rounded, color: activeTheme.primary),
                tooltip: l10n?.logConsoleTooltip ?? 'Open log and debug console',
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
          ResponsiveGmDashboard(),
          LibraryScreen(),
          SettingsScreen(),
          RepositoryCatalogScreen(),
        ],
      ),
    );
  }
}
