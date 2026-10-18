import 'dart:io';
import 'package:flutter/material.dart' hide Durations;
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_en.dart';
import 'package:ttrpg_audio_player/theme/tokens.dart';
import 'package:ttrpg_audio_player/ui/screens/library_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/main_dashboard_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/settings_screen.dart';
import 'package:ttrpg_audio_player/ui/shell/nav_rail.dart';
import 'package:ttrpg_audio_player/ui/shell/top_bar.dart';
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

  group('Navigation rail', () {
    testWidgets('is collapsed to 64px by default and switches screens', (tester) async {
      await env.pump(tester, const MainDashboardScreen());

      expect(tester.getSize(find.byType(NavRail)).width, equals(Sizes.railWidth));
      expect(find.byType(LibraryScreen), findsNothing);

      await tester.tap(find.byTooltip(l10n.tabLibrary).first);
      await settle(tester);
      expect(find.byType(LibraryScreen), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.tabSettings).first);
      await settle(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('expands to 224px, remembers the choice and shows the labels', (tester) async {
      await env.pump(tester, const MainDashboardScreen());

      await tester.tap(find.byTooltip(l10n.expandSidebarTooltip));
      await settle(tester);

      expect(env.settings.navRailOpen, isTrue);
      expect(tester.getSize(find.byType(NavRail)).width, equals(Sizes.railWidthOpen));
      expect(find.descendant(of: find.byType(NavRail), matching: find.text(l10n.tabLibrary)), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.collapseSidebarTooltip));
      await settle(tester);
      expect(env.settings.navRailOpen, isFalse);
      expect(tester.getSize(find.byType(NavRail)).width, equals(Sizes.railWidth));
    });

    testWidgets('has no logo and no panic button', (tester) async {
      env.settings.setNavRailOpen(true);
      await env.pump(tester, const MainDashboardScreen());

      expect(find.descendant(of: find.byType(NavRail), matching: find.text('DnDisc')), findsNothing);
      expect(find.descendant(of: find.byType(NavRail), matching: find.byType(Image)), findsNothing);
      expect(find.textContaining('Panic'), findsNothing);
    });

    testWidgets('is a slide-out panel in the compact window', (tester) async {
      await env.pump(tester, const MainDashboardScreen(), size: const Size(600, 900));

      expect(find.byType(NavRail), findsNothing);
      expect(find.byType(TopBar), findsWidgets);

      await tester.tap(find.byTooltip(l10n.openNavigation).first);
      await settle(tester);
      expect(find.byType(NavRail), findsOneWidget);
      expect(tester.getSize(find.byType(NavRail)).width, equals(Sizes.railWidthOpen));

      await tester.tap(find.descendant(of: find.byType(NavRail), matching: find.text(l10n.tabLibrary)));
      await settle(tester);
      expect(find.byType(NavRail), findsNothing);
      expect(find.byType(LibraryScreen), findsOneWidget);
    });
  });

  group('Toasts', () {
    testWidgets('show at most three, newest on top', (tester) async {
      await env.pump(tester, const Scaffold(body: SizedBox.expand()));

      for (final title in ['one', 'two', 'three', 'four']) {
        env.toasts.show(title: title);
      }
      await tester.pump();

      expect(env.toasts.toasts.map((t) => t.title), equals(['four', 'three', 'two']));
      expect(find.text('one'), findsNothing);
      expect(tester.getTopLeft(find.text('four')).dy, lessThan(tester.getTopLeft(find.text('two')).dy));

      await tester.pump(Durations.toast + const Duration(seconds: 1));
    });

    testWidgets('neutral and success toasts leave after five seconds, errors stay until closed', (tester) async {
      await env.pump(tester, const Scaffold(body: SizedBox.expand()));

      env.toasts.show(title: 'neutral');
      env.toasts.success('success');
      env.toasts.error('failed');
      await tester.pump();

      await tester.pump(const Duration(seconds: 4));
      expect(env.toasts.toasts, hasLength(3));

      await tester.pump(const Duration(seconds: 2));
      expect(env.toasts.toasts.map((t) => t.title), equals(['failed']));

      env.toasts.dismiss(env.toasts.toasts.single.id);
      await tester.pump();
      expect(env.toasts.toasts, isEmpty);
    });
  });
}
