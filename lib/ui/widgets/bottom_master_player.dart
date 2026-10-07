import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../audio/music_bus_controller.dart';
import '../../audio/audio_engine_service.dart';
import '../../data/services/settings_service.dart';

/// Desktop bottom master player bar with global playback, ducking, and volume controls.
class BottomMasterPlayer extends StatelessWidget {
  final VoidCallback? onExpand;
  final VoidCallback? onOpenLogConsole;

  const BottomMasterPlayer({
    super.key,
    this.onExpand,
    this.onOpenLogConsole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    // Safely retrieve controllers if available in the widget tree
    final audioEngine = _safeWatch<AudioEngineService>(context);
    final music = _safeWatch<MusicBusController>(context) ?? audioEngine?.musicBus;
    final settings = _safeWatch<SettingsService>(context);

    final track = music?.currentTrack;
    final isPlaying = music?.isPlaying ?? false;
    final isMuted = audioEngine?.isMuted ?? false;
    final masterVolume = audioEngine?.masterVolume ?? 1.0;

    return Container(
      height: 60.0,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          final isVeryNarrow = constraints.maxWidth < 480;

          return Row(
            children: [
              // Left: Track Info & Icon (fills available remaining space with text ellipsis)
              Expanded(
                child: InkWell(
                  onTap: onExpand,
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: colorScheme.onSecondaryContainer,
                            size: 18.0,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track != null ? track.title : (l10n?.noMusic ?? 'No music'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.0,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1.0),
                              Text(
                                isPlaying
                                    ? (l10n?.playing ?? 'Playing')
                                    : (l10n?.paused ?? 'Paused'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11.0,
                                  color: isPlaying
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8.0),

              // Middle: Playback Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Manual Ducking
                  Tooltip(
                    message: l10n?.manualDuckingTooltip ?? 'Manual Ducking [D]',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: IconButton(
                        icon: const Icon(Icons.volume_down_rounded),
                        color: colorScheme.onSurfaceVariant,
                        iconSize: 20.0,
                        padding: const EdgeInsets.all(6.0),
                        constraints: const BoxConstraints(),
                        onPressed: audioEngine == null ? null : () => audioEngine.triggerManualDuck(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4.0),

                  // Play / Pause Button
                  Tooltip(
                    message: isPlaying
                        ? (l10n?.pauseTooltip ?? 'Pause [Space]')
                        : (l10n?.playTooltip ?? 'Play [Space]'),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                        ),
                        color: colorScheme.primary,
                        iconSize: 32.0,
                        padding: const EdgeInsets.all(4.0),
                        constraints: const BoxConstraints(),
                        onPressed: music == null
                            ? null
                            : () {
                                if (music.isPlaying) {
                                  music.pause();
                                } else {
                                  music.resume();
                                }
                              },
                      ),
                    ),
                  ),

                  const SizedBox(width: 4.0),

                  // Panic Stop SFX
                  Tooltip(
                    message: l10n?.panicStopTooltip ?? 'Panic Stop SFX [Esc]',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: IconButton(
                        icon: const Icon(Icons.dangerous_rounded),
                        color: colorScheme.error,
                        iconSize: 20.0,
                        padding: const EdgeInsets.all(6.0),
                        constraints: const BoxConstraints(),
                        onPressed: audioEngine == null ? null : () => audioEngine.panicStopSfx(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8.0),

              // Right: Master Volume & Console
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Mute / Unmute
                  Tooltip(
                    message: isMuted
                        ? (l10n?.unmuteTooltip ?? 'Unmute [M]')
                        : (l10n?.muteTooltip ?? 'Mute [M]'),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: IconButton(
                        icon: Icon(
                          isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        ),
                        color: isMuted ? colorScheme.error : colorScheme.onSurfaceVariant,
                        iconSize: 20.0,
                        padding: const EdgeInsets.all(6.0),
                        constraints: const BoxConstraints(),
                        onPressed: audioEngine == null ? null : () => audioEngine.toggleMute(),
                      ),
                    ),
                  ),

                  // Master Volume Slider
                  if (!isVeryNarrow) ...[
                    SizedBox(
                      width: isNarrow ? 70.0 : 100.0,
                      child: Tooltip(
                        message: '${l10n?.masterVolumeLabel ?? 'Master Volume'}: ${(masterVolume * 100).toInt()}%',
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 8.0),
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor: colorScheme.surfaceContainerHighest,
                            thumbColor: colorScheme.primary,
                            overlayColor: colorScheme.primary.withValues(alpha: 0.12),
                          ),
                          child: Slider(
                            value: masterVolume,
                            semanticFormatterCallback: (val) => '${(val * 100).toInt()}%',
                            onChanged: audioEngine == null ? null : (val) => audioEngine.setMasterVolume(val),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(width: 2.0),

                  SizedBox(
                    width: 32.0,
                    child: Text(
                      '${(masterVolume * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  if (!isNarrow && settings?.showLogConsoleIcon == true) ...[
                    const SizedBox(width: 4.0),
                    Tooltip(
                      message: l10n?.logConsoleTooltip ?? 'Open log and debug console',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: IconButton(
                          icon: const Icon(Icons.terminal_rounded),
                          color: colorScheme.secondary,
                          iconSize: 18.0,
                          padding: const EdgeInsets.all(6.0),
                          constraints: const BoxConstraints(),
                          onPressed: onOpenLogConsole,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static T? _safeWatch<T extends Object>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: true);
    } catch (_) {
      return null;
    }
  }
}
