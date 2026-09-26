import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/audio_track.dart';
import '../../models/library_track.dart';
import '../../models/scene_model.dart';
import '../../services/media_library_service.dart';

class CreateEditSceneDialog extends StatefulWidget {
  final SceneModel? scene;

  const CreateEditSceneDialog({super.key, this.scene});

  @override
  State<CreateEditSceneDialog> createState() => _CreateEditSceneDialogState();
}

class _CreateEditSceneDialogState extends State<CreateEditSceneDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late int _selectedColorHex;
  String? _selectedMusicTrackId;
  MusicIntensity _selectedIntensity = MusicIntensity.calm;
  final Map<String, double> _ambientVolumes = {};
  final Set<String> _selectedSfxIds = {};

  final List<int> _colorOptions = [
    0xFF673AB7, // Deep Purple
    0xFF9C27B0, // Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Blue
    0xFF009688, // Teal
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFFF44336, // Red
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    final scene = widget.scene;
    _nameController = TextEditingController(text: scene?.name ?? '');
    _descController = TextEditingController(text: scene?.description ?? '');
    _selectedColorHex = scene?.colorHex ?? _colorOptions.first;
    _selectedMusicTrackId = scene?.musicTrackId;
    _selectedIntensity = scene?.musicIntensity ?? MusicIntensity.calm;

    if (scene != null) {
      _ambientVolumes.addAll(scene.ambientLayerVolumes);
      _selectedSfxIds.addAll(scene.soundboardSfxIds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<MediaLibraryService>();
    final musicTracks = library.tracks.where((t) => t.busType == AudioBusType.music).toList();
    final ambientTracks = library.tracks.where((t) => t.busType == AudioBusType.ambient).toList();
    final sfxTracks = library.tracks.where((t) => t.busType == AudioBusType.sfx).toList();

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  widget.scene == null ? Icons.add_circle_outline : Icons.edit_note_rounded,
                  color: Color(_selectedColorHex),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.scene == null ? 'Создание новой сцены' : 'Редактирование сцены',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scene Name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название сцены *',
                        hintText: 'например: Таверна «Пьяный Дракон»',
                        filled: true,
                        fillColor: Color(0xFF14141E),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Scene Description
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Описание атмосферы / Заметки мастера',
                        hintText: 'Теплый камин, звон кружек, тихая лютня...',
                        filled: true,
                        fillColor: Color(0xFF14141E),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Color Choice
                    const Text('Цветовой акцент:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions.map((color) {
                        final isSelected = _selectedColorHex == color;
                        return InkWell(
                          onTap: () => setState(() => _selectedColorHex = color),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Music Section
                    const Text('Фоновая музыка:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: musicTracks.any((t) => t.id == _selectedMusicTrackId) ? _selectedMusicTrackId : null,
                      decoration: const InputDecoration(
                        labelText: 'Музыкальный трек',
                        filled: true,
                        fillColor: Color(0xFF14141E),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Без музыки (тишина)'),
                        ),
                        ...musicTracks.map(
                          (t) => DropdownMenuItem<String?>(
                            value: t.id,
                            child: Text(t.title),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedMusicTrackId = val),
                    ),
                    if (_selectedMusicTrackId != null) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<MusicIntensity>(
                        initialValue: _selectedIntensity,
                        decoration: const InputDecoration(
                          labelText: 'Интенсивность музыки',
                          filled: true,
                          fillColor: Color(0xFF14141E),
                          border: OutlineInputBorder(),
                        ),
                        items: MusicIntensity.values.map(
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(i.name.toUpperCase()),
                          ),
                        ).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedIntensity = val);
                        },
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Ambient Section
                    const Text('Слои эмбиента и их громкость:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (ambientTracks.isEmpty)
                      const Text('В библиотеке нет треков с типом "Эмбиент".', style: TextStyle(color: Colors.grey))
                    else
                      ...ambientTracks.map((amb) {
                        final isIncluded = _ambientVolumes.containsKey(amb.id);
                        final vol = _ambientVolumes[amb.id] ?? 0.8;
                        return Card(
                          color: const Color(0xFF14141E),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isIncluded,
                                  activeColor: Color(_selectedColorHex),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _ambientVolumes[amb.id] = 0.8;
                                      } else {
                                        _ambientVolumes.remove(amb.id);
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    amb.title,
                                    style: TextStyle(
                                      fontWeight: isIncluded ? FontWeight.bold : FontWeight.normal,
                                      color: isIncluded ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ),
                                if (isIncluded) ...[
                                  SizedBox(
                                    width: 140,
                                    child: Slider(
                                      value: vol,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: Color(_selectedColorHex),
                                      onChanged: (val) {
                                        setState(() {
                                          _ambientVolumes[amb.id] = val;
                                        });
                                      },
                                    ),
                                  ),
                                  Text(
                                    '${(vol * 100).toInt()}%',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 20),

                    // Soundboard SFX Section
                    const Text('Привязанный саундборд (быстрые SFX):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (sfxTracks.isEmpty)
                      const Text('В библиотеке нет эффектов с типом "SFX".', style: TextStyle(color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sfxTracks.map((sfx) {
                          final isSelected = _selectedSfxIds.contains(sfx.id);
                          return FilterChip(
                            label: Text(sfx.title),
                            selected: isSelected,
                            selectedColor: Color(_selectedColorHex).withValues(alpha: 0.3),
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSfxIds.add(sfx.id);
                                } else {
                                  _selectedSfxIds.remove(sfx.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(widget.scene == null ? 'Создать' : 'Сохранить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(_selectedColorHex),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Укажите название сцены')),
                      );
                      return;
                    }

                    final updatedScene = SceneModel(
                      id: widget.scene?.id ?? const Uuid().v4(),
                      name: name,
                      description: _descController.text.trim(),
                      colorHex: _selectedColorHex,
                      musicTrackId: _selectedMusicTrackId,
                      musicIntensity: _selectedIntensity,
                      ambientLayerVolumes: Map.from(_ambientVolumes),
                      soundboardSfxIds: _selectedSfxIds.toList(),
                      createdAt: widget.scene?.createdAt ?? DateTime.now(),
                    );

                    Navigator.of(context).pop(updatedScene);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
