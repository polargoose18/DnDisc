import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';

void main() {
  group('SceneRepositoryNetworkService Tests', () {
    test('should transform short GitLab repository URL into direct raw repository.json URL', () {
      // Arrange
      const input = 'https://gitlab.com/user/myrepo';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://gitlab.com/user/myrepo/-/raw/main/repository.json');
    });

    test('should transform GitLab URL with www prefix and browser query parameters', () {
      // Arrange
      const input = 'https://www.gitlab.com/user/myrepo?ref_type=heads';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://gitlab.com/user/myrepo/-/raw/main/repository.json');
    });

    test('should transform GitLab URL specifying branch in tree path', () {
      // Arrange
      const input = 'https://gitlab.com/user/myrepo/-/tree/dev?ref_type=heads';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://gitlab.com/user/myrepo/-/raw/dev/repository.json');
    });

    test('should transform GitLab tree URL containing nested folder path', () {
      // Arrange
      const input = 'https://gitlab.com/user/myrepo/-/tree/main/subfolder/audio_pack';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://gitlab.com/user/myrepo/-/raw/main/subfolder/audio_pack/repository.json');
    });

    test('should transform GitLab blob URL pointing to custom manifest file', () {
      // Arrange
      const input = 'https://gitlab.com/user/myrepo/-/blob/master/custom_manifest.json';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://gitlab.com/user/myrepo/-/raw/master/custom_manifest.json');
    });

    test('should strip .git suffix from GitLab repository URL when transforming', () {
      // Arrange
      const input = 'https://gitlab.com/user/myrepo.git';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://gitlab.com/user/myrepo/-/raw/main/repository.json');
    });

    test('should transform GitLab subgroup repository URL properly', () {
      // Arrange
      const input = 'https://gitlab.com/my-group/subgroup/audio-repo';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://gitlab.com/my-group/subgroup/audio-repo/-/raw/main/repository.json');
    });

    test('should replace Dropbox dl=0 query parameter with dl=1 for direct download', () {
      // Arrange
      const input = 'https://www.dropbox.com/s/abcdef123456/repository.json?dl=0';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://www.dropbox.com/s/abcdef123456/repository.json?dl=1');
    });

    test('should append dl=1 query parameter to bare Dropbox URL', () {
      // Arrange
      const input = 'https://dropbox.com/s/abcdef123456/repository.json';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://dropbox.com/s/abcdef123456/repository.json?dl=1');
    });

    test('should replace dl=0 with dl=1 in Dropbox scl format with rlkey parameter', () {
      // Arrange
      const input = 'https://www.dropbox.com/scl/fi/xyz123/manifest.json?rlkey=secretkey&dl=0';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://www.dropbox.com/scl/fi/xyz123/manifest.json?rlkey=secretkey&dl=1');
    });

    test('should append repository.json to standard CDN folder URL', () {
      // Arrange
      const input = 'https://example.com/audio-pack';

      // Act
      final result = SceneRepositoryNetworkService.transformRepositoryUrl(input);

      // Assert
      expect(result, 'https://example.com/audio-pack/repository.json');
    });

    test('should resolve relative download URL against base repository URL', () {
      // Arrange
      const baseUrl = 'https://gitlab.com/user/repo/-/raw/main/repository.json';
      const relativePath = 'scenes/dragon.scene.zip';

      // Act
      final resolved = SceneRepositoryNetworkService.resolveUrl(baseUrl, relativePath);

      // Assert
      expect(resolved, 'https://gitlab.com/user/repo/-/raw/main/scenes/dragon.scene.zip');
    });

    test('should encode whitespace when resolving relative URL path', () {
      // Arrange
      const baseUrl = 'https://gitlab.com/user/repo/-/raw/main/repository.json';
      const relativePath = 'scenes/Dragon Lair.scene.zip';

      // Act
      final resolved = SceneRepositoryNetworkService.resolveUrl(baseUrl, relativePath);

      // Assert
      expect(resolved, 'https://gitlab.com/user/repo/-/raw/main/scenes/Dragon%20Lair.scene.zip');
    });

    test('should convert absolute Dropbox media URL dl=0 parameter to dl=1', () {
      // Arrange
      const baseUrl = 'https://example.com/repo/repository.json';
      const mediaUrl = 'https://www.dropbox.com/scl/fi/track/battle.mp3?rlkey=abc&dl=0';

      // Act
      final resolved = SceneRepositoryNetworkService.resolveUrl(baseUrl, mediaUrl);

      // Assert
      expect(resolved, 'https://www.dropbox.com/scl/fi/track/battle.mp3?rlkey=abc&dl=1');
    });

    test('should parse SceneRepositoryManifest from JSON with various color and camelCase properties', () {
      // Arrange
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

      // Act
      final manifest = SceneRepositoryManifest.fromJson(json);

      // Assert
      expect(manifest.name, 'Test Repo');
      expect(manifest.author, 'Tester');
      expect(manifest.scenes.length, 1);
      expect(manifest.scenes.first.name, 'Scene 1');
      expect(manifest.scenes.first.downloadUrl, 'scenes/1.zip');
      expect(manifest.scenes.first.colorHex, 0xFF123456);
      expect(manifest.scenes.first.tracks.length, 1);
      expect(manifest.scenes.first.tracks.first.title, 'Track 1');
    });
  });
}
