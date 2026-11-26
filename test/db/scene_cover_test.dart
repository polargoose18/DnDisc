import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_cover_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/theme/covers.dart';

class _FakePathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_cover_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    await DatabaseService().close();
    tempDir.delete(recursive: true).ignore();
  });

  group('SceneCovers', () {
    test('seed choice is stable and always one of the seven default covers', () {
      for (final seed in ['a', 'scene-1', 'Таверна', '']) {
        expect(SceneCovers.keys, contains(SceneCovers.forSeed(seed)));
        expect(SceneCovers.forSeed(seed), equals(SceneCovers.forSeed(seed)));
      }
      expect(SceneCovers.keys, hasLength(7));
    });

    test('pickRandom returns a known key', () {
      final service = SceneCoverService();
      for (var i = 0; i < 30; i++) {
        expect(SceneCovers.contains(service.pickRandom()), isTrue);
      }
    });
  });

  group('Scene cover storage', () {
    test('SceneModel keeps the cover key through toMap and fromMap', () {
      final scene = SceneModel(id: 's1', name: 'Catacombs', cover: 'tower');
      final restored = SceneModel.fromMap(scene.toMap());
      expect(restored.cover, equals('tower'));
      expect(SceneModel.fromMap({'id': 's2', 'name': 'Old'}).cover, isNull);
    });

    test('createScene stores a random cover once and keeps an explicit one', () async {
      final service = SceneService(autoLoad: false);
      await service.createScene(SceneModel(id: 'a', name: 'Auto'));
      await service.createScene(SceneModel(id: 'b', name: 'Chosen', cover: 'sea'));

      final repo = SqliteSceneRepository();
      final auto = await repo.getSceneById('a');
      final chosen = await repo.getSceneById('b');
      expect(SceneCovers.contains(auto!.cover), isTrue);
      expect(chosen!.cover, equals('sea'));

      // A reload must not change the stored choice.
      await service.loadScenes(force: true);
      expect(service.scenes.firstWhere((s) => s.id == 'a').cover, equals(auto.cover));
      service.dispose();
    });

    test('v6 scenes get a cover by hash of the id; scenes with an own image keep none', () async {
      final path = p.join(tempDir.path, 'ttrpg_audio_player.db');
      final legacy = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 6,
          onCreate: (db, _) async {
            await db.execute('CREATE TABLE library_tracks (id TEXT PRIMARY KEY, title TEXT, bus_type TEXT)');
            await db.execute('''
              CREATE TABLE scenes (
                id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, color_hex INTEGER,
                icon_name TEXT, music_track_id TEXT, music_intensity TEXT,
                ambient_layer_volumes TEXT, soundboard_sfx_ids TEXT, image_path TEXT,
                created_at TEXT NOT NULL
              )
            ''');
            final now = DateTime(2025).toIso8601String();
            await db.insert('scenes', {'id': 'plain-scene', 'name': 'Plain', 'created_at': now});
            await db.insert('scenes', {'id': 'own-image', 'name': 'Own', 'image_path': '/img.png', 'created_at': now});
          },
        ),
      );
      await legacy.close();

      final scenes = await DatabaseService().getAllScenes();
      final plain = scenes.firstWhere((s) => s.id == 'plain-scene');
      final own = scenes.firstWhere((s) => s.id == 'own-image');
      expect(plain.cover, equals(SceneCovers.forSeed('plain-scene')));
      expect(own.cover, isNull);
      expect(own.imagePath, equals('/img.png'));
    });
  });
}
