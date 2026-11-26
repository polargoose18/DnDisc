import 'package:flutter/material.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_dashed.dart';
import '../design/ds_icon.dart';
import '../design/ds_interactive.dart';
import '../design/ds_menu.dart';

/// Card of a theme: a thumbnail painted in the theme's own colours (window,
/// panel, two text lines, accent bar), the name and the selected mark.
class ThemeCard extends StatelessWidget {
  final CustomThemeModel theme;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const ThemeCard({
    super.key,
    required this.theme,
    required this.selected,
    required this.onSelect,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  bool get _custom => !theme.isBuiltIn;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;

    return DsInteractive(
      onTap: onSelect,
      toggled: selected,
      semanticLabel: theme.name,
      focusRadius: Radii.lgAll,
      builder: (context, s) => Container(
        decoration: BoxDecoration(
          color: ds.surfaceRaised,
          borderRadius: Radii.lgAll,
          border: Border.all(
            color: selected ? ds.primary : (s.hovered ? ds.borderStrong : ds.border),
            width: selected ? Sizes.focusRing : Sizes.borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: Radii.lgAll - BorderRadius.circular(Sizes.borderWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: Sizes.themePreviewHeight,
                padding: const EdgeInsets.all(Spacing.s3),
                decoration: BoxDecoration(
                  color: ds.surfaceRaised,
                  border: Border(bottom: BorderSide(color: ds.border, width: Sizes.borderWidth)),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: theme.background, borderRadius: Radii.mdAll),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.s2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: theme.surface, borderRadius: Radii.smAll),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.s2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FractionallySizedBox(
                              widthFactor: 0.7,
                              child: Container(height: Spacing.s1h, decoration: BoxDecoration(color: theme.textPrimary, borderRadius: Radii.smAll)),
                            ),
                            const SizedBox(height: Spacing.s1h),
                            FractionallySizedBox(
                              widthFactor: 0.45,
                              child: Container(height: Spacing.s1h, decoration: BoxDecoration(color: theme.textSecondary, borderRadius: Radii.smAll)),
                            ),
                            const Spacer(),
                            Container(
                              width: Spacing.s5 + Spacing.s3,
                              height: Spacing.s2h,
                              decoration: BoxDecoration(color: theme.primary, borderRadius: Radii.smAll),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: Sizes.targetMin),
                padding: const EdgeInsets.only(left: Spacing.s3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(theme.name, style: ds.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (_custom) Text(l10n.customThemeTag, style: ds.caption),
                        ],
                      ),
                    ),
                    if (selected) DsIcon('check-circle', color: ds.primary),
                    if (_custom)
                      DsMoreButton(
                        label: l10n.moreActions,
                        items: [
                          DsMenuItem(id: 'edit', label: l10n.editDetails, icon: 'edit'),
                          DsMenuItem(id: 'duplicate', label: l10n.duplicate),
                          const DsMenuItem.separator(),
                          DsMenuItem(id: 'delete', label: l10n.delete, icon: 'trash', danger: true),
                        ],
                        onSelected: (id) {
                          switch (id) {
                            case 'edit':
                              onEdit?.call();
                            case 'duplicate':
                              onDuplicate?.call();
                            case 'delete':
                              onDelete?.call();
                          }
                        },
                      )
                    else
                      const SizedBox(width: Spacing.s3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last card of the grid: opens the theme editor.
class ThemeAddCard extends StatelessWidget {
  final VoidCallback onTap;

  const ThemeAddCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    return DsInteractive(
      onTap: onTap,
      semanticLabel: l10n.createThemeBtn,
      focusRadius: Radii.lgAll,
      builder: (context, s) => DecoratedBox(
        decoration: DsDashedDecoration(
          color: s.hovered ? ds.surfaceRaised : Palette.transparent,
          border: ds.borderStrong,
          dashed: true,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DsIcon('plus', color: s.hovered ? ds.text : ds.textMuted),
            const SizedBox(height: Spacing.s2),
            Text(l10n.createThemeBtn, style: ds.label.copyWith(color: s.hovered ? ds.text : ds.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Row of the shortcuts table: action and description on the left, keys on
/// the right (alternatives joined by "or"), a line below.
class ShortcutRow extends StatelessWidget {
  final String action;
  final String? description;
  final List<String> keys;
  final bool last;

  const ShortcutRow({super.key, required this.action, this.description, required this.keys, this.last = false});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      constraints: const BoxConstraints(minHeight: Sizes.shortcutRow),
      padding: const EdgeInsets.symmetric(vertical: Spacing.s1),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: ds.border, width: Sizes.borderWidth)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: ds.body),
                if (description != null) Text(description!, style: ds.caption),
              ],
            ),
          ),
          const SizedBox(width: Spacing.s4),
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: Spacing.s1h),
              Text(AppLocalizations.of(context)!.orWord, style: ds.caption),
              const SizedBox(width: Spacing.s1h),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s1h),
              constraints: const BoxConstraints(minWidth: Spacing.s5, minHeight: Sizes.icon),
              decoration: BoxDecoration(
                color: ds.surfaceHover,
                borderRadius: Radii.smAll,
                border: Border.all(color: ds.border, width: Sizes.borderWidth),
              ),
              child: Center(widthFactor: 1, child: Text(keys[i], style: ds.caption)),
            ),
          ],
        ],
      ),
    );
  }
}
