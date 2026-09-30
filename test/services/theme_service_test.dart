import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/domain/models/custom_theme_model.dart';
import 'package:ttrpg_audio_player/data/services/theme_service.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';

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

  late Directory tempDir;
  late DatabaseService dbService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_theme_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
    tempDir.delete(recursive: true).ignore();
  });

  group('ThemeService Unit Tests', () {
    test('should initialize with default Deep Dark built-in theme and 5 preset themes', () {
      // Arrange & Act
      final themeService = ThemeService(dbService: dbService);

      // Assert
      expect(themeService.activeThemeId, equals(AppThemes.deepDarkId));
      expect(themeService.activeTheme.name, equals('Deep Dark'));
      expect(themeService.builtInPresets.length, equals(5));
    });

    test('should switch active theme when selectTheme is called with preset id', () {
      // Arrange
      final themeService = ThemeService(dbService: dbService);

      // Act
      themeService.selectTheme(AppThemes.emeraldForestId);

      // Assert
      expect(themeService.activeThemeId, equals(AppThemes.emeraldForestId));
      expect(themeService.activeTheme.name, equals('Emerald Forest'));
      expect(themeService.activeTheme.isBuiltIn, isTrue);
    });

    test('should persist custom theme in database and make it the active theme', () async {
      // Arrange
      final themeService = ThemeService(dbService: dbService);
      const custom = CustomThemeModel(
        id: 'custom_dragon_lair',
        name: 'Dragon Lair',
        isDark: true,
        primaryColor: 0xFFFF5722,
        secondaryColor: 0xFFFFC107,
        backgroundColor: 0xFF1B0A0A,
        surfaceColor: 0xFF2A1212,
        cardColor: 0xFF3D1A1A,
        accentColor: 0xFFFF7043,
        textPrimaryColor: 0xFFFFF3E0,
        textSecondaryColor: 0xFFFFAB91,
        duckingBadgeColor: 0xFFFF9800,
        battleIntensityColor: 0xFFD32F2F,
        bossIntensityColor: 0xFF7B1FA2,
      );

      // Act
      await themeService.saveCustomTheme(custom);

      // Assert
      expect(themeService.customThemes.any((t) => t.id == 'custom_dragon_lair'), isTrue);
      expect(themeService.activeThemeId, equals('custom_dragon_lair'));
      expect(themeService.activeTheme.name, equals('Dragon Lair'));
    });

    test('should create editable custom duplicate of existing theme preset', () async {
      // Arrange
      final themeService = ThemeService(dbService: dbService);

      // Act
      final duplicate = await themeService.duplicateCustomTheme(
        AppThemes.crimsonDungeonId,
        newName: 'Blood Crypt',
      );

      // Assert
      expect(duplicate, isNotNull);
      expect(duplicate!.name, equals('Blood Crypt'));
      expect(duplicate.primaryColor, equals(AppThemes.crimsonDungeon.primaryColor));
      expect(duplicate.isBuiltIn, isFalse);
      expect(themeService.customThemes.any((t) => t.id == duplicate.id), isTrue);
    });

    test('should remove custom theme and fallback to default Deep Dark theme on deletion', () async {
      // Arrange
      final themeService = ThemeService(dbService: dbService);
      const custom = CustomThemeModel(
        id: 'custom_to_delete',
        name: 'Temporary Theme',
        primaryColor: 0xFF000000,
        secondaryColor: 0xFFFFFFFF,
        backgroundColor: 0xFF000000,
        surfaceColor: 0xFF111111,
        cardColor: 0xFF222222,
        accentColor: 0xFF333333,
        textPrimaryColor: 0xFFFFFFFF,
        textSecondaryColor: 0xFF888888,
      );

      await themeService.saveCustomTheme(custom);
      expect(themeService.activeThemeId, equals('custom_to_delete'));

      // Act
      await themeService.deleteCustomTheme('custom_to_delete');

      // Assert
      expect(themeService.customThemes.any((t) => t.id == 'custom_to_delete'), isFalse);
      expect(themeService.activeThemeId, equals(AppThemes.deepDarkId));
    });
  });
}
