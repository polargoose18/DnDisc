import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/scene_repository_source_repository.dart';
import '../../domain/models/scene_repository_model.dart';
import '../../services/logger_service.dart';
import '../../data/services/media_package_service.dart';
import '../../data/services/scene_package_service.dart';
import '../../data/services/scene_repository_network_service.dart';

class RepositoryViewModel extends ChangeNotifier {
  final SceneRepositorySourceRepository _sourceRepo;
  final SceneRepositoryNetworkService _networkService;
  final ScenePackageService _packageService;
  final MediaPackageService _mediaPackageService;

  List<SceneRepositoryModel> _repositories = [];
  Map<String, SceneRepositoryManifest> _manifests = {}; // repo.id -> manifest
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  CatalogCategoryFilter _categoryFilter = CatalogCategoryFilter.all;

  final Map<String, double> _downloadProgress = {}; // itemId -> 0.0..1.0
  final Set<String> _downloadingSceneIds = {};

  RepositoryViewModel({
    SceneRepositorySourceRepository? sourceRepository,
    SceneRepositoryNetworkService? networkService,
    ScenePackageService? packageService,
    MediaPackageService? mediaPackageService,
  })  : _sourceRepo = sourceRepository ?? SqliteSceneRepositorySourceRepository(),
        _networkService = networkService ?? SceneRepositoryNetworkService(),
        _packageService = packageService ?? ScenePackageService(),
        _mediaPackageService = mediaPackageService ?? MediaPackageService();

  List<SceneRepositoryModel> get repositories => List.unmodifiable(_repositories);
  Map<String, SceneRepositoryManifest> get manifests => Map.unmodifiable(_manifests);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  CatalogCategoryFilter get categoryFilter => _categoryFilter;
  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);
  Set<String> get downloadingSceneIds => Set.unmodifiable(_downloadingSceneIds);

  void setCategoryFilter(CatalogCategoryFilter filter) {
    _categoryFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<({RepositorySceneItem item, SceneRepositoryModel repo})> get allCatalogScenes {
    final list = <({RepositorySceneItem item, SceneRepositoryModel repo})>[];
    for (final repo in _repositories) {
      final manifest = _manifests[repo.id];
      if (manifest != null) {
        for (final scene in manifest.scenes) {
          if (_searchQuery.isEmpty ||
              scene.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (scene.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              repo.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
            list.add((item: scene, repo: repo));
          }
        }
      }
    }
    return list;
  }

  List<({CatalogItem item, SceneRepositoryModel repo})> get filteredCatalogItems {
    final list = <({CatalogItem item, SceneRepositoryModel repo})>[];
    final query = _searchQuery.trim().toLowerCase();

    for (final repo in _repositories) {
      final manifest = _manifests[repo.id];
      if (manifest == null) continue;

      if (_categoryFilter == CatalogCategoryFilter.all || _categoryFilter == CatalogCategoryFilter.scenes) {
        for (final s in manifest.scenes) {
          if (query.isEmpty ||
              s.name.toLowerCase().contains(query) ||
              (s.description?.toLowerCase().contains(query) ?? false) ||
              repo.name.toLowerCase().contains(query)) {
            list.add((item: CatalogItem.fromScene(s), repo: repo));
          }
        }
      }

      if (_categoryFilter == CatalogCategoryFilter.all || _categoryFilter == CatalogCategoryFilter.media) {
        for (final m in manifest.media) {
          if (query.isEmpty ||
              m.name.toLowerCase().contains(query) ||
              (m.description?.toLowerCase().contains(query) ?? false) ||
              repo.name.toLowerCase().contains(query)) {
            list.add((item: CatalogItem.fromMedia(m), repo: repo));
          }
        }
      }

      if (_categoryFilter == CatalogCategoryFilter.all || _categoryFilter == CatalogCategoryFilter.packs) {
        for (final p in manifest.packs) {
          if (query.isEmpty ||
              p.name.toLowerCase().contains(query) ||
              (p.description?.toLowerCase().contains(query) ?? false) ||
              repo.name.toLowerCase().contains(query)) {
            list.add((item: CatalogItem.fromPack(p), repo: repo));
          }
        }
      }
    }
    return list;
  }

  Future<void> loadRepositories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _repositories = await _sourceRepo.getAllRepositories();
      _manifests = {};

      for (var i = 0; i < _repositories.length; i++) {
        final repo = _repositories[i];
        try {
          final result = await _networkService.fetchManifestWithResolvedUrl(repo.url);
          _manifests[repo.id] = result.manifest;
          
          final updatedRepo = repo.copyWith(
            url: result.resolvedUrl,
            lastSyncedAt: DateTime.now(),
          );
          _repositories[i] = updatedRepo;
          await _sourceRepo.updateRepository(updatedRepo);
        } catch (e) {
          LoggerService().warning('Could not load manifest for repo ${repo.name} (${repo.url}): $e');
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load repositories: $e';
      LoggerService().error(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRepository({
    required String name,
    required String url,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _networkService.fetchManifestWithResolvedUrl(url);

      final newRepo = SceneRepositoryModel(
        id: const Uuid().v4(),
        name: name.trim().isEmpty ? result.manifest.name : name.trim(),
        url: result.resolvedUrl,
        description: description?.trim().isEmpty ?? true ? result.manifest.description : description?.trim(),
        createdAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );

      await _sourceRepo.addRepository(newRepo);
      _repositories.add(newRepo);
      _manifests[newRepo.id] = result.manifest;

      LoggerService().info('Successfully added repository "${newRepo.name}" (${result.resolvedUrl})');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add repository: $e';
      LoggerService().error(_errorMessage!);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRepository({
    required String id,
    required String name,
    required String url,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final index = _repositories.indexWhere((r) => r.id == id);
      if (index == -1) {
        throw Exception('Repository not found');
      }

      final currentRepo = _repositories[index];
      final result = await _networkService.fetchManifestWithResolvedUrl(url);

      final updatedRepo = currentRepo.copyWith(
        name: name.trim().isEmpty ? result.manifest.name : name.trim(),
        url: result.resolvedUrl,
        description: description?.trim().isEmpty ?? true ? result.manifest.description : description?.trim(),
        lastSyncedAt: DateTime.now(),
      );

      await _sourceRepo.updateRepository(updatedRepo);
      _repositories[index] = updatedRepo;
      _manifests[id] = result.manifest;

      LoggerService().info('Successfully updated repository "${updatedRepo.name}" (${result.resolvedUrl})');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update repository: $e';
      LoggerService().error(_errorMessage!);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteRepository(String repoId) async {
    try {
      await _sourceRepo.deleteRepository(repoId);
      _repositories.removeWhere((r) => r.id == repoId);
      _manifests.remove(repoId);
      LoggerService().info('Deleted repository ID: $repoId');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete repository: $e';
      LoggerService().error(_errorMessage!);
      notifyListeners();
    }
  }

  Future<bool> downloadAndInstallCatalogItem({
    required CatalogItem item,
    required SceneRepositoryModel repo,
    Future<void> Function()? onInstalled,
  }) async {
    _downloadingSceneIds.add(item.id);
    _downloadProgress[item.id] = 0.0;
    notifyListeners();

    try {
      final targetPackageUrl = SceneRepositoryNetworkService.resolveUrl(repo.url, item.downloadUrl);
      final tempDir = await getTemporaryDirectory();
      final ext = item.type == CatalogItemType.scene
          ? '.scene.zip'
          : (item.type == CatalogItemType.media ? '.media.zip' : '.pack.zip');
      final tempZipPath = p.join(tempDir.path, '${item.id}_${DateTime.now().millisecondsSinceEpoch}$ext');

      await _networkService.downloadScenePackage(
        targetPackageUrl,
        tempZipPath,
        onProgress: (received, total) {
          if (total > 0) {
            _downloadProgress[item.id] = received / total;
            notifyListeners();
          }
        },
      );

      final appDocDir = await getApplicationDocumentsDirectory();
      final audioDir = p.join(appDocDir.path, 'audio_library');

      if (item.type == CatalogItemType.scene) {
        await _packageService.importSingleScenePackage(
          zipFilePath: tempZipPath,
          destinationAudioDir: audioDir,
        );
      } else if (item.type == CatalogItemType.media) {
        await _mediaPackageService.importMediaPackage(
          zipFilePath: tempZipPath,
          destinationAudioDir: audioDir,
        );
      } else if (item.type == CatalogItemType.pack) {
        await _packageService.importPackPackage(
          zipFilePath: tempZipPath,
          destinationAudioDir: audioDir,
        );
      }

      if (onInstalled != null) {
        await onInstalled();
      }

      final tempFile = File(tempZipPath);
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }

      LoggerService().info('${item.type.displayName} "${item.name}" downloaded and installed successfully!');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to download ${item.type.displayName} "${item.name}": $e';
      LoggerService().error(_errorMessage!);
      return false;
    } finally {
      _downloadingSceneIds.remove(item.id);
      _downloadProgress.remove(item.id);
      notifyListeners();
    }
  }

  Future<bool> downloadAndInstallScene({
    required RepositorySceneItem item,
    required SceneRepositoryModel repo,
    Future<void> Function()? onInstalled,
  }) async {
    return downloadAndInstallCatalogItem(
      item: CatalogItem.fromScene(item),
      repo: repo,
      onInstalled: onInstalled,
    );
  }
}
