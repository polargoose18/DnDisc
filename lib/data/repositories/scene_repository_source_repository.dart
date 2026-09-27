import '../../domain/models/scene_repository_model.dart';
import '../services/database_service.dart';

abstract class SceneRepositorySourceRepository {
  Future<List<SceneRepositoryModel>> getAllRepositories();
  Future<SceneRepositoryModel?> getRepositoryById(String id);
  Future<void> addRepository(SceneRepositoryModel repository);
  Future<void> updateRepository(SceneRepositoryModel repository);
  Future<void> deleteRepository(String id);
}

class SqliteSceneRepositorySourceRepository implements SceneRepositorySourceRepository {
  final DatabaseService _db;

  SqliteSceneRepositorySourceRepository({DatabaseService? db})
      : _db = db ?? DatabaseService();

  @override
  Future<List<SceneRepositoryModel>> getAllRepositories() =>
      _db.getAllSceneRepositories();

  @override
  Future<SceneRepositoryModel?> getRepositoryById(String id) =>
      _db.getSceneRepositoryById(id);

  @override
  Future<void> addRepository(SceneRepositoryModel repository) =>
      _db.insertSceneRepository(repository);

  @override
  Future<void> updateRepository(SceneRepositoryModel repository) =>
      _db.updateSceneRepository(repository);

  @override
  Future<void> deleteRepository(String id) =>
      _db.deleteSceneRepository(id);
}
