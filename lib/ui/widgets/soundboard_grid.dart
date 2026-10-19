import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Durations;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../audio/sfx_bus_controller.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/sfx_trigger.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_dashed.dart';
import '../design/ds_dialog.dart';
import '../design/ds_icon.dart';
import '../design/ds_icon_picker.dart';
import '../design/ds_interactive.dart';
import '../design/ds_menu.dart';
import '../design/ds_panel.dart';
import '../design/ds_tooltip.dart';
import '../design/equalizer_bars.dart';
import '../view_models/media_library_view_model.dart';
import 'track_pick_list.dart';

/// SFX panel: a grid of square tiles filling the column, an empty slot to add
/// a sound as the last tile. Tile `n` (1-9) answers to the key `n`.
class SoundboardGrid extends StatelessWidget {
  const SoundboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sfx = context.watch<SfxBusController>();
    final library = context.watch<MediaLibraryViewModel>();
    final triggers = sfx.triggers;

    Duration durationOf(SfxTrigger t) {
      for (final track in library.tracks) {
        if (track.id == t.id) return Duration(milliseconds: track.durationMs);
      }
      return Duration.zero;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        return DsPanel(
          expand: bounded,
          title: l10n.soundboardTitle,
          icon: 'bolt',
          trailing: const DsKbd('1–9'),
          child: LayoutBuilder(
            builder: (context, c) {
              const gap = Spacing.s2;
              final columns = ((c.maxWidth + gap) / (Sizes.sfxTileMin + gap)).floor().clamp(1, 12);
              final tiles = <Widget>[
                for (final (index, trigger) in triggers.indexed)
                  SfxTile(
                    key: ValueKey('sfx_btn_${trigger.id}'),
                    trigger: trigger,
                    hotkey: index < 9 ? '${index + 1}' : null,
                    duration: durationOf(trigger),
                    sfx: sfx,
                  ),
                _EmptySlot(
                  key: const ValueKey('add_sfx_trigger_btn'),
                  label: l10n.addSfxSlot,
                  onTap: () => showAddSfxDialog(context, sfx),
                ),
              ];
              return GridView.count(
                crossAxisCount: columns,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                shrinkWrap: !bounded,
                physics: bounded ? null : const NeverScrollableScrollPhysics(),
                children: tiles,
              );
            },
          ),
        );
      },
    );
  }
}

/// One-shot sound tile. While a sound plays the tile shows `primary-subtle`,
/// a progress ring that runs clockwise along the border from the top centre,
/// and an equalizer in place of the key. A loop has a full `primary` border.
class SfxTile extends StatefulWidget {
  final SfxTrigger trigger;
  final String? hotkey;
  final Duration duration;
  final SfxBusController sfx;

  const SfxTile({super.key, required this.trigger, required this.hotkey, required this.duration, required this.sfx});

  @override
  State<SfxTile> createState() => _SfxTileState();
}

class _SfxTileState extends State<SfxTile> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this);
  bool _playing = false;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  // The bus does not report playback of a single tile, so the tile follows
  // the length of the file (or runs until the next press for a loop).
  void _trigger() {
    widget.sfx.triggerSfx(widget.trigger.id);
    if (widget.trigger.isLoop) {
      setState(() => _playing = !_playing);
      return;
    }
    final length = widget.duration > Durations.slow ? widget.duration : Durations.slow;
    setState(() => _playing = true);
    _progress.duration = length;
    _progress.forward(from: 0).whenComplete(() {
      if (mounted && _progress.isCompleted) setState(() => _playing = false);
    });
  }

  List<DsMenuItem> _items(AppLocalizations l10n) => [
        DsMenuItem(id: 'pin', label: widget.trigger.isPersistent ? l10n.unpinSfx : l10n.pinSfx, icon: 'pin', checked: widget.trigger.isPersistent),
        DsMenuItem(id: 'loop', label: l10n.loopModeCheckbox, icon: 'loop', checked: widget.trigger.isLoop),
        const DsMenuItem.separator(),
        DsMenuItem(id: 'remove', label: l10n.deleteSfxButton, icon: 'trash', danger: true),
      ];

  void _select(String id) {
    switch (id) {
      case 'pin':
        widget.sfx.togglePersistent(widget.trigger.id);
      case 'loop':
        widget.sfx.toggleTriggerLoop(widget.trigger.id);
        if (widget.trigger.isLoop) setState(() => _playing = false);
      case 'remove':
        widget.sfx.removeTrigger(widget.trigger.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final trigger = widget.trigger;

    return DsInteractive(
      onTap: _trigger,
      semanticLabel: trigger.title,
      onLongPress: () async {
        final id = await showDsMenuFor(context, _items(l10n));
        if (id != null) _select(id);
      },
      onSecondaryTapUp: (d) async {
        final id = await showDsMenuAt(context, d.globalPosition, _items(l10n));
        if (id != null) _select(id);
      },
      builder: (context, s) {
        final background = _playing || s.pressed ? ds.primarySubtle : (s.hovered ? ds.surfaceHover : ds.surfaceRaised);
        final ring = _playing && !trigger.isLoop;
        final borderColor = (_playing && trigger.isLoop) || (s.pressed && !ring) ? ds.primary : ds.border;
        final tile = AnimatedContainer(
          duration: Durations.fast,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minWidth: Sizes.sfxTileMin, minHeight: Sizes.sfxTileMin),
          decoration: BoxDecoration(
            color: background,
            borderRadius: Radii.mdAll,
            border: Border.all(color: borderColor, width: Sizes.borderWidth),
          ),
          child: ClipRRect(
            borderRadius: Radii.mdAll,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Spacing.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DsIcon(DnDiscIcons.resolve(trigger.iconName, DnDiscIcons.defaultSfx), size: Sizes.iconLg, color: _playing ? ds.primary : ds.textMuted),
                          const Spacer(),
                          if (trigger.isPersistent) ...[
                            DsIcon('pin', size: Sizes.iconSm, color: ds.primary),
                            const SizedBox(width: Spacing.s1),
                          ],
                          if (_playing) const EqualizerBars(active: true, bars: 3, height: Spacing.s3) else if (widget.hotkey != null) DsKbd(widget.hotkey!),
                        ],
                      ),
                      const Spacer(),
                      Text(trigger.title, style: ds.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        return DsTooltip(
          hoverOnly: true,
          label: trigger.title,
          child: ring
              ? AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) => CustomPaint(
                    foregroundPainter: SfxProgressRingPainter(progress: _progress.value, color: ds.primary),
                    child: child,
                  ),
                  child: tile,
                )
              : tile,
        );
      },
    );
  }
}

/// Progress of a playing tile drawn over its border: starts at the top
/// centre and runs clockwise until the ring is closed at 1.0.
class SfxProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const SfxProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    const inset = Sizes.progressLine / 2;
    final rect = (Offset.zero & size).deflate(inset);
    final r = (Radii.md - inset).clamp(0.0, rect.shortestSide / 2);
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + r), radius: Radius.circular(r))
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(Offset(rect.right - r, rect.bottom), radius: Radius.circular(r))
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - r), radius: Radius.circular(r))
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(Offset(rect.left + r, rect.top), radius: Radius.circular(r))
      ..close();
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = Sizes.progressLine
      ..strokeCap = StrokeCap.butt;
    canvas.drawPath(metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)), paint);
  }

  @override
  bool shouldRepaint(SfxProgressRingPainter old) => old.progress != progress || old.color != color;
}

class _EmptySlot extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmptySlot({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsInteractive(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, s) => DecoratedBox(
        decoration: DsDashedDecoration(
          color: s.hovered ? ds.surfaceRaised : Palette.transparent,
          border: ds.borderStrong,
          dashed: true,
          radius: Radii.md,
        ),
        child: Center(child: DsIcon('plus', size: Sizes.iconLg, color: s.hovered ? ds.text : ds.textMuted)),
      ),
    );
  }
}

Future<void> showAddSfxDialog(BuildContext context, SfxBusController sfx) {
  return showDsDialog<void>(context: context, builder: (_) => _AddSfxTriggerDialog(sfx: sfx));
}

class _AddSfxTriggerDialog extends StatefulWidget {
  final SfxBusController sfx;

  const _AddSfxTriggerDialog({required this.sfx});

  @override
  State<_AddSfxTriggerDialog> createState() => _AddSfxTriggerDialogState();
}

class _AddSfxTriggerDialogState extends State<_AddSfxTriggerDialog> {
  LibraryTrack? _track;
  String _path = '';
  String _title = '';
  String _icon = DnDiscIcons.defaultSfx;
  bool _persistent = true;
  bool _loop = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'ogg', 'flac', 'm4a'],
    );
    final file = result?.files.single;
    if (file?.path == null) return;
    setState(() {
      _track = null;
      _path = file!.path!;
      _title = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final library = context.watch<MediaLibraryViewModel>();
    final tracks = library.tracks.where((t) => t.busType == AudioBusType.sfx).toList();

    return DsDialog(
      title: l10n.addSfxDialogTitle,
      description: l10n.addSfxDialogDesc,
      icon: 'bolt',
      closeLabel: l10n.close,
      actions: [
        DsButton.ghost(label: l10n.cancel, onPressed: () => Navigator.of(context).pop()),
        DsButton.primary(
          key: const ValueKey('add_sfx_confirm_btn'),
          label: l10n.addSfxBtn,
          icon: 'plus',
          onPressed: _path.isEmpty
              ? null
              : () {
                  widget.sfx.addTrigger(
                    SfxTrigger(
                      id: _track?.id ?? const Uuid().v4(),
                      title: _title.isNotEmpty ? _title : l10n.sfx,
                      filePath: _path,
                      isPersistent: _persistent,
                      isLoop: _loop,
                      iconName: _icon,
                    ),
                  );
                  Navigator.of(context).pop();
                },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.fromLibrary, style: ds.label),
          const SizedBox(height: Spacing.s2),
          if (tracks.isEmpty)
            Text(l10n.noSfxTracksInLibrary, style: ds.body.copyWith(color: ds.textMuted))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: Sizes.rowMin * 3),
              child: SingleChildScrollView(
                child: TrackPickList(
                  tracks: tracks,
                  selected: {if (_track != null) _track!.id},
                  onTap: (t) => setState(() {
                    _track = t;
                    _path = t.filePath;
                    _title = t.title;
                    _icon = DnDiscIcons.resolve(t.iconName, DnDiscIcons.defaultSfx);
                  }),
                ),
              ),
            ),
          const SizedBox(height: Spacing.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: DsButton(icon: 'upload', label: l10n.chooseLocalFile, onPressed: _pickFile),
          ),
          if (_track == null && _title.isNotEmpty) ...[
            const SizedBox(height: Spacing.s2),
            Text('${l10n.selected}: $_title', style: ds.caption),
          ],
          const SizedBox(height: Spacing.s5),
          Text(l10n.soundIcon, style: ds.label),
          const SizedBox(height: Spacing.s2),
          DsIconPicker(keys: DnDiscIcons.sfx, selected: _icon, onChanged: (k) => setState(() => _icon = k)),
          const SizedBox(height: Spacing.s3),
          DsCheckbox(
            value: _loop,
            onChanged: (v) => setState(() => _loop = v),
            label: l10n.loopModeCheckbox,
            description: l10n.loopModeDesc,
          ),
          DsCheckbox(
            value: _persistent,
            onChanged: (v) => setState(() => _persistent = v),
            label: l10n.persistentSfxCheckbox,
            description: l10n.persistentSfxDesc,
          ),
        ],
      ),
    );
  }
}
