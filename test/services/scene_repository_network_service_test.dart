import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';

void main() {
  group('SceneRepositoryNetworkService Tests', () {
    test(
      'Что проверяем: Трансформация короткого GitLab URL в прямой raw URL на repository.json. '
      'Входные данные: "https://gitlab.com/user/myrepo". '
      'Ожидаемый результат: "https://gitlab.com/user/myrepo/-/raw/main/repository.json".',
      () {
        const input = 'https://gitlab.com/user/myrepo';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://gitlab.com/user/myrepo/-/raw/main/repository.json');
      },
    );

    test(
      'Что проверяем: Трансформация GitLab URL с префиксом www и query-параметрами браузера. '
      'Входные данные: "https://www.gitlab.com/user/myrepo?ref_type=heads". '
      'Ожидаемый результат: "https://gitlab.com/user/myrepo/-/raw/main/repository.json".',
      () {
        const input = 'https://www.gitlab.com/user/myrepo?ref_type=heads';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://gitlab.com/user/myrepo/-/raw/main/repository.json');
      },
    );

    test(
      'Что проверяем: Трансформация GitLab URL с указанной веткой (tree) и параметром ref_type. '
      'Входные данные: "https://gitlab.com/user/myrepo/-/tree/dev?ref_type=heads". '
      'Ожидаемый результат: "https://gitlab.com/user/myrepo/-/raw/dev/repository.json".',
      () {
        const input = 'https://gitlab.com/user/myrepo/-/tree/dev?ref_type=heads';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://gitlab.com/user/myrepo/-/raw/dev/repository.json');
      },
    );

    test(
      'Что проверяем: Трансформация GitLab tree URL со вложенной папкой. '
      'Входные данные: "https://gitlab.com/user/myrepo/-/tree/main/subfolder/audio_pack". '
      'Ожидаемый результат: "https://gitlab.com/user/myrepo/-/raw/main/subfolder/audio_pack/repository.json".',
      () {
        const input = 'https://gitlab.com/user/myrepo/-/tree/main/subfolder/audio_pack';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://gitlab.com/user/myrepo/-/raw/main/subfolder/audio_pack/repository.json');
      },
    );

    test(
      'Что проверяем: Трансформация GitLab blob URL на конкретный файл манифеста. '
      'Входные данные: "https://gitlab.com/user/myrepo/-/blob/master/custom_manifest.json". '
      'Ожидаемый результат: "https://gitlab.com/user/myrepo/-/raw/master/custom_manifest.json".',
      () {
        const input = 'https://gitlab.com/user/myrepo/-/blob/master/custom_manifest.json';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://gitlab.com/user/myrepo/-/raw/master/custom_manifest.json');
      },
    );

    test(
      'Что проверяем: Отсечение суффикса .git у репозитория GitLab. '
      'Входные данные: "https://gitlab.com/user/myrepo.git". '
      'Ожидаемый результат: "https://gitlab.com/user/myrepo/-/raw/main/repository.json".',
      () {
        const input = 'https://gitlab.com/user/myrepo.git';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://gitlab.com/user/myrepo/-/raw/main/repository.json');
      },
    );

    test(
      'Что проверяем: Трансформация GitLab репозитория во вложенной группе (subgroup). '
      'Входные данные: "https://gitlab.com/my-group/subgroup/audio-repo". '
      'Ожидаемый результат: "https://gitlab.com/my-group/subgroup/audio-repo/-/raw/main/repository.json".',
      () {
        const input = 'https://gitlab.com/my-group/subgroup/audio-repo';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://gitlab.com/my-group/subgroup/audio-repo/-/raw/main/repository.json');
      },
    );

    test(
      'Что проверяем: Автоматическое преобразование Dropbox ссылки с dl=0 в dl=1. '
      'Входные данные: "https://www.dropbox.com/s/abcdef123456/repository.json?dl=0". '
      'Ожидаемый результат: "https://www.dropbox.com/s/abcdef123456/repository.json?dl=1".',
      () {
        const input = 'https://www.dropbox.com/s/abcdef123456/repository.json?dl=0';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://www.dropbox.com/s/abcdef123456/repository.json?dl=1');
      },
    );

    test(
      'Что проверяем: Автоматическое добавление параметра dl=1 для ссылки Dropbox без параметров. '
      'Входные данные: "https://dropbox.com/s/abcdef123456/repository.json". '
      'Ожидаемый результат: "https://dropbox.com/s/abcdef123456/repository.json?dl=1".',
      () {
        const input = 'https://dropbox.com/s/abcdef123456/repository.json';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://dropbox.com/s/abcdef123456/repository.json?dl=1');
      },
    );

    test(
      'Что проверяем: Преобразование ссылки Dropbox scl с параметрами rlkey и dl=0. '
      'Входные данные: "https://www.dropbox.com/scl/fi/xyz123/manifest.json?rlkey=secretkey&dl=0". '
      'Ожидаемый результат: "https://www.dropbox.com/scl/fi/xyz123/manifest.json?rlkey=secretkey&dl=1".',
      () {
        const input = 'https://www.dropbox.com/scl/fi/xyz123/manifest.json?rlkey=secretkey&dl=0';
        final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);
        expect(result, 'https://www.dropbox.com/scl/fi/xyz123/manifest.json?rlkey=secretkey&dl=1');
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
      'Что проверяем: Разрешение относительного download_url на базе GitLab raw URL. '
      'Входные данные: baseUrl="https://gitlab.com/user/repo/-/raw/main/repository.json", path="scenes/dragon.scene.zip". '
      'Ожидаемый результат: "https://gitlab.com/user/repo/-/raw/main/scenes/dragon.scene.zip".',
      () {
        const baseUrl = 'https://gitlab.com/user/repo/-/raw/main/repository.json';
        const relativePath = 'scenes/dragon.scene.zip';
        final resolved = SceneRepositoryNetworkService.resolveUrl(baseUrl, relativePath);
        expect(resolved, 'https://gitlab.com/user/repo/-/raw/main/scenes/dragon.scene.zip');
      },
    );

    test(
      'Что проверяем: Разрешение относительного пути с пробелами на базе GitLab raw URL. '
      'Входные данные: baseUrl="https://gitlab.com/user/repo/-/raw/main/repository.json", path="scenes/Dragon Lair.scene.zip". '
      'Ожидаемый результат: "https://gitlab.com/user/repo/-/raw/main/scenes/Dragon%20Lair.scene.zip".',
      () {
        const baseUrl = 'https://gitlab.com/user/repo/-/raw/main/repository.json';
        const relativePath = 'scenes/Dragon Lair.scene.zip';
        final resolved = SceneRepositoryNetworkService.resolveUrl(baseUrl, relativePath);
        expect(resolved, 'https://gitlab.com/user/repo/-/raw/main/scenes/Dragon%20Lair.scene.zip');
      },
    );

    test(
      'Что проверяем: Разрешение абсолютного медиа URL на Dropbox с заменой dl=0 на dl=1. '
      'Входные данные: baseUrl="https://example.com/repo/repository.json", path="https://www.dropbox.com/scl/fi/track/battle.mp3?rlkey=abc&dl=0". '
      'Ожидаемый результат: "https://www.dropbox.com/scl/fi/track/battle.mp3?rlkey=abc&dl=1".',
      () {
        const baseUrl = 'https://example.com/repo/repository.json';
        const mediaUrl = 'https://www.dropbox.com/scl/fi/track/battle.mp3?rlkey=abc&dl=0';
        final resolved = SceneRepositoryNetworkService.resolveUrl(baseUrl, mediaUrl);
        expect(resolved, 'https://www.dropbox.com/scl/fi/track/battle.mp3?rlkey=abc&dl=1');
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
