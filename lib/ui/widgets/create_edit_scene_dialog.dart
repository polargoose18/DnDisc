import 'dart:async';
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
  late TextEditingController _musicSearchController;
  late TextEditingController _ambientSearchController;
  late TextEditingController _sfxSearchController;

  String _musicQuery = '';
  String _ambientQuery = '';
  String _sfxQuery = '';

  Timer? _musicDebounce;
  Timer? _ambientDebounce;
  Timer? _sfxDebounce;

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
    _musicSearchController = TextEditingController();
    _ambientSearchController = TextEditingController();
    _sfxSearchController = TextEditingController();

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
    _musicDebounce?.cancel();
    _ambientDebounce?.cancel();
    _sfxDebounce?.cancel();
    _nameController.dispose();
    _descController.dispose();
    _musicSearchController.dispose();
    _ambientSearchController.dispose();
    _sfxSearchController.dispose();
    super.dispose();
  }

  void _onMusicSearchChanged(String query, List<LibraryTrack> tracks) {
    _musicDebounce?.cancel();
    _musicDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _musicQuery = query.trim().toLowerCase();
        // Auto-match if exactly 1 track matches
        if (_musicQuery.isNotEmpty) {
          final matches = tracks.where((t) =>
              t.title.toLowerCase().contains(_musicQuery) ||
              t.tags.any((tag) => tag.toLowerCase().contains(_musicQuery))).toList();
          if (matches.length == 1) {
            _selectedMusicTrackId = matches.first.id;
          }
        }
      });
    });
  }

  void _onMusicSearchSubmitted(String query, List<LibraryTrack> tracks) {
    _musicDebounce?.cancel();
    final q = query.trim().toLowerCase();
    setState(() {
      _musicQuery = q;
      if (q.isNotEmpty) {
        final matches = tracks.where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q))).toList();
        if (matches.isNotEmpty) {
          _selectedMusicTrackId = matches.first.id;
        }
      }
    });
  }

  void _onAmbientSearchChanged(String query) {
    _ambientDebounce?.cancel();
    _ambientDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _ambientQuery = query.trim().toLowerCase();
      });
    });
  }

  void _onAmbientSearchSubmitted(String query, List<LibraryTrack> tracks) {
    _ambientDebounce?.cancel();
    final q = query.trim().toLowerCase();
    setState(() {
      _ambientQuery = q;
      if (q.isNotEmpty) {
        final matches = tracks.where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q))).toList();
        if (matches.isNotEmpty) {
          final first = matches.first;
          if (_ambientVolumes.containsKey(first.id)) {
            _ambientVolumes.remove(first.id);
          } else {
            _ambientVolumes[first.id] = 0.8;
          }
        }
      }
    });
  }

  void _onSfxSearchChanged(String query) {
    _sfxDebounce?.cancel();
    _sfxDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _sfxQuery = query.trim().toLowerCase();
      });
    });
  }

  void _onSfxSearchSubmitted(String query, List<LibraryTrack> tracks) {
    _sfxDebounce?.cancel();
    final q = query.trim().toLowerCase();
    setState(() {
      _sfxQuery = q;
      if (q.isNotEmpty) {
        final matches = tracks.where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q))).toList();
        if (matches.isNotEmpty) {
          final first = matches.first;
          if (_selectedSfxIds.contains(first.id)) {
            _selectedSfxIds.remove(first.id);
          } else {
            _selectedSfxIds.add(first.id);
          }
        }
      }
    });
  }

  List<LibraryTrack> _filterTracks(List<LibraryTrack> tracks, String query) {
    if (query.isEmpty) return tracks;
    return tracks.where((t) {
      final matchesTitle = t.title.toLowerCase().contains(query);
      final matchesTags = t.tags.any((tag) => tag.toLowerCase().contains(query));
      return matchesTitle || matchesTags;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<MediaLibraryService>();
    final allMusicTracks = library.tracks.where((t) => t.busType == AudioBusType.music).toList();
    final allAmbientTracks = library.tracks.where((t) => t.busType == AudioBusType.ambient).toList();
    final allSfxTracks = library.tracks.where((t) => t.busType == AudioBusType.sfx).toList();

    final filteredMusic = _filterTracks(allMusicTracks, _musicQuery);
    final filteredAmbient = _filterTracks(allAmbientTracks, _ambientQuery);
    final filteredSfx = _filterTracks(allSfxTracks, _sfxQuery);

    final selectedMusicTrack = allMusicTracks.cast<LibraryTrack?>().firstWhere(
      (t) => t?.id == _selectedMusicTrackId,
      orElse: () => null,
    );

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                    const SizedBox(height: 24),

                    // Section 1: Music Channel (Unified layout)
                    _buildChannelContainer(
                      title: 'Канал Музыки',
                      icon: Icons.music_note_rounded,
                      badgeText: selectedMusicTrack != null ? selectedMusicTrack.title : 'Без музыки',
                      badgeColor: selectedMusicTrack != null ? Color(_selectedColorHex) : Colors.grey,
                      searchController: _musicSearchController,
                      searchHint: 'Поиск музыки по названию или тегам...',
                      onSearchChanged: (q) => _onMusicSearchChanged(q, allMusicTracks),
                      onSearchSubmitted: (q) => _onMusicSearchSubmitted(q, allMusicTracks),
                      onClearSearch: () {
                        _musicSearchController.clear();
                        setState(() => _musicQuery = '');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // "No Music" option card
                          _buildOptionCard(
                            isSelected: _selectedMusicTrackId == null,
                            title: 'Без музыки (тишина)',
                            subtitle: 'При активации сцены фоновая музыка плавно затухает',
                            leadingIcon: Icons.volume_off_rounded,
                            onTap: () => setState(() => _selectedMusicTrackId = null),
                          ),
                          const SizedBox(height: 6),
                          if (filteredMusic.isEmpty && _musicQuery.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            )
                          else
                            ...filteredMusic.map((track) {
                              final isSelected = _selectedMusicTrackId == track.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _buildOptionCard(
                                  isSelected: isSelected,
                                  title: track.title,
                                  subtitle: track.tags.isNotEmpty ? 'Теги: ${track.tags.join(", ")}' : null,
                                  leadingIcon: Icons.audiotrack_rounded,
                                  onTap: () => setState(() => _selectedMusicTrackId = track.id),
                                  extraContent: isSelected
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              const Text('Интенсивность:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 6,
                                                  children: MusicIntensity.values.map((intensity) {
                                                    final isIntSelected = _selectedIntensity == intensity;
                                                    return ChoiceChip(
                                                      label: Text(intensity.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                                                      selected: isIntSelected,
                                                      selectedColor: Color(_selectedColorHex),
                                                      onSelected: (sel) {
                                                        if (sel) setState(() => _selectedIntensity = intensity);
                                                      },
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Ambient Channel (Unified layout)
                    _buildChannelContainer(
                      title: 'Канал Эмбиента',
                      icon: Icons.waves_rounded,
                      badgeText: '${_ambientVolumes.length} слоев выбрано',
                      badgeColor: _ambientVolumes.isNotEmpty ? Color(_selectedColorHex) : Colors.grey,
                      searchController: _ambientSearchController,
                      searchHint: 'Поиск эмбиента по названию или тегам...',
                      onSearchChanged: _onAmbientSearchChanged,
                      onSearchSubmitted: (q) => _onAmbientSearchSubmitted(q, allAmbientTracks),
                      onClearSearch: () {
                        _ambientSearchController.clear();
                        setState(() => _ambientQuery = '');
                      },
                      child: allAmbientTracks.isEmpty
                          ? const Text('В библиотеке нет треков с типом "Эмбиент".', style: TextStyle(color: Colors.grey))
                          : Column(
                              children: [
                                if (filteredAmbient.isEmpty && _ambientQuery.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  )
                                else
                                  ...filteredAmbient.map((amb) {
                                    final isIncluded = _ambientVolumes.containsKey(amb.id);
                                    final vol = _ambientVolumes[amb.id] ?? 0.8;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: _buildOptionCard(
                                        isSelected: isIncluded,
                                        title: amb.title,
                                        subtitle: amb.tags.isNotEmpty ? 'Теги: ${amb.tags.join(", ")}' : null,
                                        leadingIcon: Icons.air_rounded,
                                        trailing: Checkbox(
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
                                        onTap: () {
                                          setState(() {
                                            if (isIncluded) {
                                              _ambientVolumes.remove(amb.id);
                                            } else {
                                              _ambientVolumes[amb.id] = 0.8;
                                            }
                                          });
                                        },
                                        extraContent: isIncluded
                                            ? Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.volume_down_rounded, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Slider(
                                                        value: vol,
                                                        min: 0.0,
                                                        max: 1.0,
                                                        activeColor: Color(_selectedColorHex),
                                                        onChanged: (val) {
                                                          setState(() => _ambientVolumes[amb.id] = val);
                                                        },
                                                      ),
                                                    ),
                                                    Text(
                                                      '${(vol * 100).toInt()}%',
                                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : null,
                                      ),
                                    );
                                  }),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: SFX Channel (Unified layout)
                    _buildChannelContainer(
                      title: 'Канал SFX (Саундборд)',
                      icon: Icons.flash_on_rounded,
                      badgeText: '${_selectedSfxIds.length} SFX выбрано',
                      badgeColor: _selectedSfxIds.isNotEmpty ? Color(_selectedColorHex) : Colors.grey,
                      searchController: _sfxSearchController,
                      searchHint: 'Поиск SFX по названию или тегам...',
                      onSearchChanged: _onSfxSearchChanged,
                      onSearchSubmitted: (q) => _onSfxSearchSubmitted(q, allSfxTracks),
                      onClearSearch: () {
                        _sfxSearchController.clear();
                        setState(() => _sfxQuery = '');
                      },
                      child: allSfxTracks.isEmpty
                          ? const Text('В библиотеке нет эффектов с типом "SFX".', style: TextStyle(color: Colors.grey))
                          : Column(
                              children: [
                                if (filteredSfx.isEmpty && _sfxQuery.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  )
                                else
                                  ...filteredSfx.map((sfx) {
                                    final isSelected = _selectedSfxIds.contains(sfx.id);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: _buildOptionCard(
                                        isSelected: isSelected,
                                        title: sfx.title,
                                        subtitle: sfx.tags.isNotEmpty ? 'Теги: ${sfx.tags.join(", ")}' : null,
                                        leadingIcon: Icons.campaign_rounded,
                                        trailing: Checkbox(
                                          value: isSelected,
                                          activeColor: Color(_selectedColorHex),
                                          onChanged: (checked) {
                                            setState(() {
                                              if (checked == true) {
                                                _selectedSfxIds.add(sfx.id);
                                              } else {
                                                _selectedSfxIds.remove(sfx.id);
                                              }
                                            });
                                          },
                                        ),
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedSfxIds.remove(sfx.id);
                                            } else {
                                              _selectedSfxIds.add(sfx.id);
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  }),
                              ],
                            ),
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

  Widget _buildChannelContainer({
    required String title,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required TextEditingController searchController,
    required String searchHint,
    required ValueChanged<String> onSearchChanged,
    required ValueChanged<String> onSearchSubmitted,
    required VoidCallback onClearSearch,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(_selectedColorHex), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            onSubmitted: onSearchSubmitted,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: searchHint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E1E2C),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required bool isSelected,
    required String title,
    String? subtitle,
    required IconData leadingIcon,
    Widget? trailing,
    required VoidCallback onTap,
    Widget? extraContent,
  }) {
    final activeColor = Color(_selectedColorHex);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white10,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  leadingIcon,
                  size: 18,
                  color: isSelected ? activeColor : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 18, color: activeColor),
              ],
            ),
            if (extraContent != null) extraContent,
          ],
        ),
      ),
    );
  }
}
