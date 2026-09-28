import '../../domain/models/scene_model.dart';
import '../services/database_service.dart';

abstract class SceneRepository {
  Future<List<SceneModel>> getAllScenes();
  Future<SceneModel?> getSceneById(String id);
  Future<void> insertScene(SceneModel scene);
  Future<void> updateScene(SceneModel scene);
  Future<void> deleteScene(String id);
}

class SqliteSceneRepository implements SceneRepository {
  final DatabaseService _db;

  SqliteSceneRepository({DatabaseService? db}) : _db = db ?? DatabaseService();

  @override
  Future<List<SceneModel>> getAllScenes() => _db.getAllScenes();

  @override
  Future<SceneModel?> getSceneById(String id) => _db.getSceneById(id);

  @override
  Future<void> insertScene(SceneModel scene) => _db.insertScene(scene);

  @override
  Future<void> updateScene(SceneModel scene) => _db.updateScene(scene);

  @override
  Future<void> deleteScene(String id) => _db.deleteScene(id);
}
