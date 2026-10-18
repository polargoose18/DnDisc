import 'package:flutter/material.dart' hide Durations;
import 'package:flutter/services.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_button.dart';
import 'ds_icon.dart';
import 'ds_interactive.dart';

/// Label above, hint or error below. Shared by text fields and selects.
class _FieldFrame extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? error;
  final bool enabled;
  final Widget child;

  const _FieldFrame({
    required this.label,
    required this.hint,
    required this.error,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: ds.label.copyWith(color: enabled ? ds.text : ds.textDisabled)),
          const SizedBox(height: Spacing.s1 + 2),
        ],
        child,
        if (error != null) ...[
          const SizedBox(height: Spacing.s1 + 2),
          Text(error!, style: ds.caption.copyWith(color: ds.danger)),
        ] else if (hint != null) ...[
          const SizedBox(height: Spacing.s1 + 2),
          Text(hint!, style: ds.caption),
        ],
      ],
    );
  }
}

/// Single-line text field: search, names, addresses. 40px high, outline
/// `border-strong`, `focus-ring` around the whole field.
class DsTextField extends StatefulWidget {
  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? placeholder;
  final String? icon;
  final bool clearable;
  final String? clearLabel;
  final String? hotkey;
  final String? hint;
  final String? error;
  final bool enabled;
  final bool autofocus;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final int? maxLines;

  const DsTextField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.placeholder,
    this.icon,
    this.clearable = false,
    this.clearLabel,
    this.hotkey,
    this.hint,
    this.error,
    this.enabled = true,
    this.autofocus = false,
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
    this.maxLines = 1,
  });

  @override
  State<DsTextField> createState() => _DsTextFieldState();
}

class _DsTextFieldState extends State<DsTextField> {
  TextEditingController? _ownController;
  bool _hovered = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController(text: widget.initialValue));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(DsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onText);
      _controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _ownController?.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final hasText = _controller.text.isNotEmpty;
    final hasError = widget.error != null;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: color, width: Sizes.borderWidth),
        );
    final outline = hasError
        ? ds.danger
        : !widget.enabled
            ? ds.border
            : _hovered
                ? ds.textMuted
                : ds.borderStrong;

    final field = TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: widget.obscure,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: ds.body.copyWith(color: widget.enabled ? ds.text : ds.textDisabled),
      cursorColor: ds.primary,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        hintStyle: ds.body.copyWith(color: ds.textMuted),
        enabledBorder: border(outline),
        focusedBorder: border(outline),
        disabledBorder: border(outline),
        errorBorder: border(outline),
        prefixIcon: widget.icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: Spacing.s3, right: Spacing.s2),
                child: DsIcon(widget.icon!),
              ),
        prefixIconConstraints: const BoxConstraints(minHeight: Sizes.targetMin),
        suffixIcon: _suffix(ds, hasText),
        suffixIconConstraints: const BoxConstraints(minHeight: Sizes.targetMin),
      ),
    );

    return _FieldFrame(
      label: widget.label,
      hint: widget.hint,
      error: widget.error,
      enabled: widget.enabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: DsFocusRing(child: field),
      ),
    );
  }

  Widget? _suffix(DsTheme ds, bool hasText) {
    if (widget.clearable && hasText) {
      return Padding(
        padding: const EdgeInsets.only(right: Spacing.s1),
        child: DsInteractive(
          onTap: () {
            _controller.clear();
            widget.onChanged?.call('');
          },
          semanticLabel: widget.clearLabel,
          focusRadius: Radii.smAll,
          builder: (context, s) => Container(
            width: Sizes.clearButton,
            height: Sizes.clearButton,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.hovered ? ds.surfaceHover : Palette.transparent,
              borderRadius: Radii.smAll,
            ),
            child: DsIcon('x', size: Sizes.iconSm, color: s.hovered ? ds.text : ds.textMuted),
          ),
        ),
      );
    }
    if (widget.hotkey != null && !hasText) {
      return Padding(
        padding: const EdgeInsets.only(right: Spacing.s2),
        child: DsKbd(widget.hotkey!),
      );
    }
    return null;
  }
}

class DsOption<T> {
  final T id;
  final String label;

  const DsOption(this.id, this.label);
}

/// Choice of one value from a long list (output device, language). Looks
/// like [DsTextField]; the list itself is the system dropdown.
class DsSelect<T> extends StatelessWidget {
  final String? label;
  final List<DsOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? icon;
  final String? hint;
  final String? placeholder;
  final bool enabled;

  const DsSelect({
    super.key,
    this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.icon,
    this.hint,
    this.placeholder,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final active = enabled && onChanged != null;
    final dropdown = DropdownButtonFormField<T>(
      initialValue: options.any((o) => o.id == value) ? value : null,
      isExpanded: true,
      isDense: true,
      icon: DsIcon('chevron-down', color: ds.textMuted),
      dropdownColor: ds.surfaceRaised,
      borderRadius: Radii.mdAll,
      style: ds.body.copyWith(color: active ? ds.text : ds.textDisabled),
      hint: placeholder == null ? null : Text(placeholder!, style: ds.body.copyWith(color: ds.textMuted)),
      decoration: InputDecoration(
        prefixIcon: icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: Spacing.s3, right: Spacing.s2),
                child: DsIcon(icon!),
              ),
        prefixIconConstraints: const BoxConstraints(minHeight: Sizes.targetMin),
      ),
      items: [
        for (final o in options)
          DropdownMenuItem<T>(
            value: o.id,
            child: Text(o.label, style: ds.body, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: active ? onChanged : null,
    );
    return _FieldFrame(
      label: label,
      hint: hint,
      error: null,
      enabled: active,
      child: DsFocusRing(child: dropdown),
    );
  }
}
