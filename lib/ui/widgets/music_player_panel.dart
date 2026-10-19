import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/music_bus_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_panel.dart';
import 'music_equalizer.dart';

String formatDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Music card: track title, state badge, equalizer, play/pause, stop and the
/// position. Intensity lives in the scene header and volume in the mixer.
class MusicPlayerPanel extends StatelessWidget {
  const MusicPlayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final music = context.watch<MusicBusController>();
    final track = music.currentTrack;
    final playing = music.isPlaying;

    return DsPanel(
      title: l10n.music,
      icon: 'music',
      trailing: track == null
          ? null
          : DsBadge(
              playing ? l10n.playing : l10n.paused,
              tone: playing ? DsTone.primary : DsTone.neutral,
              dot: true,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            track?.title ?? l10n.noMusic,
            style: ds.title.copyWith(color: track == null ? ds.textMuted : ds.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(
            padding: EdgeInsets.only(top: Spacing.s2, bottom: Spacing.s4),
            child: MusicEqualizer(bars: 48, height: Spacing.s6, wide: true),
          ),
          Row(
            children: [
              DsButton.transport(
                key: const ValueKey('music_play_pause_button'),
                icon: playing ? 'pause' : 'play',
                label: playing ? l10n.pauseTooltip : l10n.playTooltip,
                hotkey: 'Space',
                onPressed: track == null
                    ? null
                    : () {
                        if (playing) {
                          music.pause();
                        } else {
                          music.resume();
                        }
                      },
              ),
              const SizedBox(width: Spacing.s2),
              DsButton.ghost(
                key: const ValueKey('music_stop_button'),
                icon: 'stop',
                iconOnly: true,
                label: l10n.stopMusic,
                onPressed: track == null ? null : () => music.stop(),
              ),
              const SizedBox(width: Spacing.s4),
              Expanded(
                child: ValueListenableBuilder<Duration>(
                  valueListenable: music.position,
                  builder: (context, position, _) {
                    final total = music.trackDuration ?? Duration.zero;
                    final fraction = total.inMilliseconds == 0 ? 0.0 : position.inMilliseconds / total.inMilliseconds;
                    return Row(
                      children: [
                        Text(formatDuration(track == null ? Duration.zero : position), style: ds.tabular(ds.caption)),
                        const SizedBox(width: Spacing.s3),
                        Expanded(child: DsProgressBar(value: track == null ? 0 : fraction.clamp(0.0, 1.0), showValue: false)),
                        const SizedBox(width: Spacing.s3),
                        Text(formatDuration(total), style: ds.tabular(ds.caption)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
