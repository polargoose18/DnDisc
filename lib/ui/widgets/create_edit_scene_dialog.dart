import '../../theme/ds_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/scene_model.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../theme/app_themes.dart';
import '../../data/services/theme_service.dart';
import '../../ui/view_models/media_library_view_model.dart';
import '../../ui/view_models/theme_view_model.dart';
import '../../l10n/app_localizations.dart';

class CreateEditSceneDialog extends StatefulWidget {
  final SceneModel? scene;

  const CreateEditSceneDialog({super.key, this.scene});

  @override
  State<CreateEditSceneDialog> createState() => _CreateEditSceneDialogState();
}

class _CreateEditSceneDialogState extends State<CreateEditSceneDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _imagePathController;
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
  bool _colorInitialized = false;

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
    _imagePathController = TextEditingController(text: scene?.imagePath ?? '');
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

  CustomThemeModel _findActiveTheme(BuildContext context) {
    CustomThemeModel? theme;
    try {
      theme = Provider.of<ThemeViewModel?>(context, listen: false)?.activeTheme;
    } catch (_) {}
    if (theme == null) {
      try {
        theme = Provider.of<ThemeService?>(context, listen: false)?.activeTheme;
      } catch (_) {}
    }
    if (theme == null) {
      try {
        theme = Provider.of<CustomThemeModel?>(context, listen: false);
      } catch (_) {}
    }
    if (theme != null) return theme;

    final themeData = Theme.of(context);
    final isDark = themeData.brightness == Brightness.dark;
    for (final preset in AppThemes.presets) {
      if (preset.isDark == isDark &&
          preset.primaryColor == themeData.colorScheme.primary.toARGB32() &&
          preset.surfaceColor == themeData.colorScheme.surface.toARGB32()) {
        return preset;
      }
    }
    return isDark ? AppThemes.deepDark : AppThemes.cleanLight;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_colorInitialized) {
      _colorInitialized = true;
      if (widget.scene == null) {
        final active = _findActiveTheme(context);
        _selectedColorHex = active.primaryColor;
      }
    }
  }

  @override
  void dispose() {
    _musicDebounce?.cancel();
    _ambientDebounce?.cancel();
    _sfxDebounce?.cancel();
    _nameController.dispose();
    _descController.dispose();
    _imagePathController.dispose();
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
    final library = context.watch<MediaLibraryViewModel>();
    final l10n = AppLocalizations.of(context);

    CustomThemeModel? activeThemeModel;
    try {
      activeThemeModel = context.select<ThemeViewModel?, CustomThemeModel?>(
        (vm) => vm?.activeTheme,
      );
    } catch (_) {}

    if (activeThemeModel == null) {
      try {
        activeThemeModel = context.select<ThemeService?, CustomThemeModel?>(
          (ts) => ts?.activeTheme,
        );
      } catch (_) {}
    }

    if (activeThemeModel == null) {
      try {
        activeThemeModel = context.select<CustomThemeModel?, CustomThemeModel?>(
          (ct) => ct,
        );
      } catch (_) {}
    }

    final activeTheme = activeThemeModel ?? _findActiveTheme(context);
    final isDark = activeTheme.isDark;
    final sceneAccentColor = Color(_selectedColorHex);

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

    final availableColorOptions = <int>{
      activeTheme.primaryColor,
      activeTheme.battleIntensityColor,
      activeTheme.suspenseIntensityColor,
      if (widget.scene != null) widget.scene!.colorHex,
      ..._colorOptions,
    }.toList();

    return Dialog(
      backgroundColor: activeTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
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
                  color: sceneAccentColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.scene == null
                      ? (l10n?.createSceneTitle ?? 'Create New Scene')
                      : (l10n?.editSceneTitle ?? 'Edit Scene'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: activeTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: activeTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(
              height: 24,
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scene Name
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: activeTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: l10n?.sceneNameLabel ?? 'Scene Name *',
                        labelStyle: TextStyle(color: activeTheme.textSecondary),
                        hintText: l10n?.sceneNameHint ?? 'e.g. Tavern "The Drunken Dragon"',
                        hintStyle: TextStyle(color: activeTheme.textSecondary.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: activeTheme.surfaceRaised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: sceneAccentColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Scene Description
                    TextField(
                      controller: _descController,
                      style: TextStyle(color: activeTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: l10n?.sceneDescLabel ?? 'Atmosphere Description / GM Notes',
                        labelStyle: TextStyle(color: activeTheme.textSecondary),
                        hintText: l10n?.sceneDescHint ?? 'Warm fireplace, clinking mugs, quiet lute...',
                        hintStyle: TextStyle(color: activeTheme.textSecondary.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: activeTheme.surfaceRaised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: sceneAccentColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Cover Art / Image
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _imagePathController,
                            style: TextStyle(color: activeTheme.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: l10n?.sceneCoverLabel ?? 'Image / Cover Art Path',
                              labelStyle: TextStyle(color: activeTheme.textSecondary),
                              hintText: 'C:/images/tavern.jpg',
                              hintStyle: TextStyle(color: activeTheme.textSecondary.withValues(alpha: 0.6)),
                              filled: true,
                              fillColor: activeTheme.surfaceRaised,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: sceneAccentColor,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: _imagePathController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, size: 18, color: activeTheme.textSecondary),
                                      onPressed: () => setState(() => _imagePathController.clear()),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sceneAccentColor,
                            foregroundColor: ThemeData.estimateBrightnessForColor(sceneAccentColor) == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.image_rounded, size: 18),
                          label: Text(
                            l10n?.browseBtn ?? 'Browse',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                            );
                            if (result != null && result.files.single.path != null) {
                              setState(() {
                                _imagePathController.text = result.files.single.path!;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Color Choice
                    Text(
                      l10n?.colorAccent ?? 'Color Accent:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: activeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableColorOptions.map((color) {
                        final isSelected = _selectedColorHex == color;
                        final colorBrightness = ThemeData.estimateBrightnessForColor(Color(color));
                        final iconColor = colorBrightness == Brightness.dark ? Colors.white : Colors.black87;
                        return InkWell(
                          onTap: () => setState(() => _selectedColorHex = color),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: isDark ? Colors.white : Colors.black87,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color: isDark ? Colors.white24 : Colors.black12,
                                      width: 1,
                                    ),
                            ),
                            child: isSelected ? Icon(Icons.check, size: 20, color: iconColor) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Music Channel (Unified layout)
                    _buildChannelContainer(
                      title: l10n?.musicChannel ?? 'Music Channel',
                      icon: Icons.music_note_rounded,
                      badgeText: selectedMusicTrack != null ? selectedMusicTrack.title : (l10n?.noMusic ?? 'No music'),
                      badgeColor: selectedMusicTrack != null ? sceneAccentColor : activeTheme.textSecondary,
                      searchController: _musicSearchController,
                      searchHint: l10n?.searchMusicHint ?? 'Search music by title or tags...',
                      onSearchChanged: (q) => _onMusicSearchChanged(q, allMusicTracks),
                      onSearchSubmitted: (q) => _onMusicSearchSubmitted(q, allMusicTracks),
                      onClearSearch: () {
                        _musicSearchController.clear();
                        setState(() => _musicQuery = '');
                      },
                      activeTheme: activeTheme,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // "No Music" option card
                          _buildOptionCard(
                            isSelected: _selectedMusicTrackId == null,
                            title: l10n?.noMusicSilence ?? 'No music (silence)',
                            subtitle: l10n?.noMusicDesc ?? 'When activating the scene, background music smoothly fades out',
                            leadingIcon: Icons.volume_off_rounded,
                            onTap: () => setState(() => _selectedMusicTrackId = null),
                            activeTheme: activeTheme,
                          ),
                          const SizedBox(height: 6),
                          if (filteredMusic.isEmpty && _musicQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                l10n?.nothingFound ?? 'Nothing found',
                                style: TextStyle(color: activeTheme.textSecondary, fontSize: 12),
                              ),
                            )
                          else
                            ...filteredMusic.map((track) {
                              final isSelected = _selectedMusicTrackId == track.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _buildOptionCard(
                                  isSelected: isSelected,
                                  title: track.title,
                                  subtitle: track.tags.isNotEmpty ? '${l10n?.tagsPrefix ?? "Tags: "}${track.tags.join(", ")}' : null,
                                  leadingIcon: Icons.audiotrack_rounded,
                                  onTap: () => setState(() => _selectedMusicTrackId = track.id),
                                  activeTheme: activeTheme,
                                  extraContent: isSelected
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              Text(
                                                '${l10n?.musicIntensityLabel ?? "Intensity"}:',
                                                style: TextStyle(fontSize: 12, color: activeTheme.textSecondary),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 6,
                                                  children: MusicIntensity.values.map((intensity) {
                                                    final isIntSelected = _selectedIntensity == intensity;
                                                    return ChoiceChip(
                                                      showCheckmark: false,
                                                      label: Text(
                                                        intensity.name.toUpperCase(),
                                                        style: TextStyle(fontFamily: DsTheme.monoFamily, 
                                                          fontSize: 10,
                                                          fontWeight: isIntSelected ? FontWeight.bold : FontWeight.normal,
                                                          color: isIntSelected
                                                              ? (ThemeData.estimateBrightnessForColor(sceneAccentColor) == Brightness.dark
                                                                  ? Colors.white
                                                                  : Colors.black87)
                                                              : activeTheme.textSecondary,
                                                        ),
                                                      ),
                                                      selected: isIntSelected,
                                                      selectedColor: sceneAccentColor,
                                                      backgroundColor: activeTheme.surfaceRaised,
                                                      side: BorderSide(
                                                        color: isIntSelected
                                                            ? sceneAccentColor
                                                            : (isDark ? Colors.white12 : Colors.black12),
                                                      ),
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
                      title: l10n?.ambientChannel ?? 'Ambient Channel',
                      icon: Icons.waves_rounded,
                      badgeText: l10n?.layersSelected(_ambientVolumes.length) ?? '${_ambientVolumes.length} layers selected',
                      badgeColor: _ambientVolumes.isNotEmpty ? sceneAccentColor : activeTheme.textSecondary,
                      searchController: _ambientSearchController,
                      searchHint: l10n?.searchAmbientHint ?? 'Search ambient by title or tags...',
                      onSearchChanged: _onAmbientSearchChanged,
                      onSearchSubmitted: (q) => _onAmbientSearchSubmitted(q, allAmbientTracks),
                      onClearSearch: () {
                        _ambientSearchController.clear();
                        setState(() => _ambientQuery = '');
                      },
                      activeTheme: activeTheme,
                      child: allAmbientTracks.isEmpty
                          ? Text(
                              l10n?.noAmbientTracksInLibrary ?? 'No ambient tracks in the library.',
                              style: TextStyle(color: activeTheme.textSecondary),
                            )
                          : Column(
                              children: [
                                if (filteredAmbient.isEmpty && _ambientQuery.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      l10n?.nothingFound ?? 'Nothing found',
                                      style: TextStyle(color: activeTheme.textSecondary, fontSize: 12),
                                    ),
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
                                        subtitle: amb.tags.isNotEmpty ? '${l10n?.tagsPrefix ?? "Tags: "}${amb.tags.join(", ")}' : null,
                                        leadingIcon: Icons.air_rounded,
                                        activeTheme: activeTheme,
                                        trailing: Checkbox(
                                          value: isIncluded,
                                          activeColor: sceneAccentColor,
                                          checkColor: ThemeData.estimateBrightnessForColor(sceneAccentColor) == Brightness.dark
                                              ? Colors.white
                                              : Colors.black87,
                                          side: BorderSide(
                                            color: activeTheme.textSecondary.withValues(alpha: 0.6),
                                            width: 1.5,
                                          ),
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
                                                    Icon(Icons.volume_down_rounded, size: 16, color: activeTheme.textSecondary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Slider(
                                                        value: vol,
                                                        min: 0.0,
                                                        max: 1.0,
                                                        activeColor: sceneAccentColor,
                                                        inactiveColor: isDark
                                                            ? Colors.white.withValues(alpha: 0.15)
                                                            : Colors.black.withValues(alpha: 0.15),
                                                        onChanged: (val) {
                                                          setState(() => _ambientVolumes[amb.id] = val);
                                                        },
                                                      ),
                                                    ),
                                                    Text(
                                                      '${(vol * 100).toInt()}%',
                                                      style: TextStyle(fontFamily: DsTheme.monoFamily, fontSize: 12, color: activeTheme.textSecondary),
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
                      title: l10n?.sfxChannel ?? 'SFX Channel (Soundboard)',
                      icon: Icons.flash_on_rounded,
                      badgeText: l10n?.sfxSelected(_selectedSfxIds.length) ?? '${_selectedSfxIds.length} SFX selected',
                      badgeColor: _selectedSfxIds.isNotEmpty ? sceneAccentColor : activeTheme.textSecondary,
                      searchController: _sfxSearchController,
                      searchHint: l10n?.searchSfxHint ?? 'Search SFX by title or tags...',
                      onSearchChanged: _onSfxSearchChanged,
                      onSearchSubmitted: (q) => _onSfxSearchSubmitted(q, allSfxTracks),
                      onClearSearch: () {
                        _sfxSearchController.clear();
                        setState(() => _sfxQuery = '');
                      },
                      activeTheme: activeTheme,
                      child: allSfxTracks.isEmpty
                          ? Text(
                              l10n?.noSfxTracksInLibrary ?? 'No SFX tracks in the library.',
                              style: TextStyle(color: activeTheme.textSecondary),
                            )
                          : Column(
                              children: [
                                if (filteredSfx.isEmpty && _sfxQuery.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      l10n?.nothingFound ?? 'Nothing found',
                                      style: TextStyle(color: activeTheme.textSecondary, fontSize: 12),
                                    ),
                                  )
                                else
                                  ...filteredSfx.map((sfx) {
                                    final isSelected = _selectedSfxIds.contains(sfx.id);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: _buildOptionCard(
                                        isSelected: isSelected,
                                        title: sfx.title,
                                        subtitle: sfx.tags.isNotEmpty ? '${l10n?.tagsPrefix ?? "Tags: "}${sfx.tags.join(", ")}' : null,
                                        leadingIcon: Icons.campaign_rounded,
                                        activeTheme: activeTheme,
                                        trailing: Checkbox(
                                          value: isSelected,
                                          activeColor: sceneAccentColor,
                                          checkColor: ThemeData.estimateBrightnessForColor(sceneAccentColor) == Brightness.dark
                                              ? Colors.white
                                              : Colors.black87,
                                          side: BorderSide(
                                            color: activeTheme.textSecondary.withValues(alpha: 0.6),
                                            width: 1.5,
                                          ),
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
            Divider(
              height: 24,
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: activeTheme.textSecondary,
                  ),
                  child: Text(
                    l10n?.cancel ?? 'Cancel',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(
                    widget.scene == null ? (l10n?.create ?? 'Create') : (l10n?.save ?? 'Save'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sceneAccentColor,
                    foregroundColor: ThemeData.estimateBrightnessForColor(sceneAccentColor) == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: activeTheme.surfaceRaised,
                          content: Text(
                            l10n?.specifySceneName ?? 'Please specify scene name',
                            style: TextStyle(color: activeTheme.textPrimary),
                          ),
                        ),
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
                      imagePath: _imagePathController.text.trim().isNotEmpty ? _imagePathController.text.trim() : null,
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
    required CustomThemeModel activeTheme,
    required Widget child,
  }) {
    final sceneAccentColor = Color(_selectedColorHex);
    final isDark = activeTheme.isDark;

    Color effectiveBadgeTextColor = badgeColor;
    if (!isDark && ThemeData.estimateBrightnessForColor(badgeColor) == Brightness.light) {
      effectiveBadgeTextColor = HSLColor.fromColor(badgeColor).withLightness(0.35).toColor();
    }

    return Container(
      decoration: BoxDecoration(
        color: activeTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: sceneAccentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: activeTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(fontFamily: DsTheme.monoFamily, 
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: effectiveBadgeTextColor,
                  ),
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
            style: TextStyle(color: activeTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: searchHint,
              hintStyle: TextStyle(
                color: activeTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              prefixIcon: Icon(Icons.search, size: 18, color: activeTheme.textSecondary),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 16, color: activeTheme.textSecondary),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: activeTheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: sceneAccentColor,
                  width: 1.5,
                ),
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
    required CustomThemeModel activeTheme,
  }) {
    final activeColor = Color(_selectedColorHex);
    final isDark = activeTheme.isDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.20 : 0.12)
              : activeTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
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
                  color: isSelected ? activeColor : activeTheme.textSecondary,
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
                          color: activeTheme.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: activeTheme.textSecondary,
                          ),
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
