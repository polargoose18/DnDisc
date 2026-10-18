import 'dart:async';
import 'package:flutter/material.dart' hide Durations;
import 'package:provider/provider.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_button.dart';
import 'ds_controls.dart';
import 'ds_icon.dart';

class ToastAction {
  final String label;
  final VoidCallback onPressed;

  const ToastAction(this.label, this.onPressed);
}

class ToastData {
  final int id;
  final String title;
  final String? message;
  final DsTone tone;
  final double? progress;
  final ToastAction? action;

  const ToastData({
    required this.id,
    required this.title,
    this.message,
    this.tone = DsTone.neutral,
    this.progress,
    this.action,
  });

  ToastData copyWith({String? title, String? message, double? progress}) => ToastData(
        id: id,
        title: title ?? this.title,
        message: message ?? this.message,
        tone: tone,
        progress: progress ?? this.progress,
        action: action,
      );
}

/// Result of background actions, bottom right above the mixer. At most
/// three at a time, newest on top; errors stay until closed, the rest
/// disappear after five seconds (the timer stops while the pointer is over).
class ToastController extends ChangeNotifier {
  static const int maxVisible = 3;

  final List<ToastData> _toasts = [];
  final Map<int, Timer> _timers = {};
  int _nextId = 1;

  List<ToastData> get toasts => List.unmodifiable(_toasts);

  int show({
    required String title,
    String? message,
    DsTone tone = DsTone.neutral,
    double? progress,
    ToastAction? action,
  }) {
    final id = _nextId++;
    _toasts.insert(0, ToastData(id: id, title: title, message: message, tone: tone, progress: progress, action: action));
    while (_toasts.length > maxVisible) {
      dismiss(_toasts.last.id);
    }
    if (progress == null) _startTimer(id, tone);
    notifyListeners();
    return id;
  }

  void success(String title, {String? message, ToastAction? action}) =>
      show(title: title, message: message, tone: DsTone.success, action: action);

  void error(String title, {String? message, ToastAction? action}) =>
      show(title: title, message: message, tone: DsTone.danger, action: action);

  /// Updates a toast that shows progress; at 1.0 it behaves like a normal
  /// toast and disappears after five seconds.
  void update(int id, {String? title, String? message, double? progress}) {
    final index = _toasts.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _toasts[index] = _toasts[index].copyWith(title: title, message: message, progress: progress);
    if (progress != null && progress >= 1 && !_timers.containsKey(id)) _startTimer(id, _toasts[index].tone);
    notifyListeners();
  }

  void dismiss(int id) {
    _timers.remove(id)?.cancel();
    _toasts.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void pause(int id) => _timers.remove(id)?.cancel();

  void resume(int id) {
    final index = _toasts.indexWhere((t) => t.id == id);
    if (index == -1 || _timers.containsKey(id)) return;
    final toast = _toasts[index];
    if (toast.tone != DsTone.danger && (toast.progress == null || toast.progress! >= 1)) _startTimer(id, toast.tone);
  }

  void _startTimer(int id, DsTone tone) {
    if (tone == DsTone.danger) return;
    _timers[id]?.cancel();
    _timers[id] = Timer(Durations.toast, () => dismiss(id));
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}

/// Places the active toasts above the app (use in `MaterialApp.builder`).
/// Has its own [Overlay] so tooltips inside a toast work above the navigator.
class ToastHost extends StatelessWidget {
  final Widget child;
  final String closeLabel;
  final double bottomInset;

  const ToastHost({super.key, required this.child, required this.closeLabel, this.bottomInset = Sizes.mixerHeight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Overlay(
            initialEntries: [
              OverlayEntry(builder: (_) => _ToastLayer(closeLabel: closeLabel, bottomInset: bottomInset)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToastLayer extends StatelessWidget {
  final String closeLabel;
  final double bottomInset;

  const _ToastLayer({required this.closeLabel, required this.bottomInset});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ToastController?>();
    if (controller == null || controller.toasts.isEmpty) return const SizedBox.shrink();
    return Stack(
      children: [
        Positioned(
          right: Spacing.s4,
          bottom: bottomInset + Spacing.s4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.toastWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final toast in controller.toasts)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.s2),
                    child: DsToast(
                      key: ValueKey(toast.id),
                      data: toast,
                      closeLabel: closeLabel,
                      onClose: () => controller.dismiss(toast.id),
                      onHover: (hovering) => hovering ? controller.pause(toast.id) : controller.resume(toast.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DsToast extends StatelessWidget {
  final ToastData data;
  final String closeLabel;
  final VoidCallback onClose;
  final ValueChanged<bool>? onHover;

  const DsToast({super.key, required this.data, required this.closeLabel, required this.onClose, this.onHover});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final (icon, color) = switch (data.tone) {
      DsTone.success => ('check-circle', ds.success),
      DsTone.danger => ('alert', ds.danger),
      _ => ('info', ds.textMuted),
    };
    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: Material(
        color: Palette.transparent,
        child: Container(
          width: Sizes.toastWidth,
          padding: const EdgeInsets.fromLTRB(Spacing.s4, Spacing.s1, Spacing.s1, Spacing.s1),
          decoration: BoxDecoration(
            color: ds.surfaceRaised,
            borderRadius: Radii.mdAll,
            border: Border.all(color: ds.border, width: Sizes.borderWidth),
            boxShadow: Shadows.overlay,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: Spacing.s2 + 2),
                child: DsIcon(icon, color: color),
              ),
              const SizedBox(width: Spacing.s3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.s2 + 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.title, style: ds.body.copyWith(fontWeight: FontWeight.w500)),
                      if (data.message != null) ...[
                        const SizedBox(height: 2),
                        Text(data.message!, style: ds.caption),
                      ],
                      if (data.progress != null) ...[
                        const SizedBox(height: Spacing.s2),
                        DsProgressBar(value: data.progress, showValue: false),
                      ],
                    ],
                  ),
                ),
              ),
              if (data.action != null)
                DsButton.ghost(label: data.action!.label, onPressed: data.action!.onPressed),
              DsButton.ghost(icon: 'x', iconOnly: true, label: closeLabel, onPressed: onClose),
            ],
          ),
        ),
      ),
    );
  }
}
