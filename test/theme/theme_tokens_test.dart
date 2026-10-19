import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/custom_theme_model.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/theme/color_math.dart';
import 'package:ttrpg_audio_player/theme/ds_theme.dart';

class _FakePathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

/// Every pair "text on background" of the design system and its minimum
/// contrast: 4.5 for text, 3 for outlines and focus rings.
List<(String, int, int, double)> _pairs(CustomThemeModel t) => [
      ('text on bg', t.textPrimaryColor, t.backgroundColor, 4.5),
      ('text on surface', t.textPrimaryColor, t.surfaceColor, 4.5),
      ('text on surface-raised', t.textPrimaryColor, t.surfaceRaisedColor, 4.5),
      ('text-muted on bg', t.textSecondaryColor, t.backgroundColor, 4.5),
      ('text-muted on surface', t.textSecondaryColor, t.surfaceColor, 4.5),
      ('text-muted on surface-raised', t.textSecondaryColor, t.surfaceRaisedColor, 4.5),
      ('text-muted on surface-hover', t.textSecondaryColor, t.surfaceHoverColor, 4.5),
      ('primary on bg', t.primaryColor, t.backgroundColor, 4.5),
      ('primary on surface', t.primaryColor, t.surfaceColor, 4.5),
      ('primary on surface-raised', t.primaryColor, t.surfaceRaisedColor, 4.5),
      ('primary on primary-subtle', t.primaryColor, t.primarySubtleColor, 4.5),
      ('on-primary on primary', t.onPrimaryColor, t.primaryColor, 4.5),
      ('danger on surface', t.dangerColor, t.surfaceColor, 4.5),
      ('danger on danger-subtle', t.dangerColor, t.dangerSubtleColor, 4.5),
      ('success on surface', t.successColor, t.surfaceColor, 4.5),
      ('border-strong on bg', t.borderStrongColor, t.backgroundColor, 3),
      ('border-strong on surface', t.borderStrongColor, t.surfaceColor, 3),
      ('border-strong on surface-raised', t.borderStrongColor, t.surfaceRaisedColor, 3),
      ('focus-ring on bg', t.focusRingColor, t.backgroundColor, 3),
      ('focus-ring on surface', t.focusRingColor, t.surfaceColor, 3),
      ('focus-ring on surface-raised', t.focusRingColor, t.surfaceRaisedColor, 3),
      ('focus-ring on surface-hover', t.focusRingColor, t.surfaceHoverColor, 3),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Preset contrast', () {
    for (final theme in AppThemes.presets) {
      test('${theme.name} meets the contrast targets of the design system', () {
        for (final (label, fg, bg, min) in _pairs(theme)) {
          expect(
            contrastRatio(fg, bg),
            greaterThanOrEqualTo(min),
            reason: '${theme.name}: $label',
          );
        }
      });
    }
  });

  group('CustomThemeModel.derive', () {
    CustomThemeModel build(int bg, int surface, int text, int primary) => CustomThemeModel.derive(
          id: 't',
          name: 'T',
          background: bg,
          surface: surface,
          text: text,
          primary: primary,
          calm: 0xFF78B7A6,
          suspense: 0xFFB79AE0,
          battle: 0xFFE8744F,
          boss: 0xFFE0485E,
        );

    test('decides dark or light by the lightness of the background', () {
      expect(build(0xFF14110F, 0xFF1C1815, 0xFFF3ECE2, 0xFFD4A373).isDark, isTrue);
      expect(build(0xFFF8FAFC, 0xFFFFFFFF, 0xFF0F172A, 0xFF2563EB).isDark, isFalse);
    });

    test('derived dark theme keeps layers ordered and readable', () {
      final t = build(0xFF14110F, 0xFF1C1815, 0xFFF3ECE2, 0xFFD4A373);
      expect(toOklch(t.surfaceRaisedColor).l, greaterThan(toOklch(t.surfaceColor).l));
      expect(toOklch(t.surfaceHoverColor).l, greaterThan(toOklch(t.surfaceRaisedColor).l));
      for (final (label, fg, bg, min) in _pairs(t)) {
        if (label.startsWith('danger') || label.startsWith('success')) continue;
        expect(contrastRatio(fg, bg), greaterThanOrEqualTo(min), reason: label);
      }
    });

    test('derived light theme goes darker for raised layers and stays readable', () {
      final t = build(0xFFF8FAFC, 0xFFFFFFFF, 0xFF0F172A, 0xFF2563EB);
      expect(toOklch(t.surfaceRaisedColor).l, lessThan(toOklch(t.surfaceColor).l));
      expect(t.onPrimaryColor, equals(0xFFFFFFFF));
      for (final (label, fg, bg, min) in _pairs(t)) {
        expect(contrastRatio(fg, bg), greaterThanOrEqualTo(min), reason: label);
      }
    });

    test('picks black or white text for a primary of any lightness', () {
      expect(build(0xFF14110F, 0xFF1C1815, 0xFFF3ECE2, 0xFFFFD166).onPrimaryColor, equals(0xFF000000));
      expect(build(0xFFF8FAFC, 0xFFFFFFFF, 0xFF0F172A, 0xFF1D4ED8).onPrimaryColor, equals(0xFFFFFFFF));
    });
  });

  group('toThemeData', () {
    test('exposes tokens through the ThemeExtension and the colour scheme', () {
      final data = AppThemes.deepDark.toThemeData();
      final ds = data.extension<DsTheme>()!;
      expect(ds.surfaceHover, equals(AppThemes.deepDark.surfaceHover));
      expect(data.colorScheme.onPrimary, equals(AppThemes.deepDark.onPrimary));
      expect(data.colorScheme.outline, equals(AppThemes.deepDark.borderStrong));
      expect(data.colorScheme.outlineVariant, equals(AppThemes.deepDark.border));
      expect(data.colorScheme.surfaceContainerHighest, equals(AppThemes.deepDark.surfaceRaised));
    });

    test('uses IBM Plex Sans for every text style and the design-system sizes', () {
      final t = AppThemes.deepDark.toThemeData().textTheme;
      for (final style in [t.displaySmall, t.titleLarge, t.titleMedium, t.bodyMedium, t.labelLarge, t.bodySmall]) {
        expect(style!.fontFamily, equals(DsTheme.sansFamily));
        expect(style.fontFamilyFallback, isNull);
      }
      expect(t.displaySmall!.fontSize, equals(28));
      expect(t.titleLarge!.fontSize, equals(20));
      expect(t.titleMedium!.fontSize, equals(16));
      expect(t.bodyMedium!.fontSize, equals(14));
      expect(t.labelLarge!.fontSize, equals(13));
      expect(t.bodySmall!.fontSize, equals(12));
    });
  });

  group('Theme storage migration', () {
    late Directory tempDir;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ttrpg_theme_migration_');
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    });

    tearDown(() async {
      await DatabaseService().close();
      tempDir.delete(recursive: true).ignore();
    });

    test('v5 rows keep their colours and get the new tokens with defaults', () async {
      final path = p.join(tempDir.path, 'ttrpg_audio_player.db');
      final legacy = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, _) async {
            await db.execute('CREATE TABLE library_tracks (id TEXT PRIMARY KEY, title TEXT, bus_type TEXT)');
            await db.execute('CREATE TABLE scenes (id TEXT PRIMARY KEY, name TEXT, image_path TEXT, created_at TEXT)');
            await db.execute('''
              CREATE TABLE custom_themes (
                id TEXT PRIMARY KEY, name TEXT NOT NULL, is_dark INTEGER NOT NULL,
                primary_color INTEGER NOT NULL, secondary_color INTEGER NOT NULL,
                background_color INTEGER NOT NULL, surface_color INTEGER NOT NULL,
                card_color INTEGER NOT NULL, accent_color INTEGER NOT NULL,
                text_primary_color INTEGER NOT NULL, text_secondary_color INTEGER NOT NULL,
                ducking_badge_color INTEGER NOT NULL, battle_intensity_color INTEGER NOT NULL,
                boss_intensity_color INTEGER NOT NULL, created_at TEXT NOT NULL
              )
            ''');
            await db.insert('custom_themes', {
              'id': 'old-1',
              'name': 'Old theme',
              'is_dark': 1,
              'primary_color': 0xFF7C4DFF,
              'secondary_color': 0xFF00E5FF,
              'background_color': 0xFF121218,
              'surface_color': 0xFF181824,
              'card_color': 0xFF1E1E2A,
              'accent_color': 0xFFBB86FC,
              'text_primary_color': 0xFFFFFFFF,
              'text_secondary_color': 0xFFB0B0C0,
              'ducking_badge_color': 0xFFFF9800,
              'battle_intensity_color': 0xFFEF4444,
              'boss_intensity_color': 0xFF9333EA,
              'created_at': DateTime(2025).toIso8601String(),
            });
          },
        ),
      );
      await legacy.close();

      final themes = await DatabaseService().getAllCustomThemes();
      expect(themes, hasLength(1));
      final t = themes.single;
      expect(t.primaryColor, equals(0xFF7C4DFF));
      expect(t.backgroundColor, equals(0xFF121218));
      expect(t.surfaceRaisedColor, equals(0xFF1E1E2A));
      expect(t.battleIntensityColor, equals(0xFFEF4444));
      expect(t.surfaceHoverColor, isNot(equals(t.surfaceRaisedColor)));
      expect(contrastRatio(t.onPrimaryColor, t.primaryColor), greaterThanOrEqualTo(4.5));
      expect(t.dangerColor, equals(StatusColors.dark.danger));
    });
  });
}
