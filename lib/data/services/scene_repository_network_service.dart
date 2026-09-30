import 'dart:convert';
import 'dart:io';
import '../../services/logger_service.dart';
import '../../domain/models/scene_repository_model.dart';

class ManifestFetchResult {
  final SceneRepositoryManifest manifest;
  final String resolvedUrl;

  const ManifestFetchResult({
    required this.manifest,
    required this.resolvedUrl,
  });
}

class SceneRepositoryNetworkService {
  final HttpClient _client;

  SceneRepositoryNetworkService({HttpClient? client})
      : _client = client ?? HttpClient();

  static bool _isDropboxUrl(String url) {
    try {
      final uri = Uri.tryParse(Uri.encodeFull(url.trim()));
      if (uri == null) return false;
      final host = uri.host.toLowerCase();
      return host == 'dropbox.com' ||
          host.endsWith('.dropbox.com') ||
          host == 'dropboxusercontent.com' ||
          host.endsWith('.dropboxusercontent.com');
    } catch (_) {
      return false;
    }
  }

  static String _normalizeDropboxUrl(String url) {
    try {
      final trimmed = url.trim();
      final uri = Uri.tryParse(Uri.encodeFull(trimmed));
      if (uri == null) return url;
      final host = uri.host.toLowerCase();
      if (host == 'dropbox.com' ||
          host.endsWith('.dropbox.com') ||
          host == 'dropboxusercontent.com' ||
          host.endsWith('.dropboxusercontent.com')) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams['dl'] = '1';
        return uri.replace(queryParameters: queryParams).toString();
      }
    } catch (_) {
      // Fallback
    }
    return url;
  }

  static String transformRepositoryUrl(String rawUrl) {
    var trimmed = rawUrl.trim();

    // Dropbox direct download links
    if (_isDropboxUrl(trimmed)) {
      return _normalizeDropboxUrl(trimmed);
    }

    // Strip fragment
    if (trimmed.contains('#')) {
      trimmed = trimmed.split('#').first;
    }

    // GitLab link handling
    final uri = Uri.tryParse(Uri.encodeFull(trimmed));
    final host = uri?.host.toLowerCase() ?? '';
    final isGitLab = host == 'gitlab.com' || host == 'www.gitlab.com';

    if (isGitLab) {
      // Strip query parameters for GitLab repository / tree / blob web links
      if (trimmed.contains('?')) {
        trimmed = trimmed.split('?').first;
      }

      if (trimmed.endsWith('/')) {
        trimmed = trimmed.substring(0, trimmed.length - 1);
      }
      if (trimmed.endsWith('.git')) {
        trimmed = trimmed.substring(0, trimmed.length - 4);
      }

      // GitLab blob link: https://gitlab.com/user/repo/-/blob/branch/path/to/manifest.json
      final gitlabBlobRegex = RegExp(r'^https?://(?:www\.)?gitlab\.com/(.+?)/-/blob/([^/]+)/(.*)$');
      final blobMatch = gitlabBlobRegex.firstMatch(trimmed);
      if (blobMatch != null) {
        final project = blobMatch.group(1);
        final branch = blobMatch.group(2);
        final path = blobMatch.group(3);
        return 'https://gitlab.com/$project/-/raw/$branch/$path';
      }

      // GitLab tree link: https://gitlab.com/user/repo/-/tree/branch or https://gitlab.com/user/repo/-/tree/branch/subfolder
      final gitlabTreeRegex = RegExp(r'^https?://(?:www\.)?gitlab\.com/(.+?)/-/tree/(.+?)/?$');
      final treeMatch = gitlabTreeRegex.firstMatch(trimmed);
      if (treeMatch != null) {
        final project = treeMatch.group(1);
        final branchAndPath = treeMatch.group(2);
        return 'https://gitlab.com/$project/-/raw/$branchAndPath/repository.json';
      }

      // GitLab repository root: https://gitlab.com/user/repo or https://gitlab.com/group/subgroup/repo
      final gitlabRepoRegex = RegExp(r'^https?://(?:www\.)?gitlab\.com/([^/]+(?:/[^/]+)+)/?$');
      final repoMatch = gitlabRepoRegex.firstMatch(trimmed);
      if (repoMatch != null && !trimmed.contains('/-/')) {
        final project = repoMatch.group(1);
        return 'https://gitlab.com/$project/-/raw/main/repository.json';
      }
    }

    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('.git')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
    }

    if (trimmed.endsWith('.json')) {
      return trimmed;
    }

    return '$trimmed/repository.json';
  }

  static String resolveUrl(String baseUrl, String pathOrUrl) {
    String resolved;
    final trimmedPath = pathOrUrl.trim();
    if (trimmedPath.startsWith('http://') || trimmedPath.startsWith('https://')) {
      resolved = trimmedPath;
    } else {
      final baseUri = Uri.parse(Uri.encodeFull(baseUrl.trim()));
      final encodedPath = Uri.encodeFull(trimmedPath);
      resolved = baseUri.resolve(encodedPath).toString();
    }
    if (_isDropboxUrl(resolved)) {
      return _normalizeDropboxUrl(resolved);
    }
    return resolved;
  }

  Future<ManifestFetchResult> fetchManifestWithResolvedUrl(String rawUrl) async {
    final primaryUrl = transformRepositoryUrl(rawUrl);
    LoggerService().info('Fetching scene repository manifest from: $primaryUrl');

    List<String> urlsToTry = [primaryUrl];

    Object? lastException;
    for (final targetUrl in urlsToTry) {
      try {
        final request = await _client.getUrl(Uri.parse(Uri.encodeFull(targetUrl)));
        final response = await request.close();

        if (response.statusCode != 200) {
          final err = 'HTTP ${response.statusCode} when fetching $targetUrl';
          LoggerService().warning(err);
          lastException = HttpException(err);
          continue;
        }

        final jsonString = await response.transform(utf8.decoder).join();
        if (jsonString.trim().length < 5) {
          lastException = const FormatException('Manifest content is too short or invalid.');
          continue;
        }

        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        final manifest = SceneRepositoryManifest.fromJson(jsonMap);
        LoggerService().info('Successfully fetched manifest "${manifest.name}" with ${manifest.scenes.length} scenes from $targetUrl');
        return ManifestFetchResult(manifest: manifest, resolvedUrl: targetUrl);
      } catch (e, stack) {
        LoggerService().warning('Could not fetch manifest from $targetUrl: $e', details: stack.toString());
        lastException = e;
      }
    }

    throw lastException ?? FormatException('Failed to fetch manifest from $rawUrl');
  }

  Future<SceneRepositoryManifest> fetchManifest(String rawUrl) async {
    final result = await fetchManifestWithResolvedUrl(rawUrl);
    return result.manifest;
  }

  Future<File> downloadScenePackage(
    String packageUrl,
    String destinationPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    LoggerService().info('Downloading scene package from: $packageUrl');

    try {
      final request = await _client.getUrl(Uri.parse(Uri.encodeFull(packageUrl)));
      final response = await request.close();

      if (response.statusCode != 200) {
        final err = 'HTTP ${response.statusCode} when downloading package from $packageUrl';
        LoggerService().error(err);
        throw HttpException(err);
      }

      final totalBytes = response.contentLength;
      final file = File(destinationPath);
      final sink = file.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (onProgress != null) {
          onProgress(receivedBytes, totalBytes);
        }
      }

      await sink.close();

      if (receivedBytes < 100) {
        if (file.existsSync()) {
          await file.delete();
        }
        final err = 'Downloaded file is too small ($receivedBytes bytes). URL "$packageUrl" may be invalid or returning 404.';
        LoggerService().error(err);
        throw FormatException(err);
      }

      LoggerService().info('Successfully downloaded scene package to: $destinationPath ($receivedBytes bytes)');
      return file;
    } catch (e, stack) {
      LoggerService().error('Failed to download scene package from $packageUrl: $e', details: stack.toString());
      rethrow;
    }
  }
}
