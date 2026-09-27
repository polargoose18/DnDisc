import 'package:flutter/material.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000 || MediaQuery.of(context).size.width >= 1000;

        if (isDesktop) {
          return _buildDesktop3ColumnLayout();
        } else {
          return _buildMobileCompactTabbedLayout();
        }
      },
    );
  }

  Widget _buildDesktop3ColumnLayout() {
    return const Padding(
      padding: EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column 1: Scenes Gallery (320px)
          SizedBox(
            width: 320,
            child: SceneSelectorPanel(isVertical: true),
          ),
          SizedBox(width: 12),

          // Column 2: Center Stage (Scene Backdrop + Music + Ambient)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SceneBackdropHeader(),
                  MusicPlayerPanel(),
                  AmbientMixerPanel(),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),

          // Column 3: Soundboard SFX (340px)
          SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: SoundboardGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCompactTabbedLayout() {
    return Column(
      children: [
        // Sub-tabs for GM Dashboard in Compact Mode
        Container(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: TabBar(
            controller: _compactTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.theater_comedy_rounded, size: 18), text: 'Сцены'),
              Tab(icon: Icon(Icons.music_note_rounded, size: 18), text: 'Музыка'),
              Tab(icon: Icon(Icons.waves_rounded, size: 18), text: 'Эмбиент'),
              Tab(icon: Icon(Icons.campaign_rounded, size: 18), text: 'SFX'),
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
