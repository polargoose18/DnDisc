import '../domain/models/custom_theme_model.dart';

/// The three built-in presets. Their values are set by hand, not derived;
/// the formula in [CustomThemeModel.derive] is only for user themes.
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
    backgroundColor: 0xFF14110F,
    surfaceColor: 0xFF1C1815,
    surfaceRaisedColor: 0xFF261F1B,
    surfaceHoverColor: 0xFF302823,
    borderColor: 0xFF3A3029,
    borderStrongColor: 0xFF857567,
    textPrimaryColor: 0xFFF3ECE2,
    textSecondaryColor: 0xFFB8A999,
    textDisabledColor: 0xFF6F645A,
    primaryColor: 0xFFD4A373,
    primaryHoverColor: 0xFFE3B88A,
    primarySubtleColor: 0xFF3B2D20,
    onPrimaryColor: 0xFF1A1109,
    focusRingColor: 0xFFF2C48D,
    dangerColor: 0xFFEF7C71,
    dangerSubtleColor: 0xFF3D1D19,
    onDangerColor: 0xFF1C0A08,
    successColor: 0xFF6CC4B0,
    successSubtleColor: 0xFF17332D,
    calmIntensityColor: 0xFF78B7A6,
    suspenseIntensityColor: 0xFFB79AE0,
    battleIntensityColor: 0xFFE8744F,
    bossIntensityColor: 0xFFE0485E,
    isBuiltIn: true,
  );

  static const CustomThemeModel cleanLight = CustomThemeModel(
    id: cleanLightId,
    name: 'Clean Light',
    isDark: false,
    backgroundColor: 0xFFF8FAFC,
    surfaceColor: 0xFFFFFFFF,
    surfaceRaisedColor: 0xFFF1F5F9,
    surfaceHoverColor: 0xFFE6EBF2,
    borderColor: 0xFFD9E0E9,
    borderStrongColor: 0xFF74849A,
    textPrimaryColor: 0xFF0F172A,
    textSecondaryColor: 0xFF4F5D73,
    textDisabledColor: 0xFF94A3B8,
    primaryColor: 0xFF2563EB,
    primaryHoverColor: 0xFF1D4ED8,
    primarySubtleColor: 0xFFECF2FF,
    onPrimaryColor: 0xFFFFFFFF,
    focusRingColor: 0xFF1D4ED8,
    dangerColor: 0xFFB42318,
    dangerSubtleColor: 0xFFFDE4E1,
    onDangerColor: 0xFFFFFFFF,
    successColor: 0xFF0F766E,
    successSubtleColor: 0xFFD5F0EC,
    calmIntensityColor: 0xFF0F766E,
    suspenseIntensityColor: 0xFF6D3FC4,
    battleIntensityColor: 0xFFC2410C,
    bossIntensityColor: 0xFF9F1239,
    isBuiltIn: true,
  );

  /// Dark like Deep Dark, same amber `primary`, warmer and lighter text.
  static const CustomThemeModel ancientParchment = CustomThemeModel(
    id: ancientParchmentId,
    name: 'Ancient Parchment',
    isDark: true,
    backgroundColor: 0xFF17120E,
    surfaceColor: 0xFF211A14,
    surfaceRaisedColor: 0xFF2B231D,
    surfaceHoverColor: 0xFF352D27,
    borderColor: 0xFF3A322C,
    borderStrongColor: 0xFF8E8471,
    textPrimaryColor: 0xFFFAEDCD,
    textSecondaryColor: 0xFFAEA38C,
    textDisabledColor: 0xFF786E5E,
    primaryColor: 0xFFD4A373,
    primaryHoverColor: 0xFFE8B685,
    primarySubtleColor: 0xFF413325,
    onPrimaryColor: 0xFF1A1109,
    focusRingColor: 0xFFF2C48D,
    dangerColor: 0xFFEF7C71,
    dangerSubtleColor: 0xFF3D1D19,
    onDangerColor: 0xFF1C0A08,
    successColor: 0xFF6CC4B0,
    successSubtleColor: 0xFF17332D,
    calmIntensityColor: 0xFF78B7A6,
    suspenseIntensityColor: 0xFFB79AE0,
    battleIntensityColor: 0xFFE8744F,
    bossIntensityColor: 0xFFE0485E,
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
