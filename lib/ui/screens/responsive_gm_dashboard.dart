import 'package:flutter/material.dart' hide Durations;
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_icon.dart';
import '../design/ds_interactive.dart';
import '../shell/shell_scope.dart';
import '../shell/top_bar.dart';
import '../widgets/ambient_mixer_panel.dart';
import '../widgets/music_player_panel.dart';
import '../widgets/scene_backdrop_header.dart';
import '../widgets/scene_selector_panel.dart';
import '../widgets/soundboard_grid.dart';

enum _CompactTab { scenes, music, ambient, sfx }

/// GM Dashboard. Wide: scenes panel, scene header and two columns (Music and
/// Ambient | SFX). Medium: one column, scenes in a slide-out panel. Compact:
/// header once and four bottom tabs.
class ResponsiveGmDashboard extends StatefulWidget {
  const ResponsiveGmDashboard({super.key});

  @override
  State<ResponsiveGmDashboard> createState() => _ResponsiveGmDashboardState();
}

class _ResponsiveGmDashboardState extends State<ResponsiveGmDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  _CompactTab _tab = _CompactTab.scenes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ds = context.ds;
    final layout = ShellScope.maybeOf(context)?.layout ?? ShellLayout.of(MediaQuery.sizeOf(context).width);

    final Widget body = switch (layout) {
      ShellLayout.wide => _wide(),
      ShellLayout.medium => _medium(),
      ShellLayout.compact => _compact(l10n),
    };

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Palette.transparent,
      drawer: layout == ShellLayout.medium
          ? Drawer(
              width: Sizes.scenesWidth + Spacing.s4 * 2,
              backgroundColor: ds.bg,
              shape: const RoundedRectangleBorder(),
              child: const SafeArea(child: Padding(padding: EdgeInsets.all(Spacing.s4), child: SceneSelectorPanel())),
            )
          : null,
      body: Column(
        children: [
          TopBar(
            title: l10n.tabGmDashboard,
            navigationLabel: l10n.openNavigation,
            leading: [
              if (layout == ShellLayout.medium)
                DsButton.ghost(
                  key: const ValueKey('show_scenes_btn'),
                  icon: 'scene',
                  iconOnly: true,
                  label: l10n.showScenes,
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
            ],
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _wide() {
    return const Padding(
      padding: EdgeInsets.all(Spacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: Sizes.scenesWidth, child: SceneSelectorPanel()),
          SizedBox(width: Spacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SceneBackdropHeader(),
                SizedBox(height: Spacing.s4),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 12,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              MusicPlayerPanel(),
                              SizedBox(height: Spacing.s4),
                              AmbientMixerPanel(),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: Spacing.s4),
                      Expanded(flex: 10, child: SoundboardGrid()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medium() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(Spacing.s4),
      child: Column(
        children: [
          SceneBackdropHeader(),
          SizedBox(height: Spacing.s4),
          MusicPlayerPanel(),
          SizedBox(height: Spacing.s4),
          SoundboardGrid(),
          SizedBox(height: Spacing.s4),
          AmbientMixerPanel(),
        ],
      ),
    );
  }

  Widget _compact(AppLocalizations l10n) {
    final Widget content = switch (_tab) {
      _CompactTab.scenes => const SceneSelectorPanel(),
      _CompactTab.music => const SingleChildScrollView(child: MusicPlayerPanel()),
      _CompactTab.ambient => const SingleChildScrollView(child: AmbientMixerPanel()),
      _CompactTab.sfx => const SoundboardGrid(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SceneBackdropHeader(),
                const SizedBox(height: Spacing.s4),
                Expanded(child: content),
              ],
            ),
          ),
        ),
        _CompactTabs(
          active: _tab,
          labels: {
            _CompactTab.scenes: l10n.scenes,
            _CompactTab.music: l10n.music,
            _CompactTab.ambient: l10n.ambient,
            _CompactTab.sfx: l10n.sfx,
          },
          onChanged: (t) => setState(() => _tab = t),
        ),
      ],
    );
  }
}

class _CompactTabs extends StatelessWidget {
  final _CompactTab active;
  final Map<_CompactTab, String> labels;
  final ValueChanged<_CompactTab> onChanged;

  static const Map<_CompactTab, String> _icons = {
    _CompactTab.scenes: 'scene',
    _CompactTab.music: 'music',
    _CompactTab.ambient: 'waves',
    _CompactTab.sfx: 'bolt',
  };

  const _CompactTabs({required this.active, required this.labels, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.all(Spacing.s2),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ds.border, width: Sizes.borderWidth)),
      ),
      child: Row(
        children: [
          for (final tab in _CompactTab.values)
            Expanded(
              child: DsInteractive(
                key: ValueKey('compact_tab_${tab.name}'),
                onTap: () => onChanged(tab),
                selected: tab == active,
                semanticLabel: labels[tab],
                builder: (context, s) {
                  final selected = tab == active;
                  final color = selected ? ds.primary : (s.hovered ? ds.text : ds.textMuted);
                  return AnimatedContainer(
                    duration: Durations.fast,
                    height: Sizes.targetLg,
                    decoration: BoxDecoration(
                      color: selected ? ds.primarySubtle : (s.hovered ? ds.surfaceHover : Palette.transparent),
                      borderRadius: Radii.mdAll,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DsIcon(_icons[tab]!, color: color),
                        const SizedBox(width: Spacing.s2),
                        Flexible(
                          child: Text(
                            labels[tab]!,
                            style: ds.body.copyWith(fontWeight: FontWeight.w500, color: color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
