import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/music_bus_controller.dart';
import '../../models/audio_track.dart';

class MusicPlayerPanel extends StatelessWidget {
  const MusicPlayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicBusController>(
      builder: (context, music, _) {
        final track = music.currentTrack;

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Музыкальная дорожка',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  track != null ? 'Сейчас играет: ${track.title}' : 'Музыка не воспроизводится',
                  style: TextStyle(
                    color: track != null ? Colors.greenAccent : Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),

                // Intensity Selector Chips
                const Text('Уровень Интенсивности:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  key: const ValueKey('music_intensity_wrap'),
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: MusicIntensity.values.map((intensity) {
                    final isSelected = music.currentIntensity == intensity;
                    return InkWell(
                      key: ValueKey('chip_${intensity.name}'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => music.setIntensity(intensity),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFF2C2C3A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          intensity.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Playback Controls & Volume Slider
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('music_play_pause_button'),
                      icon: Icon(music.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                      iconSize: 40,
                      onPressed: () {
                        if (music.isPlaying) {
                          music.pause();
                        } else {
                          music.resume();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.volume_down),
                          Expanded(
                            child: Slider(
                              key: const ValueKey('music_volume_slider'),
                              value: music.rawVolume,
                              onChanged: (val) => music.setVolume(val),
                            ),
                          ),
                          const Icon(Icons.volume_up),
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
