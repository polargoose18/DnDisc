import 'package:flutter/material.dart' hide Durations;
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_icon.dart';
import '../design/ds_interactive.dart';
import '../design/ds_tooltip.dart';

class NavItem {
  final String id;
  final String icon;
  final String label;

  const NavItem({required this.id, required this.icon, required this.label});
}

/// Side navigation. Collapsed to 64px (icons with tooltips) or open to 224px;
/// there is no logo in the rail. [onToggle] null hides the expand button.
class NavRail extends StatelessWidget {
  final List<NavItem> items;
  final String active;
  final ValueChanged<String> onSelect;
  final bool open;
  final VoidCallback? onToggle;
  final String toggleLabel;

  const NavRail({
    super.key,
    required this.items,
    required this.active,
    required this.onSelect,
    required this.open,
    required this.toggleLabel,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return AnimatedContainer(
      duration: Durations.base,
      curve: Easings.standard,
      width: open ? Sizes.railWidthOpen : Sizes.railWidth,
      padding: const EdgeInsets.all(Spacing.s2),
      decoration: BoxDecoration(
        color: ds.surface,
        border: Border(right: BorderSide(color: ds.border, width: Sizes.borderWidth)),
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items) ...[
              _NavButton(item: item, selected: item.id == active, open: open, onTap: () => onSelect(item.id)),
              const SizedBox(height: Spacing.s1),
            ],
            const Spacer(),
            if (onToggle != null)
              Align(
                alignment: open ? Alignment.centerRight : Alignment.center,
                child: DsButton.ghost(icon: 'panel-left', iconOnly: true, label: toggleLabel, onPressed: onToggle),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final bool open;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final button = DsInteractive(
      onTap: onTap,
      selected: selected,
      semanticLabel: item.label,
      builder: (context, s) {
        final color = selected ? ds.primary : (s.hovered ? ds.text : ds.textMuted);
        return AnimatedContainer(
          duration: Durations.fast,
          curve: Curves.easeOut,
          height: Sizes.targetLg,
          decoration: BoxDecoration(
            color: selected ? ds.primarySubtle : (s.hovered ? ds.surfaceHover : Palette.transparent),
            borderRadius: Radii.mdAll,
          ),
          child: LayoutBuilder(
            builder: (context, c) => c.maxWidth > Sizes.railWidth
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.s3h),
                    child: Row(
                      children: [
                        DsIcon(item.icon, color: color),
                        const SizedBox(width: Spacing.s3),
                        Expanded(
                          child: Text(
                            item.label,
                            style: ds.body.copyWith(fontWeight: FontWeight.w500, color: color),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(child: DsIcon(item.icon, color: color)),
          ),
        );
      },
    );
    return open ? button : DsTooltip(label: item.label, child: button);
  }
}
