import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/scene_repository.dart';
import '../../domain/models/scene_model.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/ambient_layer.dart';
import '../../domain/models/sfx_trigger.dart';
import '../../audio/audio_engine_service.dart';
import 'media_library_service.dart';
import 'scene_cover_service.dart';
import '../../services/logger_service.dart';

class SceneService extends ChangeNotifier {
  final SceneRepository _repository;

  List<SceneModel> _scenes = [];
  String? _activeSceneId;
  bool _isLoading = false;

  List<SceneModel> get scenes => List.unmodifiable(_scenes);
  String? get activeSceneId => _activeSceneId;
  SceneModel? get activeScene {
    if (_activeSceneId == null) return null;
    try {
      return _scenes.firstWhere((s) => s.id == _activeSceneId);
    } catch (_) {
      return null;
    }
  }
  bool get isLoading => _isLoading;

  SceneService({SceneRepository? repository, bool autoLoad = true})
      : _repository = repository ?? SqliteSceneRepository() {
    if (autoLoad) {
      loadScenes();
    }
  }

  Future<void>? _currentLoadFuture;

  Future<void> loadScenes({bool force = false}) async {
    if (!force && _currentLoadFuture != null) return _currentLoadFuture!;
    final future = _doLoadScenes();
    _currentLoadFuture = future;
    await future;
    if (_currentLoadFuture == future) {
      _currentLoadFuture = null;
    }
  }

  Future<void> _doLoadScenes() async {
    if (_isDisposed) return;
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isDisposed) {
        _scenes = await _repository.getAllScenes();
      }
    } catch (e) {
      LoggerService().error('SceneService: Error loading scenes', details: '$e');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> createScene(SceneModel inputScene) async {
    // The default cover is picked once, here, and stored with the scene.
    final scene = inputScene.cover == null ? inputScene.copyWith(cover: SceneCoverService().pickRandom()) : inputScene;
    _scenes.removeWhere((s) => s.id == scene.id);
    _scenes.add(scene);
    notifyListeners();
    try {
      await _repository.insertScene(scene);
    } catch (_) {}
    LoggerService().info('SceneService: Created scene "${scene.name}"');
    await loadScenes(force: true);
  }

  Future<void> updateScene(SceneModel scene) async {
    final idx = _scenes.indexWhere((s) => s.id == scene.id);
    if (idx != -1) {
      _scenes[idx] = scene;
    } else {
      _scenes.add(scene);
    }
    notifyListeners();
    try {
      await _repository.updateScene(scene);
    } catch (_) {}
    LoggerService().info('SceneService: Updated scene "${scene.name}"');
    await loadScenes(force: true);
  }

  Future<void> deleteScene(String sceneId) async {
    if (_activeSceneId == sceneId) {
      _activeSceneId = null;
    }
    _scenes.removeWhere((s) => s.id == sceneId);
    notifyListeners();
    try {
      await _repository.deleteScene(sceneId);
    } catch (_) {}
    LoggerService().info('SceneService: Deleted scene $sceneId');
    await loadScenes(force: true);
  }

  Future<SceneModel?> duplicateScene(String sceneId, {String? newName}) async {
    final original = _scenes.cast<SceneModel?>().firstWhere(
      (s) => s?.id == sceneId,
      orElse: () => null,
    );
    if (original == null) return null;

    final duplicated = original.copyWith(
      id: const Uuid().v4(),
      name: newName ?? '${original.name} (Copy)',
      createdAt: DateTime.now(),
    );

    await createScene(duplicated);
    return duplicated;
  }

  Future<void> activateScene(
    SceneModel scene, {
    AudioEngineService? audioEngine,
    MediaLibraryService? mediaLibrary,
    Duration? fadeDuration,
  }) async {
    _activeSceneId = scene.id;
    if (!_scenes.any((s) => s.id == scene.id)) {
      _scenes.add(scene);
    }
    notifyListeners();
    LoggerService().info('SceneService: Activating scene "${scene.name}" (ID: ${scene.id})');

    if (audioEngine == null) return;

    final musicFade = fadeDuration ?? audioEngine.settings?.musicFadeDuration ?? const Duration(milliseconds: 1500);
    final ambientFade = fadeDuration ?? audioEngine.settings?.ambientFadeDuration ?? const Duration(milliseconds: 1000);

    // 1. Prepare Music Track (load metadata and intensity without auto-starting playback)
    if (scene.musicTrackId != null && scene.musicTrackId!.isNotEmpty && mediaLibrary != null) {
      final musicTrack = mediaLibrary.tracks.cast<dynamic>().firstWhere(
        (t) => t.id == scene.musicTrackId,
        orElse: () => null,
      );

      if (musicTrack != null) {
        await audioEngine.musicBus.prepareTrack(
          AudioTrack(
            id: musicTrack.id,
            title: musicTrack.title,
            filePath: musicTrack.filePath,
            intensity: scene.musicIntensity ?? musicTrack.intensity,
            coverImagePath: musicTrack.coverImagePath,
            loopStartMs: musicTrack.loopStartMs,
            loopEndMs: musicTrack.loopEndMs,
          ),
        );
      } else {
        LoggerService().warning('SceneService: Bound music track not found in library: ${scene.musicTrackId}');
      }
    } else {
      await audioEngine.musicBus.stop(fadeDuration: musicFade);
    }

    // 2. Adjust Ambient Layers (preserve persistent layers, load scene layers without auto-start)
    final currentLayers = List<AmbientLayer>.from(audioEngine.ambientBus.layers);
    for (final layer in currentLayers) {
      if (!layer.isPersistent && !scene.ambientLayerVolumes.containsKey(layer.id)) {
        if (layer.isActive) {
          await audioEngine.ambientBus.toggleLayer(layer.id, fadeDuration: ambientFade);
        }
        await audioEngine.ambientBus.removeLayer(layer.id);
      }
    }

    for (final entry in scene.ambientLayerVolumes.entries) {
      final layerId = entry.key;
      final targetVolume = entry.value;

      final existingIndex = audioEngine.ambientBus.layers.indexWhere((l) => l.id == layerId);
      if (existingIndex != -1) {
        audioEngine.ambientBus.setLayerVolume(layerId, targetVolume, fadeDuration: Duration.zero);
      } else if (mediaLibrary != null) {
        final ambTrack = mediaLibrary.tracks.cast<dynamic>().firstWhere(
          (t) => t.id == layerId,
          orElse: () => null,
        );
        if (ambTrack != null) {
          final newLayer = AmbientLayer(
            id: ambTrack.id,
            title: ambTrack.title,
            filePath: ambTrack.filePath,
            volume: targetVolume,
            isActive: false, // Do not start playing immediately
            iconName: ambTrack.iconName,
            isPersistent: false,
          );
          audioEngine.ambientBus.addLayer(newLayer);
        }
      }
    }

    // 3. Bind Soundboard SFX Triggers (preserve persistent triggers)
    if (mediaLibrary != null) {
      final triggersToRemove = audioEngine.sfxBus.triggers
          .where((t) => !t.isPersistent && !scene.soundboardSfxIds.contains(t.id))
          .map((t) => t.id)
          .toList();
      for (final id in triggersToRemove) {
        audioEngine.sfxBus.removeTrigger(id);
      }

      for (final sfxId in scene.soundboardSfxIds) {
        final existingTrigger = audioEngine.sfxBus.triggers.any((t) => t.id == sfxId);
        if (!existingTrigger) {
          final sfxTrack = mediaLibrary.tracks.cast<dynamic>().firstWhere(
            (t) => t.id == sfxId,
            orElse: () => null,
          );
          if (sfxTrack != null) {
            audioEngine.sfxBus.addTrigger(
              SfxTrigger(
                id: sfxTrack.id,
                title: sfxTrack.title,
                filePath: sfxTrack.filePath,
                colorHex: sfxTrack.colorHex,
                isPersistent: false,
                iconName: sfxTrack.iconName,
              ),
            );
          }
        }
      }
    }

    notifyListeners();
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
