import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository_source_repository.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/repository_view_model.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempPath;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return tempPath;
  }
}

class FakeSceneRepositorySourceRepository implements SceneRepositorySourceRepository {
  final List<SceneRepositoryModel> _repos = [];

  @override
  Future<void> addRepository(SceneRepositoryModel repository) async {
    _repos.add(repository);
  }

  @override
  Future<void> deleteRepository(String id) async {
    _repos.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<SceneRepositoryModel>> getAllRepositories() async {
    return List.from(_repos);
  }

  @override
  Future<SceneRepositoryModel?> getRepositoryById(String id) async {
    try {
      return _repos.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateRepository(SceneRepositoryModel repository) async {
    final idx = _repos.indexWhere((r) => r.id == repository.id);
    if (idx != -1) {
      _repos[idx] = repository;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_repo_vm_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    tempDir.delete(recursive: true).ignore();
  });

  group('RepositoryViewModel Unit Tests', () {
    test(
      'Что проверяем: Инициализация и установка поискового запроса setSearchQuery в RepositoryViewModel. '
      'Входные данные: setSearchQuery("дракон"). '
      'Ожидаемый результат: searchQuery становится равным "дракон" и вызывается notifyListeners.',
      () {
        final fakeSource = FakeSceneRepositorySourceRepository();
        final vm = RepositoryViewModel(sourceRepository: fakeSource);

        expect(vm.searchQuery, isEmpty);
        bool notified = false;
        vm.addListener(() => notified = true);

        vm.setSearchQuery('дракон');
        expect(vm.searchQuery, equals('дракон'));
        expect(notified, isTrue);
      },
    );

    test(
      'Что проверяем: Удаление репозитория из ViewModel deleteRepository. '
      'Входные данные: Добавленный репозиторий с id="repo-del-1". '
      'Ожидаемый результат: Список repositories пуст после вызова deleteRepository.',
      () async {
        final fakeSource = FakeSceneRepositorySourceRepository();
        final repo = SceneRepositoryModel(
          id: 'repo-del-1',
          name: 'To Delete',
          url: 'https://example.com/repo',
          createdAt: DateTime.now(),
        );
        await fakeSource.addRepository(repo);

        final vm = RepositoryViewModel(sourceRepository: fakeSource);
        await vm.loadRepositories();

        expect(vm.repositories.length, equals(1));

        await vm.deleteRepository('repo-del-1');
        expect(vm.repositories, isEmpty);
      },
    );
  });
}
