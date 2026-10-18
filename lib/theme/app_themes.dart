import '../domain/models/custom_theme_model.dart';

class AppThemes {
  static const String deepDarkId = 'preset_deep_dark';
  static const String cleanLightId = 'preset_clean_light';
  static const String ancientParchmentId = 'preset_ancient_parchment';

  /// Ids of presets that were removed from the app. A saved active theme with
  /// one of these ids falls back to [deepDark] on startup.
  static const Set<String> removedPresetIds = {
    'preset_emerald_forest',
    'preset_crimson_dungeon',
  };

  static const CustomThemeModel deepDark = CustomThemeModel(
    id: deepDarkId,
    name: 'Deep Dark',
    isDark: true,
    primaryColor: 0xFFD4A373, // Antique warm gold / amber
    secondaryColor: 0xFF9E8E81, // Muted warm hazel / sand
    backgroundColor: 0xFF151210, // Dark warm espresso
    surfaceColor: 0xFF1E1916, // Warm charcoal surface
    cardColor: 0xFF29221D, // Matte warm card
    accentColor: 0xFFE29578, // Warm terracotta
    textPrimaryColor: 0xFFF5EFE6, // Warm parchment ivory
    textSecondaryColor: 0xFFA69688, // Muted clay / warm sand
    duckingBadgeColor: 0xFFE76F51, // Warm ember
    battleIntensityColor: 0xFFC84B31, // Crimson ember
    bossIntensityColor: 0xFF8A1C14, // Deep bloodstone
    isBuiltIn: true,
  );

  static const CustomThemeModel cleanLight = CustomThemeModel(
    id: cleanLightId,
    name: 'Clean Light',
    isDark: false,
    primaryColor: 0xFF2563EB, // Royal Blue
    secondaryColor: 0xFF0D9488, // Teal
    backgroundColor: 0xFFF8FAFC,
    surfaceColor: 0xFFFFFFFF,
    cardColor: 0xFFF1F5F9,
    accentColor: 0xFF3B82F6,
    textPrimaryColor: 0xFF0F172A,
    textSecondaryColor: 0xFF64748B,
    duckingBadgeColor: 0xFFF97316,
    battleIntensityColor: 0xFFDC2626,
    bossIntensityColor: 0xFF7E22CE,
    isBuiltIn: true,
  );

  static const CustomThemeModel ancientParchment = CustomThemeModel(
    id: ancientParchmentId,
    name: 'Ancient Parchment',
    isDark: true,
    primaryColor: 0xFFD4A373, // Warm Ochre / Antique Gold
    secondaryColor: 0xFFCCD5AE, // Sage Parchment
    backgroundColor: 0xFF1C1917, // Warm Dark Umber
    surfaceColor: 0xFF292524,
    cardColor: 0xFF332E2B,
    accentColor: 0xFFE29578,
    textPrimaryColor: 0xFFFAEDCD,
    textSecondaryColor: 0xFFD4A373,
    duckingBadgeColor: 0xFFE76F51,
    battleIntensityColor: 0xFFC84B31,
    bossIntensityColor: 0xFF8A1C14,
    isBuiltIn: true,
  );

  static const List<CustomThemeModel> presets = [
    deepDark,
    cleanLight,
    ancientParchment,
  ];

  static CustomThemeModel getPresetById(String id) {
    return presets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => deepDark,
    );
  }
}
