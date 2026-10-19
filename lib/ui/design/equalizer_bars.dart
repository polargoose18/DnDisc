import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';

/// Thin vertical bars that show that sound is playing. The only continuously
/// animated element of the interface.
///
/// Without [levels] the motion is simulated (each bar has its own period and
/// phase); with [levels] (0..1) the bars follow the data. Under
/// `MediaQuery.disableAnimations` they stay static.
class EqualizerBars extends StatefulWidget {
  final bool active;
  final int bars;
  final double height;
  final List<double>? levels;

  /// Wide variant: bars grow with the width (up to 6px each, gap 3px).
  final bool wide;
  final Color? color;

  const EqualizerBars({
    super.key,
    required this.active,
    this.bars = 4,
    this.height = Sizes.iconSm,
    this.levels,
    this.wide = false,
    this.color,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _seconds = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => _seconds.value = elapsed.inMicroseconds / 1e6);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  bool get _simulated => widget.active && widget.levels == null && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    if (_simulated) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
    final color = widget.color ?? (widget.active ? ds.primary : ds.textMuted);

    Widget paint(double seconds) => CustomPaint(
          size: Size(widget.wide ? double.infinity : _width, widget.height),
          painter: _BarsPainter(
            bars: widget.bars,
            color: color,
            active: widget.active,
            levels: widget.levels,
            seconds: _simulated ? seconds : null,
            wide: widget.wide,
          ),
        );

    final child = _simulated ? ValueListenableBuilder<double>(valueListenable: _seconds, builder: (_, s, __) => paint(s)) : paint(0);
    return ExcludeSemantics(child: widget.wide ? SizedBox(height: widget.height, width: double.infinity, child: child) : child);
  }

  double get _width => widget.bars * Sizes.equalizerBar + (widget.bars - 1) * Sizes.equalizerGap;
}

class _BarsPainter extends CustomPainter {
  final int bars;
  final Color color;
  final bool active;
  final List<double>? levels;
  final double? seconds;
  final bool wide;

  const _BarsPainter({
    required this.bars,
    required this.color,
    required this.active,
    required this.levels,
    required this.seconds,
    required this.wide,
  });

  static const List<double> _wave = [0.22, 0.9, 0.42, 1.0, 0.22];
  static const List<double> _relief = [0.45, 0.8, 0.55, 0.95, 0.35, 0.7];

  double _level(int i) {
    if (levels != null && levels!.isNotEmpty) return levels![i % levels!.length].clamp(0.1, 1.0);
    if (!active) return 0.3;
    final s = seconds;
    if (s == null) return _relief[(i * 5) % _relief.length];
    final n = i + 1;
    final period = n % 5 == 0 ? 1.6 : (n % 3 == 1 ? 0.9 : (n % 3 == 2 ? 1.25 : 1.1));
    final phase = ((s + i * 0.137) / period) % 1.0;
    final scaled = phase * (_wave.length - 1);
    final index = scaled.floor().clamp(0, _wave.length - 2);
    final t = scaled - index;
    return _wave[index] + (_wave[index + 1] - _wave[index]) * t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gap = wide ? 3.0 : Sizes.equalizerGap;
    var barWidth = Sizes.equalizerBar;
    if (wide && size.width.isFinite) {
      barWidth = ((size.width - gap * (bars - 1)) / bars).clamp(1.0, 6.0);
    }
    final paint = Paint()..color = color;
    for (var i = 0; i < bars; i++) {
      final h = size.height * _level(i);
      final x = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, barWidth, h), const Radius.circular(Sizes.equalizerRadius)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.seconds != seconds || old.active != active || old.color != color || old.levels != levels || old.bars != bars;
}
