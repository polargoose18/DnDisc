import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../data/repositories/media_library_repository.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/ambient_layer.dart';
import '../../domain/models/sfx_trigger.dart';
import '../../audio/audio_engine_service.dart';
import '../../services/audio_duration_helper.dart';

class MediaLibraryService extends ChangeNotifier {
  final MediaLibraryRepository _repository;
  final _uuid = const Uuid();

  List<LibraryTrack> _tracks = [];
  bool _isLoading = false;
  AudioBusType? _activeBusFilter;
  String _searchQuery = '';

  List<LibraryTrack> get tracks => List.unmodifiable(_filteredTracks());

  /// The whole library, ignoring the bus filter and the search (for counts).
  List<LibraryTrack> get allTracks => List.unmodifiable(_tracks);
  bool get isLoading => _isLoading;
  AudioBusType? get activeBusFilter => _activeBusFilter;
  String get searchQuery => _searchQuery;

  MediaLibraryService({MediaLibraryRepository? repository, bool autoLoad = true})
      : _repository = repository ?? SqliteMediaLibraryRepository() {
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
        _tracks = await _repository.getAllTracks();
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
      allowedExtensions: supportedExtensions,
    );

    if (result == null || result.files.isEmpty) return [];

    return importPaths(
      busType: busType,
      paths: [for (final file in result.files) if (file.path != null) file.path!],
      defaultTags: defaultTags,
    );
  }

  /// Audio file extensions the library accepts.
  static const List<String> supportedExtensions = ['mp3', 'wav', 'ogg', 'flac', 'm4a'];

  static bool isSupportedFile(String path) =>
      supportedExtensions.contains(p.extension(path).replaceFirst('.', '').toLowerCase());

  /// Adds files by path (picker result or drag and drop) to the library.
  Future<List<LibraryTrack>> importPaths({
    required AudioBusType busType,
    required List<String> paths,
    List<String> defaultTags = const [],
  }) async {
    final importedTracks = <LibraryTrack>[];

    for (final path in paths) {
      final title = p.basenameWithoutExtension(path);
      final durationMs = await AudioDurationHelper.getDurationMs(path);

      final track = LibraryTrack(
        id: _uuid.v4(),
        title: title,
        filePath: path,
        busType: busType,
        tags: List.from(defaultTags),
        colorHex: _getDefaultColorForBus(busType),
        durationMs: durationMs,
      );

      await _repository.insertTrack(track);
      importedTracks.add(track);
    }

    await loadTracks(force: true);
    return importedTracks;
  }

  Future<void> addTrack(LibraryTrack track) async {
    var finalTrack = track;
    if (finalTrack.durationMs <= 0 && finalTrack.filePath.isNotEmpty) {
      final dur = await AudioDurationHelper.getDurationMs(finalTrack.filePath);
      if (dur > 0) {
        finalTrack = finalTrack.copyWith(durationMs: dur);
      }
    }
    await _repository.insertTrack(finalTrack);
    await loadTracks(force: true);
  }

  Future<void> updateTrack(LibraryTrack track) async {
    await _repository.updateTrack(track);
    await loadTracks(force: true);
  }

  Future<void> deleteTrack(String trackId) async {
    await _repository.deleteTrack(trackId);
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
