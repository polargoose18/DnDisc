import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/models/custom_theme_model.dart';
import 'package:ttrpg_audio_player/services/theme_service.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/db/database_service.dart';

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
    test(
      'Что проверяем: Инициализация ThemeService с темой по умолчанию. '
      'Входные данные: Новый экземпляр ThemeService(). '
      'Ожидаемый результат: activeThemeId == AppThemes.deepDarkId, activeTheme.name == "Deep Dark", builtInPresets.length == 5.',
      () {
        final themeService = ThemeService(dbService: dbService);
        expect(themeService.activeThemeId, equals(AppThemes.deepDarkId));
        expect(themeService.activeTheme.name, equals('Deep Dark'));
        expect(themeService.builtInPresets.length, equals(5));
      },
    );

    test(
      'Что проверяем: Переключение на другой встроенный пресет (selectTheme). '
      'Входные данные: themeService.selectTheme(AppThemes.emeraldForestId). '
      'Ожидаемый результат: activeThemeId становится AppThemes.emeraldForestId, activeTheme.name == "Emerald Forest".',
      () {
        final themeService = ThemeService(dbService: dbService);
        themeService.selectTheme(AppThemes.emeraldForestId);
        expect(themeService.activeThemeId, equals(AppThemes.emeraldForestId));
        expect(themeService.activeTheme.name, equals('Emerald Forest'));
        expect(themeService.activeTheme.isBuiltIn, isTrue);
      },
    );

    test(
      'Что проверяем: Создание, сохранение и выбор пользовательской темы. '
      'Входные данные: saveCustomTheme() с новой CustomThemeModel("Драконье логово"). '
      'Ожидаемый результат: customThemes содержит 1 тему, activeThemeId переключается на id новой темы, activeTheme возвращает созданную модель.',
      () async {
        final themeService = ThemeService(dbService: dbService);
        const custom = CustomThemeModel(
          id: 'custom_dragon_lair',
          name: 'Драконье логово',
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

        await themeService.saveCustomTheme(custom);

        expect(themeService.customThemes.any((t) => t.id == 'custom_dragon_lair'), isTrue);
        expect(themeService.activeThemeId, equals('custom_dragon_lair'));
        expect(themeService.activeTheme.name, equals('Драконье логово'));
      },
    );

    test(
      'Что проверяем: Дублирование темы через duplicateCustomTheme. '
      'Входные данные: duplicateCustomTheme(AppThemes.crimsonDungeonId, newName: "Blood Crypt"). '
      'Ожидаемый результат: Создается новая кастомная тема с name="Blood Crypt" и теми же цветами.',
      () async {
        final themeService = ThemeService(dbService: dbService);
        final duplicate = await themeService.duplicateCustomTheme(
          AppThemes.crimsonDungeonId,
          newName: 'Blood Crypt',
        );

        expect(duplicate, isNotNull);
        expect(duplicate!.name, equals('Blood Crypt'));
        expect(duplicate.primaryColor, equals(AppThemes.crimsonDungeon.primaryColor));
        expect(duplicate.isBuiltIn, isFalse);
        expect(themeService.customThemes.any((t) => t.id == duplicate.id), isTrue);
      },
    );

    test(
      'Что проверяем: Удаление пользовательской темы (deleteCustomTheme). '
      'Входные данные: deleteCustomTheme(id). '
      'Ожидаемый результат: Тема удаляется из customThemes, activeThemeId сбрасывается на AppThemes.deepDarkId.',
      () async {
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

        await themeService.deleteCustomTheme('custom_to_delete');
        expect(themeService.customThemes.any((t) => t.id == 'custom_to_delete'), isFalse);
        expect(themeService.activeThemeId, equals(AppThemes.deepDarkId));
      },
    );
  });
}
