import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';

void main() {
  group('SceneRepositoryNetworkService Tests', () {
    test(
      'Что проверяем: Трансформация GitHub URL в прямой raw URL на repository.json. '
      'Входные данные: "https://github.com/user/myrepo". '
      'Ожидаемый результат: "https://raw.githubusercontent.com/user/myrepo/main/repository.json".',
      () {
        const input = 'https://github.com/user/myrepo';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://raw.githubusercontent.com/user/myrepo/main/repository.json');
      },
    );

    test(
      'Что проверяем: Трансформация GitHub URL с указанной веткой. '
      'Входные данные: "https://github.com/user/myrepo/tree/dev". '
      'Ожидаемый результат: "https://raw.githubusercontent.com/user/myrepo/dev/repository.json".',
      () {
        const input = 'https://github.com/user/myrepo/tree/dev';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://raw.githubusercontent.com/user/myrepo/dev/repository.json');
      },
    );

    test(
      'Что проверяем: Трансформация стандартного CDN URL без завершающего .json. '
      'Входные данные: "https://example.com/audio-pack". '
      'Ожидаемый результат: "https://example.com/audio-pack/repository.json".',
      () {
        const input = 'https://example.com/audio-pack';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://example.com/audio-pack/repository.json');
      },
    );

    test(
      'Что проверяем: Трансформация GitHub blob URL на конкретный файл манифеста. '
      'Входные данные: "https://github.com/user/myrepo/blob/master/custom_manifest.json". '
      'Ожидаемый результат: "https://raw.githubusercontent.com/user/myrepo/master/custom_manifest.json".',
      () {
        const input = 'https://github.com/user/myrepo/blob/master/custom_manifest.json';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://raw.githubusercontent.com/user/myrepo/master/custom_manifest.json');
      },
    );

    test(
      'Что проверяем: Отсечение суффикса .git у репозитория GitHub. '
      'Входные данные: "https://github.com/user/myrepo.git". '
      'Ожидаемый результат: "https://raw.githubusercontent.com/user/myrepo/main/repository.json".',
      () {
        const input = 'https://github.com/user/myrepo.git';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://raw.githubusercontent.com/user/myrepo/main/repository.json');
      },
    );

    test(
      'Что проверяем: Разрешение относительного download_url. '
      'Входные данные: baseUrl="https://raw.githubusercontent.com/user/repo/main/repository.json", path="scenes/dragon.scene.zip". '
      'Ожидаемый результат: "https://raw.githubusercontent.com/user/repo/main/scenes/dragon.scene.zip".',
      () {
        const baseUrl = 'https://raw.githubusercontent.com/user/repo/main/repository.json';
        const relativePath = 'scenes/dragon.scene.zip';
        final resolved = SceneRepositoryNetworkService.resolveUrl(baseUrl, relativePath);
        expect(resolved, 'https://raw.githubusercontent.com/user/repo/main/scenes/dragon.scene.zip');
      },
    );

    test(
      'Что проверяем: Парсинг JSON структуры SceneRepositoryManifest и гибкий парсинг color_hex / downloadUrl. '
      'Входные данные: Map с полем name, description, author, camelCase downloadUrl и строковым hex цветом. '
      'Ожидаемый результат: Объект SceneRepositoryManifest успешно создан с верным альфа-каналом цвета и downloadUrl.',
      () {
        final json = {
          'name': 'Test Repo',
          'description': 'Test Desc',
          'version': '1.0',
          'author': 'Tester',
          'scenes': [
            {
              'id': 'scene_1',
              'name': 'Scene 1',
              'description': 'Desc 1',
              'downloadUrl': 'scenes/1.zip',
              'color_hex': '#123456',
              'tracks': [
                {'title': 'Track 1', 'bus_type': 'music', 'duration_ms': 120000}
              ]
            }
          ]
        };

        final manifest = SceneRepositoryManifest.fromJson(json);
        expect(manifest.name, 'Test Repo');
        expect(manifest.author, 'Tester');
        expect(manifest.scenes.length, 1);
        expect(manifest.scenes.first.name, 'Scene 1');
        expect(manifest.scenes.first.downloadUrl, 'scenes/1.zip');
        expect(manifest.scenes.first.colorHex, 0xFF123456);
        expect(manifest.scenes.first.tracks.length, 1);
        expect(manifest.scenes.first.tracks.first.title, 'Track 1');
      },
    );
  });
}
