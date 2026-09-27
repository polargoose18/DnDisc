import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/domain/models/custom_theme_model.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomThemeModel Unit Tests', () {
    test(
      'Что проверяем: Создание CustomThemeModel и корректность геттеров цветов Color. '
      'Входные данные: CustomThemeModel с primaryColor=0xFF7C4DFF и backgroundColor=0xFF121218. '
      'Ожидаемый результат: primary.value == 0xFF7C4DFF, background.value == 0xFF121218, isDark == true.',
      () {
        const theme = CustomThemeModel(
          id: 'test_theme_1',
          name: 'Test Dark Theme',
          isDark: true,
          primaryColor: 0xFF7C4DFF,
          secondaryColor: 0xFF00E5FF,
          backgroundColor: 0xFF121218,
          surfaceColor: 0xFF181824,
          cardColor: 0xFF1E1E2A,
          accentColor: 0xFFBB86FC,
          textPrimaryColor: 0xFFFFFFFF,
          textSecondaryColor: 0xFFB0B0C0,
          duckingBadgeColor: 0xFFFF9800,
          battleIntensityColor: 0xFFEF4444,
          bossIntensityColor: 0xFF9333EA,
        );

        expect(theme.id, equals('test_theme_1'));
        expect(theme.name, equals('Test Dark Theme'));
        expect(theme.isDark, isTrue);
        expect(theme.primary, equals(const Color(0xFF7C4DFF)));
        expect(theme.background, equals(const Color(0xFF121218)));
        expect(theme.duckingBadge, equals(const Color(0xFFFF9800)));
        expect(theme.battleIntensity, equals(const Color(0xFFEF4444)));
        expect(theme.bossIntensity, equals(const Color(0xFF9333EA)));
      },
    );

    test(
      'Что проверяем: Сериализация и десериализация toMap / fromMap. '
      'Входные данные: CustomThemeModel преобразованный в Map и обратно. '
      'Ожидаемый результат: Все поля (id, name, isDark, primaryColor, cardColor, duckingBadgeColor) полностью совпадают.',
      () {
        const theme = CustomThemeModel(
          id: 'custom_123',
          name: 'Emerald Dungeon',
          isDark: false,
          primaryColor: 0xFF10B981,
          secondaryColor: 0xFF34D399,
          backgroundColor: 0xFF091E16,
          surfaceColor: 0xFF0F2D22,
          cardColor: 0xFF143B2D,
          accentColor: 0xFF6EE7B7,
          textPrimaryColor: 0xFFECFDF5,
          textSecondaryColor: 0xFFA7F3D0,
          duckingBadgeColor: 0xFFF59E0B,
          battleIntensityColor: 0xFFE11D48,
          bossIntensityColor: 0xFF9F1239,
        );

        final map = theme.toMap();
        final restored = CustomThemeModel.fromMap(map);

        expect(restored.id, equals(theme.id));
        expect(restored.name, equals(theme.name));
        expect(restored.isDark, equals(theme.isDark));
        expect(restored.primaryColor, equals(theme.primaryColor));
        expect(restored.secondaryColor, equals(theme.secondaryColor));
        expect(restored.backgroundColor, equals(theme.backgroundColor));
        expect(restored.surfaceColor, equals(theme.surfaceColor));
        expect(restored.cardColor, equals(theme.cardColor));
        expect(restored.accentColor, equals(theme.accentColor));
        expect(restored.textPrimaryColor, equals(theme.textPrimaryColor));
        expect(restored.textSecondaryColor, equals(theme.textSecondaryColor));
        expect(restored.duckingBadgeColor, equals(theme.duckingBadgeColor));
        expect(restored.battleIntensityColor, equals(theme.battleIntensityColor));
        expect(restored.bossIntensityColor, equals(theme.bossIntensityColor));
      },
    );

    test(
      'Что проверяем: Конвертация CustomThemeModel в ThemeData Flutter. '
      'Входные данные: toThemeData() для AppThemes.deepDark и AppThemes.cleanLight. '
      'Ожидаемый результат: Полученные ThemeData имеют соответствующую яркость (Brightness.dark / Brightness.light) и правильный colorScheme.primary.',
      () {
        final darkThemeData = AppThemes.deepDark.toThemeData();
        expect(darkThemeData.brightness, equals(Brightness.dark));
        expect(darkThemeData.colorScheme.primary, equals(AppThemes.deepDark.primary));
        expect(darkThemeData.scaffoldBackgroundColor, equals(AppThemes.deepDark.background));

        final lightThemeData = AppThemes.cleanLight.toThemeData();
        expect(lightThemeData.brightness, equals(Brightness.light));
        expect(lightThemeData.colorScheme.primary, equals(AppThemes.cleanLight.primary));
        expect(lightThemeData.scaffoldBackgroundColor, equals(AppThemes.cleanLight.background));
      },
    );

    test(
      'Что проверяем: Наличие 5 встроенных пресетов в AppThemes. '
      'Входные данные: AppThemes.presets. '
      'Ожидаемый результат: Содержит 5 тем (Deep Dark, Clean Light, Ancient Parchment, Emerald Forest, Crimson Dungeon), все с isBuiltIn == true.',
      () {
        expect(AppThemes.presets.length, equals(5));
        final ids = AppThemes.presets.map((p) => p.id).toList();
        expect(ids, contains(AppThemes.deepDarkId));
        expect(ids, contains(AppThemes.cleanLightId));
        expect(ids, contains(AppThemes.ancientParchmentId));
        expect(ids, contains(AppThemes.emeraldForestId));
        expect(ids, contains(AppThemes.crimsonDungeonId));

        for (final p in AppThemes.presets) {
          expect(p.isBuiltIn, isTrue);
          expect(p.name.isNotEmpty, isTrue);
        }
      },
    );
  });
}
