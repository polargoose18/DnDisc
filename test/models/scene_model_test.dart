import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';

void main() {
  group('SceneModel Unit Tests', () {
    test(
      'Что проверяем: Создание объекта SceneModel со значениями по умолчанию. '
      'Входные данные: id="scene-1", name="Таверна". '
      'Ожидаемый результат: colorHex=0xFF673AB7, musicIntensity=calm, ambientLayerVolumes={}, soundboardSfxIds=[].',
      () {
        final scene = SceneModel(id: 'scene-1', name: 'Таверна');

        expect(scene.id, equals('scene-1'));
        expect(scene.name, equals('Таверна'));
        expect(scene.description, isEmpty);
        expect(scene.colorHex, equals(0xFF673AB7));
        expect(scene.musicIntensity, equals(MusicIntensity.calm));
        expect(scene.ambientLayerVolumes, isEmpty);
        expect(scene.soundboardSfxIds, isEmpty);
        expect(scene.createdAt, isNotNull);
      },
    );

    test(
      'Что проверяем: Клонирование с изменениями через copyWith. '
      'Входные данные: Исходная сцена и вызов copyWith(name: "Новая Таверна", colorHex: 0xFF00FF00). '
      'Ожидаемый результат: Измененные поля обновлены, неизмененные сохранены.',
      () {
        final scene = SceneModel(
          id: 'sc-1',
          name: 'Таверна',
          ambientLayerVolumes: {'rain': 0.8},
        );

        final updated = scene.copyWith(
          name: 'Новая Таверна',
          colorHex: 0xFF00FF00,
        );

        expect(updated.id, equals('sc-1'));
        expect(updated.name, equals('Новая Таверна'));
        expect(updated.colorHex, equals(0xFF00FF00));
        expect(updated.ambientLayerVolumes, equals({'rain': 0.8}));
      },
    );

    test(
      'Что проверяем: Сериализация и десериализация в Map / JSON. '
      'Входные данные: Объект SceneModel с привязанной музыкой, эмбиентом и SFX. '
      'Ожидаемый результат: toMap() корректно упаковывает JSON строки, fromMap() восстанавливает полную структуру данных.',
      () {
        final scene = SceneModel(
          id: 'sc-full',
          name: 'Битва у Врат',
          description: 'Эпическое столкновение с армией орков',
          colorHex: 0xFFF44336,
          musicTrackId: 'music-battle-1',
          musicIntensity: MusicIntensity.battle,
          ambientLayerVolumes: {
            'fire-1': 0.75,
            'wind-1': 0.40,
          },
          soundboardSfxIds: ['sfx-sword', 'sfx-roar'],
        );

        final map = scene.toMap();
        final restored = SceneModel.fromMap(map);

        expect(restored.id, equals(scene.id));
        expect(restored.name, equals(scene.name));
        expect(restored.description, equals(scene.description));
        expect(restored.colorHex, equals(scene.colorHex));
        expect(restored.musicTrackId, equals('music-battle-1'));
        expect(restored.musicIntensity, equals(MusicIntensity.battle));
        expect(restored.ambientLayerVolumes['fire-1'], equals(0.75));
        expect(restored.ambientLayerVolumes['wind-1'], equals(0.40));
        expect(restored.soundboardSfxIds, equals(['sfx-sword', 'sfx-roar']));
      },
    );
  });
}
