import 'package:flutter/material.dart' hide Durations;
import '../../domain/models/library_track.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_icon.dart';
import '../design/ds_interactive.dart';
import '../design/ds_menu.dart';
import '../design/ds_tooltip.dart';
import '../design/equalizer_bars.dart';
import 'bus_equalizer.dart';
import 'track_pick_list.dart';

/// Row of the media library: icon box, title, type and duration, up to three
/// tags and the actions preview, edit and menu. The file path is only in the
/// tooltip. A missing file is greyed with a `danger` badge.
class TrackRow extends StatelessWidget {
  final LibraryTrack track;
  final bool playing;
  final bool missing;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLocate;

  const TrackRow({
    super.key,
    required this.track,
    required this.playing,
    required this.missing,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
    required this.onLocate,
  });

  List<DsMenuItem> _items(AppLocalizations l10n) => [
        DsMenuItem(id: 'play', label: playing ? l10n.stopPreview : l10n.previewTrack, icon: playing ? 'stop' : 'play', hotkey: 'Space', disabled: missing),
        DsMenuItem(id: 'edit', label: l10n.editDetails, icon: 'edit'),
        if (missing) DsMenuItem(id: 'locate', label: l10n.locateFile, icon: 'search'),
        const DsMenuItem.separator(),
        DsMenuItem(id: 'delete', label: l10n.delete, icon: 'trash', danger: true),
      ];

  void _select(String id) {
    switch (id) {
      case 'play':
        onPlay();
      case 'edit':
        onEdit();
      case 'locate':
        onLocate();
      case 'delete':
        onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final tags = track.tags.take(3).toList();

    return DsInteractive(
      onTap: missing ? null : onPlay,
      focusRadius: Radii.mdAll,
      semanticLabel: track.title,
      onSecondaryTapUp: (d) async {
        final id = await showDsMenuAt(context, d.globalPosition, _items(l10n));
        if (id != null) _select(id);
      },
      builder: (context, s) => AnimatedContainer(
        duration: Durations.fast,
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: Sizes.rowMin),
        padding: const EdgeInsets.all(Spacing.s2),
        decoration: BoxDecoration(
          color: playing ? ds.primarySubtle : (s.hovered ? ds.surfaceHover : Palette.transparent),
          borderRadius: Radii.mdAll,
        ),
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
              child: playing
                  ? switch (track.busType) {
                      AudioBusType.music => const MusicEqualizer(bars: 3, height: Spacing.s4),
                      AudioBusType.ambient => AmbientEqualizer(layerId: track.id, height: Spacing.s4),
                      AudioBusType.sfx => const EqualizerBars(active: true, bars: 3, height: Spacing.s4),
                    }
                  : DsIcon(iconFor(track), color: ds.textMuted),
            ),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: DsTooltip(
                label: track.filePath,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: ds.body.copyWith(fontWeight: FontWeight.w500, color: missing ? ds.textMuted : ds.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(trackMeta(l10n, track), style: ds.tabular(ds.caption), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacing.s3),
            if (missing)
              DsBadge(l10n.fileMissing, tone: DsTone.danger, dot: true)
            else
              for (final tag in tags) ...[
                DsChip(tag),
                if (tag != tags.last) const SizedBox(width: Spacing.s1),
              ],
            const SizedBox(width: Spacing.s3),
            DsButton.ghost(
              key: ValueKey('track_play_${track.id}'),
              icon: playing ? 'stop' : 'play',
              iconOnly: true,
              label: playing ? l10n.stopPreview : l10n.previewTrack,
              onPressed: missing ? null : onPlay,
            ),
            DsButton.ghost(
              key: ValueKey('track_edit_${track.id}'),
              icon: 'edit',
              iconOnly: true,
              label: l10n.editDetails,
              onPressed: onEdit,
            ),
            DsMoreButton(label: l10n.moreActions, items: _items(l10n), onSelected: _select),
          ],
        ),
      ),
    );
  }
}
