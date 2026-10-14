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

    return SizedBox(
      height: 64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

        return Container(
          decoration: BoxDecoration(
            color: activeTheme.surface,
            border: Border(
              top: BorderSide(color: activeTheme.primary.withValues(alpha: 0.25), width: 1.0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 8),
          child: SafeArea(
            top: false,
            child: isCompact
                ? Row(
                    children: [
                      // Left: Track Info & Artwork
                      Expanded(
                        child: InkWell(
                          onTap: onExpand,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: activeTheme.card,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: activeTheme.primary.withValues(alpha: 0.4), width: 1.0),
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: activeTheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      track != null ? track.title : (l10n?.noMusic ?? 'No music'),
                                      style: TextStyle(
                                        color: activeTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Play / Pause Button
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
                      // Master Mute
                      IconButton(
                        icon: Icon(
                          audioEngine.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          size: 20,
                        ),
                        tooltip: audioEngine.isMuted
                            ? (l10n?.unmuteTooltip ?? 'Unmute [M]')
                            : (l10n?.muteTooltip ?? 'Mute [M]'),
                        color: audioEngine.isMuted ? Colors.redAccent : activeTheme.textSecondary,
                        onPressed: () => audioEngine.toggleMute(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Left: Track Info & Artwork
                      InkWell(
                        onTap: onExpand,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: activeTheme.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: activeTheme.primary.withValues(alpha: 0.4), width: 1.0),
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: activeTheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 180),
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
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: music.isPlaying ? Colors.greenAccent : activeTheme.textSecondary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          music.isPlaying
                                              ? (l10n?.playing ?? 'Playing')
                                              : (l10n?.paused ?? 'Paused'),
                                          style: TextStyle(
                                            color: music.isPlaying ? Colors.greenAccent : activeTheme.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Center: Transport Controls
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.stop_circle_outlined, size: 22),
                                color: activeTheme.textSecondary,
                                tooltip: l10n?.stopMusic ?? 'Stop music',
                                onPressed: () => music.stop(),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(
                                  music.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                  color: activeTheme.primary,
                                  size: 36,
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right: Master Controls (Mute, Volume)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Master Mute
                          IconButton(
                            icon: Icon(
                              audioEngine.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              size: 20,
                            ),
                            tooltip: audioEngine.isMuted
                                ? (l10n?.unmuteTooltip ?? 'Unmute [M]')
                                : (l10n?.muteTooltip ?? 'Mute [M]'),
                            color: audioEngine.isMuted ? Colors.redAccent : activeTheme.textSecondary,
                            onPressed: () => audioEngine.toggleMute(),
                          ),
                          // Master Volume Slider
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
      },
    ),
  );
  }
}
