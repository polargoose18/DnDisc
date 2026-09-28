import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/scene_model.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../domain/models/scene_repository_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web.');
    }

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'ttrpg_audio_player.db');

    return await openDatabase(
      dbPath,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode = WAL;');
        await db.execute('PRAGMA synchronous = NORMAL;');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _createIndexes(db);
      },
      onOpen: (db) async {
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createScenesTable(db);
        }
        if (oldVersion < 3) {
          await _createCustomThemesTable(db);
          try {
            await db.execute('ALTER TABLE scenes ADD COLUMN image_path TEXT;');
          } catch (_) {}
        }
        if (oldVersion < 4) {
          await _createSceneRepositoriesTable(db);
        }
        if (oldVersion < 5) {
          await _createAppSettingsTable(db);
        }
        await _createIndexes(db);
      },
    );
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_library_tracks_bus_type ON library_tracks(bus_type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_library_tracks_title ON library_tracks(title);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_created_at ON scenes(created_at);');
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE library_tracks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        bus_type TEXT NOT NULL,
        intensity TEXT NOT NULL,
        tags TEXT,
        color_hex INTEGER,
        icon_name TEXT,
        cover_image_path TEXT,
        duration_ms INTEGER,
        loop_start_ms INTEGER,
        loop_end_ms INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await _createScenesTable(db);
    await _createCustomThemesTable(db);
    await _createSceneRepositoriesTable(db);
    await _createAppSettingsTable(db);
  }

  static Future<void> _createScenesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scenes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        color_hex INTEGER,
        icon_name TEXT,
        music_track_id TEXT,
        music_intensity TEXT,
        ambient_layer_volumes TEXT,
        soundboard_sfx_ids TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createCustomThemesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_themes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_dark INTEGER NOT NULL,
        primary_color INTEGER NOT NULL,
        secondary_color INTEGER NOT NULL,
        background_color INTEGER NOT NULL,
        surface_color INTEGER NOT NULL,
        card_color INTEGER NOT NULL,
        accent_color INTEGER NOT NULL,
        text_primary_color INTEGER NOT NULL,
        text_secondary_color INTEGER NOT NULL,
        ducking_badge_color INTEGER NOT NULL,
        battle_intensity_color INTEGER NOT NULL,
        boss_intensity_color INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createSceneRepositoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scene_repositories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        last_synced_at TEXT
      )
    ''');
  }

  // Track operations
  Future<void> insertTrack(LibraryTrack track) async {
    final db = await database;
    await db.insert(
      'library_tracks',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertTracksBatch(List<LibraryTrack> tracks) async {
    if (tracks.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final track in tracks) {
      batch.insert(
        'library_tracks',
        track.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateTrack(LibraryTrack track) async {
    final db = await database;
    await db.update(
      'library_tracks',
      track.toMap(),
      where: 'id = ?',
      whereArgs: [track.id],
    );
  }

  Future<void> deleteTrack(String id) async {
    final db = await database;
    await db.delete(
      'library_tracks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<LibraryTrack>> getAllTracks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'library_tracks',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => LibraryTrack.fromMap(m)).toList();
  }

  Future<LibraryTrack?> getTrackById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'library_tracks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LibraryTrack.fromMap(maps.first);
  }

  Future<List<LibraryTrack>> getTracksByBus(AudioBusType busType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'library_tracks',
      where: 'bus_type = ?',
      whereArgs: [busType.name],
      orderBy: 'title ASC',
    );
    return maps.map((m) => LibraryTrack.fromMap(m)).toList();
  }

  Future<List<LibraryTrack>> searchTracks(String query, {AudioBusType? filterBus}) async {
    final db = await database;
    String whereClause = 'title LIKE ? OR tags LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];

    if (filterBus != null) {
      whereClause = '($whereClause) AND bus_type = ?';
      whereArgs.add(filterBus.name);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'library_tracks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'title ASC',
    );
    return maps.map((m) => LibraryTrack.fromMap(m)).toList();
  }

  // Scene operations
  Future<void> insertScene(SceneModel scene) async {
    final db = await database;
    await db.insert(
      'scenes',
      scene.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateScene(SceneModel scene) async {
    final db = await database;
    await db.update(
      'scenes',
      scene.toMap(),
      where: 'id = ?',
      whereArgs: [scene.id],
    );
  }

  Future<void> deleteScene(String id) async {
    final db = await database;
    await db.delete(
      'scenes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SceneModel>> getAllScenes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scenes',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SceneModel.fromMap(m)).toList();
  }

  Future<SceneModel?> getSceneById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scenes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SceneModel.fromMap(maps.first);
  }

  // Custom Theme operations
  Future<void> insertCustomTheme(CustomThemeModel theme) async {
    final db = await database;
    await db.insert(
      'custom_themes',
      theme.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCustomTheme(CustomThemeModel theme) async {
    final db = await database;
    await db.update(
      'custom_themes',
      theme.toMap(),
      where: 'id = ?',
      whereArgs: [theme.id],
    );
  }

  Future<void> deleteCustomTheme(String id) async {
    final db = await database;
    await db.delete(
      'custom_themes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CustomThemeModel>> getAllCustomThemes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_themes',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => CustomThemeModel.fromMap(m)).toList();
  }

  Future<CustomThemeModel?> getCustomThemeById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_themes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CustomThemeModel.fromMap(maps.first);
  }

  // Scene Repository operations
  Future<void> insertSceneRepository(SceneRepositoryModel repo) async {
    final db = await database;
    await db.insert(
      'scene_repositories',
      repo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSceneRepository(SceneRepositoryModel repo) async {
    final db = await database;
    await db.update(
      'scene_repositories',
      repo.toMap(),
      where: 'id = ?',
      whereArgs: [repo.id],
    );
  }

  Future<void> deleteSceneRepository(String id) async {
    final db = await database;
    await db.delete(
      'scene_repositories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SceneRepositoryModel>> getAllSceneRepositories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scene_repositories',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SceneRepositoryModel.fromMap(m)).toList();
  }

  Future<SceneRepositoryModel?> getSceneRepositoryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scene_repositories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SceneRepositoryModel.fromMap(maps.first);
  }

  static Future<void> _createAppSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Reads a single persisted setting by [key]. Returns null if not set.
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  /// Persists [value] under [key] (INSERT OR REPLACE).
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
