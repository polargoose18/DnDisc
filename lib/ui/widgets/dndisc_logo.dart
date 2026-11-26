import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/ds_theme.dart';

/// Maps the two colours of `assets/logo/logo-mark.svg` to the theme: the
/// outline takes `text`, the spindle `primary`.
class _LogoColors extends ColorMapper {
  final Color outline;
  final Color spindle;

  const _LogoColors(this.outline, this.spindle);

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    if (color == const Color(0xFFF3ECE2)) return outline;
    if (color == const Color(0xFFD4A373)) return spindle;
    return color;
  }

  @override
  bool operator ==(Object other) => other is _LogoColors && other.outline == outline && other.spindle == spindle;

  @override
  int get hashCode => Object.hash(outline, spindle);
}

/// DnDisc mark (a D built from half a record) in theme colours; with
/// [wordmark] the name is set to the right in IBM Plex Sans 600.
class DnDiscLogo extends StatelessWidget {
  final double size;
  final bool wordmark;

  const DnDiscLogo({super.key, this.size = 32, this.wordmark = false});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final mark = SvgPicture.asset(
      'assets/logo/logo-mark.svg',
      width: size,
      height: size,
      colorMapper: _LogoColors(ds.text, ds.primary),
      semanticsLabel: 'DnDisc',
    );
    if (!wordmark) return mark;
    final fontSize = size * 0.8;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: fontSize * 0.5),
        Text(
          'DnDisc',
          style: ds.title.copyWith(fontSize: fontSize, height: 1, letterSpacing: -fontSize * 0.01, color: ds.text),
        ),
      ],
    );
  }
}
