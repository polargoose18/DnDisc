import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../audio/music_bus_controller.dart';
import '../../ui/view_models/theme_view_model.dart';

import '../../domain/models/custom_theme_model.dart';
import '../../theme/app_themes.dart';

class MusicPlayerPanel extends StatelessWidget {
  const MusicPlayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.select<ThemeViewModel?, CustomThemeModel>(
      (vm) => vm?.activeTheme ?? AppThemes.deepDark,
    );
    final l10n = AppLocalizations.of(context);

    return Consumer<MusicBusController>(
      builder: (context, music, _) {
        final track = music.currentTrack;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.music_note_rounded, color: activeTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.musicTrack ?? 'Music Track',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                            color: activeTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: music.isPlaying ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        track != null
                            ? '${l10n?.nowPlaying ?? "Now playing"}: ${track.title} ${music.isPlaying ? '' : (l10n?.pausedSuffix ?? '(Paused)')}'
                            : (l10n?.musicNotPlaying ?? 'Music is not playing'),
                        style: GoogleFonts.inter(
                          color: track != null ? activeTheme.textPrimary : activeTheme.textSecondary,
                          fontWeight: track != null ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Playback Controls & Volume Slider
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('music_play_pause_button'),
                      icon: Icon(music.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                      iconSize: 42,
                      color: activeTheme.primary,
                      tooltip: music.isPlaying
                          ? (l10n?.pauseTooltip ?? 'Pause [Space]')
                          : (l10n?.playTooltip ?? 'Play [Space]'),
                      onPressed: () {
                        if (music.isPlaying) {
                          music.pause();
                        } else {
                          music.resume();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop_circle_outlined),
                      iconSize: 32,
                      color: activeTheme.textSecondary,
                      tooltip: l10n?.stopMusic ?? 'Stop music',
                      onPressed: () => music.stop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.volume_down, size: 20, color: activeTheme.textSecondary),
                          Expanded(
                            child: Slider(
                              key: const ValueKey('music_volume_slider'),
                              value: music.rawVolume,
                              onChanged: (val) => music.setVolume(val),
                            ),
                          ),
                          Text(
                            '${(music.rawVolume * 100).toInt()}%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: activeTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.volume_up, size: 20, color: activeTheme.textSecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
