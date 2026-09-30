import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository_source_repository.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempPath;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatabaseService dbService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_db_v4_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('DatabaseService v4 & SqliteSceneRepositorySourceRepository Tests', () {
    test('should perform full CRUD operations on scene_repositories table in SQLite v4 schema', () async {
      // Arrange
      final repoSource = SqliteSceneRepositorySourceRepository(db: dbService);

      final initialList = await repoSource.getAllRepositories();
      expect(initialList, isEmpty);

      final model = SceneRepositoryModel(
        id: 'repo-1',
        name: 'Fantasy Audio Repo',
        url: 'https://gitlab.com/test/repo/-/raw/main/repository.json',
        description: 'Official fantasy audio collection',
        createdAt: DateTime.now(),
      );

      // Act & Assert - Add
      await repoSource.addRepository(model);
      final fetchedList = await repoSource.getAllRepositories();
      expect(fetchedList.length, equals(1));
      expect(fetchedList.first.id, equals('repo-1'));
      expect(fetchedList.first.name, equals('Fantasy Audio Repo'));

      // Act & Assert - Update
      final updatedModel = model.copyWith(name: 'Updated Fantasy Repo', lastSyncedAt: DateTime.now());
      await repoSource.updateRepository(updatedModel);

      final singleFetched = await repoSource.getRepositoryById('repo-1');
      expect(singleFetched, isNotNull);
      expect(singleFetched!.name, equals('Updated Fantasy Repo'));
      expect(singleFetched.lastSyncedAt, isNotNull);

      // Act & Assert - Delete
      await repoSource.deleteRepository('repo-1');
      final afterDeleteList = await repoSource.getAllRepositories();
      expect(afterDeleteList, isEmpty);
    });
  });
}
