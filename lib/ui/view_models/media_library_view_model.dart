import 'package:flutter/foundation.dart';
import '../../services/media_library_service.dart';
import '../../data/repositories/media_library_repository.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/audio_track.dart';
import '../../audio/audio_engine_service.dart';

/// MediaLibraryViewModel manages UI state, filtering, search, and track operations in compliance with MVVM architecture.
class MediaLibraryViewModel extends ChangeNotifier {
  final MediaLibraryService _service;

  MediaLibraryViewModel({
    MediaLibraryService? service,
    MediaLibraryRepository? repository,
    bool autoLoad = true,
  }) : _service = service ?? MediaLibraryService(repository: repository, autoLoad: autoLoad) {
    _service.addListener(notifyListeners);
  }

  /// Underlying media library service reference
  MediaLibraryService get service => _service;

  List<LibraryTrack> get tracks => _service.tracks;
  bool get isLoading => _service.isLoading;
  AudioBusType? get activeBusFilter => _service.activeBusFilter;
  String get searchQuery => _service.searchQuery;

  Future<void> loadTracks({bool force = false}) => _service.loadTracks(force: force);

  void setBusFilter(AudioBusType? filter) => _service.setBusFilter(filter);

  void setSearchQuery(String query) => _service.setSearchQuery(query);

  Future<List<LibraryTrack>> importFiles({
    required AudioBusType busType,
    List<String> defaultTags = const [],
  }) =>
      _service.importFiles(busType: busType, defaultTags: defaultTags);

  Future<void> addTrack(LibraryTrack track) => _service.addTrack(track);

  Future<void> updateTrack(LibraryTrack track) => _service.updateTrack(track);

  Future<void> deleteTrack(String trackId) => _service.deleteTrack(trackId);

  void playTrackToEngine(LibraryTrack track, AudioEngineService engine) =>
      _service.playTrackToEngine(track, engine);

  @override
  void dispose() {
    _service.removeListener(notifyListeners);
    super.dispose();
  }
}
