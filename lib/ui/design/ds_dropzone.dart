import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart' hide Durations;
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import 'ds_dashed.dart';
import 'ds_icon.dart';
import 'ds_interactive.dart';

/// Drop target for audio files. Click opens the system picker, a drag over
/// the area switches it to the "release" state.
class DsDropzone extends StatefulWidget {
  final String title;
  final String hint;
  final String overTitle;
  final bool compact;
  final bool? active;
  final VoidCallback? onBrowse;
  final ValueChanged<List<String>>? onFiles;

  const DsDropzone({
    super.key,
    required this.title,
    required this.hint,
    required this.overTitle,
    this.compact = false,
    this.active,
    this.onBrowse,
    this.onFiles,
  });

  @override
  State<DsDropzone> createState() => _DsDropzoneState();
}

class _DsDropzoneState extends State<DsDropzone> {
  bool _over = false;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final over = widget.active ?? _over;

    final zone = DsInteractive(
      onTap: widget.onBrowse ?? () {},
      focusRadius: Radii.lgAll,
      semanticLabel: widget.title,
      builder: (context, s) {
        final icon = Container(
          width: widget.compact ? Sizes.targetMin : Sizes.targetLg,
          height: widget.compact ? Sizes.targetMin : Sizes.targetLg,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ds.surfaceRaised,
            borderRadius: widget.compact ? Radii.mdAll : Radii.lgAll,
            border: Border.all(color: ds.border, width: Sizes.borderWidth),
          ),
          child: DsIcon('upload', size: Sizes.iconLg, color: over ? ds.primary : ds.textMuted),
        );
        final text = Column(
          crossAxisAlignment: widget.compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(over ? widget.overTitle : widget.title, style: ds.body.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: Spacing.s0),
            Text(widget.hint, style: ds.caption, textAlign: widget.compact ? TextAlign.start : TextAlign.center),
          ],
        );
        return AnimatedContainer(
          duration: Durations.fast,
          curve: Curves.easeOut,
          width: double.infinity,
          padding: widget.compact
              ? const EdgeInsets.symmetric(horizontal: Spacing.s4, vertical: Spacing.s3)
              : const EdgeInsets.symmetric(horizontal: Spacing.s5, vertical: Spacing.s6),
          decoration: DsDashedDecoration(
            color: over ? ds.primarySubtle : (s.hovered ? ds.surfaceRaised : Palette.transparent),
            border: over ? ds.primary : ds.borderStrong,
            dashed: !over,
          ),
          child: widget.compact
              ? Row(children: [icon, const SizedBox(width: Spacing.s4), Expanded(child: text)])
              : Column(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(height: Spacing.s3), text]),
        );
      },
    );

    if (widget.onFiles == null) return zone;
    return DropTarget(
      onDragEntered: (_) => setState(() => _over = true),
      onDragExited: (_) => setState(() => _over = false),
      onDragDone: (details) {
        setState(() => _over = false);
        widget.onFiles!(details.files.map((f) => f.path).toList());
      },
      child: zone,
    );
  }
}
