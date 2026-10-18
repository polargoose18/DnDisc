import 'package:flutter/widgets.dart';
import '../../theme/tokens.dart';

/// Window class that decides the layout: wide (>=1000px), medium (700-999px)
/// or compact (<700px).
enum ShellLayout {
  wide,
  medium,
  compact;

  static ShellLayout of(double width) {
    if (width >= Sizes.wideBreakpoint) return ShellLayout.wide;
    if (width >= Sizes.compactBreakpoint) return ShellLayout.medium;
    return ShellLayout.compact;
  }
}

/// What the shell offers to the screens inside it.
class ShellScope extends InheritedWidget {
  final ShellLayout layout;

  /// Opens the navigation as a slide-out panel (compact layout has no rail).
  final VoidCallback openNavigation;

  /// Opens the end drawer with the log console.
  final VoidCallback openLogs;

  const ShellScope({
    super.key,
    required this.layout,
    required this.openNavigation,
    required this.openLogs,
    required super.child,
  });

  static ShellScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>();

  static ShellScope of(BuildContext context) => maybeOf(context)!;

  @override
  bool updateShouldNotify(ShellScope oldWidget) => layout != oldWidget.layout;
}
