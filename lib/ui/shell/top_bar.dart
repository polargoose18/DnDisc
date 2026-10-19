import 'package:flutter/material.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import 'shell_scope.dart';

/// Bar over the work area: screen title on the left, actions on the right.
/// In the compact layout (no rail) it also shows the navigation button.
class TopBar extends StatelessWidget {
  final String title;
  final List<Widget> leading;
  final List<Widget> actions;
  final String navigationLabel;

  const TopBar({
    super.key,
    required this.title,
    this.leading = const [],
    this.actions = const [],
    required this.navigationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final scope = ShellScope.maybeOf(context);
    return Container(
      height: Sizes.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ds.border, width: Sizes.borderWidth)),
      ),
      child: Row(
        children: [
          if (scope?.layout == ShellLayout.compact) ...[
            DsButton.ghost(icon: 'panel-left', iconOnly: true, label: navigationLabel, onPressed: scope!.openNavigation),
            const SizedBox(width: Spacing.s2),
          ],
          for (final widget in leading) ...[widget, const SizedBox(width: Spacing.s2)],
          Expanded(child: Text(title, style: ds.titleLg, maxLines: 1, overflow: TextOverflow.ellipsis)),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: Spacing.s2),
            actions[i],
          ],
        ],
      ),
    );
  }
}
