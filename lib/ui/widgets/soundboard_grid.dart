import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_localizations.dart';
import '../../audio/sfx_bus_controller.dart';
import '../../domain/models/sfx_trigger.dart';
import '../../domain/models/library_track.dart';
import '../../ui/view_models/media_library_view_model.dart';
import '../../ui/view_models/theme_view_model.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../theme/app_themes.dart';

class SoundboardGrid extends StatelessWidget {
  const SoundboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.select<ThemeViewModel?, CustomThemeModel>(
      (vm) => vm?.activeTheme ?? AppThemes.deepDark,
    );
    final l10n = AppLocalizations.of(context);

    return Consumer<SfxBusController>(
      builder: (context, sfx, _) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Add SFX and Panic Stop Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.campaign_rounded, color: activeTheme.accent),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n?.soundboardTitle ?? 'Soundboard (SFX Effects)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: activeTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          key: const ValueKey('add_sfx_trigger_btn'),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: l10n?.addSfxTooltip ?? 'Add SFX / Persistent Button',
                          color: activeTheme.accent,
                          onPressed: () => _showAddSfxDialog(context, sfx),
                        ),
                        ElevatedButton.icon(
                          key: const ValueKey('panic_stop_sfx_btn'),
                          icon: const Icon(Icons.dangerous_rounded, size: 16),
                          label: Text(l10n?.panicStopBtn ?? 'Panic Stop [Esc]', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 30),
                            elevation: 2,
                          ),
                          onPressed: () => sfx.stopAll(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Volume slider for SFX
                Row(
                  children: [
                    Icon(Icons.volume_down, size: 16, color: activeTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(l10n?.sfxVolume ?? 'SFX Volume: ', style: TextStyle(fontSize: 12, color: activeTheme.textSecondary)),
                    Expanded(
                      child: Slider(
                        value: sfx.rawVolume,
                        activeColor: activeTheme.accent,
                        onChanged: (val) => sfx.setVolume(val),
                      ),
                    ),
                    Text('${(sfx.rawVolume * 100).toInt()}%', style: TextStyle(fontSize: 12, color: activeTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),

                if (sfx.triggers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: activeTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            l10n?.soundboardEmpty ?? 'Soundboard is empty. Add SFX or persistent quick buttons.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: Text(l10n?.addPersistentSfx ?? 'Add Persistent SFX'),
                            onPressed: () => _showAddSfxDialog(context, sfx),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.35,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: sfx.triggers.length,
                    itemBuilder: (context, index) {
                      final trigger = sfx.triggers[index];
                      final isLooping = sfx.isTriggerLooping(trigger.id);
                      final color = Color(trigger.colorHex);
                      final hotkeyText = trigger.hotkey != null ? '[${trigger.hotkey}]' : (index < 9 ? '[${index + 1}]' : null);

                      return InkWell(
                        key: ValueKey('sfx_btn_${trigger.id}'),
                        onTap: () => sfx.triggerSfx(trigger.id),
                        onLongPress: () => _showTriggerOptions(context, sfx, trigger),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLooping ? color : color.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isLooping
                                  ? Colors.white
                                  : (trigger.isPersistent ? Colors.amberAccent : color.withValues(alpha: 0.7)),
                              width: isLooping ? 2.0 : 1.0,
                            ),
                            boxShadow: isLooping
                                ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (hotkeyText != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        hotkeyText,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  const Spacer(),
                                  // Persistent Pin Icon
                                  InkWell(
                                    onTap: () => sfx.togglePersistent(trigger.id),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Icon(
                                        trigger.isPersistent ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                        size: 14,
                                        color: trigger.isPersistent ? Colors.amberAccent : Colors.white38,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Loop toggle icon
                                  InkWell(
                                    onTap: () => sfx.toggleTriggerLoop(trigger.id),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Icon(
                                        Icons.repeat_rounded,
                                        size: 15,
                                        color: trigger.isLoop ? Colors.amberAccent : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    trigger.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isLooping ? Colors.white : activeTheme.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (isLooping)
                                const Text(
                                  'LOOPING',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTriggerOptions(BuildContext context, SfxBusController sfx, SfxTrigger trigger) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(trigger.isPersistent ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: Colors.amberAccent),
              title: Text(trigger.isPersistent
                  ? (l10n?.unpinSfx ?? 'Unpin (make temporary)')
                  : (l10n?.pinSfx ?? 'Pin as persistent SFX')),
              onTap: () {
                sfx.togglePersistent(trigger.id);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(l10n?.deleteSfxButton ?? 'Delete SFX button', style: const TextStyle(color: Colors.redAccent)),
              onTap: () {
                sfx.removeTrigger(trigger.id);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSfxDialog(BuildContext context, SfxBusController sfx) {
    showDialog(
      context: context,
      builder: (ctx) => _AddSfxTriggerDialog(sfx: sfx),
    );
  }
}

class _AddSfxTriggerDialog extends StatefulWidget {
  final SfxBusController sfx;
  const _AddSfxTriggerDialog({required this.sfx});

  @override
  State<_AddSfxTriggerDialog> createState() => _AddSfxTriggerDialogState();
}

class _AddSfxTriggerDialogState extends State<_AddSfxTriggerDialog> {
  LibraryTrack? _selectedTrack;
  String _customPath = '';
  String _customTitle = '';
  double _volume = 1.0;
  bool _isLoop = false;
  bool _isPersistent = true;
  String? _hotkey;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<MediaLibraryViewModel>();
    final themeViewModel = context.watch<ThemeViewModel?>();
    final activeTheme = themeViewModel?.activeTheme ?? AppThemes.deepDark;
    final sfxTracks = library.tracks.where((t) => t.busType == AudioBusType.sfx).toList();

    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.amberAccent),
          const SizedBox(width: 8),
          Text(l10n?.addSfxDialogTitle ?? 'Add SFX Button', style: const TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.selectSoundFromLibrary ?? 'Select a sound from library:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              if (sfxTracks.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: activeTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sfxTracks.length,
                    itemBuilder: (context, index) {
                      final track = sfxTracks[index];
                      final isSelected = _selectedTrack?.id == track.id;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: activeTheme.primary.withValues(alpha: 0.2),
                        leading: Icon(Icons.volume_up, color: isSelected ? activeTheme.primary : Colors.white38, size: 18),
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
                    allowedExtensions: ['wav', 'mp3', 'ogg', 'flac', 'm4a'],
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
                Text('${l10n?.selected ?? 'Selected: '}$_customTitle', style: TextStyle(color: activeTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(l10n != null ? '${l10n.volume}:' : 'Volume:', style: const TextStyle(fontSize: 12)),
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
                title: Text(l10n?.persistentSfxCheckbox ?? 'Persistent SFX (do not reset on scene change)', style: const TextStyle(fontSize: 13)),
                value: _isPersistent,
                activeTrackColor: activeTheme.accent,
                onChanged: (v) => setState(() => _isPersistent = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n?.loopModeCheckbox ?? 'Loop Mode (Loop)', style: const TextStyle(fontSize: 13)),
                value: _isLoop,
                activeTrackColor: activeTheme.accent,
                onChanged: (v) => setState(() => _isLoop = v),
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
                  final sfxId = _selectedTrack?.id ?? const Uuid().v4();
                  widget.sfx.addTrigger(
                    SfxTrigger(
                      id: sfxId,
                      title: _customTitle.isNotEmpty ? _customTitle : 'SFX',
                      filePath: _customPath,
                      volume: _volume,
                      isPersistent: _isPersistent,
                      isLoop: _isLoop,
                      hotkey: _hotkey,
                    ),
                  );
                  Navigator.of(context).pop();
                },
          child: Text(l10n?.addSfxBtn ?? 'Add SFX'),
        ),
      ],
    );
  }
}
