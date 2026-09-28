import 'package:flutter/foundation.dart';
import '../../data/services/scene_service.dart';
import '../../data/repositories/scene_repository.dart';
import '../../domain/models/scene_model.dart';
import '../../audio/audio_engine_service.dart';
import '../../data/services/media_library_service.dart';

/// SceneViewModel manages UI presentation state and scene interactions in compliance with MVVM architecture.
class SceneViewModel extends ChangeNotifier {
  final SceneService _service;

  SceneViewModel({
    SceneService? service,
    SceneRepository? repository,
    bool autoLoad = true,
  }) : _service = service ?? SceneService(repository: repository, autoLoad: autoLoad) {
    _service.addListener(notifyListeners);
  }

  /// Underlying scene service reference
  SceneService get service => _service;

  List<SceneModel> get scenes => _service.scenes;
  String? get activeSceneId => _service.activeSceneId;
  SceneModel? get activeScene => _service.activeScene;
  bool get isLoading => _service.isLoading;

  Future<void> loadScenes({bool force = false}) => _service.loadScenes(force: force);

  Future<void> createScene(SceneModel scene) => _service.createScene(scene);

  Future<void> updateScene(SceneModel scene) => _service.updateScene(scene);

  Future<void> deleteScene(String sceneId) => _service.deleteScene(sceneId);

  Future<SceneModel?> duplicateScene(String sceneId, {String? newName}) =>
      _service.duplicateScene(sceneId, newName: newName);

  Future<void> activateScene(
    SceneModel scene, {
    AudioEngineService? audioEngine,
    MediaLibraryService? mediaLibrary,
    Duration? fadeDuration,
  }) =>
      _service.activateScene(
        scene,
        audioEngine: audioEngine,
        mediaLibrary: mediaLibrary,
        fadeDuration: fadeDuration,
      );

  @override
  void dispose() {
    _service.removeListener(notifyListeners);
    super.dispose();
  }
}
