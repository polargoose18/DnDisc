import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/scene_model.dart';
import '../../ui/view_models/scene_view_model.dart';
import '../../ui/view_models/media_library_view_model.dart';
import '../../audio/audio_engine_service.dart';

/// Obsidian / VS Code styled category tree sidebar for desktop environments.
class SidebarTree extends StatefulWidget {
  final double width;
  final String? activeSceneId;
  final String? activeFolderId;
  final ValueChanged<String>? onSceneSelected;
  final ValueChanged<String>? onFolderSelected;
  final VoidCallback? onHeaderTap;
  final bool initiallyScenesExpanded;
  final bool initiallyMediaLibraryExpanded;

  const SidebarTree({
    super.key,
    this.width = 250.0,
    this.activeSceneId,
    this.activeFolderId,
    this.onSceneSelected,
    this.onFolderSelected,
    this.onHeaderTap,
    this.initiallyScenesExpanded = true,
    this.initiallyMediaLibraryExpanded = true,
  });

  @override
  State<SidebarTree> createState() => _SidebarTreeState();
}

class _SidebarTreeState extends State<SidebarTree> {
  late bool _scenesExpanded;
  late bool _mediaLibraryExpanded;
  String? _internalActiveSceneId;
  String? _internalActiveFolderId;
  String? _hoveredItemId;

  @override
  void initState() {
    super.initState();
    _scenesExpanded = widget.initiallyScenesExpanded;
    _mediaLibraryExpanded = widget.initiallyMediaLibraryExpanded;
    _internalActiveSceneId = widget.activeSceneId;
    _internalActiveFolderId = widget.activeFolderId;
  }

  @override
  void didUpdateWidget(covariant SidebarTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeSceneId != oldWidget.activeSceneId) {
      _internalActiveSceneId = widget.activeSceneId;
    }
    if (widget.activeFolderId != oldWidget.activeFolderId) {
      _internalActiveFolderId = widget.activeFolderId;
    }
    if (widget.initiallyScenesExpanded != oldWidget.initiallyScenesExpanded) {
      _scenesExpanded = widget.initiallyScenesExpanded;
    }
    if (widget.initiallyMediaLibraryExpanded != oldWidget.initiallyMediaLibraryExpanded) {
      _mediaLibraryExpanded = widget.initiallyMediaLibraryExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final sceneViewModel = _safeWatch<SceneViewModel>(context);
    final mediaLibrary = _safeWatch<MediaLibraryViewModel>(context);
    final audioEngine = _safeWatch<AudioEngineService>(context);

    // Active scene precedence: explicit widget prop > SceneViewModel > local state
    final effectiveActiveSceneId = widget.activeSceneId ?? sceneViewModel?.activeSceneId ?? _internalActiveSceneId;
    final effectiveActiveFolderId = widget.activeFolderId ?? _internalActiveFolderId;

    // Use actual scenes from ViewModel, or fallback sample scenes if empty
    final realScenes = sceneViewModel?.scenes ?? const <SceneModel>[];
    final defaultSampleScenes = [
      _TreeSceneItem(id: 'town', name: l10n?.sceneTown ?? 'Town'),
      _TreeSceneItem(id: 'enchanted_forest', name: l10n?.sceneEnchantedForest ?? 'Enchanted Forest'),
      _TreeSceneItem(id: 'caves', name: l10n?.sceneCaves ?? 'Caves'),
    ];

    return Container(
      width: widget.width,
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: "DnDisc" in elegant serif font
          InkWell(
            onTap: widget.onHeaderTap,
            mouseCursor: SystemMouseCursors.click,
            child: Container(
              height: 48.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: Text(
                l10n?.appTitle ?? 'DnDisc',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),

          Divider(
            height: 1.0,
            thickness: 1.0,
            color: colorScheme.outlineVariant,
          ),

          // Tree contents with desktop mouse scroll behavior
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              children: [
                // Section: Scenes
                _buildSectionHeader(
                  title: l10n?.scenes ?? 'Scenes',
                  icon: Icons.theater_comedy_rounded,
                  isExpanded: _scenesExpanded,
                  onToggle: () {
                    setState(() {
                      _scenesExpanded = !_scenesExpanded;
                    });
                  },
                  colorScheme: colorScheme,
                  theme: theme,
                ),

                if (_scenesExpanded) ...[
                  if (realScenes.isNotEmpty)
                    ...realScenes.map((scene) {
                      final isActive = scene.id == effectiveActiveSceneId;
                      return _buildSceneRow(
                        id: scene.id,
                        name: scene.name,
                        isActive: isActive,
                        colorScheme: colorScheme,
                        theme: theme,
                        onTap: () {
                          setState(() {
                            _internalActiveSceneId = scene.id;
                          });
                          if (sceneViewModel != null) {
                            sceneViewModel.activateScene(
                              scene,
                              audioEngine: audioEngine,
                              mediaLibrary: mediaLibrary?.service,
                            );
                          }
                          widget.onSceneSelected?.call(scene.id);
                        },
                      );
                    })
                  else
                    ...defaultSampleScenes.map((item) {
                      final isActive = item.id == effectiveActiveSceneId;
                      return _buildSceneRow(
                        id: item.id,
                        name: item.name,
                        isActive: isActive,
                        colorScheme: colorScheme,
                        theme: theme,
                        onTap: () {
                          setState(() {
                            _internalActiveSceneId = item.id;
                          });
                          widget.onSceneSelected?.call(item.id);
                        },
                      );
                    }),
                ],

                const SizedBox(height: 8.0),

                // Section: Media Library
                _buildSectionHeader(
                  title: l10n?.tabLibrary ?? 'Media Library',
                  icon: Icons.folder_rounded,
                  isExpanded: _mediaLibraryExpanded,
                  onToggle: () {
                    setState(() {
                      _mediaLibraryExpanded = !_mediaLibraryExpanded;
                    });
                  },
                  colorScheme: colorScheme,
                  theme: theme,
                ),

                if (_mediaLibraryExpanded) ...[
                  _buildFolderRow(
                    id: 'foley',
                    name: l10n?.categoryFoley ?? 'Foley',
                    icon: Icons.folder_outlined,
                    isActive: effectiveActiveFolderId == 'foley',
                    colorScheme: colorScheme,
                    theme: theme,
                    onTap: () {
                      setState(() {
                        _internalActiveFolderId = 'foley';
                      });
                      widget.onFolderSelected?.call('foley');
                    },
                  ),
                  _buildFolderRow(
                    id: 'music',
                    name: l10n?.music ?? 'Music',
                    icon: Icons.folder_outlined,
                    isActive: effectiveActiveFolderId == 'music',
                    colorScheme: colorScheme,
                    theme: theme,
                    onTap: () {
                      setState(() {
                        _internalActiveFolderId = 'music';
                      });
                      widget.onFolderSelected?.call('music');
                    },
                  ),
                  _buildFolderRow(
                    id: 'ambient',
                    name: l10n?.ambient ?? 'Ambient',
                    icon: Icons.folder_outlined,
                    isActive: effectiveActiveFolderId == 'ambient',
                    colorScheme: colorScheme,
                    theme: theme,
                    onTap: () {
                      setState(() {
                        _internalActiveFolderId = 'ambient';
                      });
                      widget.onFolderSelected?.call('ambient');
                    },
                  ),
                  _buildFolderRow(
                    id: 'sfx',
                    name: l10n?.sfx ?? 'SFX',
                    icon: Icons.folder_outlined,
                    isActive: effectiveActiveFolderId == 'sfx',
                    colorScheme: colorScheme,
                    theme: theme,
                    onTap: () {
                      setState(() {
                        _internalActiveFolderId = 'sfx';
                      });
                      widget.onFolderSelected?.call('sfx');
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onToggle,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(6.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                size: 18.0,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4.0),
              Icon(
                icon,
                size: 16.0,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSceneRow({
    required String id,
    required String name,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    final isHovered = _hoveredItemId == id;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredItemId = id),
      onExit: (_) => setState(() => _hoveredItemId = null),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1.5),
          padding: const EdgeInsets.only(left: 24.0, right: 8.0, top: 5.0, bottom: 5.0),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.secondaryContainer.withValues(alpha: 0.6)
                : (isHovered ? colorScheme.onSurface.withValues(alpha: 0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(6.0),
            border: isActive
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.landscape_rounded : Icons.landscape_outlined,
                size: 15.0,
                color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.0,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderRow({
    required String id,
    required String name,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    final isHovered = _hoveredItemId == id;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredItemId = id),
      onExit: (_) => setState(() => _hoveredItemId = null),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1.5),
          padding: const EdgeInsets.only(left: 24.0, right: 8.0, top: 5.0, bottom: 5.0),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.secondaryContainer.withValues(alpha: 0.6)
                : (isHovered ? colorScheme.onSurface.withValues(alpha: 0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(6.0),
            border: isActive
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 15.0,
                color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.0,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static T? _safeWatch<T extends Object>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: true);
    } catch (_) {
      return null;
    }
  }
}

class _TreeSceneItem {
  final String id;
  final String name;

  const _TreeSceneItem({required this.id, required this.name});
}
