import 'package:flutter/material.dart';

class CustomThemeModel {
  final String id;
  final String name;
  final bool isDark;
  final int primaryColor;
  final int secondaryColor;
  final int backgroundColor;
  final int surfaceColor;
  final int cardColor;
  final int accentColor;
  final int textPrimaryColor;
  final int textSecondaryColor;
  final int duckingBadgeColor;
  final int battleIntensityColor;
  final int bossIntensityColor;
  final bool isBuiltIn;
  final DateTime createdAt;

  const CustomThemeModel({
    required this.id,
    required this.name,
    this.isDark = true,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.accentColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    this.duckingBadgeColor = 0xFFFF9800,
    this.battleIntensityColor = 0xFFEF4444,
    this.bossIntensityColor = 0xFF9333EA,
    this.isBuiltIn = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? const _DefaultDateTime();

  Color get primary => Color(primaryColor);
  Color get secondary => Color(secondaryColor);
  Color get background => Color(backgroundColor);
  Color get surface => Color(surfaceColor);
  Color get card => Color(cardColor);
  Color get accent => Color(accentColor);
  Color get textPrimary => Color(textPrimaryColor);
  Color get textSecondary => Color(textSecondaryColor);
  Color get duckingBadge => Color(duckingBadgeColor);
  Color get battleIntensity => Color(battleIntensityColor);
  Color get bossIntensity => Color(bossIntensityColor);

  ThemeData toThemeData() {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? Colors.white : Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      error: const Color(0xFFCF6679),
      onError: Colors.black,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: card,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: card,
      cardTheme: CardThemeData(
        color: card,
        elevation: 3,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.25),
        overlayColor: primary.withValues(alpha: 0.15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: primary.withValues(alpha: 0.35),
        labelStyle: TextStyle(color: textPrimary, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.grey.withValues(alpha: 0.5)
        ),
      )
    );
  }

  CustomThemeModel copyWith({
    String? id,
    String? name,
    bool? isDark,
    int? primaryColor,
    int? secondaryColor,
    int? backgroundColor,
    int? surfaceColor,
    int? cardColor,
    int? accentColor,
    int? textPrimaryColor,
    int? textSecondaryColor,
    int? duckingBadgeColor,
    int? battleIntensityColor,
    int? bossIntensityColor,
    bool? isBuiltIn,
    DateTime? createdAt,
  }) {
    return CustomThemeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isDark: isDark ?? this.isDark,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardColor: cardColor ?? this.cardColor,
      accentColor: accentColor ?? this.accentColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      duckingBadgeColor: duckingBadgeColor ?? this.duckingBadgeColor,
      battleIntensityColor: battleIntensityColor ?? this.battleIntensityColor,
      bossIntensityColor: bossIntensityColor ?? this.bossIntensityColor,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_dark': isDark ? 1 : 0,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'background_color': backgroundColor,
      'surface_color': surfaceColor,
      'card_color': cardColor,
      'accent_color': accentColor,
      'text_primary_color': textPrimaryColor,
      'text_secondary_color': textSecondaryColor,
      'ducking_badge_color': duckingBadgeColor,
      'battle_intensity_color': battleIntensityColor,
      'boss_intensity_color': bossIntensityColor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomThemeModel.fromMap(Map<String, dynamic> map) {
    return CustomThemeModel(
      id: map['id'] as String,
      name: map['name'] as String,
      isDark: (map['is_dark'] as num? ?? 1) == 1,
      primaryColor: map['primary_color'] as int? ?? 0xFF7C4DFF,
      secondaryColor: map['secondary_color'] as int? ?? 0xFF00E5FF,
      backgroundColor: map['background_color'] as int? ?? 0xFF121218,
      surfaceColor: map['surface_color'] as int? ?? 0xFF181824,
      cardColor: map['card_color'] as int? ?? 0xFF1E1E2A,
      accentColor: map['accent_color'] as int? ?? 0xFFBB86FC,
      textPrimaryColor: map['text_primary_color'] as int? ?? 0xFFFFFFFF,
      textSecondaryColor: map['text_secondary_color'] as int? ?? 0xFFB0B0C0,
      duckingBadgeColor: map['ducking_badge_color'] as int? ?? 0xFFFF9800,
      battleIntensityColor: map['battle_intensity_color'] as int? ?? 0xFFEF4444,
      bossIntensityColor: map['boss_intensity_color'] as int? ?? 0xFF9333EA,
      isBuiltIn: false,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory CustomThemeModel.fromJson(Map<String, dynamic> json) => CustomThemeModel.fromMap(json);
}

class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  DateTime get _now => DateTime.now();

  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);
  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  Duration difference(DateTime other) => _now.difference(other);
  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;
  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get weekday => _now.weekday;
  @override
  bool get isUtc => _now.isUtc;
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();
  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  String toString() => _now.toString();
}
