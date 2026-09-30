import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/data/services/scene_package_service.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempPath;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;
  late SqliteMediaLibraryRepository mediaRepo;
  late SqliteSceneRepository sceneRepo;
  late ScenePackageService packageService;
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pack_pkg_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();

    mediaRepo = SqliteMediaLibraryRepository(db: dbService);
    sceneRepo = SqliteSceneRepository(db: dbService);
    packageService = ScenePackageService(
      db: dbService,
      mediaLibraryRepository: mediaRepo,
      sceneRepository: sceneRepo,
    );
  });

  tearDown(() async {
    await dbService.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ScenePackageService Pack Export & Import Tests', () {
    test('should export multi-scene pack into .pack.zip and import scenes with tracks into database', () async {
      // Arrange
      final audioFile = File(p.join(tempDir.path, 'shared_track.mp3'));
      await audioFile.writeAsString('audio content for pack');

      final track = LibraryTrack(
        id: 'ptrack_1',
        title: 'Curse Theme',
        filePath: audioFile.path,
        busType: AudioBusType.music,
      );
      await mediaRepo.insertTrack(track);

      final scene1 = SceneModel(
        id: 'pscene_1',
        name: 'Castle Ravenloft',
        description: 'Gothic vampire castle',
        musicTrackId: 'ptrack_1',
        colorHex: 0xFFD32F2F,
      );
      final scene2 = SceneModel(
        id: 'pscene_2',
        name: 'Village Tavern',
        description: 'Cozy rustic tavern',
        musicTrackId: 'ptrack_1',
        colorHex: 0xFF795548,
      );

      final exportZipPath = p.join(tempDir.path, 'curse_of_strahd.pack.zip');

      // Act - Export
      final exportedZip = await packageService.exportPackPackage(
        scenes: [scene1, scene2],
        exportZipPath: exportZipPath,
        title: 'Curse of Strahd',
        description: 'Complete campaign scene pack',
      );

      expect(exportedZip.existsSync(), isTrue);

      // Act - Import into new destination
      final importDestDir = p.join(tempDir.path, 'imported_pack');
      final result = await packageService.importPackPackage(
        zipFilePath: exportZipPath,
        destinationAudioDir: importDestDir,
      );

      // Assert
      expect(result.title, 'Curse of Strahd');
      expect(result.importedScenes.length, 2);
      expect(result.importedTracks.length, 1);

      final dbScenes = await sceneRepo.getAllScenes();
      expect(dbScenes.length, 2);
      expect(dbScenes.any((s) => s.name == 'Castle Ravenloft'), isTrue);
      expect(dbScenes.any((s) => s.name == 'Village Tavern'), isTrue);
    });
  });
}
