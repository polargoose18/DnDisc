import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/models/audio_track.dart';
import 'package:ttrpg_audio_player/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/models/sfx_trigger.dart';
import 'package:ttrpg_audio_player/models/library_track.dart';

void main() {
  group('AudioTrack Model Tests', () {
    test('Что проверяем: Конструктор по умолчанию и значения свойств. '
        'Входные данные: id="track-1", title="Battle Theme", filePath="/audio/battle.mp3". '
        'Ожидаемый результат: Все свойства совпадают со значениями по умолчанию (intensity=calm, duration=zero).', () {
      const track = AudioTrack(
        id: 'track-1',
        title: 'Battle Theme',
        filePath: '/audio/battle.mp3',
      );

      expect(track.id, equals('track-1'));
      expect(track.title, equals('Battle Theme'));
      expect(track.filePath, equals('/audio/battle.mp3'));
      expect(track.intensity, equals(MusicIntensity.calm));
      expect(track.duration, equals(Duration.zero));
      expect(track.loopStartMs, isNull);
      expect(track.loopEndMs, isNull);
      expect(track.coverImagePath, isNull);
    });

    test('Что проверяем: Метод copyWith для точечного обновления полей. '
        'Входные данные: Исходный AudioTrack и изменённые intensity=boss, loopStartMs=1000. '
        'Ожидаемый результат: Создан новый объект с обновлёнными полями, оставшиеся поля неизменны.', () {
      const original = AudioTrack(
        id: 't-1',
        title: 'Original Title',
        filePath: '/path/orig.mp3',
        intensity: MusicIntensity.calm,
      );

      final updated = original.copyWith(
        intensity: MusicIntensity.boss,
        loopStartMs: 1000,
        loopEndMs: 5000,
      );

      expect(updated.id, equals('t-1'));
      expect(updated.title, equals('Original Title'));
      expect(updated.filePath, equals('/path/orig.mp3'));
      expect(updated.intensity, equals(MusicIntensity.boss));
      expect(updated.loopStartMs, equals(1000));
      expect(updated.loopEndMs, equals(5000));
    });
  });

  group('AmbientLayer Model Tests', () {
    test('Что проверяем: Конструктор AmbientLayer и дефолтные значения. '
        'Входные данные: id="amb-1", title="Rain", filePath="/ambient/rain.mp3". '
        'Ожидаемый результат: volume=0.8, isActive=false.', () {
      const layer = AmbientLayer(
        id: 'amb-1',
        title: 'Rain',
        filePath: '/ambient/rain.mp3',
      );

      expect(layer.id, equals('amb-1'));
      expect(layer.title, equals('Rain'));
      expect(layer.filePath, equals('/ambient/rain.mp3'));
      expect(layer.volume, equals(0.8));
      expect(layer.isActive, isFalse);
      expect(layer.iconName, isNull);
    });

    test('Что проверяем: Метод copyWith в AmbientLayer. '
        'Входные данные: layer с volume=0.8, вызов copyWith(isActive: true, volume: 0.5). '
        'Ожидаемый результат: isActive=true, volume=0.5, id и title не изменились.', () {
      const layer = AmbientLayer(
        id: 'amb-1',
        title: 'Campfire',
        filePath: '/fire.mp3',
      );

      final modified = layer.copyWith(isActive: true, volume: 0.5);

      expect(modified.id, equals('amb-1'));
      expect(modified.title, equals('Campfire'));
      expect(modified.isActive, isTrue);
      expect(modified.volume, equals(0.5));
    });
  });

  group('SfxTrigger Model Tests', () {
    test('Что проверяем: Конструктор SfxTrigger и значение цвета по умолчанию. '
        'Входные данные: id="sfx-1", title="Sword Clash", filePath="/sfx/sword.wav". '
        'Ожидаемый результат: volume=1.0, colorHex=0xFF4A90E2, hotkey=null.', () {
      const trigger = SfxTrigger(
        id: 'sfx-1',
        title: 'Sword Clash',
        filePath: '/sfx/sword.wav',
      );

      expect(trigger.id, equals('sfx-1'));
      expect(trigger.title, equals('Sword Clash'));
      expect(trigger.filePath, equals('/sfx/sword.wav'));
      expect(trigger.volume, equals(1.0));
      expect(trigger.colorHex, equals(0xFF4A90E2));
      expect(trigger.hotkey, isNull);
    });

    test('Что проверяем: Метод copyWith для SfxTrigger. '
        'Входные данные: trigger с hotkey="Space", вызов copyWith(hotkey: "KeyA", colorHex: 0xFF0000). '
        'Ожидаемый результат: hotkey="KeyA", colorHex=0xFF0000.', () {
      const trigger = SfxTrigger(
        id: 'sfx-1',
        title: 'Explosion',
        filePath: '/boom.wav',
        hotkey: 'Space',
      );

      final updated = trigger.copyWith(hotkey: 'KeyA', colorHex: 0xFFFF0000);

      expect(updated.id, equals('sfx-1'));
      expect(updated.hotkey, equals('KeyA'));
      expect(updated.colorHex, equals(0xFFFF0000));
    });
  });

  group('LibraryTrack & AudioBusType Extension Tests', () {
    test('Что проверяем: Расширение AudioBusTypeExtension (displayName, codeName, fromCode). '
        'Входные данные: значения music, ambient, sfx, и невалидный код invalid. '
        'Ожидаемый результат: корректные русские названия и fallback на music при невалидном коде.', () {
      expect(AudioBusType.music.displayName, equals('Музыка'));
      expect(AudioBusType.ambient.displayName, equals('Эмбиент'));
      expect(AudioBusType.sfx.displayName, equals('SFX Эффект'));

      expect(AudioBusType.music.codeName, equals('music'));
      expect(AudioBusTypeExtension.fromCode('ambient'), equals(AudioBusType.ambient));
      expect(AudioBusTypeExtension.fromCode('sfx'), equals(AudioBusType.sfx));
      expect(AudioBusTypeExtension.fromCode('unknown_code'), equals(AudioBusType.music));
    });

    test('Что проверяем: Преобразование LibraryTrack в Map (toMap) и обратно (fromMap). '
        'Входные данные: Заполненный объект LibraryTrack с тегами ["Таверна", "Уют"]. '
        'Ожидаемый результат: toMap() возвращает Map с ключами под SQLite, из которого fromMap воссоздаёт эквивалентный объект.', () {
      final now = DateTime.now();
      final track = LibraryTrack(
        id: 'lib-100',
        title: 'Tavern Lute',
        filePath: '/music/lute.mp3',
        busType: AudioBusType.music,
        intensity: MusicIntensity.calm,
        tags: const ['Таверна', 'Уют'],
        colorHex: 0xFF9C27B0,
        iconName: 'music_icon',
        coverImagePath: '/covers/lute.png',
        durationMs: 180000,
        loopStartMs: 5000,
        loopEndMs: 175000,
        createdAt: now,
      );

      final map = track.toMap();

      expect(map['id'], equals('lib-100'));
      expect(map['title'], equals('Tavern Lute'));
      expect(map['file_path'], equals('/music/lute.mp3'));
      expect(map['bus_type'], equals('music'));
      expect(map['intensity'], equals('calm'));
      expect(map['tags'], equals('Таверна,Уют'));
      expect(map['color_hex'], equals(0xFF9C27B0));
      expect(map['duration_ms'], equals(180000));

      final restored = LibraryTrack.fromMap(map);

      expect(restored.id, equals(track.id));
      expect(restored.title, equals(track.title));
      expect(restored.filePath, equals(track.filePath));
      expect(restored.busType, equals(track.busType));
      expect(restored.intensity, equals(track.intensity));
      expect(restored.tags, equals(['Таверна', 'Уют']));
      expect(restored.colorHex, equals(track.colorHex));
      expect(restored.iconName, equals(track.iconName));
      expect(restored.coverImagePath, equals(track.coverImagePath));
      expect(restored.durationMs, equals(track.durationMs));
      expect(restored.loopStartMs, equals(track.loopStartMs));
      expect(restored.loopEndMs, equals(track.loopEndMs));
    });

    test('Что проверяем: Обработка пустых тегов и nullable полей при извлечении fromMap. '
        'Входные данные: Map с минимальным набором полей (tags="", null-значения). '
        'Ожидаемый результат: Дефолтные безопасные значения без исключений.', () {
      final map = <String, dynamic>{
        'id': 'lib-min',
        'title': 'Minimal Track',
        'file_path': '/min.mp3',
        'bus_type': 'ambient',
        'intensity': 'suspense',
        'tags': null,
        'created_at': DateTime.now().toIso8601String(),
      };

      final track = LibraryTrack.fromMap(map);

      expect(track.id, equals('lib-min'));
      expect(track.busType, equals(AudioBusType.ambient));
      expect(track.intensity, equals(MusicIntensity.suspense));
      expect(track.tags, isEmpty);
      expect(track.durationMs, equals(0));
      expect(track.colorHex, equals(0xFF4A90E2));
    });

    test('Что проверяем: Метод copyWith для LibraryTrack. '
        'Входные данные: Исходный LibraryTrack и вызов copyWith с обновлёнными полями (title, busType, intensity, tags). '
        'Ожидаемый результат: Создаётся новый объект LibraryTrack с обновлёнными полями, незатронутые поля сохраняют значения.', () {
      final original = LibraryTrack(
        id: 'lib-copy-1',
        title: 'Original Title',
        filePath: '/orig.mp3',
        busType: AudioBusType.music,
        intensity: MusicIntensity.calm,
        tags: const ['Tag1'],
        colorHex: 0xFF123456,
      );

      final updated = original.copyWith(
        title: 'New Title',
        busType: AudioBusType.ambient,
        intensity: MusicIntensity.boss,
        tags: const ['Tag1', 'Tag2'],
      );

      expect(updated.id, equals('lib-copy-1'));
      expect(updated.title, equals('New Title'));
      expect(updated.filePath, equals('/orig.mp3'));
      expect(updated.busType, equals(AudioBusType.ambient));
      expect(updated.intensity, equals(MusicIntensity.boss));
      expect(updated.tags, equals(['Tag1', 'Tag2']));
      expect(updated.colorHex, equals(0xFF123456));
    });
  });
}
