import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../data/services/audio_file_picker.dart';
import '../../data/services/media_library_service.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/library_track.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_dialog.dart';
import '../design/ds_dropzone.dart';
import '../design/ds_field.dart';
import '../design/ds_icon.dart';
import '../design/ds_icon_picker.dart';
import 'track_pick_list.dart';

/// Result of [ImportAudioDialog]: the channel and the chosen files.
class ImportSelection {
  final AudioBusType busType;
  final List<String> paths;

  const ImportSelection(this.busType, this.paths);
}

/// Import dialog: channel, dropzone and the list of files to add.
class ImportAudioDialog extends StatefulWidget {
  final List<String> initialPaths;
  final AudioBusType initialBus;

  const ImportAudioDialog({super.key, this.initialPaths = const [], this.initialBus = AudioBusType.music});

  @override
  State<ImportAudioDialog> createState() => _ImportAudioDialogState();
}

class _ImportAudioDialogState extends State<ImportAudioDialog> {
  late AudioBusType _bus = widget.initialBus;
  late final List<String> _paths = [...widget.initialPaths.where(MediaLibraryService.isSupportedFile)];

  void _add(Iterable<String> paths) {
    setState(() {
      for (final path in paths) {
        if (MediaLibraryService.isSupportedFile(path) && !_paths.contains(path)) _paths.add(path);
      }
    });
  }

  Future<void> _browse() async {
    final picked = await AudioFilePicker.pick(multiple: true);
    _add(picked.paths);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;

    return DsDialog(
      title: l10n.importDialogTitle,
      description: l10n.importDialogDesc,
      icon: 'upload',
      closeLabel: l10n.close,
      actions: [
        DsButton.ghost(label: l10n.cancel, onPressed: () => Navigator.of(context).pop()),
        DsButton.primary(
          key: const ValueKey('import_confirm_btn'),
          label: l10n.importNFiles(_paths.length),
          icon: 'upload',
          onPressed: _paths.isEmpty ? null : () => Navigator.of(context).pop(ImportSelection(_bus, List.of(_paths))),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.importTarget, style: ds.label),
          const SizedBox(height: Spacing.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: DsSegmentedControl<AudioBusType>(
              label: l10n.importTarget,
              value: _bus,
              onChanged: (v) => setState(() => _bus = v),
              options: [
                for (final bus in AudioBusType.values) DsSegment(id: bus, label: trackKindLabel(l10n, bus)),
              ],
            ),
          ),
          const SizedBox(height: Spacing.s5),
          DsDropzone(
            title: l10n.dropFilesTitle,
            hint: l10n.dropFilesHint,
            overTitle: l10n.releaseToImport,
            compact: _paths.isNotEmpty,
            onBrowse: _browse,
            onFiles: _add,
          ),
          if (_paths.isNotEmpty) ...[
            const SizedBox(height: Spacing.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: Sizes.rowMin * 3),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final path in _paths)
                      Container(
                        constraints: const BoxConstraints(minHeight: Sizes.targetMin),
                        padding: const EdgeInsets.only(left: Spacing.s2),
                        child: Row(
                          children: [
                            DsIcon(defaultIconFor(_bus)),
                            const SizedBox(width: Spacing.s3),
                            Expanded(
                              child: Text(p.basename(path), style: ds.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            DsButton.ghost(
                              icon: 'x',
                              iconOnly: true,
                              label: l10n.removeFromList,
                              onPressed: () => setState(() => _paths.remove(path)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Edit the metadata of a library track: title, type, intensity, tags and
/// the icon of the sound. The file path is shown, not editable here.
class EditTrackDialog extends StatefulWidget {
  final LibraryTrack track;

  const EditTrackDialog({super.key, required this.track});

  @override
  State<EditTrackDialog> createState() => _EditTrackDialogState();
}

class _EditTrackDialogState extends State<EditTrackDialog> {
  late final TextEditingController _title = TextEditingController(text: widget.track.title);
  late final TextEditingController _tags = TextEditingController(text: widget.track.tags.join(', '));
  late AudioBusType _bus = widget.track.busType;
  late MusicIntensity _intensity = widget.track.intensity;
  late String? _icon = widget.track.iconName;

  @override
  void dispose() {
    _title.dispose();
    _tags.dispose();
    super.dispose();
  }

  List<String> get _iconKeys => _bus == AudioBusType.sfx ? DnDiscIcons.sfx : DnDiscIcons.ambient;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;

    return DsDialog(
      title: l10n.editTrackTitle,
      icon: 'edit',
      closeLabel: l10n.close,
      actions: [
        DsButton.ghost(label: l10n.cancel, onPressed: () => Navigator.of(context).pop()),
        DsButton.primary(
          key: const ValueKey('save_track_btn'),
          label: l10n.saveBtn,
          icon: 'check',
          onPressed: () {
            final tags = _tags.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
            final iconValid = _bus != AudioBusType.music && _icon != null && _iconKeys.contains(_icon);
            Navigator.of(context).pop(
              widget.track.copyWith(
                title: _title.text.trim().isEmpty ? widget.track.title : _title.text.trim(),
                busType: _bus,
                intensity: _intensity,
                tags: tags,
                iconName: iconValid ? _icon : widget.track.iconName,
              ),
            );
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DsTextField(key: const ValueKey('track_title_field'), label: l10n.trackTitleLabel, controller: _title),
          const SizedBox(height: Spacing.s5),
          Text(l10n.trackTypeLabel, style: ds.label),
          const SizedBox(height: Spacing.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: DsSegmentedControl<AudioBusType>(
              label: l10n.trackTypeLabel,
              value: _bus,
              onChanged: (v) => setState(() => _bus = v),
              options: [for (final bus in AudioBusType.values) DsSegment(id: bus, label: trackKindLabel(l10n, bus))],
            ),
          ),
          if (_bus == AudioBusType.music) ...[
            const SizedBox(height: Spacing.s5),
            Text(l10n.intensityLabel, style: ds.label),
            const SizedBox(height: Spacing.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: DsSegmentedControl<MusicIntensity>(
                label: l10n.intensityLabel,
                value: _intensity,
                onChanged: (v) => setState(() => _intensity = v),
                options: [
                  for (final (index, level) in MusicIntensity.values.indexed)
                    DsSegment(id: level, label: level.getLocalizedName(l10n), color: ds.intensityColor(level.name), key: '${index + 1}'),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: Spacing.s5),
            Text(l10n.soundIcon, style: ds.label),
            const SizedBox(height: Spacing.s2),
            DsIconPicker(
              keys: _iconKeys,
              selected: _icon,
              onChanged: (k) => setState(() => _icon = k),
            ),
          ],
          const SizedBox(height: Spacing.s5),
          DsTextField(
            key: const ValueKey('track_tags_field'),
            label: l10n.tagsLabel,
            controller: _tags,
            hint: l10n.tagsHint,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n\r]'))],
          ),
          const SizedBox(height: Spacing.s5),
          Text(l10n.filePathLabel, style: ds.label),
          const SizedBox(height: Spacing.s2),
          SelectableText(widget.track.filePath, style: ds.code),
        ],
      ),
    );
  }
}
