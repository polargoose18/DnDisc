import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/library_track.dart';
import '../../ui/view_models/media_library_view_model.dart';
import '../../audio/audio_engine_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/media_package_service.dart';
import '../widgets/import_track_dialog.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer2<MediaLibraryViewModel, AudioEngineService>(
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
                        decoration: InputDecoration(
                          hintText: l10n?.searchPlaceholder ?? 'Search by title or tags (e.g. Tavern, Battle)...',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      label: Text(
                        l10n?.importFilesBtn ?? 'Import Files',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      key: const ValueKey('export_media_package_button'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: library.tracks.isEmpty ? null : () => _handleExportMediaPackage(context, library),
                      icon: const Icon(Icons.archive_outlined),
                      label: Text(l10n?.exportMediaPackageBtn ?? 'Export Set'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bus Filter Chips
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(l10n?.allSounds ?? 'All Sounds'),
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
                                  Text(
                                    l10n?.libraryEmpty ?? 'Media library is empty',
                                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n?.libraryEmptyHint ?? 'Click "Import Files" to add music, ambient or SFX.',
                                    style: const TextStyle(color: Colors.white54),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _handleImport(context, library),
                                    icon: const Icon(Icons.file_upload_outlined),
                                    label: Text(l10n?.importFilesBtn ?? 'Import Files'),
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
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            track.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          key: ValueKey('library_track_duration_${track.id}'),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white12,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.timer_outlined, size: 12, color: Colors.white70),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDuration(track.durationMs),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bus: ${track.busType.displayName} | Duration: ${_formatDuration(track.durationMs)} | Path: ${track.filePath}',
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
                                          tooltip: l10n?.dispatchToBus(track.busType.displayName) ?? 'Play on ${track.busType.displayName} bus',
                                          onPressed: () {
                                            library.playTrackToEngine(track, audioEngine);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Sent to ${track.busType.displayName} bus: "${track.title}"',
                                                ),
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                        // Edit metadata button
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: l10n?.edit ?? 'Edit',
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
                                          tooltip: l10n?.delete ?? 'Delete',
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

  Future<void> _handleImport(BuildContext context, MediaLibraryViewModel library) async {
    final l10n = AppLocalizations.of(context);
    final busType = await showDialog<AudioBusType>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text(l10n?.selectBusForImport ?? 'Select target audio bus for imported files'),
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

  String _formatDuration(int? durationMs) {
    if (durationMs == null || durationMs <= 0) return '--:--';
    final duration = Duration(milliseconds: durationMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
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

  Future<void> _handleExportMediaPackage(BuildContext context, MediaLibraryViewModel library) async {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController(text: l10n?.defaultMediaPackageName ?? 'My Media Package');
    final descController = TextEditingController(text: l10n?.defaultMediaPackageDesc ?? 'TTRPG Audio tracks collection');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.exportMediaPackageTitle ?? 'Export Media Package (.media.zip)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: l10n?.mediaPackageNameLabel ?? 'Package Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: l10n?.mediaPackageDescLabel ?? 'Package Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.export ?? 'Export'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final sanitized = titleController.text.trim().replaceAll(RegExp(r'[^\w\s\-]'), '_');
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: l10n?.saveMediaPackageAs ?? 'Save media package as...',
          fileName: '$sanitized.media.zip',
          type: FileType.custom,
          allowedExtensions: ['zip', 'media.zip'],
        );

        if (savePath != null) {
          final service = MediaPackageService();
          await service.exportMediaPackage(
            tracks: library.tracks,
            exportZipPath: savePath,
            title: titleController.text.trim(),
            description: descController.text.trim(),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n?.mediaPackageExported(titleController.text) ?? 'Media package "${titleController.text}" successfully exported!')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.mediaPackageExportError(e.toString()) ?? 'Error exporting media package: $e')),
          );
        }
      }
    }
  }
}
