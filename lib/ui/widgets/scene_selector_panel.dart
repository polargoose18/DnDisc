import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scene_model.dart';
import '../../services/scene_service.dart';
import '../../services/media_library_service.dart';
import '../../audio/audio_engine_service.dart';
import 'create_edit_scene_dialog.dart';

class SceneSelectorPanel extends StatelessWidget {
  const SceneSelectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final sceneService = context.watch<SceneService>();
    final mediaLibrary = context.watch<MediaLibraryService>();
    final audioEngine = context.watch<AudioEngineService>();
    final scenes = sceneService.scenes;
    final activeSceneId = sceneService.activeSceneId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.movie_filter_rounded, color: Colors.amberAccent),
                const SizedBox(width: 8),
                const Text(
                  'Атмосферные Сцены',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Создать сцену'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amberAccent,
                    side: const BorderSide(color: Colors.amberAccent),
                  ),
                  onPressed: () async {
                    final newScene = await showDialog<SceneModel>(
                      context: context,
                      builder: (_) => const CreateEditSceneDialog(),
                    );
                    if (newScene != null) {
                      await sceneService.createScene(newScene);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (scenes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF14141E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Сцены пока не созданы. Нажмите «Создать сцену» для настройки звуковой атмосферы.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: scenes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    final isActive = scene.id == activeSceneId;
                    final cardColor = Color(scene.colorHex);

                    return InkWell(
                      onTap: () {
                        sceneService.activateScene(
                          scene,
                          audioEngine: audioEngine,
                          mediaLibrary: mediaLibrary,
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive ? cardColor.withValues(alpha: 0.35) : const Color(0xFF14141E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive ? cardColor : Colors.white12,
                            width: isActive ? 2.0 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    scene.name,
                                    style: TextStyle(
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 14,
                                      color: isActive ? Colors.white : Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                                    const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.redAccent))),
                                  ],
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      final updated = await showDialog<SceneModel>(
                                        context: context,
                                        builder: (_) => CreateEditSceneDialog(scene: scene),
                                      );
                                      if (updated != null) {
                                        await sceneService.updateScene(updated);
                                      }
                                    } else if (action == 'delete') {
                                      await sceneService.deleteScene(scene.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (scene.description.isNotEmpty)
                              Text(
                                scene.description,
                                style: const TextStyle(fontSize: 11, color: Colors.white54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  isActive ? Icons.volume_up : Icons.play_arrow_rounded,
                                  size: 16,
                                  color: isActive ? cardColor : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isActive ? 'АКТИВНА' : 'Включить',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    color: isActive ? cardColor : Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                if (scene.ambientLayerVolumes.isNotEmpty)
                                  Text(
                                    '${scene.ambientLayerVolumes.length} эмб.',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                              ],
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
  }
}
