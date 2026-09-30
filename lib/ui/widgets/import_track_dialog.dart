import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/audio_track.dart';

class EditTrackDialog extends StatefulWidget {
  final LibraryTrack track;

  const EditTrackDialog({super.key, required this.track});

  @override
  State<EditTrackDialog> createState() => _EditTrackDialogState();
}

class _EditTrackDialogState extends State<EditTrackDialog> {
  late TextEditingController _titleController;
  late TextEditingController _tagsController;
  late AudioBusType _selectedBus;
  late MusicIntensity _selectedIntensity;
  late int _selectedColor;

  final List<int> _availableColors = const [
    0xFF9C27B0, // Purple
    0xFF009688, // Teal
    0xFFFF9800, // Orange
    0xFFE91E63, // Pink
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFF607D8B, // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.title);
    _tagsController = TextEditingController(text: widget.track.tags.join(', '));
    _selectedBus = widget.track.busType;
    _selectedIntensity = widget.track.intensity;
    _selectedColor = widget.track.colorHex;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n?.editTrackTitle ?? 'Edit Audio Track'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n?.trackTitleLabel ?? 'Track Title',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n?.targetAudioBus ?? 'Target Audio Bus:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<AudioBusType>(
              initialValue: _selectedBus,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: AudioBusType.values.map((bus) {
                return DropdownMenuItem(
                  value: bus,
                  child: Text(bus.getLocalizedName(l10n)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedBus = val);
                }
              },
            ),
            if (_selectedBus == AudioBusType.music) ...[
              const SizedBox(height: 16),
              Text(l10n?.musicIntensitySetting ?? 'Music Intensity Level:', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<MusicIntensity>(
                initialValue: _selectedIntensity,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: MusicIntensity.values.map((intensity) {
                  return DropdownMenuItem(
                    value: intensity,
                    child: Text(intensity.getLocalizedName(l10n).toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedIntensity = val);
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: l10n?.tagsLabel ?? 'Tags (comma separated)',
                hintText: l10n?.tagsHint ?? 'Tavern, Battle, Forest, Magic',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n?.colorLabel ?? 'Color Badge:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableColors.map((colorVal) {
                final isSelected = _selectedColor == colorVal;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorVal),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final tags = _tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();

            final updated = widget.track.copyWith(
              title: _titleController.text.trim(),
              busType: _selectedBus,
              intensity: _selectedIntensity,
              tags: tags,
              colorHex: _selectedColor,
            );

            Navigator.of(context).pop(updated);
          },
          child: Text(l10n?.save ?? 'Save'),
        ),
      ],
    );
  }
}
