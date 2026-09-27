import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scene_model.dart';
import '../../models/audio_track.dart';
import '../../services/theme_service.dart';

import '../../theme/app_themes.dart';

class SceneCard extends StatelessWidget {
  final SceneModel scene;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const SceneCard({
    super.key,
    required this.scene,
    required this.isActive,
    required this.onActivate,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService?>();
    final activeTheme = themeService?.activeTheme ?? AppThemes.deepDark;
    final sceneColor = Color(scene.colorHex);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: activeTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? activeTheme.primary : Colors.white12,
          width: isActive ? 2.5 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeTheme.primary.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
            : [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onActivate,
            child: Stack(
              children: [
                // Background Image or atmospheric gradient
                if (scene.imagePath != null && scene.imagePath!.isNotEmpty && File(scene.imagePath!).existsSync())
                  Positioned.fill(
                    child: Image.file(
                      File(scene.imagePath!),
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.6),
                      colorBlendMode: BlendMode.darken,
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            sceneColor.withValues(alpha: 0.35),
                            activeTheme.card.withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Card Content
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Top Row: Icon, Title, Active Badge, Actions Menu
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: sceneColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIcon(scene.iconName),
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          scene.name,
                          style: TextStyle(
                            color: activeTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: activeTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'АКТИВНА',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 18, color: activeTheme.textSecondary),
                        padding: EdgeInsets.zero,
                        color: activeTheme.surface,
                        onSelected: (action) {
                          if (action == 'edit') onEdit();
                          if (action == 'duplicate') onDuplicate();
                          if (action == 'delete') onDelete();
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16, color: activeTheme.textPrimary),
                                const SizedBox(width: 8),
                                Text('Редактировать', style: TextStyle(color: activeTheme.textPrimary)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 16, color: activeTheme.textPrimary),
                                const SizedBox(width: 8),
                                Text('Дублировать', style: TextStyle(color: activeTheme.textPrimary)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text('Удалить', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Description
                  if (scene.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      scene.description,
                      style: TextStyle(color: activeTheme.textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Bottom Row: Summary Badges and Activate Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 6,
                        children: [
                          if (scene.musicTrackId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getIntensityColor(scene.musicIntensity, activeTheme).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _getIntensityColor(scene.musicIntensity, activeTheme),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.music_note, size: 12, color: _getIntensityColor(scene.musicIntensity, activeTheme)),
                                  const SizedBox(width: 2),
                                  Text(
                                    scene.musicIntensity?.name.toUpperCase() ?? 'CALM',
                                    style: TextStyle(
                                      color: _getIntensityColor(scene.musicIntensity, activeTheme),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (scene.ambientLayerVolumes.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.teal, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.waves, size: 12, color: Colors.tealAccent),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${scene.ambientLayerVolumes.length} эмбиент',
                                    style: const TextStyle(
                                      color: Colors.tealAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.teal : activeTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(isActive ? Icons.volume_up_rounded : Icons.play_arrow_rounded, size: 14),
                        label: Text(isActive ? 'Активна' : 'Включить', style: const TextStyle(fontSize: 11)),
                        onPressed: onActivate,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Color _getIntensityColor(MusicIntensity? intensity, dynamic activeTheme) {
    switch (intensity) {
      case MusicIntensity.suspense:
        return Colors.amberAccent;
      case MusicIntensity.battle:
        return activeTheme.battleIntensity;
      case MusicIntensity.boss:
        return activeTheme.bossIntensity;
      case MusicIntensity.calm:
      default:
        return activeTheme.secondary;
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'castle':
        return Icons.fort_rounded;
      case 'forest':
        return Icons.forest_rounded;
      case 'dungeon':
        return Icons.shield_rounded;
      case 'tavern':
        return Icons.sports_bar_rounded;
      case 'combat':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.auto_awesome_mosaic_rounded;
    }
  }
}
