import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/scene_repository_network_service.dart';
import '../../domain/models/scene_repository_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_dialog.dart';
import '../design/ds_icon.dart';
import '../design/scene_cover.dart';
import '../design/toast.dart';
import '../screens/repository_catalog_screen.dart';
import '../view_models/media_library_view_model.dart';
import '../view_models/repository_view_model.dart';
import '../view_models/scene_view_model.dart';
import 'catalog_card.dart';

/// Details of a catalog item: cover, description, what it contains and the
/// install or remove action. Results are reported with toasts.
class SceneRepositoryDetailsDialog extends StatelessWidget {
  final CatalogItem catalogItem;
  final SceneRepositoryModel repo;

  SceneRepositoryDetailsDialog({
    super.key,
    CatalogItem? item,
    RepositorySceneItem? legacySceneItem,
    required this.repo,
  }) : catalogItem = item ?? CatalogItem.fromScene(legacySceneItem!);

  String _duration(int? durationMs) {
    if (durationMs == null || durationMs <= 0) return '';
    final d = Duration(milliseconds: durationMs);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  String _busIcon(String bus) => switch (bus.toLowerCase()) {
        'music' => 'music',
        'ambient' => 'waves',
        'sfx' => 'bolt',
        _ => 'music',
      };

  String _busLabel(AppLocalizations l10n, String bus) => switch (bus.toLowerCase()) {
        'music' => l10n.music,
        'ambient' => l10n.ambient,
        'sfx' => l10n.sfx,
        _ => bus,
      };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<RepositoryViewModel>();
    final sceneVm = context.watch<SceneViewModel>();
    final mediaVm = context.watch<MediaLibraryViewModel>();
    final toasts = context.read<ToastController?>();

    final downloading = vm.downloadingSceneIds.contains(catalogItem.id);
    final progress = vm.downloadProgress[catalogItem.id] ?? 0.0;
    final installed = isCatalogItemInstalled(item: catalogItem, sceneVm: sceneVm, mediaVm: mediaVm);

    final coverUrl = catalogItem.coverUrl != null && catalogItem.coverUrl!.isNotEmpty
        ? SceneRepositoryNetworkService.resolveUrl(repo.url, catalogItem.coverUrl!)
        : null;

    final tracks = catalogItem.type == CatalogItemType.scene
        ? catalogItem.sceneItem?.tracks
        : (catalogItem.type == CatalogItemType.media ? catalogItem.mediaItem?.tracks : null);
    final scenes = catalogItem.type == CatalogItemType.pack ? catalogItem.packItem?.scenes : null;

    final contentTitle = switch (catalogItem.type) {
      CatalogItemType.pack => l10n.scenesInPack,
      CatalogItemType.media => l10n.mediaSetContent,
      CatalogItemType.scene => l10n.sceneContent,
    };

    Widget row(String icon, String title, String meta) => Container(
          constraints: const BoxConstraints(minHeight: Sizes.rowMin),
          padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
          child: Row(
            children: [
              Container(
                width: Sizes.sceneThumb,
                height: Sizes.sceneThumb,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ds.surfaceRaised,
                  borderRadius: Radii.mdAll,
                  border: Border.all(color: ds.border, width: Sizes.borderWidth),
                ),
                child: DsIcon(icon),
              ),
              const SizedBox(width: Spacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ds.body.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(meta, style: ds.tabular(ds.caption), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );

    final List<Widget> content;
    if ((tracks == null && scenes == null) || (tracks?.isEmpty ?? scenes!.isEmpty)) {
      content = [
        Text(
          scenes != null ? l10n.scenesMissingInManifest : l10n.tracksMissingInManifest,
          style: ds.body.copyWith(color: ds.textMuted),
        ),
      ];
    } else if (tracks != null) {
      content = [
        for (final t in tracks)
          row(_busIcon(t.busType), t.title, [_busLabel(l10n, t.busType), _duration(t.durationMs)].where((e) => e.isNotEmpty).join(' · ')),
      ];
    } else {
      content = [
        for (final s in scenes!) row('scene', s.name, l10n.tracksCount(s.tracksCount ?? 0)),
      ];
    }

    return DsDialog(
      title: catalogItem.name,
      description: l10n.repositoryLabel(repo.name),
      icon: catalogKindIcon(catalogItem.type),
      closeLabel: l10n.close,
      actions: [
        DsButton.ghost(label: l10n.close, onPressed: () => Navigator.of(context).pop()),
        if (installed)
          DsButton.danger(
            key: const ValueKey('details_remove_btn'),
            label: l10n.removeFromApp,
            icon: 'trash',
            onPressed: downloading
                ? null
                : () async {
                    final confirmed = await confirmDelete(
                      context,
                      title: l10n.removeItemTitle(catalogItem.name),
                      message: l10n.removeItemMessage,
                      confirmLabel: l10n.delete,
                      cancelLabel: l10n.cancel,
                      closeLabel: l10n.close,
                    );
                    if (!confirmed) return;
                    final ok = await vm.uninstallCatalogItem(item: catalogItem, sceneVm: sceneVm, mediaVm: mediaVm);
                    if (ok) {
                      toasts?.show(title: l10n.toastRemoved, message: catalogItem.name);
                    } else {
                      toasts?.error(l10n.toastRemoveFailed, message: catalogItem.name);
                    }
                  },
          )
        else
          DsButton.primary(
            key: const ValueKey('details_install_btn'),
            label: l10n.installItem,
            icon: 'download',
            onPressed: downloading
                ? null
                : () async {
                    final ok = await vm.downloadAndInstallCatalogItem(
                      item: catalogItem,
                      repo: repo,
                      onInstalled: () async {
                        await sceneVm.loadScenes(force: true);
                        await mediaVm.loadTracks(force: true);
                      },
                    );
                    if (ok) {
                      toasts?.success(l10n.toastInstalled, message: catalogItem.name);
                    } else {
                      toasts?.error(l10n.toastInstallFailed, message: l10n.toastInstallFailedHint);
                    }
                  },
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: Radii.mdAll,
            child: coverUrl == null
                ? SceneCover(seed: catalogItem.name, height: Sizes.catalogCover)
                : SizedBox(
                    height: Sizes.catalogCover,
                    child: Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => SceneCover(seed: catalogItem.name, height: Sizes.catalogCover),
                    ),
                  ),
          ),
          if (catalogItem.description != null && catalogItem.description!.isNotEmpty) ...[
            const SizedBox(height: Spacing.s4),
            Text(catalogItem.description!, style: ds.body),
          ],
          const SizedBox(height: Spacing.s4),
          Wrap(
            spacing: Spacing.s2,
            runSpacing: Spacing.s2,
            children: [
              DsChip(formatMegabytes(l10n, catalogItem.sizeBytes)),
              DsChip(catalogCountLabel(l10n, catalogItem)),
              if (catalogItem.type == CatalogItemType.pack) DsChip(l10n.tracksCount(catalogItem.tracksCount)),
              if (installed) DsBadge(l10n.installedBadge, tone: DsTone.success),
            ],
          ),
          if (downloading) ...[
            const SizedBox(height: Spacing.s4),
            DsProgressBar(value: progress > 0 ? progress : null, label: l10n.downloadingLabel),
          ],
          const SizedBox(height: Spacing.s5),
          Text(contentTitle, style: ds.title),
          const SizedBox(height: Spacing.s2),
          ...content,
        ],
      ),
    );
  }
}
