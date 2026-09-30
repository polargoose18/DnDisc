import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../audio/music_bus_controller.dart';
import '../../audio/audio_engine_service.dart';
import '../../ui/view_models/theme_view_model.dart';

import '../../theme/app_themes.dart';

class StickyMiniPlayer extends StatelessWidget {
  final VoidCallback? onExpand;

  const StickyMiniPlayer({super.key, this.onExpand});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel?>();
    final activeTheme = themeViewModel?.activeTheme ?? AppThemes.deepDark;
    final music = context.watch<MusicBusController>();
    final audioEngine = context.watch<AudioEngineService>();
    final l10n = AppLocalizations.of(context);
    final track = music.currentTrack;

    return Container(
      decoration: BoxDecoration(
        color: activeTheme.surface,
        border: Border(
          top: BorderSide(color: activeTheme.primary.withValues(alpha: 0.4), width: 1.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Track Info / Icon
            InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: activeTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: activeTheme.primary, width: 0.8),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: activeTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track != null ? track.title : (l10n?.noMusic ?? 'No music'),
                          style: TextStyle(
                            color: activeTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          music.isPlaying
                              ? (l10n?.playing ?? 'Playing')
                              : (l10n?.paused ?? 'Paused'),
                          style: TextStyle(
                            color: music.isPlaying ? Colors.greenAccent : activeTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Quick Play / Pause Button
            IconButton(
              icon: Icon(
                music.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: activeTheme.primary,
                size: 32,
              ),
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

            // Panic Stop SFX button
            IconButton(
              icon: const Icon(Icons.dangerous_rounded, color: Colors.redAccent, size: 24),
              tooltip: l10n?.panicStopTooltip ?? 'Panic Stop SFX [Esc]',
              onPressed: () => audioEngine.panicStopSfx(),
            ),

            // Master Volume quick slider
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 110,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: activeTheme.primary,
                      thumbColor: activeTheme.primary,
                    ),
                    child: Slider(
                      value: audioEngine.masterVolume,
                      onChanged: (val) => audioEngine.setMasterVolume(val),
                    ),
                  ),
                ),
                Text(
                  '${(audioEngine.masterVolume * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: activeTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
