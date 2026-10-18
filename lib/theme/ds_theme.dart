import 'package:flutter/material.dart';
import '../domain/models/custom_theme_model.dart';
import '../theme/app_themes.dart';

/// Token colours and text styles of the active theme, available as
/// `context.ds`. Names follow the design-system tokens.
@immutable
class DsTheme extends ThemeExtension<DsTheme> {
  static const String sansFamily = 'IBMPlexSans';
  static const String monoFamily = 'IBMPlexMono';

  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceHover;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color textDisabled;
  final Color primary;
  final Color primaryHover;
  final Color primarySubtle;
  final Color onPrimary;
  final Color focusRing;
  final Color danger;
  final Color dangerSubtle;
  final Color onDanger;
  final Color success;
  final Color successSubtle;
  final Color intensityCalm;
  final Color intensitySuspense;
  final Color intensityBattle;
  final Color intensityBoss;

  final TextStyle display;
  final TextStyle titleLg;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle code;

  const DsTheme({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceHover,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textDisabled,
    required this.primary,
    required this.primaryHover,
    required this.primarySubtle,
    required this.onPrimary,
    required this.focusRing,
    required this.danger,
    required this.dangerSubtle,
    required this.onDanger,
    required this.success,
    required this.successSubtle,
    required this.intensityCalm,
    required this.intensitySuspense,
    required this.intensityBattle,
    required this.intensityBoss,
    required this.display,
    required this.titleLg,
    required this.title,
    required this.body,
    required this.bodyStrong,
    required this.label,
    required this.caption,
    required this.code,
  });

  factory DsTheme.fromModel(CustomThemeModel m) {
    TextStyle sans(double size, double lineHeight, FontWeight weight, Color color) => TextStyle(
          fontFamily: sansFamily,
          fontSize: size,
          height: lineHeight / size,
          fontWeight: weight,
          color: color,
        );
    return DsTheme(
      bg: m.background,
      surface: m.surface,
      surfaceRaised: m.surfaceRaised,
      surfaceHover: m.surfaceHover,
      border: m.border,
      borderStrong: m.borderStrong,
      text: m.textPrimary,
      textMuted: m.textSecondary,
      textDisabled: m.textDisabled,
      primary: m.primary,
      primaryHover: m.primaryHover,
      primarySubtle: m.primarySubtle,
      onPrimary: m.onPrimary,
      focusRing: m.focusRing,
      danger: m.danger,
      dangerSubtle: m.dangerSubtle,
      onDanger: m.onDanger,
      success: m.success,
      successSubtle: m.successSubtle,
      intensityCalm: m.calmIntensity,
      intensitySuspense: m.suspenseIntensity,
      intensityBattle: m.battleIntensity,
      intensityBoss: m.bossIntensity,
      display: sans(28, 36, FontWeight.w600, m.textPrimary),
      titleLg: sans(20, 28, FontWeight.w600, m.textPrimary),
      title: sans(16, 24, FontWeight.w600, m.textPrimary),
      body: sans(14, 20, FontWeight.w400, m.textPrimary),
      bodyStrong: sans(14, 20, FontWeight.w600, m.textPrimary),
      label: sans(13, 16, FontWeight.w500, m.textPrimary),
      caption: sans(12, 16, FontWeight.w400, m.textSecondary),
      code: TextStyle(
        fontFamily: monoFamily,
        fontSize: 12,
        height: 18 / 12,
        fontWeight: FontWeight.w400,
        color: m.textSecondary,
      ),
    );
  }

  /// Digits of equal width: values do not jump while a slider moves.
  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  TextStyle tabular(TextStyle style) => style.copyWith(fontFeatures: tabularFigures);

  /// Colour of an intensity level key (`calm`, `suspense`, `battle`, `boss`).
  Color intensityColor(String key) {
    switch (key) {
      case 'calm':
        return intensityCalm;
      case 'suspense':
        return intensitySuspense;
      case 'battle':
        return intensityBattle;
      case 'boss':
        return intensityBoss;
      default:
        return textMuted;
    }
  }

  TextTheme get textTheme => TextTheme(
        displayLarge: display,
        displayMedium: display,
        displaySmall: display,
        headlineLarge: titleLg,
        headlineMedium: titleLg,
        headlineSmall: titleLg,
        titleLarge: titleLg,
        titleMedium: title,
        titleSmall: bodyStrong,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: label,
        labelMedium: label,
        labelSmall: caption,
      );

  /// Tokens of the active theme; Deep Dark when the widget tree has none.
  static DsTheme of(BuildContext context) =>
      Theme.of(context).extension<DsTheme>() ?? AppThemes.deepDark.tokens;

  @override
  DsTheme copyWith() => this;

  @override
  DsTheme lerp(ThemeExtension<DsTheme>? other, double t) => t < 0.5 ? this : (other as DsTheme? ?? this);
}

extension DsContext on BuildContext {
  DsTheme get ds => DsTheme.of(this);
}
