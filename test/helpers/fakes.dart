import 'dart:async';
import 'package:ttrpg_audio_player/audio/playback/bus_player.dart';
import 'package:ttrpg_audio_player/audio/audio_output_service.dart';
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository_source_repository.dart';
import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';

class FakeSourceRepo implements SceneRepositorySourceRepository {
  final List<SceneRepositoryModel> repos;

  FakeSourceRepo(this.repos);

  @override
  Future<List<SceneRepositoryModel>> getAllRepositories() async => List.from(repos);

  @override
  Future<SceneRepositoryModel?> getRepositoryById(String id) async {
    return repos.firstWhere((r) => r.id == id);
  }

  @override
  Future<void> addRepository(SceneRepositoryModel repo) async => repos.add(repo);

  @override
  Future<void> updateRepository(SceneRepositoryModel repo) async {
    final idx = repos.indexWhere((r) => r.id == repo.id);
    if (idx != -1) {
      repos[idx] = repo;
    }
  }

  @override
  Future<void> deleteRepository(String id) async => repos.removeWhere((r) => r.id == id);
}

class FakeMediaLibraryRepo implements MediaLibraryRepository {
  final List<LibraryTrack> tracks = [];

  @override
  Future<List<LibraryTrack>> getAllTracks() async => List.from(tracks);

  @override
  Future<LibraryTrack?> getTrackById(String id) async {
    try {
      return tracks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertTrack(LibraryTrack track) async {
    tracks.add(track);
  }

  @override
  Future<void> insertTracksBatch(List<LibraryTrack> newTracks) async {
    tracks.addAll(newTracks);
  }

  @override
  Future<void> updateTrack(LibraryTrack track) async {
    final idx = tracks.indexWhere((t) => t.id == track.id);
    if (idx != -1) tracks[idx] = track;
  }

  @override
  Future<void> deleteTrack(String id) async {
    tracks.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<LibraryTrack>> searchTracks(String query, {AudioBusType? filterBus}) async {
    return tracks.where((t) => t.title.toLowerCase().contains(query.toLowerCase())).toList();
  }
}

class FakeSceneRepo implements SceneRepository {
  final List<SceneModel> scenes = [];

  @override
  Future<List<SceneModel>> getAllScenes() async => List.from(scenes);

  @override
  Future<SceneModel?> getSceneById(String id) async {
    try {
      return scenes.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertScene(SceneModel scene) async {
    scenes.add(scene);
  }

  @override
  Future<void> updateScene(SceneModel scene) async {
    final idx = scenes.indexWhere((s) => s.id == scene.id);
    if (idx != -1) scenes[idx] = scene;
  }

  @override
  Future<void> deleteScene(String id) async {
    scenes.removeWhere((s) => s.id == id);
  }
}

class FakeNetworkService extends SceneRepositoryNetworkService {
  final SceneRepositoryManifest manifest;

  FakeNetworkService(this.manifest);

  @override
  Future<ManifestFetchResult> fetchManifestWithResolvedUrl(String url) async {
    return ManifestFetchResult(manifest: manifest, resolvedUrl: url);
  }
}


/// Output devices in memory; records where the sound was moved.
class FakeOutputBackend implements OutputDeviceBackend {
  List<OutputDevice> devices;
  final List<String?> changes = [];
  String? startedOn;
  bool started = false;
  bool failChange = false;

  FakeOutputBackend(this.devices);

  @override
  Future<List<OutputDevice>> listDevices() async => devices;

  @override
  Future<bool> start({String? deviceId}) async {
    started = true;
    startedOn = deviceId;
    return true;
  }

  @override
  Future<void> changeDevice(String? deviceId) async {
    if (failChange) throw StateError('Device is gone');
    changes.add(deviceId);
  }
}

/// Player without sound: records what the controllers ask for. [loading]
/// holds play() until it completes, like a file that takes time to load.
class FakeBusPlayer implements BusPlayer {
  final String path;
  double volume = 1;
  bool playing = false;
  bool paused = false;
  bool stopped = false;
  bool disposed = false;
  bool looping = false;
  Duration loopStart = Duration.zero;
  Duration? loopEnd;
  Completer<void>? loading;
  final _duration = StreamController<Duration>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _complete = StreamController<void>.broadcast();

  FakeBusPlayer(this.path);

  @override
  Stream<Duration> get onDurationChanged => _duration.stream;
  @override
  Stream<Duration> get onPositionChanged => _position.stream;
  @override
  Stream<void> get onPlayerComplete => _complete.stream;

  @override
  Future<void> setVolume(double v) async => volume = v;
  @override
  Future<void> setLooping(bool looping) async => this.looping = looping;
  @override
  Future<void> setLoopRegion({Duration start = Duration.zero, Duration? end}) async {
    loopStart = start;
    loopEnd = end;
  }

  @override
  Future<void> play(String path) async {
    plays++;
    await loading?.future;
    if (disposed) return;
    playing = true;
  }

  @override
  Future<void> pause() async => paused = true;
  @override
  Future<void> resume() async => paused = false;
  @override
  Future<void> stop() async {
    stopped = true;
    playing = false;
  }

  @override
  Future<void> dispose() async => disposed = true;

  void emitDuration(Duration d) => _duration.add(d);
  void emitPosition(Duration p) => _position.add(p);
  void emitComplete() => _complete.add(null);

  /// How often play() was called.
  int plays = 0;

  /// Audible: started, not paused, not stopped.
  bool get audible => playing && !paused && !stopped && !disposed;
}
