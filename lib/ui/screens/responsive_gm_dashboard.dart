import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/scene_selector_panel.dart';
import '../widgets/scene_backdrop_header.dart';
import '../widgets/music_player_panel.dart';
import '../widgets/ambient_mixer_panel.dart';
import '../widgets/soundboard_grid.dart';
import '../widgets/sticky_mini_player.dart';

class ResponsiveGmDashboard extends StatefulWidget {
  const ResponsiveGmDashboard({super.key});

  @override
  State<ResponsiveGmDashboard> createState() => _ResponsiveGmDashboardState();
}

class _ResponsiveGmDashboardState extends State<ResponsiveGmDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _compactTabController;

  @override
  void initState() {
    super.initState();
    _compactTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _compactTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000 || MediaQuery.of(context).size.width >= 1000;

        if (isDesktop) {
          return _buildDesktop3ColumnLayout(constraints.maxWidth);
        } else {
          return _buildMobileCompactTabbedLayout(l10n);
        }
      },
    );
  }

  Widget _buildDesktop3ColumnLayout(double availableWidth) {
    final isWideWorkstation = availableWidth >= 950;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar: Scenes Gallery (295px)
          const SizedBox(
            width: 295,
            child: SceneSelectorPanel(isVertical: true),
          ),
          const SizedBox(width: 12),

          // Main Center Stage: Hero + Workstation
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Scene Hero Centerpiece at the top
                  const SceneBackdropHeader(),
                  const SizedBox(height: 4),

                  // Workstation: Side-by-side on wide screens, stacked on medium screens
                  if (isWideWorkstation)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              MusicPlayerPanel(),
                              AmbientMixerPanel(),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: SoundboardGrid(),
                        ),
                      ],
                    )
                  else
                    const Column(
                      children: [
                        MusicPlayerPanel(),
                        AmbientMixerPanel(),
                        SizedBox(height: 8),
                        SoundboardGrid(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCompactTabbedLayout(AppLocalizations? l10n) {
    return Column(
      children: [
        // Sub-tabs for GM Dashboard in Compact Mode
        Container(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: TabBar(
            controller: _compactTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: const Icon(Icons.theater_comedy_rounded, size: 18), text: l10n?.scenes ?? 'Scenes'),
              Tab(icon: const Icon(Icons.music_note_rounded, size: 18), text: l10n?.music ?? 'Music'),
              Tab(icon: const Icon(Icons.waves_rounded, size: 18), text: l10n?.ambient ?? 'Ambient'),
              Tab(icon: const Icon(Icons.campaign_rounded, size: 18), text: l10n?.sfx ?? 'SFX'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _compactTabController,
            children: const [
              SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    SceneBackdropHeader(),
                    SceneSelectorPanel(isVertical: false),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    SceneBackdropHeader(),
                    MusicPlayerPanel(),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    SceneBackdropHeader(),
                    AmbientMixerPanel(),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: SoundboardGrid(),
              ),
            ],
          ),
        ),

        // Sticky MiniPlayer at the bottom of compact view
        StickyMiniPlayer(
          onExpand: () {
            _compactTabController.animateTo(1); // switch to Music tab
          },
        ),
      ],
    );
  }
}
