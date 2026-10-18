import 'package:flutter/material.dart' hide Durations;
import '../../theme/color_math.dart' as cm;
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_icon.dart';
import 'ds_interactive.dart';

/// Short status label: Playing, Paused, Installed, File missing.
enum DsTone { neutral, primary, success, danger }

class DsBadge extends StatelessWidget {
  final String label;
  final DsTone tone;
  final bool dot;

  const DsBadge(this.label, {super.key, this.tone = DsTone.neutral, this.dot = false});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final (background, foreground) = switch (tone) {
      DsTone.neutral => (ds.surfaceHover, ds.text),
      DsTone.primary => (ds.primarySubtle, ds.primary),
      DsTone.success => (ds.successSubtle, ds.success),
      DsTone.danger => (ds.dangerSubtle, ds.danger),
    };
    return Container(
      height: Sizes.icon,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s2),
      decoration: BoxDecoration(color: background, borderRadius: Radii.smAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: Spacing.s1h,
              height: Spacing.s1h,
              decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
            ),
            const SizedBox(width: Spacing.s1h),
          ],
          Text(label, style: ds.captionStrong.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

/// Tag (static, 24px) or toggle chip (32px, `onTap` set).
class DsChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const DsChip(this.label, {super.key, this.selected = false, this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final toggle = onTap != null;
    final text = Text(
      label,
      style: ds.captionStrong.copyWith(color: selected ? ds.text : ds.textMuted),
    );
    final remove = onRemove == null
        ? null
        : DsInteractive(
            onTap: onRemove,
            semanticLabel: label,
            focusRadius: Radii.smAll,
            builder: (context, s) => Container(
              width: Sizes.icon,
              height: Sizes.icon,
              margin: const EdgeInsets.only(left: Spacing.s1, right: -Spacing.s1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: s.hovered ? ds.surfaceRaised : Palette.transparent,
                borderRadius: Radii.smAll,
              ),
              child: DsIcon('x', size: Sizes.iconSm, color: s.hovered ? ds.text : ds.textMuted),
            ),
          );

    Widget body(DsStates s) => AnimatedContainer(
          duration: Durations.fast,
          height: toggle ? Sizes.chipToggle : Sizes.chipStatic,
          padding: EdgeInsets.symmetric(horizontal: toggle ? Spacing.s3 : Spacing.s2),
          decoration: BoxDecoration(
            color: selected ? ds.primarySubtle : ds.surfaceHover,
            borderRadius: Radii.smAll,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [text, if (remove != null) remove]),
        );

    if (!toggle) return body(const DsStates());
    return DsInteractive(
      onTap: onTap,
      toggled: selected,
      semanticLabel: label,
      focusRadius: Radii.smAll,
      builder: (context, s) => body(s),
    );
  }
}

/// On/off switch (40x24). The accessible name comes from [label]; there is
/// no visible text, the label sits next to it in the row.
class DsSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  const DsSwitch({super.key, required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    const thumb = Sizes.sliderThumb;
    const inset = (Sizes.switchHeight - thumb) / 2 - Sizes.borderWidth;
    return DsInteractive(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      toggled: value,
      semanticLabel: label,
      focusRadius: Radii.fullAll,
      builder: (context, s) => AnimatedContainer(
        duration: Durations.fast,
        curve: Curves.easeOut,
        width: Sizes.switchWidth,
        height: Sizes.switchHeight,
        decoration: BoxDecoration(
          color: value ? ds.primary : ds.surfaceHover,
          borderRadius: Radii.fullAll,
          border: Border.all(color: value ? ds.primary : ds.borderStrong, width: Sizes.borderWidth),
        ),
        child: AnimatedAlign(
          duration: Durations.fast,
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: inset),
            child: Container(
              width: thumb,
              height: thumb,
              decoration: BoxDecoration(
                color: value ? ds.onPrimary : ds.textMuted,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox row: the whole row toggles. [description] explains the effect.
class DsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? description;

  const DsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final enabled = onChanged != null;
    return DsInteractive(
      onTap: enabled ? () => onChanged!(!value) : null,
      toggled: value,
      semanticLabel: label,
      focusRadius: Radii.smAll,
      builder: (context, s) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.targetMin),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.s2h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: Durations.fast,
                width: Sizes.checkbox,
                height: Sizes.checkbox,
                decoration: BoxDecoration(
                  color: value ? ds.primary : Palette.transparent,
                  borderRadius: Radii.smAll,
                  border: Border.all(
                    color: !enabled ? ds.border : (value ? ds.primary : ds.borderStrong),
                    width: Sizes.checkboxBorder,
                  ),
                ),
                child: value ? Center(child: DsIcon('check', size: Sizes.iconSm, color: ds.onPrimary)) : null,
              ),
              const SizedBox(width: Spacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: ds.body.copyWith(color: enabled ? ds.text : ds.textDisabled)),
                    if (description != null) ...[
                      const SizedBox(height: Spacing.s0),
                      Text(description!, style: ds.caption),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DsSegment<T> {
  final T id;
  final String label;
  final Color? color;
  final String? key;

  const DsSegment({required this.id, required this.label, this.color, this.key});
}

/// Single choice from a few options. With [DsSegment.color] the selected
/// segment gets a 16% tint and outline of that colour (intensity switch).
class DsSegmentedControl<T> extends StatelessWidget {
  final List<DsSegment<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String label;

  /// Collapse to dot + key only (narrow windows).
  final bool compact;

  const DsSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s1),
        decoration: BoxDecoration(
          color: ds.surfaceRaised,
          borderRadius: Radii.lgAll,
          border: Border.all(color: ds.border, width: Sizes.borderWidth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: Spacing.s1),
              _item(context, ds, options[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, DsTheme ds, DsSegment<T> option) {
    final selected = option.id == value;
    final accent = option.color ?? ds.textMuted;
    return DsInteractive(
      onTap: () => onChanged(option.id),
      toggled: selected,
      semanticLabel: option.label,
      builder: (context, s) {
        final tint = Color(cm.mix(accent.toARGB32(), ds.surfaceRaised.toARGB32(), 0.16));
        return AnimatedContainer(
          duration: Durations.fast,
          curve: Curves.easeOut,
          height: Sizes.targetMin,
          padding: EdgeInsets.symmetric(horizontal: compact ? Spacing.s2 : Spacing.s3),
          decoration: BoxDecoration(
            color: selected
                ? (option.color == null ? ds.primarySubtle : tint)
                : (s.hovered ? ds.surfaceHover : Palette.transparent),
            borderRadius: Radii.mdAll,
            border: Border.all(
              color: selected ? (option.color ?? ds.primary) : Palette.transparent,
              width: Sizes.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.color != null) ...[
                Container(
                  width: Spacing.s2,
                  height: Spacing.s2,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                if (!compact || option.key != null) const SizedBox(width: Spacing.s2),
              ],
              if (!compact)
                Text(
                  option.label,
                  style: ds.label.copyWith(color: selected || s.hovered ? ds.text : ds.textMuted),
                ),
              if (option.key != null) ...[
                if (!compact) const SizedBox(width: Spacing.s2),
                Text(option.key!, style: ds.caption.copyWith(color: selected ? ds.text : ds.textMuted)),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Thin progress bar for imports, downloads and scans. Without [value] it is
/// indeterminate (a 30% segment runs along the track).
class DsProgressBar extends StatefulWidget {
  final double? value;
  final String? label;
  final String? caption;
  final bool showValue;

  /// [value] is 0..1.
  const DsProgressBar({super.key, this.value, this.label, this.caption, this.showValue = true});

  @override
  State<DsProgressBar> createState() => _DsProgressBarState();
}

class _DsProgressBarState extends State<DsProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: Durations.indeterminate);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final determinate = widget.value != null;
    if (!determinate && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }

    final track = ClipRRect(
      borderRadius: Radii.fullAll,
      child: SizedBox(
        height: Sizes.sliderTrack,
        child: LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            return Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: ds.surfaceHover)),
                if (determinate)
                  AnimatedPositioned(
                    duration: Durations.base,
                    curve: Curves.easeOut,
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: width * widget.value!.clamp(0.0, 1.0),
                    child: DecoratedBox(decoration: BoxDecoration(color: ds.primary, borderRadius: Radii.fullAll)),
                  )
                else if (reduceMotion)
                  Positioned.fill(child: ColoredBox(color: ds.primarySubtle))
                else
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => Positioned(
                      left: -width * 0.3 + _controller.value * width * 1.3,
                      top: 0,
                      bottom: 0,
                      width: width * 0.3,
                      child: DecoratedBox(decoration: BoxDecoration(color: ds.primary, borderRadius: Radii.fullAll)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || (determinate && widget.showValue))
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.s1h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null) Flexible(child: Text(widget.label!, style: ds.caption, overflow: TextOverflow.ellipsis)),
                if (determinate && widget.showValue)
                  Text('${(widget.value! * 100).round()}%', style: ds.tabular(ds.caption)),
              ],
            ),
          ),
        track,
        if (widget.caption != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.s1h),
            child: Text(widget.caption!, style: ds.caption),
          ),
      ],
    );
  }
}
