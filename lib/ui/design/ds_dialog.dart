import 'package:flutter/material.dart' hide Durations;
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_button.dart';
import 'ds_icon.dart';

enum DsDialogSize { sm, md, lg }

/// Modal window: header (title, description, close), body and a footer with
/// a top border; the main action is the last one on the right. Use
/// [showDsDialog] to open it.
class DsDialog extends StatelessWidget {
  final String title;
  final String? description;
  final String? icon;
  final bool danger;
  final DsDialogSize size;
  final List<Widget> actions;
  final String? footNote;
  final VoidCallback? onClose;
  final String closeLabel;
  final Widget? child;

  const DsDialog({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.danger = false,
    this.size = DsDialogSize.md,
    this.actions = const [],
    this.footNote,
    this.onClose,
    required this.closeLabel,
    this.child,
  });

  double get _width => switch (size) {
        DsDialogSize.sm => Sizes.dialogSm,
        DsDialogSize.md => Sizes.dialogMd,
        DsDialogSize.lg => Sizes.dialogLg,
      };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Dialog(
      backgroundColor: Palette.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(Spacing.s4),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _width),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ds.surface,
            borderRadius: Radii.lgAll,
            border: Border.all(color: ds.border, width: Sizes.borderWidth),
            boxShadow: Shadows.overlay,
          ),
          child: ClipRRect(
            borderRadius: Radii.lgAll,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.s5, Spacing.s5, Spacing.s4, Spacing.s4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Container(
                          width: Sizes.targetMin,
                          height: Sizes.targetMin,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: danger ? ds.dangerSubtle : ds.surfaceRaised,
                            borderRadius: Radii.mdAll,
                            border: Border.all(color: danger ? Palette.transparent : ds.border, width: Sizes.borderWidth),
                          ),
                          child: DsIcon(icon!, color: danger ? ds.danger : ds.textMuted),
                        ),
                        const SizedBox(width: Spacing.s3),
                      ],
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: Spacing.s1 + 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: ds.titleLg),
                              if (description != null) ...[
                                const SizedBox(height: Spacing.s1),
                                Text(description!, style: ds.body.copyWith(color: ds.textMuted)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.s3),
                      DsButton.ghost(
                        icon: 'x',
                        iconOnly: true,
                        label: closeLabel,
                        onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
                if (child != null)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(Spacing.s5, 0, Spacing.s5, Spacing.s5),
                      child: child,
                    ),
                  ),
                if (actions.isNotEmpty || footNote != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.s5, vertical: Spacing.s4),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: ds.border, width: Sizes.borderWidth))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (footNote != null) Expanded(child: Text(footNote!, style: ds.caption)),
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0 || footNote != null) const SizedBox(width: Spacing.s2),
                          actions[i],
                        ],
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
}

/// Opens [builder] as a modal: `bg` at 72% behind it, 320ms fade with an 8px
/// rise from below, no scaling.
Future<T?> showDsDialog<T>({required BuildContext context, required WidgetBuilder builder, bool barrierDismissible = true}) {
  final ds = context.ds;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: ds.bg.withAlpha(0xB8),
    transitionDuration: Durations.slow,
    pageBuilder: (ctx, _, __) => SafeArea(child: Builder(builder: builder)),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Easings.standard, reverseCurve: Easings.exit);
      return FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, child) => Transform.translate(offset: Offset(0, (1 - curved.value) * Spacing.s2), child: child),
          child: child,
        ),
      );
    },
  );
}

/// Confirmation for an irreversible action: `sm` dialog, `trash` icon on
/// `danger-subtle`, Cancel (ghost) and a `danger` confirm button.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  required String closeLabel,
}) async {
  final result = await showDsDialog<bool>(
    context: context,
    builder: (ctx) => DsDialog(
      title: title,
      description: message,
      icon: 'trash',
      danger: true,
      size: DsDialogSize.sm,
      closeLabel: closeLabel,
      onClose: () => Navigator.of(ctx).pop(false),
      actions: [
        DsButton.ghost(label: cancelLabel, onPressed: () => Navigator.of(ctx).pop(false)),
        DsButton.danger(label: confirmLabel, icon: 'trash', onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ),
  );
  return result ?? false;
}
