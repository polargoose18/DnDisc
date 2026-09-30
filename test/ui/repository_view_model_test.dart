import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository_source_repository.dart';
import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';
import 'package:ttrpg_audio_player/data/services/settings_service.dart';
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

class FakeSceneRepositoryNetworkService extends SceneRepositoryNetworkService {
  final SceneRepositoryManifest manifest;

  FakeSceneRepositoryNetworkService([
    this.manifest = const SceneRepositoryManifest(name: 'Fake Repo'),
  ]);

  @override
  Future<ManifestFetchResult> fetchManifestWithResolvedUrl(String url) async {
    return ManifestFetchResult(manifest: manifest, resolvedUrl: url);
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

    test(
      'Что проверяем: Редактирование данных существующего репозитория через updateRepository. '
      'Входные данные: Исходный репозиторий id="repo-edit-1", вызов updateRepository с новым именем "Updated Name" и URL "https://example.com/new_repo.json". '
      'Ожидаемый результат: Метод возвращает true, имя и URL репозитория обновляются в списке repositories и в репозитории данных.',
      () async {
        final fakeSource = FakeSceneRepositorySourceRepository();
        final fakeNetwork = FakeSceneRepositoryNetworkService(
          const SceneRepositoryManifest(
            name: 'Updated Name',
            description: 'Updated Description',
          ),
        );
        final initialRepo = SceneRepositoryModel(
          id: 'repo-edit-1',
          name: 'Original Name',
          url: 'https://example.com/old_repo.json',
          description: 'Original Description',
          createdAt: DateTime.now(),
        );
        await fakeSource.addRepository(initialRepo);

        final vm = RepositoryViewModel(
          sourceRepository: fakeSource,
          networkService: fakeNetwork,
        );
        await vm.loadRepositories();
        expect(vm.repositories.first.name, equals('Original Name'));

        final success = await vm.updateRepository(
          id: 'repo-edit-1',
          name: 'Updated Name',
          url: 'https://example.com/new_repo.json',
          description: 'Updated Description',
        );

        expect(success, isTrue);
        expect(vm.repositories.first.name, equals('Updated Name'));
        expect(vm.repositories.first.url, equals('https://example.com/new_repo.json'));
        expect(vm.repositories.first.description, equals('Updated Description'));

        final persisted = await fakeSource.getRepositoryById('repo-edit-1');
        expect(persisted?.name, equals('Updated Name'));
        expect(persisted?.url, equals('https://example.com/new_repo.json'));
      },
    );

    test(
      'Что проверяем: Определение целевой папки аудиобиблиотеки getEffectiveAudioDirectory в RepositoryViewModel. '
      'Входные данные: RepositoryViewModel с дефолтным SettingsService, затем с установленным customDownloadDirectory ("D:/CustomFolder"). '
      'Ожидаемый результат: В первом случае возвращается путь к fallback Documents/audio_library, во втором случае возвращается "D:/CustomFolder".',
      () async {
        final fakeSource = FakeSceneRepositorySourceRepository();
        final settings = SettingsService();

        final vm = RepositoryViewModel(
          sourceRepository: fakeSource,
          settingsService: settings,
        );

        final defaultDir = await vm.getEffectiveAudioDirectory();
        expect(defaultDir.endsWith('audio_library'), isTrue);

        settings.setCustomDownloadDirectory('D:/CustomFolder');
        final customDir = await vm.getEffectiveAudioDirectory();
        expect(customDir, equals('D:/CustomFolder'));

        settings.resetCustomDownloadDirectory();
        final resetDir = await vm.getEffectiveAudioDirectory();
        expect(resetDir.endsWith('audio_library'), isTrue);
      },
    );
  });
}
