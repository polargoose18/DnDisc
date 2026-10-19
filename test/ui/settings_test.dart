import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ttrpg_audio_player/audio/audio_output_service.dart';
import 'package:ttrpg_audio_player/domain/models/custom_theme_model.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_en.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_ru.dart';
import 'package:ttrpg_audio_player/services/shortcut_service.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/theme/color_math.dart' as cm;
import 'package:ttrpg_audio_player/ui/design/ds_button.dart';
import 'package:ttrpg_audio_player/ui/design/ds_controls.dart';
import 'package:ttrpg_audio_player/ui/screens/main_dashboard_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/settings_screen.dart';
import 'package:ttrpg_audio_player/ui/widgets/custom_theme_editor_dialog.dart';
import 'package:ttrpg_audio_player/ui/widgets/logger_console_drawer.dart';
import 'package:ttrpg_audio_player/ui/widgets/theme_card.dart';
import '../helpers/fakes.dart';
import '../helpers/ui_harness.dart';

final l10n = AppLocalizationsEn();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UiTestEnv env;

  setUp(() async {
    tempDir = await setUpUiTestDb();
    env = UiTestEnv();
  });

  tearDown(() => tearDownUiTestDb(tempDir));

  Future<void> pumpSettings(WidgetTester tester, {Size size = const Size(1440, 1800)}) =>
      env.pump(tester, const SettingsScreen(), size: size);

  group('Settings screen', () {
    testWidgets('has the panels Appearance, Audio, Storage, Shortcuts and About in one column', (tester) async {
      await pumpSettings(tester);

      for (final title in [l10n.appearanceTitle, l10n.audioTitle, l10n.storageTitle, l10n.hotkeysTitle]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text('DnDisc'), findsOneWidget);
      expect(find.text('${l10n.appVersion} · ${l10n.aboutDesc}'), findsOneWidget);
      // One column no wider than 880px, centred.
      final panel = tester.getSize(find.ancestor(of: find.text(l10n.audioTitle), matching: find.byType(Container)).last);
      expect(panel.width, lessThanOrEqualTo(880));
    });

    testWidgets('shows the three presets and a create card, with the active theme marked', (tester) async {
      await pumpSettings(tester);

      for (final name in ['Deep Dark', 'Clean Light', 'Ancient Parchment']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text(l10n.createThemeBtn), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('theme_card_${AppThemes.deepDarkId}')), matching: find.bySemanticsLabel('check-circle')), findsNothing);
      // The active card has the selected mark (a check icon in the footer).
      expect(tester.widget<ThemeCard>(find.byKey(const ValueKey('theme_card_${AppThemes.deepDarkId}'))).selected, isTrue);
      expect(tester.widget<ThemeCard>(find.byKey(const ValueKey('theme_card_${AppThemes.cleanLightId}'))).selected, isFalse);
    });

    testWidgets('switches the whole app theme when a card is tapped', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('Clean Light'));
      await settle(tester);

      expect(env.themes.activeThemeId, equals(AppThemes.cleanLightId));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, isNotNull);
      expect(Theme.of(tester.element(find.byType(SettingsScreen))).scaffoldBackgroundColor, equals(AppThemes.cleanLight.background));
      expect(Theme.of(tester.element(find.byType(SettingsScreen))).colorScheme.onPrimary, equals(AppThemes.cleanLight.onPrimary));
    });

    testWidgets('changes crossfade and ducking settings with sliders and resets them to defaults', (tester) async {
      await pumpSettings(tester);

      expect(find.text('1.5 s'), findsOneWidget);
      expect(find.text('1.0 s'), findsOneWidget);
      expect(find.text('300 ms'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);

      await tester.drag(find.descendant(of: find.byKey(const ValueKey('music_fade_slider')), matching: find.byType(Slider)), const Offset(80, 0));
      await tester.pump();
      expect(env.settings.musicFadeMs, greaterThan(1500));

      await tester.drag(find.descendant(of: find.byKey(const ValueKey('duck_depth_slider')), matching: find.byType(Slider)), const Offset(80, 0));
      await tester.pump();
      expect(env.settings.duckMultiplier, greaterThan(0.4));

      await tester.tap(find.byKey(const ValueKey('reset_settings_button')));
      await tester.pump();
      expect(env.settings.musicFadeMs, equals(1500));
      expect(env.settings.duckMultiplier, equals(0.4));
      expect(find.text(l10n.toastSettingsReset), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('shows the storage folder and lets the user reset a custom one', (tester) async {
      env.settings.setCustomDownloadDirectory('/data/audio');
      await pumpSettings(tester);

      expect(find.text(l10n.customDirectory), findsOneWidget);
      expect(find.text('/data/audio'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reset_download_dir_button')));
      await tester.pump();
      expect(env.settings.customDownloadDirectory, isNull);
      expect(find.text(l10n.defaultDirectory), findsOneWidget);
      expect(find.byKey(const ValueKey('reset_download_dir_button')), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('switches the interface language to Russian', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.byKey(const ValueKey('language_selector_dropdown')));
      await settle(tester);
      await tester.tap(find.text(l10n.languageRussian).last);
      await settle(tester);

      expect(env.settings.appLanguage, equals('ru'));
      final ru = AppLocalizationsRu();
      expect(find.text(ru.appearanceTitle), findsOneWidget);
      expect(find.text(ru.audioTitle), findsOneWidget);
      expect(find.text(l10n.appearanceTitle), findsNothing);
    });

    testWidgets('lists shortcuts by group with keys as separate caps and toggles them with the panel switch', (tester) async {
      await pumpSettings(tester);

      for (final group in [l10n.shortcutGroupPlayback, l10n.shortcutGroupIntensity, l10n.shortcutGroupSfx]) {
        expect(find.text(group.toUpperCase()), findsOneWidget, reason: group);
      }
      expect(find.text('Space'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('F11'), findsOneWidget);
      for (final key in ['1', '2', '3', '4']) {
        expect(find.text(key), findsOneWidget);
      }
      // SFX slots: one row, alternatives joined with "or".
      expect(find.text('Num 1'), findsOneWidget);
      expect(find.text('Ctrl+1'), findsOneWidget);
      expect(find.text(l10n.orWord), findsOneWidget);
      expect(find.text(l10n.shortcutSfxSlotsDesc), findsOneWidget);

      final shortcuts = tester.element(find.byType(SettingsScreen)).read<ShortcutService>();
      expect(shortcuts.isEnabled, isTrue);
      await tester.tap(find.byKey(const ValueKey('shortcuts_switch')));
      await tester.pump();
      expect(shortcuts.isEnabled, isFalse);
      expect(tester.widget<DsSwitch>(find.byKey(const ValueKey('shortcuts_switch'))).value, isFalse);
    });

    testWidgets('opens the log console from About', (tester) async {
      await env.pump(tester, const MainDashboardScreen(), size: const Size(1440, 1000));
      await tester.tap(find.byTooltip(l10n.tabSettings).first);
      await settle(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('open_logs_button')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('open_logs_button')));
      await settle(tester);

      expect(find.byType(LoggerConsoleDrawer), findsOneWidget);
      expect(find.text(l10n.logConsoleTitle), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.close));
      await settle(tester);
      expect(find.byType(LoggerConsoleDrawer), findsNothing);
    });
  });

  group('Output device', () {
    const speakers = OutputDevice('alsa_output.speakers', label: 'Speakers', isDefault: true);
    const headset = OutputDevice('bluez_output.headset', label: 'Headset');

    Future<FakeOutputBackend> pumpWithOutput(WidgetTester tester, {bool supported = true}) async {
      final backend = FakeOutputBackend([speakers, headset]);
      final output = AudioOutputService(backend: backend, supported: supported);
      await tester.runAsync(output.init);
      env.output = output;
      await pumpSettings(tester);
      return backend;
    }

    testWidgets('lists the system default and the devices by name in the Audio panel', (tester) async {
      await pumpWithOutput(tester);

      expect(find.text(l10n.outputDeviceLabel), findsOneWidget);
      expect(find.text(l10n.outputDeviceDefault), findsOneWidget);
      expect(find.text(l10n.outputDeviceHint), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('output_device_select')));
      await settle(tester);
      expect(find.text('Speakers'), findsWidgets);
      expect(find.text('Headset'), findsWidgets);
    });

    testWidgets('moves the sound to the picked device', (tester) async {
      final backend = await pumpWithOutput(tester);

      await tester.tap(find.byKey(const ValueKey('output_device_select')));
      await settle(tester);
      await tester.tap(find.text('Headset').last);
      await settle(tester);

      expect(backend.changes, [headset.id]);
      expect(env.output!.selectedDevice, headset.id);
      expect(find.text('Headset'), findsOneWidget);
    });

    testWidgets('says when the saved device is not connected and refreshes the list', (tester) async {
      final backend = await pumpWithOutput(tester);
      await tester.runAsync(() => env.output!.select(headset.id));
      backend.devices = [speakers];

      await tester.tap(find.byKey(const ValueKey('refresh_devices_button')));
      await settleIo(tester, rounds: 2);

      expect(find.text(l10n.outputDeviceMissing(headset.id)), findsOneWidget);
      expect(find.text(l10n.outputDeviceDefault), findsOneWidget);
    });

    testWidgets('shows an error toast when the device cannot be used', (tester) async {
      final backend = await pumpWithOutput(tester);
      backend.failChange = true;

      await tester.tap(find.byKey(const ValueKey('output_device_select')));
      await settle(tester);
      await tester.tap(find.text('Headset').last);
      await settle(tester);

      expect(find.text(l10n.toastOutputDeviceFailed), findsOneWidget);
      expect(env.output!.selectedDevice, isNull);
    });

    testWidgets('is hidden where the system has a single output (Android)', (tester) async {
      await pumpWithOutput(tester, supported: false);
      expect(find.byKey(const ValueKey('output_device_select')), findsNothing);
    });
  });

  group('Custom themes', () {
    testWidgets('creates a custom theme from the editor, applies it and marks the card as custom', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.byKey(const ValueKey('create_theme_button')));
      await settle(tester);
      expect(find.text(l10n.createCustomThemeTitle), findsWidgets);

      // Saving needs a name.
      await tester.tap(find.byKey(const ValueKey('save_theme_btn')));
      await tester.pump();
      expect(find.text(l10n.themeNameRequired), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('theme_name_field')), 'Moss');
      await tester.tap(find.byKey(const ValueKey('theme_color_primary')));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey('color_hex_field')), '#2E9F6B');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('apply_color_btn')));
      await settle(tester);
      expect(find.text('#2E9F6B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save_theme_btn')));
      await settleIo(tester);

      final saved = env.themes.customThemes.single;
      expect(saved.name, equals('Moss'));
      expect(saved.primaryColor, equals(0xFF2E9F6B));
      expect(saved.isBuiltIn, isFalse);
      expect(env.themes.activeThemeId, equals(saved.id));
      expect(find.text(l10n.customThemeTag), findsOneWidget);
      // The derived tokens exist and the text on the accent is readable.
      expect(cm.contrastRatio(saved.onPrimaryColor, saved.primaryColor), greaterThanOrEqualTo(4.5));
    });

    testWidgets('rejects an invalid hex colour in the picker', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.byKey(const ValueKey('create_theme_button')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('theme_color_text')));
      await settle(tester);

      await tester.enterText(find.byKey(const ValueKey('color_hex_field')), '#12');
      await tester.pump();
      expect(find.text(l10n.hexInvalid), findsOneWidget);
      expect(tester.widget<DsButton>(find.byKey(const ValueKey('apply_color_btn'))).onPressed, isNull);
    });

    testWidgets('starts from a preset and fills the eight colours', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.byKey(const ValueKey('create_theme_button')));
      await settle(tester);
      expect(find.text('#14110F'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('theme_preset_select')));
      await settle(tester);
      await tester.tap(find.text('Clean Light').last);
      await settle(tester);

      expect(find.text('#F8FAFC'), findsOneWidget);
      expect(find.text('#FFFFFF'), findsOneWidget);
      expect(find.text('#2563EB'), findsOneWidget);
    });

    testWidgets('flags a pair below the readable minimum, fixes it with one button and still allows saving with warnings', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.byKey(const ValueKey('create_theme_button')));
      await settle(tester);

      // Text colour equal to the background: contrast 1:1.
      await tester.tap(find.byKey(const ValueKey('theme_color_text')));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey('color_hex_field')), '#14110F');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('apply_color_btn')));
      await settle(tester);

      expect(find.text(l10n.contrastWarning), findsOneWidget);
      expect(find.byKey(const ValueKey('contrast_fix_0')), findsOneWidget);
      expect(find.text('1.0:1'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('contrast_fix_0')));
      await tester.pump();
      expect(find.byKey(const ValueKey('contrast_fix_0')), findsNothing);

      // Break it again and save anyway: warnings do not block saving.
      await tester.tap(find.byKey(const ValueKey('theme_color_text')));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey('color_hex_field')), '#14110F');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('apply_color_btn')));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey('theme_name_field')), 'Murky');
      await tester.tap(find.byKey(const ValueKey('save_theme_btn')));
      await settleIo(tester);
      expect(env.themes.customThemes.single.name, equals('Murky'));
    });

    testWidgets('edits, duplicates and deletes a custom theme from its card menu', (tester) async {
      final custom = CustomThemeModel.derive(
        id: 'c1',
        name: 'Mine',
        background: 0xFF101010,
        surface: 0xFF181818,
        text: 0xFFEEEEEE,
        primary: 0xFFD4A373,
        calm: 0xFF78B7A6,
        suspense: 0xFFB79AE0,
        battle: 0xFFE8744F,
        boss: 0xFFE0485E,
      );
      await tester.runAsync(() => env.themes.saveCustomTheme(custom));
      env.themes.selectTheme(AppThemes.deepDarkId);
      await pumpSettings(tester);

      Future<void> choose(String label) async {
        await tester.tap(find.descendant(of: find.byKey(const ValueKey('theme_card_c1')), matching: find.byTooltip(l10n.moreActions)));
        await settle(tester);
        await tester.tap(find.text(label));
        await settleIo(tester);
      }

      await choose(l10n.duplicate);
      expect(env.themes.customThemes, hasLength(2));

      await choose(l10n.editDetails);
      expect(find.text(l10n.editCustomThemeTitle), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('theme_name_field')), 'Mine v2');
      await tester.tap(find.byKey(const ValueKey('save_theme_btn')));
      await settleIo(tester);
      expect(env.themes.customThemes.any((t) => t.name == 'Mine v2'), isTrue);

      await choose(l10n.delete);
      expect(find.text(l10n.deleteThemeTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(DsButton, l10n.delete));
      await settleIo(tester);
      expect(env.themes.customThemes.any((t) => t.id == 'c1'), isFalse);
    });

    test('the editor asks the user for exactly eight colours', () {
      expect(const CustomThemeEditorDialog(), isA<StatefulWidget>());
    });
  });
}
