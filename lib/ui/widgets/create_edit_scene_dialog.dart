import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Durations;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/scene_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/covers.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_dashed.dart';
import '../design/ds_dialog.dart';
import '../design/ds_field.dart';
import '../design/ds_icon.dart';
import '../design/ds_interactive.dart';
import '../design/scene_cover.dart';
import '../view_models/media_library_view_model.dart';
import 'track_pick_list.dart';

/// Create or edit a scene: name, cover, starting intensity and the sounds
/// (one music track, ambient layers, SFX tiles) as checkable rows. Pops with
/// the resulting [SceneModel].
class CreateEditSceneDialog extends StatefulWidget {
  final SceneModel? scene;

  const CreateEditSceneDialog({super.key, this.scene});

  @override
  State<CreateEditSceneDialog> createState() => _CreateEditSceneDialogState();
}

class _CreateEditSceneDialogState extends State<CreateEditSceneDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.scene?.name ?? '');
  final TextEditingController _filter = TextEditingController();

  late String? _cover = widget.scene?.cover;
  late String? _imagePath = widget.scene?.imagePath;
  late MusicIntensity _intensity = widget.scene?.musicIntensity ?? MusicIntensity.calm;
  late String? _musicId = widget.scene?.musicTrackId;
  late final Set<String> _ambientIds = {...?widget.scene?.ambientLayerVolumes.keys};
  late final Set<String> _sfxIds = {...?widget.scene?.soundboardSfxIds};

  String _query = '';
  bool _nameError = false;
  bool _confirmedDiscard = false;

  bool get _dirty {
    final scene = widget.scene;
    if (scene == null) {
      return _name.text.trim().isNotEmpty ||
          _cover != null ||
          _imagePath != null ||
          _musicId != null ||
          _ambientIds.isNotEmpty ||
          _sfxIds.isNotEmpty ||
          _intensity != MusicIntensity.calm;
    }
    return _name.text.trim() != scene.name ||
        _cover != scene.cover ||
        _imagePath != scene.imagePath ||
        _intensity != (scene.musicIntensity ?? MusicIntensity.calm) ||
        _musicId != scene.musicTrackId ||
        !_ambientIds.containsAll(scene.ambientLayerVolumes.keys) ||
        _ambientIds.length != scene.ambientLayerVolumes.length ||
        !_sfxIds.containsAll(scene.soundboardSfxIds) ||
        _sfxIds.length != scene.soundboardSfxIds.length;
  }

  @override
  void dispose() {
    _name.dispose();
    _filter.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path != null) {
      setState(() {
        _imagePath = path;
        _cover = null;
      });
    }
  }

  void _toggle(LibraryTrack track) {
    setState(() {
      switch (track.busType) {
        case AudioBusType.music:
          _musicId = _musicId == track.id ? null : track.id;
        case AudioBusType.ambient:
          if (!_ambientIds.remove(track.id)) _ambientIds.add(track.id);
        case AudioBusType.sfx:
          if (!_sfxIds.remove(track.id)) _sfxIds.add(track.id);
      }
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    final old = widget.scene;
    final volumes = <String, double>{for (final id in _ambientIds) id: old?.ambientLayerVolumes[id] ?? 0.8};
    final sfxOrder = [
      ...?old?.soundboardSfxIds.where(_sfxIds.contains),
      ..._sfxIds.where((id) => !(old?.soundboardSfxIds.contains(id) ?? false)),
    ];
    _confirmedDiscard = true;
    Navigator.of(context).pop(
      SceneModel(
        id: old?.id ?? const Uuid().v4(),
        name: name,
        description: old?.description ?? '',
        colorHex: old?.colorHex ?? 0xFF673AB7,
        iconName: old?.iconName,
        musicTrackId: _musicId,
        musicIntensity: _intensity,
        ambientLayerVolumes: volumes,
        soundboardSfxIds: sfxOrder,
        imagePath: _imagePath,
        cover: _imagePath == null ? _cover : null,
        createdAt: old?.createdAt ?? DateTime.now(),
      ),
    );
  }

  Future<void> _askDiscard() async {
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDsDialog<bool>(
      context: context,
      builder: (ctx) => DsDialog(
        title: l10n.discardChangesTitle,
        description: l10n.discardChangesMessage,
        icon: 'alert',
        size: DsDialogSize.sm,
        closeLabel: l10n.close,
        onClose: () => Navigator.of(ctx).pop(false),
        actions: [
          DsButton.ghost(label: l10n.keepEditing, onPressed: () => Navigator.of(ctx).pop(false)),
          DsButton.danger(label: l10n.discard, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _confirmedDiscard = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final library = context.watch<MediaLibraryViewModel>();
    final editing = widget.scene != null;

    final query = _query.trim().toLowerCase();
    final tracks = library.tracks
        .where((t) => query.isEmpty || t.title.toLowerCase().contains(query) || t.tags.any((tag) => tag.toLowerCase().contains(query)))
        .toList();
    final selectedCount = (_musicId != null ? 1 : 0) + _ambientIds.length + _sfxIds.length;
    final selected = {if (_musicId != null) _musicId!, ..._ambientIds, ..._sfxIds};

    return PopScope(
      canPop: _confirmedDiscard || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askDiscard();
      },
      child: DsDialog(
        title: editing ? l10n.editSceneTitle : l10n.createSceneTitle,
        description: l10n.createSceneDesc,
        size: DsDialogSize.lg,
        closeLabel: l10n.close,
        footNote: l10n.everythingEditableLater,
        actions: [
          DsButton.ghost(label: l10n.cancel, onPressed: () => Navigator.of(context).maybePop()),
          DsButton.primary(
            key: const ValueKey('save_scene_btn'),
            label: editing ? l10n.saveBtn : l10n.createSceneBtn,
            icon: editing ? 'check' : 'plus',
            onPressed: _save,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsTextField(
              key: const ValueKey('scene_name_field'),
              label: l10n.sceneNameLabel,
              controller: _name,
              placeholder: l10n.sceneNameHint,
              autofocus: !editing,
              error: _nameError && _name.text.trim().isEmpty ? l10n.specifySceneName : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacing.s5),
            Text(l10n.coverLabel, style: ds.label),
            const SizedBox(height: Spacing.s2),
            _CoverPicker(
              selectedCover: _imagePath == null ? _cover : null,
              imagePath: _imagePath,
              uploadLabel: l10n.uploadCover,
              onCover: (key) => setState(() {
                _cover = key;
                _imagePath = null;
              }),
              onUpload: _pickImage,
            ),
            const SizedBox(height: Spacing.s2),
            Text(l10n.coverHint, style: ds.caption),
            const SizedBox(height: Spacing.s5),
            Text(l10n.startingIntensity, style: ds.label),
            const SizedBox(height: Spacing.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: DsSegmentedControl<MusicIntensity>(
                label: l10n.startingIntensity,
                value: _intensity,
                onChanged: (v) => setState(() => _intensity = v),
                options: [
                  for (final (index, level) in MusicIntensity.values.indexed)
                    DsSegment(
                      id: level,
                      label: level.getLocalizedName(l10n),
                      color: ds.intensityColor(level.name),
                      key: '${index + 1}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.s5),
            Row(
              children: [
                Text(l10n.soundsSelected(selectedCount), style: ds.label),
                const Spacer(),
                Flexible(child: Text(l10n.soundsHint, style: ds.caption, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: Spacing.s2),
            DsTextField(
              key: const ValueKey('scene_sound_filter'),
              controller: _filter,
              icon: 'search',
              placeholder: l10n.filterLibrary,
              clearable: true,
              clearLabel: l10n.clearSearch,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: Spacing.s3),
            if (tracks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.s4),
                child: Text(l10n.noSoundsFound, style: ds.body.copyWith(color: ds.textMuted)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: Sizes.rowMin * 5),
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final twoColumns = c.maxWidth >= Sizes.dialogMd;
                      final width = twoColumns ? (c.maxWidth - Spacing.s4) / 2 : c.maxWidth;
                      return Wrap(
                        spacing: Spacing.s4,
                        children: [
                          for (final track in tracks)
                            SizedBox(
                              width: width,
                              child: _SoundCheckRow(track: track, checked: selected.contains(track.id), onTap: () => _toggle(track)),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SoundCheckRow extends StatelessWidget {
  final LibraryTrack track;
  final bool checked;
  final VoidCallback onTap;

  const _SoundCheckRow({required this.track, required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    return DsInteractive(
      key: ValueKey('scene_sound_${track.id}'),
      onTap: onTap,
      toggled: checked,
      semanticLabel: track.title,
      focusRadius: Radii.smAll,
      builder: (context, s) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.targetLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
          child: Row(
            children: [
              AnimatedContainer(
                duration: Durations.fast,
                width: Sizes.checkbox,
                height: Sizes.checkbox,
                decoration: BoxDecoration(
                  color: checked ? ds.primary : Palette.transparent,
                  borderRadius: Radii.smAll,
                  border: Border.all(color: checked ? ds.primary : ds.borderStrong, width: Sizes.checkboxBorder),
                ),
                child: checked ? Center(child: DsIcon('check', size: Sizes.iconSm, color: ds.onPrimary)) : null,
              ),
              const SizedBox(width: Spacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title, style: ds.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(trackMeta(l10n, track), style: ds.tabular(ds.caption), maxLines: 1, overflow: TextOverflow.ellipsis),
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

/// The seven default covers plus an upload tile for the user's own image.
class _CoverPicker extends StatelessWidget {
  final String? selectedCover;
  final String? imagePath;
  final String uploadLabel;
  final ValueChanged<String> onCover;
  final VoidCallback onUpload;

  const _CoverPicker({
    required this.selectedCover,
    required this.imagePath,
    required this.uploadLabel,
    required this.onCover,
    required this.onUpload,
  });

  static const double _tileHeight = Sizes.targetLg + Spacing.s2;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    Widget frame({required bool selected, required Widget child}) => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: Radii.mdAll,
            border: Border.all(color: selected ? ds.primary : ds.border, width: selected ? Sizes.focusRing : Sizes.borderWidth),
          ),
          child: ClipRRect(borderRadius: Radii.mdAll, child: child),
        );

    return LayoutBuilder(
      builder: (context, c) {
        const gap = Spacing.s2;
        final count = SceneCovers.keys.length + 1;
        final width = (c.maxWidth - gap * (count - 1)) / count;
        return Row(
          children: [
            for (final key in SceneCovers.keys) ...[
              SizedBox(
                width: width,
                height: _tileHeight,
                child: DsInteractive(
                  key: ValueKey('cover_$key'),
                  onTap: () => onCover(key),
                  toggled: selectedCover == key,
                  semanticLabel: key,
                  builder: (context, s) => frame(
                    selected: selectedCover == key,
                    child: SceneCover(cover: key),
                  ),
                ),
              ),
              const SizedBox(width: gap),
            ],
            SizedBox(
              width: width,
              height: _tileHeight,
              child: DsInteractive(
                key: const ValueKey('cover_upload'),
                onTap: onUpload,
                toggled: imagePath != null,
                semanticLabel: uploadLabel,
                builder: (context, s) => imagePath != null
                    ? frame(selected: true, child: SceneCover(src: imagePath))
                    : DecoratedBox(
                        decoration: DsDashedDecoration(
                          color: s.hovered ? ds.surfaceRaised : Palette.transparent,
                          border: ds.borderStrong,
                          dashed: true,
                          radius: Radii.md,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DsIcon('upload', size: Sizes.iconSm, color: ds.textMuted),
                            Text(uploadLabel, style: ds.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
