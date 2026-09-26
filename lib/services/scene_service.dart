import 'package:flutter/foundation.dart';
import '../db/database_service.dart';
import '../models/scene_model.dart';
import '../models/audio_track.dart';
import '../models/ambient_layer.dart';
import '../models/sfx_trigger.dart';
import '../audio/audio_engine_service.dart';
import 'media_library_service.dart';
import 'logger_service.dart';

class SceneService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

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

  SceneService({bool autoLoad = true}) {
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
        _scenes = await _db.getAllScenes();
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

  Future<void> createScene(SceneModel scene) async {
    await _db.insertScene(scene);
    LoggerService().info('SceneService: Created scene "${scene.name}"');
    await loadScenes(force: true);
  }

  Future<void> updateScene(SceneModel scene) async {
    await _db.updateScene(scene);
    LoggerService().info('SceneService: Updated scene "${scene.name}"');
    await loadScenes(force: true);
  }

  Future<void> deleteScene(String sceneId) async {
    if (_activeSceneId == sceneId) {
      _activeSceneId = null;
    }
    await _db.deleteScene(sceneId);
    LoggerService().info('SceneService: Deleted scene $sceneId');
    await loadScenes(force: true);
  }

  Future<void> activateScene(
    SceneModel scene, {
    required AudioEngineService audioEngine,
    required MediaLibraryService mediaLibrary,
    Duration? fadeDuration,
  }) async {
    _activeSceneId = scene.id;
    notifyListeners();
    LoggerService().info('SceneService: Activating scene "${scene.name}" (ID: ${scene.id})');

    final musicFade = fadeDuration ?? audioEngine.settings?.musicFadeDuration ?? const Duration(milliseconds: 1500);
    final ambientFade = fadeDuration ?? audioEngine.settings?.ambientFadeDuration ?? const Duration(milliseconds: 1000);

    // 1. Switch Music Track
    if (scene.musicTrackId != null && scene.musicTrackId!.isNotEmpty) {
      final musicTrack = mediaLibrary.tracks.cast<dynamic>().firstWhere(
        (t) => t.id == scene.musicTrackId,
        orElse: () => null,
      );

      if (musicTrack != null) {
        await audioEngine.musicBus.playTrack(
          AudioTrack(
            id: musicTrack.id,
            title: musicTrack.title,
            filePath: musicTrack.filePath,
            intensity: scene.musicIntensity ?? musicTrack.intensity,
            coverImagePath: musicTrack.coverImagePath,
            loopStartMs: musicTrack.loopStartMs,
            loopEndMs: musicTrack.loopEndMs,
          ),
          fadeDuration: musicFade,
        );
      } else {
        LoggerService().warning('SceneService: Bound music track not found in library: ${scene.musicTrackId}');
      }
    } else {
      await audioEngine.musicBus.stop(fadeDuration: musicFade);
    }

    // 2. Adjust Ambient Layers
    final currentLayers = audioEngine.ambientBus.layers;
    for (final layer in currentLayers) {
      if (!scene.ambientLayerVolumes.containsKey(layer.id) && layer.isActive) {
        // Fade out layers not in scene
        await audioEngine.ambientBus.toggleLayer(layer.id, fadeDuration: ambientFade);
      }
    }

    for (final entry in scene.ambientLayerVolumes.entries) {
      final layerId = entry.key;
      final targetVolume = entry.value;

      final existingIndex = currentLayers.indexWhere((l) => l.id == layerId);
      if (existingIndex != -1) {
        final existing = currentLayers[existingIndex];
        if (!existing.isActive) {
          audioEngine.ambientBus.setLayerVolume(layerId, targetVolume, fadeDuration: Duration.zero);
          await audioEngine.ambientBus.toggleLayer(layerId, fadeDuration: ambientFade);
        } else {
          audioEngine.ambientBus.setLayerVolume(layerId, targetVolume, fadeDuration: ambientFade);
        }
      } else {
        // Find track in library to add as layer
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
            isActive: true,
            iconName: ambTrack.iconName,
          );
          audioEngine.ambientBus.addLayer(newLayer);
        }
      }
    }

    // 3. Bind Soundboard SFX Triggers
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
            ),
          );
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
