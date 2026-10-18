import '../../theme/ds_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_localizations.dart';
import '../../audio/ambient_bus_controller.dart';
import '../../domain/models/ambient_layer.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../ui/view_models/media_library_view_model.dart';
import '../../ui/view_models/theme_view_model.dart';
import '../../theme/app_themes.dart';

class AmbientMixerPanel extends StatelessWidget {
  const AmbientMixerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.select<ThemeViewModel?, CustomThemeModel>(
      (vm) => vm?.activeTheme ?? AppThemes.deepDark,
    );
    final l10n = AppLocalizations.of(context);

    return Consumer<AmbientBusController>(
      builder: (context, ambient, _) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.waves_rounded, color: activeTheme.primary),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n?.ambientLayers ?? 'Ambient Layers (Background Sounds)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                                color: activeTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ambient.layers.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: activeTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: activeTheme.primary.withValues(alpha: 0.3), width: 0.8),
                              ),
                              child: Text(
                                '${ambient.layers.where((l) => l.isActive).length}/${ambient.layers.length}',
                                style: TextStyle(fontFamily: DsTheme.monoFamily, 
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: activeTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          key: const ValueKey('add_ambient_layer_btn'),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: l10n?.addAmbientTooltip ?? 'Add Layer / Persistent Ambient',
                          color: activeTheme.primary,
                          onPressed: () => _showAddAmbientDialog(context, ambient),
                        ),
                        if (ambient.layers.isNotEmpty)
                          OutlinedButton.icon(
                            key: const ValueKey('ambient_stop_all_btn'),
                            onPressed: () => ambient.stopAllLayers(),
                            icon: const Icon(Icons.stop_rounded, size: 16),
                            label: Text(
                              l10n?.stopAll ?? 'Stop All',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent, width: 0.8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 30),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (ambient.layers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: activeTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            l10n?.noActiveAmbients ?? 'No active ambients. Click "+" to add a persistent background sound.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: Text(l10n?.addPersistentAmbient ?? 'Add Persistent Ambient'),
                            onPressed: () => _showAddAmbientDialog(context, ambient),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: ambient.layers.map((layer) {
                      return AnimatedContainer(
                        key: ValueKey('ambient_row_${layer.id}'),
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: layer.isActive
                              ? activeTheme.primary.withValues(alpha: 0.1)
                              : activeTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: layer.isActive
                                ? activeTheme.primary.withValues(alpha: 0.45)
                                : (layer.isPersistent ? Colors.amberAccent.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.05)),
                            width: layer.isActive ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Switch(
                              key: ValueKey('ambient_switch_${layer.id}'),
                              value: layer.isActive,
                              activeTrackColor: activeTheme.primary,
                              onChanged: (_) => ambient.toggleLayer(layer.id),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          layer.title,
                                          style: TextStyle(
                                            fontWeight: layer.isActive ? FontWeight.bold : FontWeight.normal,
                                            color: layer.isActive
                                                ? activeTheme.textPrimary
                                                : activeTheme.textSecondary,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (layer.isPersistent) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.push_pin_rounded, size: 12, color: Colors.amberAccent),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${l10n?.volume ?? "Volume"}: ${(layer.volume * 100).toInt()}%',
                                    style: TextStyle(fontSize: 11, color: activeTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Slider(
                                key: ValueKey('ambient_slider_${layer.id}'),
                                value: layer.volume,
                                activeColor: activeTheme.primary,
                                onChanged: (val) => ambient.setLayerVolume(layer.id, val),
                              ),
                            ),
                            // Persistent Pin Button
                            IconButton(
                              icon: Icon(
                                layer.isPersistent ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                size: 18,
                                color: layer.isPersistent ? Colors.amberAccent : activeTheme.textSecondary,
                              ),
                              tooltip: layer.isPersistent
                                  ? (l10n?.persistentLayerTooltip ?? 'Persistent layer (not reset when switching scenes)')
                                  : (l10n?.makePersistentTooltip ?? 'Make persistent layer'),
                              onPressed: () => ambient.togglePersistent(layer.id),
                            ),
                            // Solo / Mute quick action
                            IconButton(
                              icon: Icon(
                                layer.isActive ? Icons.volume_up : Icons.volume_off,
                                size: 18,
                                color: layer.isActive ? activeTheme.primary : activeTheme.textSecondary,
                              ),
                              tooltip: layer.isActive
                                  ? (l10n?.muteLayerTooltip ?? 'Mute layer')
                                  : (l10n?.unmuteLayerTooltip ?? 'Unmute layer'),
                              onPressed: () => ambient.toggleLayer(layer.id),
                            ),
                            // Remove Layer Button
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              color: Colors.white38,
                              tooltip: l10n?.removeLayerTooltip ?? 'Remove layer',
                              onPressed: () => ambient.removeLayer(layer.id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddAmbientDialog(BuildContext context, AmbientBusController ambient) {
    showDialog(
      context: context,
      builder: (ctx) => _AddAmbientLayerDialog(ambient: ambient),
    );
  }
}

class _AddAmbientLayerDialog extends StatefulWidget {
  final AmbientBusController ambient;
  const _AddAmbientLayerDialog({required this.ambient});

  @override
  State<_AddAmbientLayerDialog> createState() => _AddAmbientLayerDialogState();
}

class _AddAmbientLayerDialogState extends State<_AddAmbientLayerDialog> {
  LibraryTrack? _selectedTrack;
  String _customPath = '';
  String _customTitle = '';
  double _volume = 0.7;
  bool _isPersistent = true;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<MediaLibraryViewModel>();
    final themeViewModel = context.watch<ThemeViewModel?>();
    final activeTheme = themeViewModel?.activeTheme ?? AppThemes.deepDark;
    final ambientTracks = library.tracks.where((t) => t.busType == AudioBusType.ambient).toList();

    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.waves_rounded, color: Colors.tealAccent),
          const SizedBox(width: 8),
          Text(l10n?.addAmbientDialogTitle ?? 'Add Ambient Layer', style: const TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.selectTrackFromLibrary ?? 'Select a track from the media library:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              if (ambientTracks.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: activeTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: ambientTracks.length,
                    itemBuilder: (context, index) {
                      final track = ambientTracks[index];
                      final isSelected = _selectedTrack?.id == track.id;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: activeTheme.primary.withValues(alpha: 0.2),
                        leading: Icon(Icons.music_note, color: isSelected ? activeTheme.primary : Colors.white38, size: 18),
                        title: Text(track.title, style: const TextStyle(fontSize: 13)),
                        onTap: () {
                          setState(() {
                            _selectedTrack = track;
                            _customPath = track.filePath;
                            _customTitle = track.title;
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text(l10n?.selectLocalAudioFile ?? 'Choose local audio file...'),
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'm4a'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final path = result.files.single.path!;
                    final name = result.files.single.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
                    setState(() {
                      _selectedTrack = null;
                      _customPath = path;
                      _customTitle = name;
                    });
                  }
                },
              ),
              if (_customTitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${l10n?.selected ?? "Selected: "}$_customTitle', style: TextStyle(color: activeTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('${l10n?.volume ?? "Volume"}:', style: const TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: (v) => setState(() => _volume = v),
                    ),
                  ),
                  Text('${(_volume * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n?.persistentLayerCheckbox ?? 'Persistent layer (do not reset on scene change)', style: const TextStyle(fontSize: 13)),
                value: _isPersistent,
                activeTrackColor: activeTheme.primary,
                onChanged: (v) => setState(() => _isPersistent = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _customPath.isEmpty
              ? null
              : () {
                  final layerId = _selectedTrack?.id ?? const Uuid().v4();
                  widget.ambient.addLayer(
                    AmbientLayer(
                      id: layerId,
                      title: _customTitle.isNotEmpty ? _customTitle : (l10n?.ambient ?? 'Ambient'),
                      filePath: _customPath,
                      volume: _volume,
                      isPersistent: _isPersistent,
                      isActive: false,
                    ),
                  );
                  Navigator.of(context).pop();
                },
          child: Text(l10n?.addLayerBtn ?? 'Add Layer'),
        ),
      ],
    );
  }
}
