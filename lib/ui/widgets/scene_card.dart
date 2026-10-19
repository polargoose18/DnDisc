import 'package:flutter/material.dart' hide Durations;
import '../../l10n/app_localizations.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/scene_model.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_interactive.dart';
import '../design/ds_menu.dart';
import '../design/ds_tooltip.dart';
import '../design/scene_cover.dart';

/// Row of the scene list: thumbnail, name, one line of metadata. The active
/// scene gets `primary-subtle`; the menu opens by right
/// click, long press or the `more` button that shows on hover.
class SceneCard extends StatefulWidget {
  final SceneModel scene;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback? onExport;

  const SceneCard({
    super.key,
    required this.scene,
    required this.isActive,
    required this.onActivate,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    this.onExport,
  });

  @override
  State<SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends State<SceneCard> {
  bool _menuOpen = false;

  SceneModel get scene => widget.scene;
  bool get isActive => widget.isActive;

  List<DsMenuItem> _items(AppLocalizations l10n) => [
        DsMenuItem(id: 'edit', label: l10n.editDetails, icon: 'edit'),
        DsMenuItem(id: 'duplicate', label: l10n.duplicate),
        if (widget.onExport != null) DsMenuItem(id: 'export', label: l10n.exportAction, icon: 'archive'),
        const DsMenuItem.separator(),
        DsMenuItem(id: 'delete', label: l10n.delete, icon: 'trash', danger: true),
      ];

  void _select(String id) {
    switch (id) {
      case 'edit':
        widget.onEdit();
      case 'duplicate':
        widget.onDuplicate();
      case 'export':
        widget.onExport?.call();
      case 'delete':
        widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final intensity = (scene.musicIntensity ?? MusicIntensity.calm).getLocalizedName(l10n);
    final meta = l10n.sceneMeta(
      intensity,
      l10n.ambientCount(scene.ambientLayerVolumes.length),
      l10n.sfxCount(scene.soundboardSfxIds.length),
    );

    return DsInteractive(
      onTap: widget.onActivate,
      selected: isActive,
      semanticLabel: scene.name,
      onLongPress: () async {
        final id = await showDsMenuFor(context, _items(l10n));
        if (id != null) _select(id);
      },
      onSecondaryTapUp: (details) async {
        final id = await showDsMenuAt(context, details.globalPosition, _items(l10n));
        if (id != null) _select(id);
      },
      builder: (context, s) {
        final background = isActive ? ds.primarySubtle : (s.hovered ? ds.surfaceHover : Palette.transparent);
        return AnimatedContainer(
          duration: Durations.fast,
          curve: Curves.easeOut,
          height: Sizes.rowMin,
          padding: const EdgeInsets.all(Spacing.s2),
          decoration: BoxDecoration(color: background, borderRadius: Radii.mdAll),
          child: Row(
            children: [
              SceneThumb(cover: scene.cover, src: scene.imagePath, seed: scene.id),
              const SizedBox(width: Spacing.s3),
              Expanded(
                child: DsTooltip(
                  hoverOnly: true,
                  label: scene.name,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scene.name,
                        style: (isActive ? ds.bodyStrong : ds.body.copyWith(fontWeight: FontWeight.w500)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(meta, style: ds.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              if (s.hovered || s.focused || _menuOpen)
                DsMoreButton(
                  items: _items(l10n),
                  onSelected: _select,
                  label: l10n.moreActions,
                  onOpenChanged: (open) {
                    if (mounted) setState(() => _menuOpen = open);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
