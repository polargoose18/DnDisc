import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/scene_repository_model.dart';
import '../../services/scene_repository_network_service.dart';
import '../view_models/repository_view_model.dart';
import '../view_models/scene_view_model.dart';
import '../widgets/scene_repository_details_dialog.dart';

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
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить репозиторий'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL репозитория (GitHub / HTTP / JSON)',
                      hintText: 'https://github.com/user/repo',
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Введите URL репозитория';
                      }
                      if (!val.startsWith('http://') && !val.startsWith('https://')) {
                        return 'URL должен начинаться с http:// или https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название (опционально)',
                      hintText: 'Извлечётся из манифеста, если пусто',
                      prefixIcon: Icon(Icons.label_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Описание (опционально)',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
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
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _showManageRepositoriesModal(BuildContext context) {
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
                      Text(
                        'Управление репозиториями (${repos.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_link_rounded),
                        tooltip: 'Добавить репозиторий',
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
                        ? const Center(
                            child: Text('Нет подключенных репозиториев.'),
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
                                          'Сцен: ${manifest.scenes.length} | Медиа: ${manifest.media.length} | Паков: ${manifest.packs.length}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () async {
                                      await vm.deleteRepository(repo.id);
                                    },
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
    final vm = context.watch<RepositoryViewModel>();
    final catalogItems = vm.filteredCatalogItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Обновить каталог',
            onPressed: () => vm.loadRepositories(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_input_composite_rounded),
            tooltip: 'Управление репозиториями',
            onPressed: () => _showManageRepositoriesModal(context),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddRepositoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('+ Добавить'),
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
                          hintText: 'Поиск элементов в каталоге...',
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
                      label: Text('Источники (${vm.repositories.length})'),
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
                        label: Text(filter.label),
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
                      'Нет подключенных репозиториев',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Добавьте ссылку на GitHub или CDN с манифестом repository.json'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRepositoryDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить репозиторий'),
                    ),
                  ],
                ),
              ),
            )
          else if (catalogItems.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Элементы не найдены по вашему запросу.'),
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
                  final isInstalled = item.type == CatalogItemType.scene &&
                      sceneVm.scenes.any(
                        (s) => s.id == item.id || s.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
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
                                      color: Colors.black.withOpacity(0.65),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item.type.badgeLabel,
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
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'Загружено',
                                            style: TextStyle(
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
                                    item.description ?? 'Без описания',
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
                                            ? '${item.packItem?.scenesCount ?? item.packItem?.scenes.length ?? 0} сцен'
                                            : '${item.tracksCount} треков',
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
