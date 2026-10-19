import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Durations;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../audio/ambient_bus_controller.dart';
import '../../domain/models/ambient_layer.dart';
import '../../domain/models/library_track.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_dialog.dart';
import '../design/ds_icon.dart';
import '../design/ds_icon_picker.dart';
import '../design/ds_interactive.dart';
import '../design/ds_menu.dart';
import '../design/ds_panel.dart';
import '../design/ds_slider.dart';
import '../design/ds_tooltip.dart';
import 'bus_equalizer.dart';
import '../view_models/media_library_view_model.dart';
import 'track_pick_list.dart';

/// Ambient layers panel: a row per layer with its toggle button, name,
/// volume and menu.
class AmbientMixerPanel extends StatelessWidget {
  const AmbientMixerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ambient = context.watch<AmbientBusController>();
    final layers = ambient.layers;
    final on = layers.where((l) => l.isActive).length;

    return DsPanel(
      title: l10n.ambientLayers,
      icon: 'waves',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (layers.isNotEmpty) ...[
            DsBadge(l10n.ambientOnCount(on, layers.length), dot: on > 0),
            const SizedBox(width: Spacing.s2),
            DsButton.ghost(
              key: const ValueKey('ambient_stop_all_btn'),
              icon: 'stop',
              iconOnly: true,
              label: l10n.stopAllLayers,
              onPressed: ambient.stopAllLayers,
            ),
          ],
          DsButton.ghost(
            key: const ValueKey('add_ambient_layer_btn'),
            icon: 'plus',
            iconOnly: true,
            label: l10n.addAmbientTooltip,
            onPressed: () => showAddAmbientDialog(context, ambient),
          ),
        ],
      ),
      child: layers.isEmpty
          ? DsEmptyState(
              icon: 'waves',
              title: l10n.noAmbientTitle,
              message: l10n.noAmbientHint,
              action: DsButton(
                label: l10n.addAmbientLayer,
                icon: 'plus',
                onPressed: () => showAddAmbientDialog(context, ambient),
              ),
            )
          : Column(
              children: [
                for (final layer in layers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.s2),
                    child: AmbientRow(key: ValueKey('ambient_row_${layer.id}'), layer: layer, ambient: ambient),
                  ),
              ],
            ),
    );
  }
}

class AmbientRow extends StatelessWidget {
  final AmbientLayer layer;
  final AmbientBusController ambient;

  const AmbientRow({super.key, required this.layer, required this.ambient});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final on = layer.isActive;

    return Container(
      constraints: const BoxConstraints(minHeight: Sizes.rowMin),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s3, vertical: Spacing.s2),
      decoration: BoxDecoration(
        color: ds.surfaceRaised,
        borderRadius: Radii.mdAll,
        border: Border.all(color: ds.border, width: Sizes.borderWidth),
      ),
      child: Row(
        children: [
          DsInteractive(
            key: ValueKey('ambient_toggle_${layer.id}'),
            onTap: () => ambient.toggleLayer(layer.id),
            toggled: on,
            semanticLabel: layer.title,
            builder: (context, s) => AnimatedContainer(
              duration: Durations.fast,
              curve: Curves.easeOut,
              width: Sizes.targetMin,
              height: Sizes.targetMin,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? ds.primarySubtle : (s.hovered ? ds.surfaceHover : Palette.transparent),
                borderRadius: Radii.mdAll,
                border: Border.all(color: on ? ds.primary : ds.borderStrong, width: Sizes.borderWidth),
              ),
              child: DsIcon(
                DnDiscIcons.resolve(layer.iconName, DnDiscIcons.defaultAmbient),
                size: Sizes.iconLayer,
                color: on ? ds.primary : (s.hovered ? ds.text : ds.textMuted),
              ),
            ),
          ),
          const SizedBox(width: Spacing.s3),
          Expanded(
            flex: 2,
            child: DsTooltip(
              label: layer.title,
              child: Row(
                children: [
                  if (layer.isPersistent) ...[
                    DsIcon('pin', size: Sizes.iconSm, color: ds.primary),
                    const SizedBox(width: Spacing.s2),
                  ],
                  Flexible(
                    child: Text(
                      layer.title,
                      style: ds.body.copyWith(fontWeight: FontWeight.w500, color: on ? ds.text : ds.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (on) ...[
                    const SizedBox(width: Spacing.s2),
                    AmbientEqualizer(layerId: layer.id, height: Spacing.s3),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: Spacing.s3),
          Expanded(
            flex: 3,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: DsSlider(
                key: ValueKey('ambient_slider_${layer.id}'),
                value: layer.volume,
                onChanged: (v) => ambient.setLayerVolume(layer.id, v),
                semanticLabel: layer.title,
                ringColor: ds.surfaceRaised,
              ),
            ),
          ),
          DsMoreButton(
            label: l10n.moreActions,
            items: [
              DsMenuItem(id: 'pin', label: l10n.pinEverywhere, icon: 'pin', checked: layer.isPersistent),
              const DsMenuItem.separator(),
              DsMenuItem(id: 'remove', label: l10n.removeLayer, icon: 'trash', danger: true),
            ],
            onSelected: (id) {
              if (id == 'pin') ambient.togglePersistent(layer.id);
              if (id == 'remove') ambient.removeLayer(layer.id);
            },
          ),
        ],
      ),
    );
  }
}

Future<void> showAddAmbientDialog(BuildContext context, AmbientBusController ambient) {
  return showDsDialog<void>(context: context, builder: (_) => _AddAmbientLayerDialog(ambient: ambient));
}

class _AddAmbientLayerDialog extends StatefulWidget {
  final AmbientBusController ambient;

  const _AddAmbientLayerDialog({required this.ambient});

  @override
  State<_AddAmbientLayerDialog> createState() => _AddAmbientLayerDialogState();
}

class _AddAmbientLayerDialogState extends State<_AddAmbientLayerDialog> {
  LibraryTrack? _track;
  String _path = '';
  String _title = '';
  String _icon = DnDiscIcons.defaultAmbient;
  double _volume = 0.7;
  bool _persistent = true;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'm4a'],
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
    final tracks = library.tracks.where((t) => t.busType == AudioBusType.ambient).toList();

    return DsDialog(
      title: l10n.addAmbientDialogTitle,
      description: l10n.addAmbientDialogDesc,
      icon: 'waves',
      closeLabel: l10n.close,
      actions: [
        DsButton.ghost(label: l10n.cancel, onPressed: () => Navigator.of(context).pop()),
        DsButton.primary(
          key: const ValueKey('add_ambient_confirm_btn'),
          label: l10n.addLayerBtn,
          icon: 'plus',
          onPressed: _path.isEmpty
              ? null
              : () {
                  widget.ambient.addLayer(
                    AmbientLayer(
                      id: _track?.id ?? const Uuid().v4(),
                      title: _title.isNotEmpty ? _title : l10n.ambient,
                      filePath: _path,
                      volume: _volume,
                      isPersistent: _persistent,
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
            Text(l10n.noAmbientTracksInLibrary, style: ds.body.copyWith(color: ds.textMuted))
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
                    _icon = DnDiscIcons.resolve(t.iconName, DnDiscIcons.defaultAmbient);
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
          DsIconPicker(keys: DnDiscIcons.ambient, selected: _icon, onChanged: (k) => setState(() => _icon = k)),
          const SizedBox(height: Spacing.s5),
          DsSlider(
            label: l10n.volume,
            value: _volume,
            onChanged: (v) => setState(() => _volume = v),
            semanticLabel: l10n.volume,
          ),
          DsCheckbox(
            value: _persistent,
            onChanged: (v) => setState(() => _persistent = v),
            label: l10n.persistentLayerCheckbox,
            description: l10n.persistentLayerDesc,
          ),
        ],
      ),
    );
  }
}
