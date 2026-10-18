import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_icon.dart';
import 'ds_interactive.dart';

/// Thumb of the design-system slider: 16px, filled with `primary` and ringed
/// with the panel colour so it reads on the filled track.
class _DsThumbShape extends SliderComponentShape {
  final Color fill;
  final Color ring;

  const _DsThumbShape({required this.fill, required this.ring});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size.square(Sizes.sliderThumb);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, Sizes.sliderThumb / 2, Paint()..color = ring);
    canvas.drawCircle(center, Sizes.sliderThumb / 2 - 2, Paint()..color = fill);
  }
}

/// Volume or position slider with an icon or short label on the left and
/// the value on the right (tabular digits, fixed width).
class DsSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final String? icon;
  final String? label;
  final String semanticLabel;
  final bool showValue;

  /// Own value text (time); the default is the percentage.
  final String Function(double value)? format;

  /// Colour of the thumb ring; the panel the slider sits on.
  final Color? ringColor;

  const DsSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.min = 0,
    this.max = 1,
    this.icon,
    this.label,
    this.showValue = true,
    this.format,
    this.ringColor,
  });

  @override
  State<DsSlider> createState() => _DsSliderState();
}

class _DsSliderState extends State<DsSlider> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String _text() {
    if (widget.format != null) return widget.format!(widget.value);
    final span = widget.max - widget.min;
    final fraction = span == 0 ? 0.0 : (widget.value - widget.min) / span;
    return '${(fraction * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final span = widget.max - widget.min;
    final step = span / 100;
    final onChanged = widget.onChanged;

    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: _DsThumbShape(fill: ds.primary, ring: widget.ringColor ?? ds.surface),
        overlayShape: SliderComponentShape.noOverlay,
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (onChanged == null || event is KeyUpEvent) return KeyEventResult.ignored;
          final big = HardwareKeyboard.instance.isShiftPressed ? 10 : 1;
          if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.arrowUp) {
            onChanged((widget.value + step * big).clamp(widget.min, widget.max));
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.arrowDown) {
            onChanged((widget.value - step * big).clamp(widget.min, widget.max));
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Slider(
          focusNode: _focus,
          value: widget.value.clamp(widget.min, widget.max),
          min: widget.min,
          max: widget.max,
          onChanged: onChanged,
          semanticFormatterCallback: (_) => '${widget.semanticLabel}, ${_text()}',
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.targetMin),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            DsIcon(widget.icon!),
            const SizedBox(width: Spacing.s2),
          ],
          if (widget.label != null) ...[
            Text(widget.label!, style: ds.caption),
            const SizedBox(width: Spacing.s2),
          ],
          Expanded(child: DsFocusRing(radius: Radii.smAll, focusNode: _focus, child: slider)),
          if (widget.showValue) ...[
            const SizedBox(width: Spacing.s2),
            SizedBox(
              width: Sizes.sliderValueWidth,
              child: Text(_text(), textAlign: TextAlign.right, style: ds.tabular(ds.caption)),
            ),
          ],
        ],
      ),
    );
  }
}
