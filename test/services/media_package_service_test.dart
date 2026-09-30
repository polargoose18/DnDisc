import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/data/services/media_package_service.dart';

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
  late MediaPackageService mediaPackageService;
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('media_pkg_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();

    mediaRepo = SqliteMediaLibraryRepository(db: dbService);
    mediaPackageService = MediaPackageService(
      db: dbService,
      mediaLibraryRepository: mediaRepo,
    );
  });

  tearDown(() async {
    await dbService.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MediaPackageService Unit & Integration Tests', () {
    test('should export media package to .media.zip and correctly import tracks into database', () async {
      // Arrange
      final audioFile1 = File(p.join(tempDir.path, 'track1.mp3'));
      await audioFile1.writeAsString('fake audio content 1');
      final audioFile2 = File(p.join(tempDir.path, 'track2.wav'));
      await audioFile2.writeAsString('fake audio content 2');

      final track1 = LibraryTrack(
        id: 'mtrack_1',
        title: 'Tavern Lute',
        filePath: audioFile1.path,
        busType: AudioBusType.music,
        colorHex: 0xFF9C27B0,
      );
      final track2 = LibraryTrack(
        id: 'mtrack_2',
        title: 'Sword Clashing',
        filePath: audioFile2.path,
        busType: AudioBusType.sfx,
        colorHex: 0xFFFF9800,
      );

      final exportZipPath = p.join(tempDir.path, 'monsters.media.zip');

      // Act - Export
      final exportedZip = await mediaPackageService.exportMediaPackage(
        tracks: [track1, track2],
        exportZipPath: exportZipPath,
        title: 'SFX Monsters Set',
        description: 'Custom media set for D&D',
      );

      expect(exportedZip.existsSync(), isTrue);
      expect(exportedZip.lengthSync(), greaterThan(0));

      // Act - Import into new destination
      final importDestDir = p.join(tempDir.path, 'imported_media');
      final result = await mediaPackageService.importMediaPackage(
        zipFilePath: exportZipPath,
        destinationAudioDir: importDestDir,
      );

      // Assert
      expect(result.title, 'SFX Monsters Set');
      expect(result.importedTracks.length, 2);

      final dbTracks = await mediaRepo.getAllTracks();
      expect(dbTracks.length, 2);
      expect(dbTracks.any((t) => t.title == 'Tavern Lute'), isTrue);
      expect(dbTracks.any((t) => t.title == 'Sword Clashing'), isTrue);
    });
  });
}
