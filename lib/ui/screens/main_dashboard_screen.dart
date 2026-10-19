import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../audio/playback/soloud_engine.dart';
import '../../data/services/settings_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/toast.dart';
import '../shell/mixer_bar.dart';
import '../shell/nav_rail.dart';
import '../shell/shell_scope.dart';
import '../widgets/logger_console_drawer.dart';
import 'library_screen.dart';
import 'repository_catalog_screen.dart';
import 'responsive_gm_dashboard.dart';
import 'settings_screen.dart';

enum AppScreen { dashboard, library, catalog, settings }

/// App shell: navigation rail, the active screen and the mixer that stays at
/// the bottom of every screen (music keeps playing between screens). In the
/// compact layout the rail opens as a slide-out panel.
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppScreen _screen = AppScreen.dashboard;
  final Set<AppScreen> _visited = {AppScreen.dashboard};
  StreamSubscription<String>? _loadFailures;
  StreamSubscription<void>? _deviceFailures;

  @override
  void initState() {
    super.initState();
    _loadFailures = SoLoudEngine.instance.loadFailures.listen(_onLoadFailure);
    _deviceFailures = SoLoudEngine.instance.deviceFailures.listen((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.read<ToastController?>()?.error(l10n.toastOutputDeviceFailed, message: l10n.toastOutputDeviceFailedHint);
    });
  }

  @override
  void dispose() {
    _loadFailures?.cancel();
    _deviceFailures?.cancel();
    super.dispose();
  }

  /// A file that could not be played says why, once per attempt.
  void _onLoadFailure(String path) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final m4a = p.extension(path).toLowerCase() == '.m4a';
    final linux = !kIsWeb && Platform.isLinux;
    context.read<ToastController?>()?.error(
          l10n.toastCannotPlay(p.basename(path)),
          message: m4a && linux ? l10n.toastM4aNeedsFfmpeg : l10n.toastCannotPlayHint,
        );
  }

  void _select(AppScreen screen) {
    setState(() {
      _screen = screen;
      _visited.add(screen);
    });
  }

  Widget _build(AppScreen screen) => switch (screen) {
        AppScreen.dashboard => const ResponsiveGmDashboard(),
        AppScreen.library => const LibraryScreen(),
        AppScreen.catalog => const RepositoryCatalogScreen(),
        AppScreen.settings => const SettingsScreen(),
      };

  List<NavItem> _items(AppLocalizations l10n) => [
        NavItem(id: AppScreen.dashboard.name, icon: 'dashboard', label: l10n.tabGmDashboard),
        NavItem(id: AppScreen.library.name, icon: 'library', label: l10n.tabLibrary),
        NavItem(id: AppScreen.catalog.name, icon: 'catalog', label: l10n.tabCatalog),
        NavItem(id: AppScreen.settings.name, icon: 'settings', label: l10n.tabSettings),
      ];

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService?>();
    final layout = ShellLayout.of(MediaQuery.sizeOf(context).width);
    final open = layout == ShellLayout.wide && (settings?.navRailOpen ?? false);

    final screens = IndexedStack(
      index: _screen.index,
      children: [
        for (final screen in AppScreen.values)
          if (_visited.contains(screen)) _build(screen) else const SizedBox.shrink(),
      ],
    );

    return ShellScope(
      layout: layout,
      openNavigation: () => _scaffoldKey.currentState?.openDrawer(),
      openLogs: () => _scaffoldKey.currentState?.openEndDrawer(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: ds.bg,
        endDrawer: const LoggerConsoleDrawer(),
        drawer: layout == ShellLayout.compact
            ? Drawer(
                width: Sizes.railWidthOpen,
                backgroundColor: ds.surface,
                shape: const RoundedRectangleBorder(),
                child: SafeArea(
                  child: NavRail(
                    items: _items(l10n),
                    active: _screen.name,
                    open: true,
                    toggleLabel: l10n.collapseSidebarTooltip,
                    onSelect: (id) {
                      _select(AppScreen.values.byName(id));
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              )
            : null,
        body: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (layout != ShellLayout.compact)
                    NavRail(
                      items: _items(l10n),
                      active: _screen.name,
                      open: open,
                      toggleLabel: open ? l10n.collapseSidebarTooltip : l10n.expandSidebarTooltip,
                      onToggle: layout == ShellLayout.wide ? () => settings?.setNavRailOpen(!open) : null,
                      onSelect: (id) => _select(AppScreen.values.byName(id)),
                    ),
                  Expanded(child: screens),
                ],
              ),
            ),
            const MixerBar(),
          ],
        ),
      ),
    );
  }
}
