import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/library_track.dart';
import '../../ui/view_models/media_library_view_model.dart';
import '../screens/responsive_gm_dashboard.dart';
import '../screens/library_screen.dart';
import '../screens/repository_catalog_screen.dart';
import '../screens/settings_screen.dart';
import 'sidebar_tree.dart';
import 'bottom_master_player.dart';
import 'logger_console_drawer.dart';

export 'sidebar_tree.dart';
export 'bottom_master_player.dart';
export '../screens/responsive_gm_dashboard.dart' show GmDashboardScreen;

/// Custom ScrollBehavior optimized for desktop environments:
/// disables mobile glow/stretch overscroll indicators and clamps mouse wheel events.
class DesktopScrollBehavior extends MaterialScrollBehavior {
  const DesktopScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

/// Desktop application layout shell adhering to Zen Minimalist widescreen desktop architecture.
///
/// Features:
/// 1. Three-column desktop layout:
///    - Navigation Rail (~64px): Compact icons, active state pill/strip, hamburger menu.
///    - SidebarTree (~250px): Obsidian/VS Code category tree for scenes and media library folders.
///    - Main Content Area (Expanded): Defaults to [GmDashboardScreen], switches via rail.
/// 2. Sticky Bottom Bar (~60px): Global [BottomMasterPlayer] spanning under all columns.
/// 3. Subtle 1px dividers styled with `colorScheme.outlineVariant`.
/// 4. Desktop mouse scrolling behavior without mobile overscroll physics.
class AppLayoutShell extends StatefulWidget {
  final Widget? child;
  final int initialNavIndex;
  final ValueChanged<int>? onNavIndexChanged;
  final bool initialSidebarOpen;
  final ValueChanged<String>? onSceneSelected;
  final ValueChanged<String>? onFolderSelected;

  const AppLayoutShell({
    super.key,
    this.child,
    this.initialNavIndex = 0,
    this.onNavIndexChanged,
    this.initialSidebarOpen = true,
    this.onSceneSelected,
    this.onFolderSelected,
  });

  @override
  State<AppLayoutShell> createState() => _AppLayoutShellState();
}

class _AppLayoutShellState extends State<AppLayoutShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedNavIndex;
  late bool _isSidebarOpen;
  String? _selectedFolderId;
  int? _hoveredRailIndex;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
    _isSidebarOpen = widget.initialSidebarOpen;
  }

  @override
  void didUpdateWidget(covariant AppLayoutShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialNavIndex != oldWidget.initialNavIndex) {
      _selectedNavIndex = widget.initialNavIndex;
    }
    if (widget.initialSidebarOpen != oldWidget.initialSidebarOpen) {
      _isSidebarOpen = widget.initialSidebarOpen;
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    widget.onNavIndexChanged?.call(index);
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final navItems = [
      _RailItemData(
        icon: Icons.dashboard_rounded,
        label: l10n?.tabGmDashboard ?? 'GM Dashboard',
      ),
      _RailItemData(
        icon: Icons.library_music_rounded,
        label: l10n?.tabLibrary ?? 'Media Library',
      ),
      _RailItemData(
        icon: Icons.grid_view_rounded,
        label: l10n?.tabCatalog ?? 'Catalog',
      ),
      _RailItemData(
        icon: Icons.settings_rounded,
        label: l10n?.tabSettings ?? 'Settings',
      ),
    ];

    return ScrollConfiguration(
      behavior: const DesktopScrollBehavior(),
      child: Theme(
        data: theme.copyWith(
          dividerTheme: theme.dividerTheme.copyWith(
            color: colorScheme.outlineVariant,
            space: 1.0,
            thickness: 1.0,
          ),
        ),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: colorScheme.surface,
          endDrawer: const LoggerConsoleDrawer(),
          body: Column(
            children: [
              // Top Section: Horizontal 3-Column Work Area
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Column 1: Navigation Rail (~64px)
                    Container(
                      width: 64.0,
                      color: colorScheme.surface,
                      child: Column(
                        children: [
                          const SizedBox(height: 10.0),
                          // Hamburger Menu Button with context-aware tooltip
                          Tooltip(
                            message: _isSidebarOpen
                                ? (l10n?.collapseSidebarTooltip ?? 'Collapse sidebar')
                                : (l10n?.expandSidebarTooltip ?? 'Expand sidebar'),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: IconButton(
                                icon: const Icon(Icons.menu_rounded),
                                color: colorScheme.onSurfaceVariant,
                                iconSize: 22.0,
                                onPressed: _toggleSidebar,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          // Navigation Items
                          ...List.generate(navItems.length, (index) {
                            final item = navItems[index];
                            final isActive = _selectedNavIndex == index;
                            final isHovered = _hoveredRailIndex == index;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Tooltip(
                                message: item.label,
                                preferBelow: false,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) => setState(() => _hoveredRailIndex = index),
                                  onExit: (_) => setState(() => _hoveredRailIndex = null),
                                  child: GestureDetector(
                                    onTap: () => _onNavTapped(index),
                                    child: Container(
                                      width: 48.0,
                                      height: 48.0,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? colorScheme.secondaryContainer
                                            : (isHovered
                                                ? colorScheme.onSurface.withValues(alpha: 0.08)
                                                : Colors.transparent),
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Left Indicator Strip for active item
                                          if (isActive)
                                            Positioned(
                                              left: 0,
                                              child: Container(
                                                width: 3.0,
                                                height: 24.0,
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary,
                                                  borderRadius: const BorderRadius.only(
                                                    topRight: Radius.circular(3.0),
                                                    bottomRight: Radius.circular(3.0),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Icon(
                                            item.icon,
                                            size: 22.0,
                                            color: isActive
                                                ? colorScheme.primary
                                                : (isHovered
                                                    ? colorScheme.onSurface
                                                    : colorScheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const Spacer(),
                        ],
                      ),
                    ),

                    // Divider between Rail and Sidebar
                    VerticalDivider(
                      width: 1.0,
                      thickness: 1.0,
                      color: colorScheme.outlineVariant,
                    ),

                    // Column 2: Sidebar Scene Tree (~250px)
                    if (_isSidebarOpen) ...[
                      SidebarTree(
                        activeFolderId: _selectedNavIndex == 1 ? _selectedFolderId : null,
                        onSceneSelected: (sceneId) {
                          widget.onSceneSelected?.call(sceneId);
                          if (_selectedNavIndex != 0) {
                            _onNavTapped(0); // Switch to GM Dashboard when a scene is tapped
                          }
                        },
                        onFolderSelected: (folderId) {
                          setState(() {
                            _selectedFolderId = folderId;
                          });
                          widget.onFolderSelected?.call(folderId);

                          // Optionally route media filter in MediaLibraryViewModel
                          final mediaLib = _safeRead<MediaLibraryViewModel>(context);
                          if (mediaLib != null) {
                            if (folderId == 'music') {
                              mediaLib.setBusFilter(AudioBusType.music);
                            } else if (folderId == 'ambient') {
                              mediaLib.setBusFilter(AudioBusType.ambient);
                            } else if (folderId == 'sfx') {
                              mediaLib.setBusFilter(AudioBusType.sfx);
                            } else if (folderId == 'foley') {
                              mediaLib.setBusFilter(AudioBusType.sfx);
                              mediaLib.setSearchQuery('foley');
                            }
                          }

                          _onNavTapped(1); // Switch to Media Library tab
                        },
                      ),

                      // Divider between Sidebar and Main Content
                      VerticalDivider(
                        width: 1.0,
                        thickness: 1.0,
                        color: colorScheme.outlineVariant,
                      ),
                    ],

                    // Column 3: Main Stage / Content Area (Expanded)
                    Expanded(
                      child: Container(
                        color: colorScheme.surface,
                        child: widget.child ?? _buildMainScreen(_selectedNavIndex),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Sticky Master Player (~60px)
              BottomMasterPlayer(
                onExpand: () {
                  if (_selectedNavIndex != 0) {
                    _onNavTapped(0);
                  }
                },
                onOpenLogConsole: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen(int index) {
    switch (index) {
      case 0:
        return const GmDashboardScreen();
      case 1:
        return const LibraryScreen();
      case 2:
        return const RepositoryCatalogScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const GmDashboardScreen();
    }
  }

  static T? _safeRead<T extends Object>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: false);
    } catch (_) {
      return null;
    }
  }
}

class _RailItemData {
  final IconData icon;
  final String label;

  const _RailItemData({
    required this.icon,
    required this.label,
  });
}
