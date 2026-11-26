import 'package:flutter/material.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_icon.dart';

/// Panel on `surface` with a `border`, no shadow. Title row: icon, title,
/// optional [trailing].
class DsPanel extends StatelessWidget {
  final String? title;
  final String? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Fill the height of the parent; [child] then gets all the space left.
  final bool expand;

  const DsPanel({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.s5),
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ds.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: ds.border, width: Sizes.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.s4),
              child: Row(
                children: [
                  if (icon != null) ...[
                    DsIcon(icon!, color: ds.text),
                    const SizedBox(width: Spacing.s3),
                  ],
                  Expanded(child: Text(title!, style: ds.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          if (expand) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

/// Empty or error state: what to do next, one action.
class DsEmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool danger;

  const DsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s7, horizontal: Spacing.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: Sizes.emptyIconBox,
              height: Sizes.emptyIconBox,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: danger ? ds.dangerSubtle : ds.surfaceRaised,
                borderRadius: Radii.lgAll,
                border: Border.all(color: danger ? Palette.transparent : ds.border, width: Sizes.borderWidth),
              ),
              child: DsIcon(icon, size: Sizes.iconLg, color: danger ? ds.danger : ds.textMuted),
            ),
            const SizedBox(height: Spacing.s3),
            Text(title, style: ds.title, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: Spacing.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Sizes.emptyMessageMax),
                child: Text(message!, style: ds.body.copyWith(color: ds.textMuted), textAlign: TextAlign.center),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: Spacing.s3),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
