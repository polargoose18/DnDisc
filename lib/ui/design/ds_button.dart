import 'package:flutter/material.dart' hide Durations;
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_icon.dart';
import 'ds_interactive.dart';
import 'ds_tooltip.dart';

enum DsButtonVariant { primary, secondary, ghost, danger, transport }

/// Keyboard shortcut label (`dd-kbd`).
class DsKbd extends StatelessWidget {
  final String text;
  final Color? background;
  final Color? foreground;

  const DsKbd(this.text, {super.key, this.background, this.foreground});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      height: Sizes.icon,
      constraints: const BoxConstraints(minWidth: Sizes.icon),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s1h),
      decoration: BoxDecoration(color: background ?? ds.surfaceHover, borderRadius: Radii.smAll),
      child: Center(
        widthFactor: 1,
        child: Text(text, style: ds.caption.copyWith(color: foreground ?? ds.textMuted)),
      ),
    );
  }
}

/// Action button. One `primary` per visible area, `transport` is the round
/// play/pause button. Icon-only buttons need a [label] (tooltip + semantics).
class DsButton extends StatelessWidget {
  final DsButtonVariant variant;
  final String? label;
  final String? icon;
  final bool iconOnly;
  final String? hotkey;
  final bool large;
  final VoidCallback? onPressed;

  const DsButton({
    super.key,
    this.variant = DsButtonVariant.secondary,
    this.label,
    this.icon,
    this.iconOnly = false,
    this.hotkey,
    this.large = false,
    this.onPressed,
  }) : assert(label != null || icon != null);

  const DsButton.primary({super.key, this.label, this.icon, this.hotkey, this.large = false, this.onPressed})
      : variant = DsButtonVariant.primary,
        iconOnly = false;

  const DsButton.ghost({super.key, this.label, this.icon, this.iconOnly = false, this.hotkey, this.onPressed})
      : variant = DsButtonVariant.ghost,
        large = false;

  const DsButton.danger({super.key, this.label, this.icon, this.hotkey, this.onPressed})
      : variant = DsButtonVariant.danger,
        iconOnly = false,
        large = false;

  const DsButton.transport({super.key, required String this.label, required String this.icon, this.hotkey, this.onPressed})
      : variant = DsButtonVariant.transport,
        iconOnly = true,
        large = true;

  Color _background(DsTheme ds, DsStates s) {
    if (!s.enabled) return variant == DsButtonVariant.ghost || variant == DsButtonVariant.danger ? Palette.transparent : ds.surfaceRaised;
    switch (variant) {
      case DsButtonVariant.primary:
      case DsButtonVariant.transport:
        return s.hovered || s.pressed ? ds.primaryHover : ds.primary;
      case DsButtonVariant.secondary:
        return s.hovered || s.pressed ? ds.surfaceHover : ds.surfaceRaised;
      case DsButtonVariant.ghost:
        return s.hovered || s.pressed ? ds.surfaceHover : Palette.transparent;
      case DsButtonVariant.danger:
        return s.hovered || s.pressed ? ds.dangerSubtle : Palette.transparent;
    }
  }

  Color _foreground(DsTheme ds, DsStates s) {
    if (!s.enabled) return ds.textDisabled;
    switch (variant) {
      case DsButtonVariant.primary:
      case DsButtonVariant.transport:
        return ds.onPrimary;
      case DsButtonVariant.secondary:
        return ds.text;
      case DsButtonVariant.ghost:
        return s.hovered ? ds.text : ds.textMuted;
      case DsButtonVariant.danger:
        return ds.danger;
    }
  }

  Color _border(DsTheme ds, DsStates s) {
    if (!s.enabled) return Palette.transparent;
    switch (variant) {
      case DsButtonVariant.secondary:
        return ds.border;
      case DsButtonVariant.danger:
        return ds.danger;
      default:
        return Palette.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final height = large ? Sizes.targetLg : Sizes.targetMin;
    final round = variant == DsButtonVariant.transport;
    final radius = round ? Radii.fullAll : Radii.mdAll;
    final onlyIcon = iconOnly || label == null;

    Widget button = DsInteractive(
      onTap: onPressed,
      focusRadius: radius,
      semanticLabel: label,
      builder: (context, states) {
        final fg = _foreground(ds, states);
        final children = <Widget>[
          if (icon != null) DsIcon(icon!, color: fg),
          if (!onlyIcon && icon != null) const SizedBox(width: Spacing.s2),
          if (!onlyIcon)
            Flexible(
              child: Text(label!, style: ds.label.copyWith(color: fg), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          if (!onlyIcon && hotkey != null) ...[
            const SizedBox(width: Spacing.s2),
            DsKbd(
              hotkey!,
              background: variant == DsButtonVariant.danger ? ds.dangerSubtle : null,
              foreground: variant == DsButtonVariant.danger ? ds.text : null,
            ),
          ],
        ];
        return AnimatedContainer(
          duration: Durations.fast,
          curve: Curves.easeOut,
          height: height,
          width: onlyIcon ? height : null,
          padding: onlyIcon ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: large ? Spacing.s5 : Spacing.s4),
          alignment: onlyIcon ? Alignment.center : null,
          decoration: BoxDecoration(
            color: _background(ds, states),
            borderRadius: radius,
            border: Border.all(color: _border(ds, states), width: Sizes.borderWidth),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: children),
        );
      },
    );

    if (onlyIcon && label != null) {
      button = DsTooltip(label: label!, hotkey: hotkey, child: button);
    }
    return button;
  }
}
