import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../db/database_service.dart';
import '../models/library_track.dart';
import '../models/audio_track.dart';
import '../models/ambient_layer.dart';
import '../models/sfx_trigger.dart';
import '../audio/audio_engine_service.dart';

class MediaLibraryService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  List<LibraryTrack> _tracks = [];
  bool _isLoading = false;
  AudioBusType? _activeBusFilter;
  String _searchQuery = '';

  List<LibraryTrack> get tracks => List.unmodifiable(_filteredTracks());
  bool get isLoading => _isLoading;
  AudioBusType? get activeBusFilter => _activeBusFilter;
  String get searchQuery => _searchQuery;

  MediaLibraryService({bool autoLoad = true}) {
    if (autoLoad) {
      loadTracks();
    }
  }

  Future<void>? _currentLoadFuture;

  Future<void> loadTracks({bool force = false}) async {
    if (!force && _currentLoadFuture != null) return _currentLoadFuture!;
    final future = _doLoadTracks();
    _currentLoadFuture = future;
    await future;
    if (_currentLoadFuture == future) {
      _currentLoadFuture = null;
    }
  }

  Future<void> _doLoadTracks() async {
    if (_isDisposed) return;
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isDisposed) {
        _tracks = await _db.getAllTracks();
      }
    } catch (e) {
      debugPrint('Error loading tracks: $e');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setBusFilter(AudioBusType? filter) {
    _activeBusFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<LibraryTrack> _filteredTracks() {
    return _tracks.where((track) {
      final matchesBus = _activeBusFilter == null || track.busType == _activeBusFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          track.title.toLowerCase().contains(_searchQuery) ||
          track.tags.any((t) => t.toLowerCase().contains(_searchQuery));
      return matchesBus && matchesSearch;
    }).toList();
  }

  Future<List<LibraryTrack>> importFiles({
    required AudioBusType busType,
    List<String> defaultTags = const [],
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'm4a'],
    );

    if (result == null || result.files.isEmpty) return [];

    final importedTracks = <LibraryTrack>[];

    for (final file in result.files) {
      if (file.path == null) continue;

      final title = p.basenameWithoutExtension(file.path!);
      final track = LibraryTrack(
        id: _uuid.v4(),
        title: title,
        filePath: file.path!,
        busType: busType,
        tags: List.from(defaultTags),
        colorHex: _getDefaultColorForBus(busType),
      );

      await _db.insertTrack(track);
      importedTracks.add(track);
    }

    await loadTracks(force: true);
    return importedTracks;
  }

  Future<void> addTrack(LibraryTrack track) async {
    await _db.insertTrack(track);
    await loadTracks(force: true);
  }

  Future<void> updateTrack(LibraryTrack track) async {
    await _db.updateTrack(track);
    await loadTracks(force: true);
  }

  Future<void> deleteTrack(String trackId) async {
    await _db.deleteTrack(trackId);
    await loadTracks(force: true);
  }

  /// Dispatch track directly to its designated Audio Bus in AudioEngineService
  void playTrackToEngine(LibraryTrack track, AudioEngineService engine) {
    switch (track.busType) {
      case AudioBusType.music:
        engine.musicBus.playTrack(
          AudioTrack(
            id: track.id,
            title: track.title,
            filePath: track.filePath,
            intensity: track.intensity,
            coverImagePath: track.coverImagePath,
            loopStartMs: track.loopStartMs,
            loopEndMs: track.loopEndMs,
          ),
        );
        break;

      case AudioBusType.ambient:
        final existingLayerIndex = engine.ambientBus.layers.indexWhere((l) => l.id == track.id);
        if (existingLayerIndex == -1) {
          engine.ambientBus.addLayer(
            AmbientLayer(
              id: track.id,
              title: track.title,
              filePath: track.filePath,
              isActive: true,
            ),
          );
        } else {
          engine.ambientBus.toggleLayer(track.id);
        }
        break;

      case AudioBusType.sfx:
        final existingTriggerIndex = engine.sfxBus.triggers.indexWhere((t) => t.id == track.id);
        if (existingTriggerIndex == -1) {
          engine.sfxBus.addTrigger(
            SfxTrigger(
              id: track.id,
              title: track.title,
              filePath: track.filePath,
              colorHex: track.colorHex,
            ),
          );
        }
        engine.sfxBus.triggerSfx(track.id);
        break;
    }
  }

  int _getDefaultColorForBus(AudioBusType bus) {
    switch (bus) {
      case AudioBusType.music:
        return 0xFF9C27B0; // Purple
      case AudioBusType.ambient:
        return 0xFF009688; // Teal
      case AudioBusType.sfx:
        return 0xFFFF9800; // Orange
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
