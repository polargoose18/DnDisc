import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/scene_model.dart';
import '../../ui/view_models/scene_view_model.dart';
import '../../ui/view_models/media_library_view_model.dart';
import '../../ui/view_models/theme_view_model.dart';
import '../../theme/app_themes.dart';
import '../../audio/audio_engine_service.dart';
import 'create_edit_scene_dialog.dart';
import 'scene_card.dart';

class SceneSelectorPanel extends StatefulWidget {
  final bool isVertical;

  const SceneSelectorPanel({super.key, this.isVertical = false});

  @override
  State<SceneSelectorPanel> createState() => _SceneSelectorPanelState();
}

class _SceneSelectorPanelState extends State<SceneSelectorPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sceneViewModel = context.watch<SceneViewModel>();
    final mediaLibrary = context.watch<MediaLibraryViewModel>();
    final audioEngine = context.watch<AudioEngineService>();
    final themeViewModel = context.watch<ThemeViewModel?>();
    final activeTheme = themeViewModel?.activeTheme ?? AppThemes.deepDark;
    final l10n = AppLocalizations.of(context);

    final allScenes = sceneViewModel.scenes;
    final activeSceneId = sceneViewModel.activeSceneId;

    final filteredScenes = _searchQuery.isEmpty
        ? allScenes
        : allScenes.where((s) =>
            s.name.toLowerCase().contains(_searchQuery) ||
            s.description.toLowerCase().contains(_searchQuery)).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.isVertical ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.theater_comedy_rounded, color: activeTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n?.scenesTitle ?? 'Атмосферные Сцены',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: activeTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: Text(l10n?.createSceneBtn ?? 'Создать сцену', style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    final newScene = await showDialog<SceneModel>(
                      context: context,
                      builder: (_) => const CreateEditSceneDialog(),
                    );
                    if (newScene != null) {
                      await sceneViewModel.createScene(newScene);
                    }
                  },
                ),
              ],
            ),
            if (widget.isVertical) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                style: TextStyle(color: activeTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n?.searchPlaceholder ?? 'Поиск сцен...',
                  hintStyle: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search, size: 18, color: activeTheme.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 16, color: activeTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: activeTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ],
            const SizedBox(height: 12),
            if (filteredScenes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: activeTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    allScenes.isEmpty
                        ? (l10n?.noScenesHint ?? 'Сцены пока не созданы.\nНажмите «Новая сцена» для добавления.')
                        : 'Сцен по запросу не найдено.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else if (widget.isVertical)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredScenes.length,
                  itemBuilder: (context, index) {
                    final scene = filteredScenes[index];
                    return SceneCard(
                      scene: scene,
                      isActive: scene.id == activeSceneId,
                      onActivate: () {
                        sceneViewModel.activateScene(
                          scene,
                          audioEngine: audioEngine,
                          mediaLibrary: mediaLibrary.service,
                        );
                      },
                      onEdit: () async {
                        final updated = await showDialog<SceneModel>(
                          context: context,
                          builder: (_) => CreateEditSceneDialog(scene: scene),
                        );
                        if (updated != null) {
                          await sceneViewModel.updateScene(updated);
                        }
                      },
                      onDuplicate: () async {
                        await sceneViewModel.duplicateScene(scene.id);
                      },
                      onDelete: () async {
                        await sceneViewModel.deleteScene(scene.id);
                      },
                    );
                  },
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredScenes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final scene = filteredScenes[index];
                    return SizedBox(
                      width: 280,
                      child: SceneCard(
                        scene: scene,
                        isActive: scene.id == activeSceneId,
                        onActivate: () {
                          sceneViewModel.activateScene(
                            scene,
                            audioEngine: audioEngine,
                            mediaLibrary: mediaLibrary.service,
                          );
                        },
                        onEdit: () async {
                          final updated = await showDialog<SceneModel>(
                            context: context,
                            builder: (_) => CreateEditSceneDialog(scene: scene),
                          );
                          if (updated != null) {
                            await sceneViewModel.updateScene(updated);
                          }
                        },
                        onDuplicate: () async {
                          await sceneViewModel.duplicateScene(scene.id);
                        },
                        onDelete: () async {
                          await sceneViewModel.deleteScene(scene.id);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
