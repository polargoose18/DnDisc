import 'dart:convert';
import 'dart:io';
import 'logger_service.dart';
import '../domain/models/scene_repository_model.dart';

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

  static String transformRepositoryUrl(String rawUrl) {
    var trimmed = rawUrl.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('.git')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
    }

    // GitHub blob link: https://github.com/user/repo/blob/branch/file.json
    final githubBlobRegex = RegExp(r'^https?://github\.com/([^/]+)/([^/]+)/blob/([^/]+)/(.*)$');
    final blobMatch = githubBlobRegex.firstMatch(trimmed);
    if (blobMatch != null) {
      final user = blobMatch.group(1);
      final repo = blobMatch.group(2);
      final branch = blobMatch.group(3);
      final path = blobMatch.group(4);
      return 'https://raw.githubusercontent.com/$user/$repo/$branch/$path';
    }

    // Transform GitHub URL: https://github.com/user/repo or https://github.com/user/repo/tree/branch
    final githubRegex = RegExp(r'^https?://github\.com/([^/]+)/([^/]+)(?:/tree/([^/]+))?/?$');
    final match = githubRegex.firstMatch(trimmed);
    if (match != null) {
      final user = match.group(1);
      final repo = match.group(2);
      final branch = match.group(3) ?? 'main';
      return 'https://raw.githubusercontent.com/$user/$repo/$branch/repository.json';
    }

    if (trimmed.endsWith('.json')) {
      return trimmed;
    }

    return '$trimmed/repository.json';
  }

  static String resolveUrl(String baseUrl, String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    final baseUri = Uri.parse(Uri.encodeFull(baseUrl));
    return baseUri.resolve(pathOrUrl).toString();
  }

  Future<ManifestFetchResult> fetchManifestWithResolvedUrl(String rawUrl) async {
    final primaryUrl = transformRepositoryUrl(rawUrl);
    LoggerService().info('Fetching scene repository manifest from: $primaryUrl');

    List<String> urlsToTry = [primaryUrl];

    // If primary URL auto-defaulted to main branch on GitHub raw, also try master branch as fallback
    if (primaryUrl.contains('raw.githubusercontent.com') && primaryUrl.contains('/main/repository.json')) {
      final masterFallbackUrl = primaryUrl.replaceAll('/main/repository.json', '/master/repository.json');
      if (!urlsToTry.contains(masterFallbackUrl)) {
        urlsToTry.add(masterFallbackUrl);
      }
    }

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
