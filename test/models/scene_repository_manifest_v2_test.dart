import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';

void main() {
  group('SceneRepositoryManifest Schema v2 Tests', () {
    test('should correctly parse repository.json v2 with scenes, media, and packs sections', () {
      // Arrange
      final jsonMap = {
        'name': 'D&D Treasury',
        'description': 'Complete audio repository',
        'version': '2.0.0',
        'author': 'GM',
        'scenes': [
          {
            'id': 'scene_dragon',
            'name': 'Dragon Lair',
            'description': 'Battle against ancient dragon',
            'download_url': 'scenes/dragon.scene.zip',
            'cover_url': 'covers/dragon.jpg',
            'color_hex': '0xFF673AB7',
            'tracks_count': 2,
            'size_bytes': 1048576,
            'tracks': [
              {'title': 'Dragon Battle', 'bus_type': 'music', 'duration_ms': 120000}
            ],
          }
        ],
        'media': [
          {
            'id': 'media_sfx_monsters',
            'name': 'Monster Roars SFX',
            'description': 'Monster sound library',
            'download_url': 'media/monsters.media.zip',
            'cover_url': 'covers/monsters.jpg',
            'color_hex': '#FF9800',
            'tracks_count': 5,
            'size_bytes': 524288,
            'tracks': [
              {'title': 'Goblin Screech', 'bus_type': 'sfx', 'duration_ms': 1500}
            ],
          }
        ],
        'packs': [
          {
            'id': 'pack_strahd',
            'name': 'Curse of Strahd',
            'description': 'Adventure sound pack',
            'download_url': 'packs/strahd.pack.zip',
            'cover_url': 'covers/strahd.jpg',
            'color_hex': 0xD32F2F,
            'scenes_count': 3,
            'tracks_count': 12,
            'size_bytes': 20971520,
            'scenes': [
              {'name': 'Castle Ravenloft', 'tracks_count': 4}
            ],
          }
        ],
      };

      // Act
      final manifest = SceneRepositoryManifest.fromJson(jsonMap);

      // Assert
      expect(manifest.name, 'D&D Treasury');
      expect(manifest.version, '2.0.0');
      expect(manifest.scenes.length, 1);
      expect(manifest.media.length, 1);
      expect(manifest.packs.length, 1);

      // Verify Scene item
      final sceneItem = manifest.scenes.first;
      expect(sceneItem.id, 'scene_dragon');
      expect(sceneItem.name, 'Dragon Lair');
      expect(sceneItem.colorHex, 0xFF673AB7);
      expect(sceneItem.tracks.first.title, 'Dragon Battle');

      // Verify Media item
      final mediaItem = manifest.media.first;
      expect(mediaItem.id, 'media_sfx_monsters');
      expect(mediaItem.name, 'Monster Roars SFX');
      expect(mediaItem.colorHex, 0xFFFF9800);
      expect(mediaItem.tracks.first.busType, 'sfx');

      // Verify Pack item
      final packItem = manifest.packs.first;
      expect(packItem.id, 'pack_strahd');
      expect(packItem.name, 'Curse of Strahd');
      expect(packItem.scenesCount, 3);
      expect(packItem.scenes.first.name, 'Castle Ravenloft');
    });

    test('should serialize SceneRepositoryManifest v2 to valid JSON map with all categories', () {
      // Arrange
      const manifest = SceneRepositoryManifest(
        name: 'Test Manifest',
        scenes: [
          RepositorySceneItem(
            id: 's1',
            name: 'Scene 1',
            downloadUrl: 'scenes/s1.zip',
          ),
        ],
        media: [
          RepositoryMediaItem(
            id: 'm1',
            name: 'Media 1',
            downloadUrl: 'media/m1.zip',
          ),
        ],
        packs: [
          RepositoryPackItem(
            id: 'p1',
            name: 'Pack 1',
            downloadUrl: 'packs/p1.zip',
          ),
        ],
      );

      // Act
      final jsonMap = manifest.toJson();

      // Assert
      expect(jsonMap['name'], 'Test Manifest');
      expect((jsonMap['scenes'] as List).length, 1);
      expect((jsonMap['media'] as List).length, 1);
      expect((jsonMap['packs'] as List).length, 1);
    });
  });
}
