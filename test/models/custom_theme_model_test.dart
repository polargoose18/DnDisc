import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/domain/models/custom_theme_model.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomThemeModel Unit Tests', () {
    test('should return correct Color objects from hexadecimal color properties', () {
      // Arrange & Act
      final theme = CustomThemeModel.derive(
        id: 'test_theme_1',
        name: 'Test Dark Theme',
        background: 0xFF121218,
        surface: 0xFF181824,
        text: 0xFFFFFFFF,
        primary: 0xFF7C4DFF,
        calm: 0xFF00E5FF,
        suspense: 0xFFBB86FC,
        battle: 0xFFEF4444,
        boss: 0xFF9333EA,
      );

      // Assert
      expect(theme.id, equals('test_theme_1'));
      expect(theme.name, equals('Test Dark Theme'));
      expect(theme.isDark, isTrue);
      expect(theme.primary, equals(const Color(0xFF7C4DFF)));
      expect(theme.background, equals(const Color(0xFF121218)));
      expect(theme.calmIntensity, equals(const Color(0xFF00E5FF)));
      expect(theme.suspenseIntensity, equals(const Color(0xFFBB86FC)));
      expect(theme.battleIntensity, equals(const Color(0xFFEF4444)));
      expect(theme.bossIntensity, equals(const Color(0xFF9333EA)));
    });

    test('should correctly serialize to Map and restore identical theme from Map', () {
      // Arrange
      final theme = CustomThemeModel.derive(
        id: 'custom_123',
        name: 'Emerald Dungeon',
        background: 0xFF091E16,
        surface: 0xFF0F2D22,
        text: 0xFFECFDF5,
        primary: 0xFF10B981,
        calm: 0xFF34D399,
        suspense: 0xFF6EE7B7,
        battle: 0xFFE11D48,
        boss: 0xFF9F1239,
      );

      // Act
      final map = theme.toMap();
      final restored = CustomThemeModel.fromMap(map);

      // Assert
      expect(restored.id, equals(theme.id));
      expect(restored.name, equals(theme.name));
      expect(restored.isDark, equals(theme.isDark));
      expect(restored.primaryColor, equals(theme.primaryColor));
      expect(restored.backgroundColor, equals(theme.backgroundColor));
      expect(restored.surfaceColor, equals(theme.surfaceColor));
      expect(restored.surfaceRaisedColor, equals(theme.surfaceRaisedColor));
      expect(restored.surfaceHoverColor, equals(theme.surfaceHoverColor));
      expect(restored.borderColor, equals(theme.borderColor));
      expect(restored.borderStrongColor, equals(theme.borderStrongColor));
      expect(restored.onPrimaryColor, equals(theme.onPrimaryColor));
      expect(restored.primarySubtleColor, equals(theme.primarySubtleColor));
      expect(restored.focusRingColor, equals(theme.focusRingColor));
      expect(restored.dangerColor, equals(theme.dangerColor));
      expect(restored.calmIntensityColor, equals(theme.calmIntensityColor));
      expect(restored.suspenseIntensityColor, equals(theme.suspenseIntensityColor));
      expect(restored.textPrimaryColor, equals(theme.textPrimaryColor));
      expect(restored.textSecondaryColor, equals(theme.textSecondaryColor));
      expect(restored.battleIntensityColor, equals(theme.battleIntensityColor));
      expect(restored.bossIntensityColor, equals(theme.bossIntensityColor));
    });

    test('should convert CustomThemeModel to ThemeData with matching Brightness and primary color', () {
      // Arrange & Act
      final darkThemeData = AppThemes.deepDark.toThemeData();
      final lightThemeData = AppThemes.cleanLight.toThemeData();

      // Assert
      expect(darkThemeData.brightness, equals(Brightness.dark));
      expect(darkThemeData.colorScheme.primary, equals(AppThemes.deepDark.primary));
      expect(darkThemeData.scaffoldBackgroundColor, equals(AppThemes.deepDark.background));

      expect(lightThemeData.brightness, equals(Brightness.light));
      expect(lightThemeData.colorScheme.primary, equals(AppThemes.cleanLight.primary));
      expect(lightThemeData.scaffoldBackgroundColor, equals(AppThemes.cleanLight.background));
    });

    test('should provide 3 built-in theme presets in AppThemes', () {
      // Arrange & Act
      const presets = AppThemes.presets;

      // Assert
      expect(presets.length, equals(3));
      final ids = presets.map((p) => p.id).toList();
      expect(ids, contains(AppThemes.deepDarkId));
      expect(ids, contains(AppThemes.cleanLightId));
      expect(ids, contains(AppThemes.ancientParchmentId));
      for (final removed in AppThemes.removedPresetIds) {
        expect(ids, isNot(contains(removed)));
        expect(AppThemes.getPresetById(removed).id, equals(AppThemes.deepDarkId));
      }

      for (final p in presets) {
        expect(p.isBuiltIn, isTrue);
        expect(p.name.isNotEmpty, isTrue);
      }
    });
  });
}
