import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/covers.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';

/// Cover of a scene. Priority: the user's own image [src], then the stored
/// [cover] key, then the cover chosen by [seed]. [dim] (0..100) puts that
/// percentage of the `bg` colour over the image.
class SceneCover extends StatelessWidget {
  final String? cover;
  final String? src;
  final String? seed;
  final int dim;
  final double? width;
  final double? height;
  final double radius;

  const SceneCover({
    super.key,
    this.cover,
    this.src,
    this.seed,
    this.dim = 0,
    this.width,
    this.height,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final userImage = src != null && src!.isNotEmpty && File(src!).existsSync();
    final key = SceneCovers.contains(cover) ? cover! : SceneCovers.forSeed(seed ?? '');

    final image = userImage
        ? Image.file(File(src!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _asset(key))
        : _asset(key);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (dim > 0) ColoredBox(color: ds.bg.withAlpha((dim.clamp(0, 100) * 255 / 100).round())),
          ],
        ),
      ),
    );
  }

  Widget _asset(String key) => SvgPicture.asset(SceneCovers.pathOf(key), fit: BoxFit.cover, alignment: Alignment.center);
}

/// Square thumbnail of a scene (list rows).
class SceneThumb extends StatelessWidget {
  final String? cover;
  final String? src;
  final String seed;
  final double size;

  const SceneThumb({super.key, this.cover, this.src, required this.seed, this.size = Sizes.sceneThumb});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: Radii.mdAll,
        border: Border.all(color: ds.border, width: Sizes.borderWidth),
      ),
      child: SceneCover(cover: cover, src: src, seed: seed, radius: Radii.md - Sizes.borderWidth),
    );
  }
}
