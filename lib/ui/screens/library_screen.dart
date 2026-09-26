import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/library_track.dart';
import '../../services/media_library_service.dart';
import '../../audio/audio_engine_service.dart';
import '../widgets/import_track_dialog.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MediaLibraryService, AudioEngineService>(
      builder: (context, library, audioEngine, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action & Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('library_search_input'),
                        decoration: const InputDecoration(
                          hintText: 'Поиск по названию или тегам (например, Таверна, Бой)...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (val) => library.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      key: const ValueKey('import_media_button'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        backgroundColor: const Color(0xFF673AB7),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _handleImport(context, library),
                      icon: const Icon(Icons.file_upload_rounded, color: Colors.white),
                      label: const Text(
                        'Импорт файлов',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bus Filter Chips
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Все звуки'),
                      selected: library.activeBusFilter == null,
                      onSelected: (_) => library.setBusFilter(null),
                    ),
                    ...AudioBusType.values.map((bus) {
                      return FilterChip(
                        label: Text(bus.displayName),
                        selected: library.activeBusFilter == bus,
                        onSelected: (selected) {
                          library.setBusFilter(selected ? bus : null);
                        },
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 12),

                // Track List View
                Expanded(
                  child: library.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : library.tracks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.library_music_outlined, size: 64, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Медиабиблиотека пуста',
                                    style: TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Нажмите "Импорт файлов", чтобы добавить музыку, эмбиент или SFX.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _handleImport(context, library),
                                    icon: const Icon(Icons.file_upload_outlined),
                                    label: const Text('Выбрать файлы (MP3, OGG, WAV, FLAC)'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: library.tracks.length,
                              itemBuilder: (context, index) {
                                final track = library.tracks[index];
                                final color = Color(track.colorHex);

                                return Card(
                                  key: ValueKey('library_track_card_${track.id}'),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: color,
                                      child: Icon(
                                        _getIconForBus(track.busType),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      track.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Шина: ${track.busType.displayName} | Путь: ${track.filePath}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: Colors.white60),
                                        ),
                                        if (track.tags.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 4,
                                            children: track.tags.map((tag) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white12,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '#$tag',
                                                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Quick Dispatch Play Button
                                        IconButton(
                                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.greenAccent),
                                          tooltip: 'Воспроизвести на шине ${track.busType.displayName}',
                                          onPressed: () {
                                            library.playTrackToEngine(track, audioEngine);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Отправлено на шину ${track.busType.displayName}: "${track.title}"',
                                                ),
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                        // Edit metadata button
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: 'Редактировать',
                                          onPressed: () async {
                                            final updated = await showDialog<LibraryTrack>(
                                              context: context,
                                              builder: (_) => EditTrackDialog(track: track),
                                            );
                                            if (updated != null) {
                                              library.updateTrack(updated);
                                            }
                                          },
                                        ),
                                        // Delete button
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          tooltip: 'Удалить из библиотеки',
                                          onPressed: () => library.deleteTrack(track.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleImport(BuildContext context, MediaLibraryService library) async {
    final busType = await showDialog<AudioBusType>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Выберите целевую шину для импортируемых файлов'),
          children: AudioBusType.values.map((bus) {
            return SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(bus),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(_getIconForBus(bus)),
                    const SizedBox(width: 12),
                    Text(bus.displayName, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (busType != null) {
      await library.importFiles(busType: busType);
    }
  }

  IconData _getIconForBus(AudioBusType bus) {
    switch (bus) {
      case AudioBusType.music:
        return Icons.music_note_rounded;
      case AudioBusType.ambient:
        return Icons.graphic_eq_rounded;
      case AudioBusType.sfx:
        return Icons.bolt_rounded;
    }
  }
}
