import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/scene_repository_model.dart';
import '../../data/services/scene_repository_network_service.dart';
import '../view_models/media_library_view_model.dart';
import '../view_models/repository_view_model.dart';
import '../view_models/scene_view_model.dart';
import '../screens/repository_catalog_screen.dart';

class SceneRepositoryDetailsDialog extends StatelessWidget {
  final CatalogItem catalogItem;
  final SceneRepositoryModel repo;

  SceneRepositoryDetailsDialog({
    super.key,
    CatalogItem? item,
    RepositorySceneItem? legacySceneItem,
    required this.repo,
  })  : catalogItem = item ?? CatalogItem.fromScene(legacySceneItem!);

  String _formatDuration(int? durationMs) {
    if (durationMs == null) return '--:--';
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Size unknown';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  IconData _getBusIcon(String busType) {
    switch (busType.toLowerCase()) {
      case 'music':
        return Icons.music_note_rounded;
      case 'ambient':
        return Icons.nature_people_rounded;
      case 'sfx':
        return Icons.graphic_eq_rounded;
      default:
        return Icons.audiotrack_rounded;
    }
  }

  Color _getBusColor(String busType, ThemeData theme) {
    switch (busType.toLowerCase()) {
      case 'music':
        return Colors.purpleAccent;
      case 'ambient':
        return Colors.tealAccent;
      case 'sfx':
        return Colors.orangeAccent;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getTypeDisplayNameInAccusative(CatalogItemType type) {
    switch (type) {
      case CatalogItemType.scene:
        return 'scene';
      case CatalogItemType.media:
        return 'media package';
      case CatalogItemType.pack:
        return 'pack';
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    final typeName = _getTypeDisplayNameInAccusative(catalogItem.type);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $typeName?'),
        content: Text(
          'Are you sure you want to delete $typeName "${catalogItem.name}" and associated files from the application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<RepositoryViewModel>();
    final sceneVm = context.watch<SceneViewModel>();
    final mediaVm = context.watch<MediaLibraryViewModel>();

    final isDownloading = vm.downloadingSceneIds.contains(catalogItem.id);
    final progress = vm.downloadProgress[catalogItem.id] ?? 0.0;

    final isInstalled = isCatalogItemInstalled(
      item: catalogItem,
      sceneVm: sceneVm,
      mediaVm: mediaVm,
    );

    final headerColor = catalogItem.colorHex != null ? Color(catalogItem.colorHex!) : theme.colorScheme.primary;

    final coverUrl = catalogItem.coverUrl != null && catalogItem.coverUrl!.isNotEmpty
        ? SceneRepositoryNetworkService.resolveUrl(repo.url, catalogItem.coverUrl!)
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header Banner
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: headerColor,
                gradient: coverUrl == null
                    ? LinearGradient(
                        colors: [headerColor.withValues(alpha: 0.8), headerColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (coverUrl != null)
                    Positioned.fill(
                      child: Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.55),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                catalogItem.type.badgeLabel,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                catalogItem.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        Text(
                          'Repository: ${repo.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (catalogItem.description != null && catalogItem.description!.isNotEmpty) ...[
                      Text(
                        catalogItem.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.folder_zip_outlined, size: 18),
                          label: Text(_formatSize(catalogItem.sizeBytes)),
                        ),
                        if (catalogItem.type == CatalogItemType.pack) ...[
                          Chip(
                            avatar: const Icon(Icons.style_rounded, size: 18),
                            label: Text('${catalogItem.packItem?.scenesCount ?? catalogItem.packItem?.scenes.length ?? 0} scenes'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.audiotrack, size: 18),
                            label: Text('${catalogItem.tracksCount} tracks'),
                          ),
                        ] else ...[
                          Chip(
                            avatar: const Icon(Icons.audiotrack, size: 18),
                            label: Text('${catalogItem.tracksCount} tracks'),
                          ),
                        ],
                        if (isInstalled)
                          const Chip(
                            avatar: Icon(Icons.check_circle_rounded, size: 18, color: Colors.tealAccent),
                            label: Text('Installed', style: TextStyle(color: Colors.tealAccent)),
                            backgroundColor: Colors.teal,
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Text(
                      catalogItem.type == CatalogItemType.pack
                          ? 'Scenes in Pack'
                          : (catalogItem.type == CatalogItemType.media ? 'Media Package Content' : 'Scene Content'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),

                    if (catalogItem.type == CatalogItemType.scene && (catalogItem.sceneItem?.tracks.isEmpty ?? true))
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Track list is missing from manifest.'),
                      )
                    else if (catalogItem.type == CatalogItemType.scene)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: catalogItem.sceneItem!.tracks.length,
                        itemBuilder: (context, index) {
                          final track = catalogItem.sceneItem!.tracks[index];
                          final busColor = _getBusColor(track.busType, theme);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: busColor.withValues(alpha: 0.2),
                              child: Icon(_getBusIcon(track.busType), color: busColor, size: 20),
                            ),
                            title: Text(track.title),
                            subtitle: Text('Channel: ${track.busType.toUpperCase()}'),
                            trailing: Text(_formatDuration(track.durationMs)),
                          );
                        },
                      )
                    else if (catalogItem.type == CatalogItemType.media && (catalogItem.mediaItem?.tracks.isEmpty ?? true))
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Track list is missing from manifest.'),
                      )
                    else if (catalogItem.type == CatalogItemType.media)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: catalogItem.mediaItem!.tracks.length,
                        itemBuilder: (context, index) {
                          final track = catalogItem.mediaItem!.tracks[index];
                          final busColor = _getBusColor(track.busType, theme);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: busColor.withValues(alpha: 0.2),
                              child: Icon(_getBusIcon(track.busType), color: busColor, size: 20),
                            ),
                            title: Text(track.title),
                            subtitle: Text('Channel: ${track.busType.toUpperCase()}'),
                            trailing: Text(_formatDuration(track.durationMs)),
                          );
                        },
                      )
                    else if (catalogItem.type == CatalogItemType.pack && (catalogItem.packItem?.scenes.isEmpty ?? true))
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Scene list is missing from manifest.'),
                      )
                    else if (catalogItem.type == CatalogItemType.pack)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: catalogItem.packItem!.scenes.length,
                        itemBuilder: (context, index) {
                          final sceneSummary = catalogItem.packItem!.scenes[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.theater_comedy_rounded, size: 20),
                            ),
                            title: Text(sceneSummary.name),
                            subtitle: Text('${sceneSummary.tracksCount ?? 0} tracks'),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Footer (Install / Delete Actions)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDownloading) ...[
                    LinearProgressIndicator(value: progress > 0 ? progress : null),
                    const SizedBox(height: 8),
                    Text(
                      'Downloading and importing... ${(progress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: isInstalled
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                            ),
                            onPressed: isDownloading
                                ? null
                                : () async {
                                    final confirm = await _showDeleteConfirmationDialog(context);
                                    if (confirm == true) {
                                      final success = await vm.uninstallCatalogItem(
                                        item: catalogItem,
                                        sceneVm: sceneVm,
                                        mediaVm: mediaVm,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? '${catalogItem.type.displayName} "${catalogItem.name}" was successfully removed from the application.'
                                                  : 'Error removing ${catalogItem.type.displayName.toLowerCase()}.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Delete from application'),
                          )
                        : ElevatedButton.icon(
                            onPressed: isDownloading
                                ? null
                                : () async {
                                    final success = await vm.downloadAndInstallCatalogItem(
                                      item: catalogItem,
                                      repo: repo,
                                      onInstalled: () async {
                                        await sceneVm.loadScenes(force: true);
                                        await mediaVm.loadTracks(force: true);
                                      },
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? '${catalogItem.type.displayName} "${catalogItem.name}" was successfully installed!'
                                                : 'Error downloading ${catalogItem.type.displayName.toLowerCase()}.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: Icon(
                              isDownloading
                                  ? Icons.hourglass_top_rounded
                                  : Icons.download_rounded,
                            ),
                            label: Text(
                              isDownloading
                                  ? 'Installing...'
                                  : 'Install ${_getTypeDisplayNameInAccusative(catalogItem.type)}',
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
