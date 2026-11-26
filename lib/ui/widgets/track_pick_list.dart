import 'package:flutter/material.dart' hide Durations;
import '../../domain/models/library_track.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../design/ds_controls.dart';
import '../design/ds_icon.dart';
import '../design/ds_interactive.dart';
import 'music_player_panel.dart' show formatDuration;

String trackKindLabel(AppLocalizations l10n, AudioBusType type) => switch (type) {
      AudioBusType.music => l10n.music,
      AudioBusType.ambient => l10n.ambient,
      AudioBusType.sfx => l10n.sfx,
    };

String defaultIconFor(AudioBusType type) => switch (type) {
      AudioBusType.music => 'music',
      AudioBusType.ambient => DnDiscIcons.defaultAmbient,
      AudioBusType.sfx => DnDiscIcons.defaultSfx,
    };

/// Icon key of a track: its own when it is in the icon set, else the default of its channel.
String iconFor(LibraryTrack track) =>
    DnDiscIcons.contains(track.iconName) ? track.iconName! : defaultIconFor(track.busType);

/// "Music · 3:28" metadata line of a track.
String trackMeta(AppLocalizations l10n, LibraryTrack track) {
  final kind = trackKindLabel(l10n, track.busType);
  return track.durationMs > 0 ? '$kind · ${formatDuration(Duration(milliseconds: track.durationMs))}' : kind;
}

/// Library tracks as selectable rows (icon box, title, metadata). With
/// [multi] each row has a checkbox, otherwise the chosen row is highlighted.
class TrackPickList extends StatelessWidget {
  final List<LibraryTrack> tracks;
  final Set<String> selected;
  final ValueChanged<LibraryTrack> onTap;
  final bool multi;

  const TrackPickList({super.key, required this.tracks, required this.selected, required this.onTap, this.multi = false});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (final track in tracks)
          DsInteractive(
            key: ValueKey('pick_${track.id}'),
            onTap: () => onTap(track),
            toggled: selected.contains(track.id),
            semanticLabel: track.title,
            builder: (context, s) {
              final on = selected.contains(track.id);
              return AnimatedContainer(
                duration: Durations.fast,
                constraints: const BoxConstraints(minHeight: Sizes.rowMin),
                padding: const EdgeInsets.all(Spacing.s2),
                decoration: BoxDecoration(
                  color: !multi && on ? ds.primarySubtle : (s.hovered ? ds.surfaceHover : Palette.transparent),
                  borderRadius: Radii.mdAll,
                ),
                child: Row(
                  children: [
                    if (multi) ...[
                      AnimatedContainer(
                        duration: Durations.fast,
                        width: Sizes.checkbox,
                        height: Sizes.checkbox,
                        decoration: BoxDecoration(
                          color: on ? ds.primary : Palette.transparent,
                          borderRadius: Radii.smAll,
                          border: Border.all(color: on ? ds.primary : ds.borderStrong, width: Sizes.checkboxBorder),
                        ),
                        child: on ? Center(child: DsIcon('check', size: Sizes.iconSm, color: ds.onPrimary)) : null,
                      ),
                      const SizedBox(width: Spacing.s3),
                    ],
                    Container(
                      width: Sizes.sceneThumb,
                      height: Sizes.sceneThumb,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ds.surfaceRaised,
                        borderRadius: Radii.mdAll,
                        border: Border.all(color: ds.border, width: Sizes.borderWidth),
                      ),
                      child: DsIcon(iconFor(track), color: on && !multi ? ds.primary : ds.textMuted),
                    ),
                    const SizedBox(width: Spacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(track.title, style: ds.body.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(trackMeta(l10n, track), style: ds.tabular(ds.caption), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (!multi && on) DsIcon('check', color: ds.primary),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Count of selected tracks shown next to a section title.
class SelectedCount extends StatelessWidget {
  final int count;

  const SelectedCount(this.count, {super.key});

  @override
  Widget build(BuildContext context) => DsBadge('$count', tone: count > 0 ? DsTone.primary : DsTone.neutral);
}
