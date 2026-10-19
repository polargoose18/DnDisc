import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';

/// Pointer and keyboard state of an interactive element.
class DsStates {
  final bool hovered;
  final bool pressed;
  final bool focused;
  final bool enabled;

  const DsStates({
    this.hovered = false,
    this.pressed = false,
    this.focused = false,
    this.enabled = true,
  });
}

/// Draws the `focus-ring` (2px, 2px offset) around [child] while it or a
/// descendant has keyboard focus.
class DsFocusRing extends StatefulWidget {
  final Widget child;
  final BorderRadius radius;
  final FocusNode? focusNode;

  const DsFocusRing({
    super.key,
    required this.child,
    this.radius = Radii.mdAll,
    this.focusNode,
  });

  @override
  State<DsFocusRing> createState() => _DsFocusRingState();
}

class _DsFocusRingState extends State<DsFocusRing> {
  FocusNode? _ownNode;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode(skipTraversal: true, canRequestFocus: false));

  @override
  void initState() {
    super.initState();
    _node.addListener(_update);
  }

  @override
  void didUpdateWidget(DsFocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_update);
      _node.addListener(_update);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_update);
    _ownNode?.dispose();
    super.dispose();
  }

  void _update() {
    final show = _node.hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (show != _focused) setState(() => _focused = show);
  }

  @override
  Widget build(BuildContext context) {
    final ring = context.ds.focusRing;
    final child = widget.focusNode == null
        ? Focus(focusNode: _node, canRequestFocus: false, skipTraversal: true, child: widget.child)
        : widget.child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (_focused)
          Positioned.fill(
            left: -(Sizes.focusRing * 2),
            top: -(Sizes.focusRing * 2),
            right: -(Sizes.focusRing * 2),
            bottom: -(Sizes.focusRing * 2),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.radius + BorderRadius.circular(Sizes.focusRing * 2),
                  border: Border.all(color: ring, width: Sizes.focusRing),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Hover, press and keyboard-focus handling shared by every clickable
/// element. Colour transitions are the caller's job (use `AnimatedContainer`
/// with the `duration-fast` token).
class DsInteractive extends StatefulWidget {
  final Widget Function(BuildContext context, DsStates states) builder;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final VoidCallback? onLongPress;
  final BorderRadius focusRadius;
  final String? semanticLabel;
  final bool? toggled;
  final bool selected;
  final MouseCursor? cursor;

  const DsInteractive({
    super.key,
    required this.builder,
    this.onTap,
    this.onSecondaryTapUp,
    this.onLongPress,
    this.focusRadius = Radii.mdAll,
    this.semanticLabel,
    this.toggled,
    this.selected = false,
    this.cursor,
  });

  @override
  State<DsInteractive> createState() => _DsInteractiveState();
}

class _DsInteractiveState extends State<DsInteractive> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final states = DsStates(hovered: _hovered, pressed: _pressed, focused: _focused, enabled: _enabled);
    final ring = context.ds.focusRing;

    Widget content = widget.builder(context, states);
    content = Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        content,
        if (_focused && _enabled)
          Positioned.fill(
            left: -(Sizes.focusRing * 2),
            top: -(Sizes.focusRing * 2),
            right: -(Sizes.focusRing * 2),
            bottom: -(Sizes.focusRing * 2),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.focusRadius + BorderRadius.circular(Sizes.focusRing * 2),
                  border: Border.all(color: ring, width: Sizes.focusRing),
                ),
              ),
            ),
          ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      toggled: widget.toggled,
      selected: widget.selected,
      container: true,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: widget.cursor ?? (_enabled ? SystemMouseCursors.click : SystemMouseCursors.basic),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            widget.onTap?.call();
            return null;
          }),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onSecondaryTapUp: widget.onSecondaryTapUp,
          onLongPress: widget.onLongPress,
          child: content,
        ),
      ),
    );
  }
}
