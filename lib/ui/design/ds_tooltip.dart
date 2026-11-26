import 'package:flutter/material.dart';
import '../../theme/ds_theme.dart';

/// Tooltip with an optional hotkey; styled by `TooltipThemeData`.
class DsTooltip extends StatelessWidget {
  final String label;
  final String? hotkey;
  final Widget child;

  /// Show only on hover or focus, never on long press: for elements whose
  /// long press opens a menu.
  final bool hoverOnly;

  const DsTooltip({super.key, required this.label, this.hotkey, required this.child, this.hoverOnly = false});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Tooltip(
      triggerMode: hoverOnly ? TooltipTriggerMode.manual : null,
      message: hotkey == null ? label : null,
      richMessage: hotkey == null
          ? null
          : TextSpan(
              children: [
                TextSpan(text: label),
                TextSpan(text: ' $hotkey', style: TextStyle(color: ds.bg.withAlpha(0xB3))),
              ],
            ),
      child: child,
    );
  }
}
