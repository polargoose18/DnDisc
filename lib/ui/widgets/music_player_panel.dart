import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../audio/music_bus_controller.dart';
import '../../domain/models/audio_track.dart';
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
                          l10n?.musicTrack ?? 'Музыкальная дорожка',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
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
                            ? '${l10n?.nowPlaying ?? "Сейчас играет"}: ${track.title} ${music.isPlaying ? '' : (l10n?.pausedSuffix ?? '(Пауза)')}'
                            : (l10n?.musicNotPlaying ?? 'Музыка не воспроизводится'),
                        style: TextStyle(
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

                // Intensity Selector Chips with Hotkey Badges
                Row(
                  children: [
                    Text(
                      '${l10n?.intensityLevel ?? "Уровень Интенсивности"}:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: activeTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  key: const ValueKey('music_intensity_wrap'),
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: MusicIntensity.values.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final intensity = entry.value;
                    final isSelected = music.currentIntensity == intensity;
                    final chipColor = _getIntensityColor(intensity, activeTheme);

                    return InkWell(
                      key: ValueKey('chip_${intensity.name}'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => music.setIntensity(intensity),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.4),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: chipColor.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black26 : Colors.white12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$index',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : activeTheme.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              intensity.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : activeTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                      tooltip: music.isPlaying ? 'Пауза [Space]' : 'Воспроизведение [Space]',
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
                      tooltip: l10n?.stopMusic ?? 'Остановить музыку',
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
                            style: TextStyle(fontSize: 12, color: activeTheme.textSecondary),
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

  Color _getIntensityColor(MusicIntensity intensity, dynamic activeTheme) {
    switch (intensity) {
      case MusicIntensity.calm:
        return activeTheme.secondary;
      case MusicIntensity.suspense:
        return const Color(0xFFF59E0B); // Amber
      case MusicIntensity.battle:
        return activeTheme.battleIntensity;
      case MusicIntensity.boss:
        return activeTheme.bossIntensity;
    }
  }
}
