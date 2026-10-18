import 'package:flutter/material.dart' hide Durations;
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_icon.dart';
import 'ds_interactive.dart';

/// Grid of icons to choose the icon of a sound or a layer. The selected icon
/// sits on `primary-subtle` with a `primary` outline.
class DsIconPicker extends StatelessWidget {
  final List<String> keys;
  final String? selected;
  final ValueChanged<String> onChanged;

  const DsIconPicker({super.key, required this.keys, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Wrap(
      spacing: Spacing.s2,
      runSpacing: Spacing.s2,
      children: [
        for (final key in keys)
          DsInteractive(
            onTap: () => onChanged(key),
            toggled: key == selected,
            semanticLabel: key,
            builder: (context, s) {
              final on = key == selected;
              return AnimatedContainer(
                duration: Durations.fast,
                width: Sizes.targetMin,
                height: Sizes.targetMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? ds.primarySubtle : (s.hovered ? ds.surfaceHover : ds.surfaceRaised),
                  borderRadius: Radii.mdAll,
                  border: Border.all(color: on ? ds.primary : ds.border, width: Sizes.borderWidth),
                ),
                child: DsIcon(key, size: Sizes.iconLayer, color: on ? ds.primary : ds.textMuted),
              );
            },
          ),
      ],
    );
  }
}
