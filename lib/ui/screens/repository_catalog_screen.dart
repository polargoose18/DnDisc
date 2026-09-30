import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/scene_repository_model.dart';
import '../../data/services/scene_repository_network_service.dart';
import '../view_models/media_library_view_model.dart';
import '../view_models/repository_view_model.dart';
import '../view_models/scene_view_model.dart';
import '../widgets/scene_repository_details_dialog.dart';

bool isCatalogItemInstalled({
  required CatalogItem item,
  required SceneViewModel sceneVm,
  required MediaLibraryViewModel mediaVm,
}) {
  switch (item.type) {
    case CatalogItemType.scene:
      return sceneVm.scenes.any(
        (s) =>
            s.id == item.id ||
            s.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
      );

    case CatalogItemType.media:
      final tracks = item.mediaItem?.tracks ?? [];
      if (tracks.isNotEmpty) {
        return tracks.any(
          (t) => mediaVm.tracks.any(
            (mt) =>
                mt.title.trim().toLowerCase() == t.title.trim().toLowerCase(),
          ),
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
          (ps) => sceneVm.scenes.any(
            (s) =>
                s.name.trim().toLowerCase() == ps.name.trim().toLowerCase(),
          ),
        );
      }
      return sceneVm.scenes.any(
        (s) =>
            s.id == item.id ||
            s.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
      );
  }
}

class RepositoryCatalogScreen extends StatefulWidget {
  const RepositoryCatalogScreen({super.key});

  @override
  State<RepositoryCatalogScreen> createState() => _RepositoryCatalogScreenState();
}

class _RepositoryCatalogScreenState extends State<RepositoryCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  void _showAddRepositoryDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n?.addRepositoryDialogTitle ?? 'Add Repository'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: l10n?.repositoryUrlLabel ?? 'Repository URL (GitLab / Dropbox / HTTP / JSON)',
                      hintText: l10n?.repositoryUrlHint ?? 'https://gitlab.com/user/repo',
                      prefixIcon: const Icon(Icons.link),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n?.enterRepositoryUrl ?? 'Please enter repository URL';
                      }
                      if (!val.startsWith('http://') && !val.startsWith('https://')) {
                        return l10n?.urlHttpPrefixValidation ?? 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n?.repositoryNameOptionalLabel ?? 'Name (optional)',
                      hintText: l10n?.repositoryNameHint ?? 'Extracted from manifest if empty',
                      prefixIcon: const Icon(Icons.label_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n?.repositoryDescOptionalLabel ?? 'Description (optional)',
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final vm = context.read<RepositoryViewModel>();
                  final success = await vm.addRepository(
                    name: nameController.text,
                    url: urlController.text,
                    description: descController.text,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (!success && vm.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(vm.errorMessage!)),
                      );
                    }
                  }
                }
              },
              child: Text(l10n?.addRepositoryBtn ?? 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditRepositoryDialog(BuildContext context, SceneRepositoryModel repo) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: repo.name);
    final urlController = TextEditingController(text: repo.url);
    final descController = TextEditingController(text: repo.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n?.editRepositoryDialogTitle ?? 'Edit Repository'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: l10n?.repositoryUrlLabel ?? 'Repository URL (GitLab / Dropbox / HTTP / JSON)',
                      prefixIcon: const Icon(Icons.link),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n?.enterRepositoryUrl ?? 'Please enter repository URL';
                      }
                      if (!val.startsWith('http://') && !val.startsWith('https://')) {
                        return l10n?.urlHttpPrefixValidation ?? 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n?.repositoryNameLabel ?? 'Name',
                      prefixIcon: const Icon(Icons.label_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n?.enterRepositoryName ?? 'Please enter repository name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n?.repositoryDescOptionalLabel ?? 'Description (optional)',
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final vm = context.read<RepositoryViewModel>();
                  final success = await vm.updateRepository(
                    id: repo.id,
                    name: nameController.text,
                    url: urlController.text,
                    description: descController.text,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (!success && vm.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(vm.errorMessage!)),
                      );
                    } else if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n?.repositoryUpdated ?? 'Repository successfully updated')),
                      );
                    }
                  }
                }
              },
              child: Text(l10n?.save ?? 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _showManageRepositoriesModal(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            final vm = context.watch<RepositoryViewModel>();
            final repos = vm.repositories;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.manageRepositoriesTitle(repos.length) ?? 'Manage Repositories (${repos.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_link_rounded),
                        tooltip: l10n?.addRepositoryTooltip ?? 'Add repository',
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showAddRepositoryDialog(context);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: repos.isEmpty
                        ? Center(
                            child: Text(l10n?.noConnectedRepositories ?? 'No repositories connected.'),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: repos.length,
                            itemBuilder: (context, index) {
                              final repo = repos[index];
                              final manifest = vm.manifests[repo.id];

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.cloud_queue_rounded),
                                  ),
                                  title: Text(repo.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        repo.url,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (manifest != null)
                                        Text(
                                          l10n?.repoStats(
                                                manifest.scenes.length,
                                                manifest.media.length,
                                                manifest.packs.length,
                                              ) ??
                                              'Scenes: ${manifest.scenes.length} | Media: ${manifest.media.length} | Packs: ${manifest.packs.length}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: l10n?.edit ?? 'Edit',
                                        onPressed: () {
                                          _showEditRepositoryDialog(context, repo);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        tooltip: l10n?.delete ?? 'Delete',
                                        onPressed: () async {
                                          await vm.deleteRepository(repo.id);
                                        },
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<RepositoryViewModel>();
    final catalogItems = vm.filteredCatalogItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.catalogTitle ?? 'Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n?.refreshCatalogTooltip ?? 'Refresh catalog',
            onPressed: () => vm.loadRepositories(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_input_composite_rounded),
            tooltip: l10n?.manageRepositoriesTooltip ?? 'Manage repositories',
            onPressed: () => _showManageRepositoriesModal(context),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddRepositoryDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n?.addRepositoryBtn ?? 'Add'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n?.searchCatalogPlaceholder ?? 'Search items in catalog...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    vm.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) => vm.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showManageRepositoriesModal(context),
                      icon: const Icon(Icons.source),
                      label: Text(l10n?.sourcesBtn(vm.repositories.length) ?? 'Sources (${vm.repositories.length})'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Filter Chips
                Row(
                  children: CatalogCategoryFilter.values.map((filter) {
                    final isSelected = vm.categoryFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter.getLocalizedLabel(l10n)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            vm.setCategoryFilter(filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          if (vm.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (vm.repositories.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.noRepositoriesConnected ?? 'No repositories connected',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n?.addRepositoryUrlHint ?? 'Add a link to GitLab, Dropbox or CDN with repository.json manifest'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRepositoryDialog(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n?.addRepositoryTooltip ?? 'Add repository'),
                    ),
                  ],
                ),
              ),
            )
          else if (catalogItems.isEmpty)
            Expanded(
              child: Center(
                child: Text(l10n?.noCatalogItemsFound ?? 'No items found matching your query.'),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: catalogItems.length,
                itemBuilder: (context, index) {
                  final entry = catalogItems[index];
                  final item = entry.item;
                  final repo = entry.repo;

                  final sceneVm = context.watch<SceneViewModel>();
                  final mediaVm = context.watch<MediaLibraryViewModel>();
                  final isInstalled = isCatalogItemInstalled(
                    item: item,
                    sceneVm: sceneVm,
                    mediaVm: mediaVm,
                  );

                  final cardColor = item.colorHex != null
                      ? Color(item.colorHex!)
                      : theme.colorScheme.primaryContainer;

                  final coverUrl = item.coverUrl != null && item.coverUrl!.isNotEmpty
                      ? SceneRepositoryNetworkService.resolveUrl(repo.url, item.coverUrl!)
                      : null;

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isInstalled
                          ? BorderSide(color: Colors.teal.shade400, width: 1.5)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => SceneRepositoryDetailsDialog(
                            item: item,
                            repo: repo,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Image Header
                          Container(
                            height: 110,
                            width: double.infinity,
                            color: cardColor,
                            child: Stack(
                              children: [
                                if (coverUrl != null)
                                  Positioned.fill(
                                    child: Image.network(
                                      coverUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => Center(
                                        child: Icon(
                                          item.type == CatalogItemType.media
                                              ? Icons.library_music_rounded
                                              : (item.type == CatalogItemType.pack
                                                  ? Icons.inventory_2_rounded
                                                  : Icons.landscape_rounded),
                                          size: 48,
                                          color: cardColor.computeLuminance() > 0.5
                                              ? Colors.black54
                                              : Colors.white70,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Center(
                                    child: Icon(
                                      item.type == CatalogItemType.media
                                          ? Icons.library_music_rounded
                                          : (item.type == CatalogItemType.pack
                                              ? Icons.inventory_2_rounded
                                              : Icons.landscape_rounded),
                                      size: 48,
                                      color: cardColor.computeLuminance() > 0.5
                                          ? Colors.black54
                                          : Colors.white70,
                                    ),
                                  ),

                                // Category Badge
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item.type.getLocalizedBadge(l10n),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                if (isInstalled)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade700,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black38, blurRadius: 4),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n?.installedBadge ?? 'Installed',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Card Body
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    repo.name,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description ?? (l10n?.noDescription ?? 'No description'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.type == CatalogItemType.pack
                                            ? (l10n?.scenesCount(item.packItem?.scenesCount ?? item.packItem?.scenes.length ?? 0) ??
                                                '${item.packItem?.scenesCount ?? item.packItem?.scenes.length ?? 0} scenes')
                                            : (l10n?.tracksCount(item.tracksCount) ?? '${item.tracksCount} tracks'),
                                        style: theme.textTheme.labelSmall,
                                      ),
                                      Icon(
                                        isInstalled ? Icons.check_circle_rounded : Icons.download_rounded,
                                        size: 20,
                                        color: isInstalled ? Colors.teal : theme.colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}
