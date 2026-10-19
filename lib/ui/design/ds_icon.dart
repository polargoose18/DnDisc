import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/icons.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';

/// Icon from the DnDisc set. Colour defaults to `text-muted`; sizes are
/// 16, 20 (default) and 24.
class DsIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const DsIcon(this.name, {super.key, this.size = Sizes.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.ds.textMuted;
    return SvgPicture.asset(
      DnDiscIcons.pathOf(name),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
