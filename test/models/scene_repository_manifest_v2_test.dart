import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';

void main() {
  group('SceneRepositoryManifest Schema v2 Tests', () {
    test(
      'Что проверяем: Парсинг repository.json v2 с секциями scenes, media и packs. '
      'Входные данные: Map с метаданными репозитория и элементами всех 3 категорий. '
      'Ожидаемый результат: Manifest корректно содержит списки scenes, media и packs с правильными полями.',
      () {
        final jsonMap = {
          'name': 'D&D Treasury',
          'description': 'Полный каталог аудио',
          'version': '2.0.0',
          'author': 'GM',
          'scenes': [
            {
              'id': 'scene_dragon',
              'name': 'Логово Дракона',
              'description': 'Битва с драконом',
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
              'name': 'SFX Рыки Монстров',
              'description': 'Набор звуков монстров',
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
              'name': 'Проклятие Страда',
              'description': 'Пак приключений',
              'download_url': 'packs/strahd.pack.zip',
              'cover_url': 'covers/strahd.jpg',
              'color_hex': 0xD32F2F,
              'scenes_count': 3,
              'tracks_count': 12,
              'size_bytes': 20971520,
              'scenes': [
                {'name': 'Замок Равенлофт', 'tracks_count': 4}
              ],
            }
          ],
        };

        final manifest = SceneRepositoryManifest.fromJson(jsonMap);

        expect(manifest.name, 'D&D Treasury');
        expect(manifest.version, '2.0.0');
        expect(manifest.scenes.length, 1);
        expect(manifest.media.length, 1);
        expect(manifest.packs.length, 1);

        // Verify Scene item
        final sceneItem = manifest.scenes.first;
        expect(sceneItem.id, 'scene_dragon');
        expect(sceneItem.name, 'Логово Дракона');
        expect(sceneItem.colorHex, 0xFF673AB7);
        expect(sceneItem.tracks.first.title, 'Dragon Battle');

        // Verify Media item
        final mediaItem = manifest.media.first;
        expect(mediaItem.id, 'media_sfx_monsters');
        expect(mediaItem.name, 'SFX Рыки Монстров');
        expect(mediaItem.colorHex, 0xFFFF9800);
        expect(mediaItem.tracks.first.busType, 'sfx');

        // Verify Pack item
        final packItem = manifest.packs.first;
        expect(packItem.id, 'pack_strahd');
        expect(packItem.name, 'Проклятие Страда');
        expect(packItem.scenesCount, 3);
        expect(packItem.scenes.first.name, 'Замок Равенлофт');
      },
    );

    test(
      'Что проверяем: Сериализация SceneRepositoryManifest v2 в JSON. '
      'Входные данные: Объект Manifest с заполненными объектами scenes, media и packs. '
      'Ожидаемый результат: toJson() возвращает Map с валидными ключами scenes, media, packs.',
      () {
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

        final jsonMap = manifest.toJson();

        expect(jsonMap['name'], 'Test Manifest');
        expect((jsonMap['scenes'] as List).length, 1);
        expect((jsonMap['media'] as List).length, 1);
        expect((jsonMap['packs'] as List).length, 1);
      },
    );
  });
}
