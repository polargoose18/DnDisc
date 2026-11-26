import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/music_bus_controller.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/scene_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_controls.dart';
import '../design/scene_cover.dart';
import '../view_models/scene_view_model.dart';

/// Header of the active scene (120px): cover dimmed 55%, name, one line of
/// metadata and the only intensity switch of the app.
class SceneBackdropHeader extends StatelessWidget {
  const SceneBackdropHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final scene = context.select<SceneViewModel, SceneModel?>((vm) => vm.activeScene);
    final music = context.watch<MusicBusController>();

    final Widget content;
    if (scene == null) {
      content = Align(
        alignment: Alignment.centerLeft,
        child: Text(l10n.selectScenePrompt, style: ds.body.copyWith(color: ds.textMuted)),
      );
    } else {
      final intensity = scene.musicIntensity ?? MusicIntensity.calm;
      final meta = l10n.sceneMeta(
        intensity.getLocalizedName(l10n),
        l10n.ambientCount(scene.ambientLayerVolumes.length),
        l10n.sfxCount(scene.soundboardSfxIds.length),
      );
      content = LayoutBuilder(
        builder: (context, c) {
          final stacked = c.maxWidth < 700;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(scene.name, style: ds.display, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(meta, style: ds.caption.copyWith(color: ds.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          );
          final switcher = DsSegmentedControl<MusicIntensity>(
            label: l10n.musicIntensityLabel,
            compact: c.maxWidth < 480,
            value: music.currentIntensity,
            onChanged: music.setIntensity,
            options: [
              for (final (index, level) in MusicIntensity.values.indexed)
                DsSegment(
                  id: level,
                  label: level.getLocalizedName(l10n),
                  color: ds.intensityColor(level.name),
                  key: '${index + 1}',
                ),
            ],
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [title, const SizedBox(height: Spacing.s3), switcher],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: Spacing.s4),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: switcher),
                ),
              ),
            ],
          );
        },
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: Sizes.sceneHeaderHeight),
      decoration: BoxDecoration(
        borderRadius: Radii.lgAll,
        border: Border.all(color: ds.border, width: Sizes.borderWidth),
      ),
      child: ClipRRect(
        borderRadius: Radii.lgAll - BorderRadius.circular(Sizes.borderWidth),
        child: Stack(
          children: [
            Positioned.fill(
              child: scene == null
                  ? ColoredBox(color: ds.surface)
                  : SceneCover(cover: scene.cover, src: scene.imagePath, seed: scene.id, dim: 55),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s5, vertical: Spacing.s4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Sizes.sceneHeaderHeight - Spacing.s4 * 2),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
