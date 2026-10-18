import 'package:flutter/material.dart';
import '../../domain/models/scene_repository_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_icon.dart';
import '../design/ds_interactive.dart';
import '../design/ds_menu.dart';
import '../design/scene_cover.dart';

String catalogKindIcon(CatalogItemType type) => switch (type) {
      CatalogItemType.scene => 'scene',
      CatalogItemType.media => 'music',
      CatalogItemType.pack => 'bundle',
    };

/// "3 tracks" or "1 scene" line for a catalog item.
String catalogCountLabel(AppLocalizations l10n, CatalogItem item) {
  if (item.type == CatalogItemType.pack) {
    return l10n.scenesCount(item.packItem?.scenesCount ?? item.packItem?.scenes.length ?? 0);
  }
  return l10n.tracksCount(item.tracksCount);
}

String formatMegabytes(AppLocalizations l10n, int? bytes) {
  if (bytes == null || bytes <= 0) return l10n.sizeUnknown;
  return l10n.sizeMb((bytes / (1024 * 1024)).toStringAsFixed(1));
}

/// Card of a catalog item: cover, kind, title, author, description and one
/// footer that fits every state (available, downloading, installed).
class CatalogCard extends StatelessWidget {
  final CatalogItem item;
  final String author;
  final String? coverUrl;
  final bool installed;
  final bool downloading;
  final double progress;
  final VoidCallback onOpen;
  final VoidCallback onInstall;
  final VoidCallback onRemove;

  const CatalogCard({
    super.key,
    required this.item,
    required this.author,
    this.coverUrl,
    required this.installed,
    required this.downloading,
    required this.progress,
    required this.onOpen,
    required this.onInstall,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;

    final Widget cover = coverUrl == null
        ? SceneCover(seed: item.name, height: Sizes.catalogCover)
        : SizedBox(
            height: Sizes.catalogCover,
            width: double.infinity,
            child: Image.network(
              coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => SceneCover(seed: item.name, height: Sizes.catalogCover),
            ),
          );

    final Widget footer;
    if (downloading) {
      footer = Expanded(
        child: DsProgressBar(value: progress > 0 ? progress : null, label: l10n.downloadingLabel),
      );
    } else if (installed) {
      footer = Expanded(
        child: Row(
          children: [
            DsIcon('check-circle', color: ds.success),
            const SizedBox(width: Spacing.s2),
            Text(l10n.installedBadge, style: ds.label.copyWith(color: ds.success)),
            const Spacer(),
            DsMoreButton(
              label: l10n.moreActions,
              items: [
                DsMenuItem(id: 'details', label: l10n.viewDetails, icon: 'info'),
                const DsMenuItem.separator(),
                DsMenuItem(id: 'remove', label: l10n.removeFromApp, icon: 'trash', danger: true),
              ],
              onSelected: (id) => id == 'remove' ? onRemove() : onOpen(),
            ),
          ],
        ),
      );
    } else {
      footer = Expanded(
        child: Row(
          children: [
            Text(formatMegabytes(l10n, item.sizeBytes), style: ds.caption),
            const Spacer(),
            DsButton(
              key: ValueKey('catalog_install_${item.id}'),
              label: l10n.installItem,
              icon: 'download',
              onPressed: onInstall,
            ),
          ],
        ),
      );
    }

    return DsInteractive(
      onTap: onOpen,
      semanticLabel: item.name,
      focusRadius: Radii.lgAll,
      builder: (context, s) => Container(
        decoration: BoxDecoration(
          color: ds.surface,
          borderRadius: Radii.lgAll,
          border: Border.all(color: s.hovered ? ds.borderStrong : ds.border, width: Sizes.borderWidth),
        ),
        child: ClipRRect(
          borderRadius: Radii.lgAll - BorderRadius.circular(Sizes.borderWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ds.border, width: Sizes.borderWidth))),
                child: cover,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.s4, Spacing.s4, Spacing.s4, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DsIcon(catalogKindIcon(item.type), size: Sizes.iconSm),
                          const SizedBox(width: Spacing.s1h),
                          Flexible(
                            child: Text(
                              '${item.type.getLocalizedBadge(l10n)} · ${catalogCountLabel(l10n, item)}',
                              style: ds.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.s1),
                      Text(item.name, style: ds.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(author, style: ds.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: Spacing.s1),
                      Text(
                        item.description ?? l10n.noDescription,
                        style: ds.body.copyWith(color: ds.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: Sizes.catalogFooter),
                padding: const EdgeInsets.all(Spacing.s4),
                child: Row(children: [footer]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
