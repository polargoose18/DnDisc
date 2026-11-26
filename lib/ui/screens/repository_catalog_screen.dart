import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/scene_repository_network_service.dart';
import '../../domain/models/scene_repository_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_dialog.dart';
import '../design/ds_field.dart';
import '../design/ds_panel.dart';
import '../design/toast.dart';
import '../shell/top_bar.dart';
import '../view_models/media_library_view_model.dart';
import '../view_models/repository_view_model.dart';
import '../view_models/scene_view_model.dart';
import '../widgets/catalog_card.dart';
import '../widgets/catalog_source_dialogs.dart';
import '../widgets/scene_repository_details_dialog.dart';

bool isCatalogItemInstalled({
  required CatalogItem item,
  required SceneViewModel sceneVm,
  required MediaLibraryViewModel mediaVm,
}) {
  switch (item.type) {
    case CatalogItemType.scene:
      return sceneVm.scenes.any(
        (s) => s.id == item.id || s.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
      );

    case CatalogItemType.media:
      final tracks = item.mediaItem?.tracks ?? [];
      if (tracks.isNotEmpty) {
        return tracks.any(
          (t) => mediaVm.tracks.any((mt) => mt.title.trim().toLowerCase() == t.title.trim().toLowerCase()),
        );
      }
      return mediaVm.tracks.any(
        (mt) =>
            mt.id == item.id ||
            mt.title.trim().toLowerCase() == item.name.trim().toLowerCase() ||
            mt.tags.any((tag) => tag.trim().toLowerCase() == item.name.trim().toLowerCase()),
      );

    case CatalogItemType.pack:
      final scenes = item.packItem?.scenes ?? [];
      if (scenes.isNotEmpty) {
        return scenes.any(
          (ps) => sceneVm.scenes.any((s) => s.name.trim().toLowerCase() == ps.name.trim().toLowerCase()),
        );
      }
      return sceneVm.scenes.any(
        (s) => s.id == item.id || s.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
      );
  }
}

/// Catalog: search, kind filter with counts and a grid of cards.
class RepositoryCatalogScreen extends StatefulWidget {
  const RepositoryCatalogScreen({super.key});

  @override
  State<RepositoryCatalogScreen> createState() => _RepositoryCatalogScreenState();
}

class _RepositoryCatalogScreenState extends State<RepositoryCatalogScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RepositoryViewModel>();
      if (vm.repositories.isEmpty && !vm.isLoading) {
        vm.loadRepositories();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _install(CatalogItem item, SceneRepositoryModel repo) async {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.read<RepositoryViewModel>();
    final sceneVm = context.read<SceneViewModel>();
    final mediaVm = context.read<MediaLibraryViewModel>();
    final toasts = context.read<ToastController?>();
    final success = await vm.downloadAndInstallCatalogItem(
      item: item,
      repo: repo,
      onInstalled: () async {
        await sceneVm.loadScenes(force: true);
        await mediaVm.loadTracks(force: true);
      },
    );
    if (success) {
      toasts?.success(l10n.toastInstalled, message: item.name);
    } else {
      toasts?.error(l10n.toastInstallFailed, message: l10n.toastInstallFailedHint);
    }
  }

  Future<void> _remove(CatalogItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.read<RepositoryViewModel>();
    final sceneVm = context.read<SceneViewModel>();
    final mediaVm = context.read<MediaLibraryViewModel>();
    final toasts = context.read<ToastController?>();
    final confirmed = await confirmDelete(
      context,
      title: l10n.removeItemTitle(item.name),
      message: l10n.removeItemMessage,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      closeLabel: l10n.close,
    );
    if (!confirmed) return;
    final success = await vm.uninstallCatalogItem(item: item, sceneVm: sceneVm, mediaVm: mediaVm);
    if (success) {
      toasts?.show(title: l10n.toastRemoved, message: item.name);
    } else {
      toasts?.error(l10n.toastRemoveFailed, message: item.name);
    }
  }

  void _open(CatalogItem item, SceneRepositoryModel repo) {
    showDsDialog<void>(context: context, builder: (_) => SceneRepositoryDetailsDialog(item: item, repo: repo));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<RepositoryViewModel>();
    final sceneVm = context.watch<SceneViewModel>();
    final mediaVm = context.watch<MediaLibraryViewModel>();
    final items = vm.filteredCatalogItems;

    var scenes = 0, media = 0, packs = 0;
    for (final manifest in vm.manifests.values) {
      scenes += manifest.scenes.length;
      media += manifest.media.length;
      packs += manifest.packs.length;
    }
    String filterLabel(CatalogCategoryFilter f) {
      final (name, count) = switch (f) {
        CatalogCategoryFilter.all => (l10n.filterAll, scenes + media + packs),
        CatalogCategoryFilter.scenes => (l10n.filterScenes, scenes),
        CatalogCategoryFilter.media => (l10n.filterMedia, media),
        CatalogCategoryFilter.packs => (l10n.filterPacks, packs),
      };
      return '$name · $count';
    }

    final searchField = DsTextField(
      key: const ValueKey('catalog_search_input'),
      controller: _search,
      icon: 'search',
      placeholder: l10n.searchCatalogPlaceholder,
      clearable: true,
      clearLabel: l10n.clearSearch,
      onChanged: vm.setSearchQuery,
    );
    final filter = DsSegmentedControl<CatalogCategoryFilter>(
      label: l10n.tabCatalog,
      value: vm.categoryFilter,
      onChanged: vm.setCategoryFilter,
      options: [for (final f in CatalogCategoryFilter.values) DsSegment(id: f, label: filterLabel(f))],
    );

    final Widget body;
    if (vm.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (vm.errorMessage != null) {
      body = DsEmptyState(
        icon: 'alert',
        danger: true,
        title: l10n.sourceUnavailableTitle,
        message: l10n.sourceUnavailableHint,
        action: DsButton(label: l10n.retry, icon: 'refresh', onPressed: vm.loadRepositories),
      );
    } else if (vm.repositories.isEmpty) {
      body = DsEmptyState(
        icon: 'catalog',
        title: l10n.noSourcesTitle,
        message: l10n.noSourcesHint,
        action: DsButton.primary(
          label: l10n.addSourceBtn,
          icon: 'plus',
          onPressed: () => showDsDialog<void>(context: context, builder: (_) => const SourceFormDialog()),
        ),
      );
    } else if (items.isEmpty) {
      body = DsEmptyState(
        icon: 'search',
        title: l10n.noCatalogItemsTitle,
        message: l10n.noCatalogItemsFound,
        action: DsButton(
          label: l10n.clearSearch,
          onPressed: () {
            _search.clear();
            vm.setSearchQuery('');
            vm.setCategoryFilter(CatalogCategoryFilter.all);
          },
        ),
      );
    } else {
      body = LayoutBuilder(
        builder: (context, c) {
          const gap = Spacing.s4;
          final columns = ((c.maxWidth + gap) / (Sizes.catalogCardMin + gap)).floor().clamp(1, 12);
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              mainAxisExtent: Sizes.catalogCardHeight,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final entry = items[index];
              final item = entry.item;
              final repo = entry.repo;
              final coverUrl = item.coverUrl != null && item.coverUrl!.isNotEmpty
                  ? SceneRepositoryNetworkService.resolveUrl(repo.url, item.coverUrl!)
                  : null;
              return CatalogCard(
                key: ValueKey('catalog_card_${item.id}'),
                item: item,
                author: repo.name,
                coverUrl: coverUrl,
                installed: isCatalogItemInstalled(item: item, sceneVm: sceneVm, mediaVm: mediaVm),
                downloading: vm.downloadingSceneIds.contains(item.id),
                progress: vm.downloadProgress[item.id] ?? 0,
                onOpen: () => _open(item, repo),
                onInstall: () => _install(item, repo),
                onRemove: () => _remove(item),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Palette.transparent,
      body: Column(
        children: [
          TopBar(
            title: l10n.catalogTitle,
            navigationLabel: l10n.openNavigation,
            actions: [
              DsButton.ghost(icon: 'refresh', iconOnly: true, label: l10n.refreshCatalogTooltip, onPressed: vm.loadRepositories),
              DsButton(
                key: const ValueKey('catalog_sources_button'),
                label: l10n.sourcesBtn(vm.repositories.length),
                icon: 'settings',
                onPressed: () => showDsDialog<void>(context: context, builder: (_) => const SourcesDialog()),
              ),
              DsButton.primary(
                key: const ValueKey('catalog_add_source_button'),
                label: l10n.addSourceBtn,
                icon: 'plus',
                onPressed: () => showDsDialog<void>(context: context, builder: (_) => const SourceFormDialog()),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, c) => c.maxWidth >= 800
                        ? Row(children: [Expanded(child: searchField), const SizedBox(width: Spacing.s4), filter])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: Spacing.s3),
                              SingleChildScrollView(scrollDirection: Axis.horizontal, child: filter),
                            ],
                          ),
                  ),
                  const SizedBox(height: Spacing.s4),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
