import 'package:flutter/material.dart' hide Durations;
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_button.dart';
import 'ds_icon.dart';

/// Entry of a [showDsMenu]; use [DsMenuItem.separator] before the deletion.
class DsMenuItem {
  final String id;
  final String label;
  final String? icon;
  final String? hotkey;
  final bool danger;
  final bool disabled;
  final bool checked;
  final bool isSeparator;

  const DsMenuItem({
    required this.id,
    required this.label,
    this.icon,
    this.hotkey,
    this.danger = false,
    this.disabled = false,
    this.checked = false,
  }) : isSeparator = false;

  const DsMenuItem.separator()
      : id = '',
        label = '',
        icon = null,
        hotkey = null,
        danger = false,
        disabled = false,
        checked = false,
        isSeparator = true;
}

class _DsMenuEntry extends PopupMenuEntry<String> {
  final DsMenuItem item;
  final bool reserveIcon;

  const _DsMenuEntry(this.item, this.reserveIcon);

  @override
  double get height => item.isSeparator ? Spacing.s2 + Sizes.borderWidth : Sizes.targetMin;

  @override
  bool represents(String? value) => !item.isSeparator && value == item.id;

  @override
  State<_DsMenuEntry> createState() => _DsMenuEntryState();
}

class _DsMenuEntryState extends State<_DsMenuEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final item = widget.item;
    if (item.isSeparator) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s1),
        child: Container(height: Sizes.borderWidth, color: ds.border),
      );
    }
    final color = item.disabled ? ds.textDisabled : (item.danger ? ds.danger : ds.text);
    final iconColor = item.disabled ? ds.textDisabled : (item.danger ? ds.danger : ds.textMuted);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: item.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: item.disabled ? null : () => Navigator.of(context).pop(item.id),
        child: Semantics(
          button: true,
          enabled: !item.disabled,
          label: item.label,
          child: Container(
            height: Sizes.targetMin,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s3),
            decoration: BoxDecoration(
              color: _hovered && !item.disabled ? ds.surfaceHover : Palette.transparent,
              borderRadius: Radii.smAll,
            ),
            child: Row(
              children: [
                if (item.icon != null)
                  DsIcon(item.icon!, size: 18, color: iconColor)
                else if (widget.reserveIcon)
                  const SizedBox(width: 18),
                const SizedBox(width: Spacing.s3),
                Expanded(child: Text(item.label, style: ds.body.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (item.hotkey != null) ...[
                  const SizedBox(width: Spacing.s3),
                  DsKbd(item.hotkey!),
                ],
                if (item.checked) ...[
                  const SizedBox(width: Spacing.s3),
                  DsIcon('check', size: 18, color: ds.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> _show(BuildContext context, RelativeRect position, List<DsMenuItem> items) {
  final reserve = items.any((i) => i.icon != null);
  return showMenu<String>(
    context: context,
    position: position,
    constraints: const BoxConstraints(minWidth: 220),
    items: [for (final item in items) _DsMenuEntry(item, reserve)],
    popUpAnimationStyle: const AnimationStyle(duration: Durations.base, curve: Easings.standard, reverseCurve: Easings.exit),
  );
}

/// Opens a menu at a pointer position (right click on a row).
Future<String?> showDsMenuAt(BuildContext context, Offset globalPosition, List<DsMenuItem> items) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final position = RelativeRect.fromLTRB(
    globalPosition.dx,
    globalPosition.dy,
    overlay.size.width - globalPosition.dx,
    overlay.size.height - globalPosition.dy,
  );
  return _show(context, position, items);
}

/// Opens a menu under the widget of [context] (the `more` button).
Future<String?> showDsMenuFor(BuildContext context, List<DsMenuItem> items) {
  final button = context.findRenderObject()! as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final topLeft = button.localToGlobal(Offset(0, button.size.height + Spacing.s1), ancestor: overlay);
  final position = RelativeRect.fromLTRB(
    topLeft.dx + button.size.width - 220,
    topLeft.dy,
    overlay.size.width - (topLeft.dx + button.size.width),
    overlay.size.height - topLeft.dy,
  );
  return _show(context, position, items);
}

/// `more` button that opens [items] and reports the chosen id.
class DsMoreButton extends StatelessWidget {
  final List<DsMenuItem> items;
  final ValueChanged<String> onSelected;
  final String label;

  const DsMoreButton({super.key, required this.items, required this.onSelected, required this.label});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => DsButton.ghost(
        icon: 'more',
        iconOnly: true,
        label: label,
        onPressed: () async {
          final id = await showDsMenuFor(buttonContext, items);
          if (id != null) onSelected(id);
        },
      ),
    );
  }
}
