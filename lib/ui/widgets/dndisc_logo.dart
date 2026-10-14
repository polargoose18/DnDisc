import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// DnDisc brand logo widget rendering the official vector emblem.
class DnDiscLogo extends StatelessWidget {
  /// The width and height of the logo emblem.
  final double size;

  /// The stroke tint color. If null, falls back to the current [IconTheme.color] or [ColorScheme.primary].
  final Color? color;

  /// Whether to use the transparent symbol SVG or the full branded badge.
  final bool useSymbol;

  const DnDiscLogo({
    super.key,
    this.size = 24.0,
    this.color,
    this.useSymbol = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.primary;

    if (useSymbol) {
      return SvgPicture.asset(
        'assets/logo_symbol.svg',
        width: size,
        height: size,
        theme: SvgTheme(currentColor: effectiveColor),
        colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
        semanticsLabel: 'DnDisc Logo',
      );
    }

    return SvgPicture.asset(
      'assets/logo.svg',
      width: size,
      height: size,
      semanticsLabel: 'DnDisc Logo',
    );
  }
}
