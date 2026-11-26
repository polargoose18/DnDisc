import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

/// Dashed or solid rounded outline with a fill (dropzones, empty slots).
class DsDashedDecoration extends Decoration {
  final Color color;
  final Color border;
  final bool dashed;
  final double radius;

  const DsDashedDecoration({
    required this.color,
    required this.border,
    required this.dashed,
    this.radius = Radii.lg,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DashedPainter(this);
}

class _DashedPainter extends BoxPainter {
  final DsDashedDecoration d;

  _DashedPainter(this.d);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    final rrect = RRect.fromRectAndRadius(offset & size, Radius.circular(d.radius));
    canvas.drawRRect(rrect, Paint()..color = d.color);
    final stroke = Paint()
      ..color = d.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = Sizes.borderWidth;
    if (!d.dashed) {
      canvas.drawRRect(rrect.deflate(0.5), stroke);
      return;
    }
    final path = Path()..addRRect(rrect.deflate(0.5));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), stroke);
        distance += 8;
      }
    }
  }
}
