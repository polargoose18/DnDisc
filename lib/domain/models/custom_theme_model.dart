import 'package:flutter/material.dart' hide Durations;
import '../../theme/color_math.dart' as cm;
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';

/// Colour values of `danger` / `success` shared by every dark or light theme.
class StatusColors {
  final int danger;
  final int dangerSubtle;
  final int onDanger;
  final int success;
  final int successSubtle;

  const StatusColors({
    required this.danger,
    required this.dangerSubtle,
    required this.onDanger,
    required this.success,
    required this.successSubtle,
  });

  static const dark = StatusColors(
    danger: 0xFFEF7C71,
    dangerSubtle: 0xFF3D1D19,
    onDanger: 0xFF1C0A08,
    success: 0xFF6CC4B0,
    successSubtle: 0xFF17332D,
  );

  static const light = StatusColors(
    danger: 0xFFB42318,
    dangerSubtle: 0xFFFDE4E1,
    onDanger: 0xFFFFFFFF,
    success: 0xFF0F766E,
    successSubtle: 0xFFD5F0EC,
  );
}

/// A colour theme: every token of the design system as an ARGB int.
///
/// Presets set all values by hand; user themes pick eight colours in the
/// editor and the rest is computed by [CustomThemeModel.derive].
class CustomThemeModel {
  final String id;
  final String name;
  final bool isDark;

  final int backgroundColor;
  final int surfaceColor;
  final int surfaceRaisedColor;
  final int surfaceHoverColor;
  final int borderColor;
  final int borderStrongColor;

  final int textPrimaryColor;
  final int textSecondaryColor;
  final int textDisabledColor;

  final int primaryColor;
  final int primaryHoverColor;
  final int primarySubtleColor;
  final int onPrimaryColor;
  final int focusRingColor;

  final int dangerColor;
  final int dangerSubtleColor;
  final int onDangerColor;
  final int successColor;
  final int successSubtleColor;

  final int calmIntensityColor;
  final int suspenseIntensityColor;
  final int battleIntensityColor;
  final int bossIntensityColor;

  final bool isBuiltIn;
  final DateTime createdAt;

  const CustomThemeModel({
    required this.id,
    required this.name,
    this.isDark = true,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.surfaceRaisedColor,
    required this.surfaceHoverColor,
    required this.borderColor,
    required this.borderStrongColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.textDisabledColor,
    required this.primaryColor,
    required this.primaryHoverColor,
    required this.primarySubtleColor,
    required this.onPrimaryColor,
    required this.focusRingColor,
    required this.dangerColor,
    required this.dangerSubtleColor,
    required this.onDangerColor,
    required this.successColor,
    required this.successSubtleColor,
    required this.calmIntensityColor,
    required this.suspenseIntensityColor,
    required this.battleIntensityColor,
    required this.bossIntensityColor,
    this.isBuiltIn = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? const _DefaultDateTime();

  /// Builds a full theme from the eight colours a user picks in the editor.
  /// Dark or light is decided by the lightness of [background].
  factory CustomThemeModel.derive({
    required String id,
    required String name,
    required int background,
    required int surface,
    required int text,
    required int primary,
    required int calm,
    required int suspense,
    required int battle,
    required int boss,
    bool isBuiltIn = false,
    DateTime? createdAt,
  }) {
    final dark = cm.isDarkColor(background);
    final sign = dark ? 1.0 : -1.0;
    final raised = cm.shiftLightness(surface, dark ? 0.04 : -0.02);
    final hover = cm.shiftLightness(surface, dark ? 0.08 : -0.05);
    final border = cm.shiftLightness(surface, 0.10 * sign);

    final strongBackdrops = [background, surface, raised];
    final borderStrong = cm.adjustToContrast(
      cm.mix(text, surface, 0.5),
      strongBackdrops,
      3,
      lighter: dark,
    );

    var muted = cm.mix(text, surface, 0.65);
    muted = cm.adjustToContrast(muted, [surface, raised, hover], 4.5, lighter: dark);
    // Moving towards the text colour: if the mix started on the wrong side
    // of the contrast target, fall back to text itself.
    if (cm.contrastRatio(muted, hover) < 4.5) muted = text;
    final disabled = cm.mix(text, surface, 0.4);

    final primaryHover = cm.shiftLightness(primary, 0.06 * sign);
    // 18% (dark) or 10% (light) of primary over surface; a weaker tint when
    // primary text would not stay readable on it.
    var primarySubtle = cm.mix(primary, surface, dark ? 0.18 : 0.10);
    for (var amount = dark ? 0.18 : 0.10; amount > 0.02; amount -= 0.02) {
      primarySubtle = cm.mix(primary, surface, amount);
      if (cm.contrastRatio(primary, primarySubtle) >= 4.5) break;
    }
    final focus = cm.adjustToContrast(
      primary,
      [background, surface, raised, hover],
      3,
      lighter: dark,
    );
    final status = dark ? StatusColors.dark : StatusColors.light;

    return CustomThemeModel(
      id: id,
      name: name,
      isDark: dark,
      backgroundColor: background,
      surfaceColor: surface,
      surfaceRaisedColor: raised,
      surfaceHoverColor: hover,
      borderColor: border,
      borderStrongColor: borderStrong,
      textPrimaryColor: text,
      textSecondaryColor: muted,
      textDisabledColor: disabled,
      primaryColor: primary,
      primaryHoverColor: primaryHover,
      primarySubtleColor: primarySubtle,
      onPrimaryColor: cm.bestOnColor(primary),
      focusRingColor: focus,
      dangerColor: status.danger,
      dangerSubtleColor: status.dangerSubtle,
      onDangerColor: status.onDanger,
      successColor: status.success,
      successSubtleColor: status.successSubtle,
      calmIntensityColor: calm,
      suspenseIntensityColor: suspense,
      battleIntensityColor: battle,
      bossIntensityColor: boss,
      isBuiltIn: isBuiltIn,
      createdAt: createdAt,
    );
  }

  Color get background => Color(backgroundColor);
  Color get surface => Color(surfaceColor);
  Color get surfaceRaised => Color(surfaceRaisedColor);
  Color get surfaceHover => Color(surfaceHoverColor);
  Color get border => Color(borderColor);
  Color get borderStrong => Color(borderStrongColor);
  Color get textPrimary => Color(textPrimaryColor);
  Color get textSecondary => Color(textSecondaryColor);
  Color get textDisabled => Color(textDisabledColor);
  Color get primary => Color(primaryColor);
  Color get primaryHover => Color(primaryHoverColor);
  Color get primarySubtle => Color(primarySubtleColor);
  Color get onPrimary => Color(onPrimaryColor);
  Color get focusRing => Color(focusRingColor);
  Color get danger => Color(dangerColor);
  Color get dangerSubtle => Color(dangerSubtleColor);
  Color get onDanger => Color(onDangerColor);
  Color get success => Color(successColor);
  Color get successSubtle => Color(successSubtleColor);
  Color get calmIntensity => Color(calmIntensityColor);
  Color get suspenseIntensity => Color(suspenseIntensityColor);
  Color get battleIntensity => Color(battleIntensityColor);
  Color get bossIntensity => Color(bossIntensityColor);

  /// Token colours and text styles for widgets (`context.ds`).
  DsTheme get tokens => DsTheme.fromModel(this);

  ThemeData toThemeData() {
    final ds = tokens;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primarySubtle,
      onPrimaryContainer: primary,
      secondary: primary,
      onSecondary: onPrimary,
      error: danger,
      onError: onDanger,
      errorContainer: dangerSubtle,
      onErrorContainer: danger,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceRaised,
      surfaceContainerHighest: surfaceRaised,
      outline: borderStrong,
      outlineVariant: border,
      shadow: Palette.shadow,
      surfaceTint: Palette.transparent,
    );

    const panelShape = RoundedRectangleBorder(borderRadius: Radii.lgAll);
    final panelSide = BorderSide(color: border, width: Sizes.borderWidth);
    OutlineInputBorder fieldBorder(Color c, [double width = Sizes.borderWidth]) => OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: c, width: width),
        );

    const buttonShape = RoundedRectangleBorder(borderRadius: Radii.mdAll);
    const buttonSize = Size(0, Sizes.targetMin);
    const buttonPadding = EdgeInsets.symmetric(horizontal: Spacing.s4);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: DsTheme.sansFamily,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: border,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Palette.transparent,
      hoverColor: surfaceHover,
      focusColor: Palette.transparent,
      extensions: [ds],
      textTheme: ds.textTheme,
      iconTheme: IconThemeData(color: textSecondary, size: Sizes.icon),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Palette.transparent,
        surfaceTintColor: Palette.transparent,
        shape: RoundedRectangleBorder(borderRadius: Radii.lgAll, side: panelSide),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Palette.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: ds.titleLg,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Palette.transparent,
        shape: panelShape.copyWith(side: panelSide),
        titleTextStyle: ds.titleLg,
        contentTextStyle: ds.body,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceRaised,
        elevation: 8,
        shadowColor: Palette.shadow,
        surfaceTintColor: Palette.transparent,
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll, side: panelSide),
        textStyle: ds.body,
        labelTextStyle: WidgetStatePropertyAll(ds.body),
        menuPadding: const EdgeInsets.symmetric(vertical: Spacing.s1),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: Sizes.borderWidth, space: Sizes.borderWidth),
      sliderTheme: SliderThemeData(
        trackHeight: Sizes.sliderTrack,
        activeTrackColor: primary,
        inactiveTrackColor: surfaceHover,
        disabledActiveTrackColor: textDisabled,
        disabledInactiveTrackColor: surfaceHover,
        thumbColor: primary,
        overlayColor: primarySubtle,
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: Sizes.sliderThumb / 2,
          elevation: 0,
          pressedElevation: 0,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: Spacing.s4),
        showValueIndicator: ShowValueIndicator.never,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : surfaceHover,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : borderStrong,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? onPrimary : textSecondary,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? BorderSide(color: primary, width: 1.5)
              : BorderSide(color: borderStrong, width: 1.5),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : Palette.transparent,
        ),
        checkColor: WidgetStatePropertyAll(onPrimary),
        overlayColor: const WidgetStatePropertyAll(Palette.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: Durations.tooltipDelay,
        decoration: BoxDecoration(color: textPrimary, borderRadius: Radii.smAll),
        textStyle: ds.caption.copyWith(color: background),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.s2, vertical: Spacing.s1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.s3, vertical: Spacing.s3),
        constraints: const BoxConstraints(minHeight: Sizes.targetMin),
        hintStyle: ds.body.copyWith(color: textSecondary),
        labelStyle: ds.label.copyWith(color: textSecondary),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        helperStyle: ds.caption.copyWith(color: textSecondary),
        errorStyle: ds.caption.copyWith(color: danger),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: fieldBorder(borderStrong),
        enabledBorder: fieldBorder(borderStrong),
        focusedBorder: fieldBorder(borderStrong),
        errorBorder: fieldBorder(danger),
        focusedErrorBorder: fieldBorder(danger),
        disabledBorder: fieldBorder(border),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primarySubtle,
        selectionHandleColor: primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceHover,
          disabledForegroundColor: textDisabled,
          elevation: 0,
          shadowColor: Palette.transparent,
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: ds.label,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceHover,
          disabledForegroundColor: textDisabled,
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: ds.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surfaceRaised,
          foregroundColor: textPrimary,
          disabledForegroundColor: textDisabled,
          side: panelSide,
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: ds.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          disabledForegroundColor: textDisabled,
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: ds.label,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          disabledForegroundColor: textDisabled,
          minimumSize: const Size.square(Sizes.targetMin),
          shape: buttonShape,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: ds.body,
        subtitleTextStyle: ds.caption.copyWith(color: textSecondary),
        minVerticalPadding: Spacing.s2,
        shape: buttonShape,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        labelStyle: ds.label,
        unselectedLabelStyle: ds.label,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Palette.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceHover,
        circularTrackColor: surfaceHover,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(borderStrong),
        radius: const Radius.circular(Radii.full),
      ),
    );
  }

  CustomThemeModel copyWith({
    String? id,
    String? name,
    bool? isDark,
    int? backgroundColor,
    int? surfaceColor,
    int? surfaceRaisedColor,
    int? surfaceHoverColor,
    int? borderColor,
    int? borderStrongColor,
    int? textPrimaryColor,
    int? textSecondaryColor,
    int? textDisabledColor,
    int? primaryColor,
    int? primaryHoverColor,
    int? primarySubtleColor,
    int? onPrimaryColor,
    int? focusRingColor,
    int? dangerColor,
    int? dangerSubtleColor,
    int? onDangerColor,
    int? successColor,
    int? successSubtleColor,
    int? calmIntensityColor,
    int? suspenseIntensityColor,
    int? battleIntensityColor,
    int? bossIntensityColor,
    bool? isBuiltIn,
    DateTime? createdAt,
  }) {
    return CustomThemeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isDark: isDark ?? this.isDark,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      surfaceRaisedColor: surfaceRaisedColor ?? this.surfaceRaisedColor,
      surfaceHoverColor: surfaceHoverColor ?? this.surfaceHoverColor,
      borderColor: borderColor ?? this.borderColor,
      borderStrongColor: borderStrongColor ?? this.borderStrongColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      textDisabledColor: textDisabledColor ?? this.textDisabledColor,
      primaryColor: primaryColor ?? this.primaryColor,
      primaryHoverColor: primaryHoverColor ?? this.primaryHoverColor,
      primarySubtleColor: primarySubtleColor ?? this.primarySubtleColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      dangerColor: dangerColor ?? this.dangerColor,
      dangerSubtleColor: dangerSubtleColor ?? this.dangerSubtleColor,
      onDangerColor: onDangerColor ?? this.onDangerColor,
      successColor: successColor ?? this.successColor,
      successSubtleColor: successSubtleColor ?? this.successSubtleColor,
      calmIntensityColor: calmIntensityColor ?? this.calmIntensityColor,
      suspenseIntensityColor: suspenseIntensityColor ?? this.suspenseIntensityColor,
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
      'background_color': backgroundColor,
      'surface_color': surfaceColor,
      'surface_raised_color': surfaceRaisedColor,
      'surface_hover_color': surfaceHoverColor,
      'border_color': borderColor,
      'border_strong_color': borderStrongColor,
      'text_primary_color': textPrimaryColor,
      'text_secondary_color': textSecondaryColor,
      'text_disabled_color': textDisabledColor,
      'primary_color': primaryColor,
      'primary_hover_color': primaryHoverColor,
      'primary_subtle_color': primarySubtleColor,
      'on_primary_color': onPrimaryColor,
      'focus_ring_color': focusRingColor,
      'danger_color': dangerColor,
      'danger_subtle_color': dangerSubtleColor,
      'on_danger_color': onDangerColor,
      'success_color': successColor,
      'success_subtle_color': successSubtleColor,
      'calm_intensity_color': calmIntensityColor,
      'suspense_intensity_color': suspenseIntensityColor,
      'battle_intensity_color': battleIntensityColor,
      'boss_intensity_color': bossIntensityColor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Reads a theme row. Rows saved before the design-system migration only
  /// hold the base colours; the missing tokens are derived from them.
  factory CustomThemeModel.fromMap(Map<String, dynamic> map) {
    int? colour(String key) => (map[key] as num?)?.toInt();
    final isDark = (map['is_dark'] as num? ?? 1) == 1;
    final fallback = isDark ? _fallbackDark : _fallbackLight;

    final derived = CustomThemeModel.derive(
      id: map['id'] as String,
      name: map['name'] as String,
      background: colour('background_color') ?? fallback.backgroundColor,
      surface: colour('surface_color') ?? fallback.surfaceColor,
      text: colour('text_primary_color') ?? fallback.textPrimaryColor,
      primary: colour('primary_color') ?? fallback.primaryColor,
      calm: colour('calm_intensity_color') ?? fallback.calmIntensityColor,
      suspense: colour('suspense_intensity_color') ?? fallback.suspenseIntensityColor,
      battle: colour('battle_intensity_color') ?? fallback.battleIntensityColor,
      boss: colour('boss_intensity_color') ?? fallback.bossIntensityColor,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );

    return derived.copyWith(
      isDark: isDark,
      surfaceRaisedColor: colour('surface_raised_color') ?? colour('card_color'),
      surfaceHoverColor: colour('surface_hover_color'),
      borderColor: colour('border_color'),
      borderStrongColor: colour('border_strong_color'),
      textSecondaryColor: colour('text_secondary_color'),
      textDisabledColor: colour('text_disabled_color'),
      primaryHoverColor: colour('primary_hover_color'),
      primarySubtleColor: colour('primary_subtle_color'),
      onPrimaryColor: colour('on_primary_color'),
      focusRingColor: colour('focus_ring_color'),
      dangerColor: colour('danger_color'),
      dangerSubtleColor: colour('danger_subtle_color'),
      onDangerColor: colour('on_danger_color'),
      successColor: colour('success_color'),
      successSubtleColor: colour('success_subtle_color'),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory CustomThemeModel.fromJson(Map<String, dynamic> json) => CustomThemeModel.fromMap(json);

  // Defaults for rows that miss a colour entirely: the Deep Dark / Clean
  // Light values of the design system.
  static const CustomThemeModel _fallbackDark = CustomThemeModel(
    id: '',
    name: '',
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
  );

  static const CustomThemeModel _fallbackLight = CustomThemeModel(
    id: '',
    name: '',
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
  );
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
