import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';

void main() {
  group('SceneModel Unit Tests', () {
    test('should initialize with default parameters when constructed', () {
      // Arrange & Act
      final scene = SceneModel(id: 'scene-1', name: 'Tavern');

      // Assert
      expect(scene.id, equals('scene-1'));
      expect(scene.name, equals('Tavern'));
      expect(scene.description, isEmpty);
      expect(scene.colorHex, equals(0xFF673AB7));
      expect(scene.musicIntensity, equals(MusicIntensity.calm));
      expect(scene.ambientLayerVolumes, isEmpty);
      expect(scene.soundboardSfxIds, isEmpty);
      expect(scene.createdAt, isNotNull);
    });

    test('should return modified scene while preserving other fields when copyWith is called', () {
      // Arrange
      final scene = SceneModel(
        id: 'sc-1',
        name: 'Tavern',
        ambientLayerVolumes: {'rain': 0.8},
      );

      // Act
      final updated = scene.copyWith(
        name: 'New Tavern',
        colorHex: 0xFF00FF00,
      );

      // Assert
      expect(updated.id, equals('sc-1'));
      expect(updated.name, equals('New Tavern'));
      expect(updated.colorHex, equals(0xFF00FF00));
      expect(updated.ambientLayerVolumes, equals({'rain': 0.8}));
    });

    test('should correctly serialize to Map and restore from Map when handling JSON conversion', () {
      // Arrange
      final scene = SceneModel(
        id: 'sc-full',
        name: 'Gate Battle',
        description: 'Epic clash with orc vanguard',
        colorHex: 0xFFF44336,
        musicTrackId: 'music-battle-1',
        musicIntensity: MusicIntensity.battle,
        ambientLayerVolumes: {
          'fire-1': 0.75,
          'wind-1': 0.40,
        },
        soundboardSfxIds: ['sfx-sword', 'sfx-roar'],
      );

      // Act
      final map = scene.toMap();
      final restored = SceneModel.fromMap(map);

      // Assert
      expect(restored.id, equals(scene.id));
      expect(restored.name, equals(scene.name));
      expect(restored.description, equals(scene.description));
      expect(restored.colorHex, equals(scene.colorHex));
      expect(restored.musicTrackId, equals('music-battle-1'));
      expect(restored.musicIntensity, equals(MusicIntensity.battle));
      expect(restored.ambientLayerVolumes['fire-1'], equals(0.75));
      expect(restored.ambientLayerVolumes['wind-1'], equals(0.40));
      expect(restored.soundboardSfxIds, equals(['sfx-sword', 'sfx-roar']));
    });
  });
}
