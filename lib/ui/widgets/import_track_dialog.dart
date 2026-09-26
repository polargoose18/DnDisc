import 'package:flutter/material.dart';
import '../../models/library_track.dart';
import '../../models/audio_track.dart';

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
    return AlertDialog(
      title: const Text('Редактировать аудиозапись'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название трека',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Целевая аудио-шина:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<AudioBusType>(
              initialValue: _selectedBus,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: AudioBusType.values.map((bus) {
                return DropdownMenuItem(
                  value: bus,
                  child: Text(bus.displayName),
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
              const Text('Уровень Интенсивности Музыки:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<MusicIntensity>(
                initialValue: _selectedIntensity,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: MusicIntensity.values.map((intensity) {
                  return DropdownMenuItem(
                    value: intensity,
                    child: Text(intensity.name.toUpperCase()),
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
              decoration: const InputDecoration(
                labelText: 'Теги (через запятую)',
                hintText: 'Таверна, Бой, Лес, Магия',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Цветовая метка:', style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: const Text('Отмена'),
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
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
