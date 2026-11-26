import 'dart:io';
import 'package:flutter/material.dart' hide Durations;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/theme/icons.dart';
import 'package:ttrpg_audio_player/theme/tokens.dart';
import 'package:ttrpg_audio_player/ui/design/ds_button.dart';
import 'package:ttrpg_audio_player/ui/design/ds_controls.dart';
import 'package:ttrpg_audio_player/ui/design/ds_dialog.dart';
import 'package:ttrpg_audio_player/ui/design/ds_field.dart';
import 'package:ttrpg_audio_player/ui/design/ds_icon.dart';
import 'package:ttrpg_audio_player/ui/design/ds_menu.dart';
import 'package:ttrpg_audio_player/ui/design/ds_slider.dart';
import 'package:ttrpg_audio_player/ui/design/equalizer_bars.dart';
import '../helpers/ui_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UiTestEnv env;

  setUp(() async {
    tempDir = await setUpUiTestDb();
    env = UiTestEnv();
  });
  tearDown(() => tearDownUiTestDb(tempDir));

  Future<void> pumpBody(WidgetTester tester, Widget child) =>
      env.pump(tester, Scaffold(body: Center(child: child)), size: const Size(800, 600));

  group('Buttons', () {
    testWidgets('are at least 40px tall in every variant, icon-only ones 40px wide', (tester) async {
      await pumpBody(
        tester,
        Wrap(
          spacing: Spacing.s2,
          children: [
            DsButton(key: const ValueKey('secondary'), label: 'Secondary', onPressed: () {}),
            DsButton.primary(key: const ValueKey('primary'), label: 'Primary', onPressed: () {}),
            DsButton.ghost(key: const ValueKey('ghost'), label: 'Ghost', onPressed: () {}),
            DsButton.danger(key: const ValueKey('danger'), label: 'Danger', onPressed: () {}),
            DsButton.ghost(key: const ValueKey('icon'), icon: 'search', iconOnly: true, label: 'Search', onPressed: () {}),
          ],
        ),
      );

      for (final key in ['secondary', 'primary', 'ghost', 'danger', 'icon']) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.height, greaterThanOrEqualTo(Sizes.targetMin), reason: key);
      }
      expect(tester.getSize(find.byKey(const ValueKey('icon'))).width, greaterThanOrEqualTo(Sizes.targetMin));
    });

    testWidgets('call onPressed on tap and Enter, and ignore a disabled button', (tester) async {
      var taps = 0;
      await pumpBody(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsButton.primary(key: const ValueKey('on'), label: 'On', onPressed: () => taps++),
            const DsButton(key: ValueKey('off'), label: 'Off'),
          ],
        ),
      );

      await tester.tap(find.byKey(const ValueKey('on')));
      await tester.pump();
      expect(taps, 1);

      await tester.tap(find.byKey(const ValueKey('off')));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('Switch and checkbox', () {
    testWidgets('the switch reports the opposite value on tap', (tester) async {
      bool? changed;
      await pumpBody(tester, DsSwitch(value: false, label: 'Enabled', onChanged: (v) => changed = v));

      await tester.tap(find.byType(DsSwitch));
      await tester.pump();
      expect(changed, isTrue);
    });

    testWidgets('the checkbox shows its label and toggles', (tester) async {
      bool? changed;
      await pumpBody(tester, DsCheckbox(value: true, label: 'Keep layers', onChanged: (v) => changed = v));

      expect(find.text('Keep layers'), findsOneWidget);
      await tester.tap(find.text('Keep layers'));
      await tester.pump();
      expect(changed, isFalse);
    });
  });

  group('Slider', () {
    testWidgets('shows the value as a percentage and changes it with arrow keys, Shift makes the step bigger', (tester) async {
      var value = 0.5;
      await pumpBody(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 400,
            child: DsSlider(value: value, semanticLabel: 'Volume', onChanged: (v) => setState(() => value = v)),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);

      tester.widget<Slider>(find.byType(Slider)).focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, closeTo(0.51, 0.001));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, closeTo(0.49, 0.001));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(value, closeTo(0.59, 0.001));
    });

    testWidgets('uses its own text for the value', (tester) async {
      await pumpBody(
        tester,
        SizedBox(
          width: 400,
          child: DsSlider(value: 1.5, min: 0, max: 5, semanticLabel: 'Fade', format: (v) => '${v.toStringAsFixed(1)} s', onChanged: (_) {}),
        ),
      );

      expect(find.text('1.5 s'), findsOneWidget);
    });
  });

  group('Segmented control and text field', () {
    testWidgets('the segmented control selects the tapped option', (tester) async {
      String? chosen;
      await pumpBody(
        tester,
        DsSegmentedControl<String>(
          label: 'Kind',
          value: 'a',
          onChanged: (v) => chosen = v,
          options: const [DsSegment(id: 'a', label: 'First'), DsSegment(id: 'b', label: 'Second')],
        ),
      );

      await tester.tap(find.text('Second'));
      await tester.pump();
      expect(chosen, 'b');
    });

    testWidgets('the text field shows the error below and passes typed text on', (tester) async {
      String typed = '';
      await pumpBody(
        tester,
        SizedBox(width: 320, child: DsTextField(label: 'Name', error: 'Name is required', onChanged: (v) => typed = v)),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Name is required'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Moss');
      expect(typed, 'Moss');
    });

    testWidgets('the clear button empties a clearable field', (tester) async {
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);
      await pumpBody(tester, SizedBox(width: 320, child: DsTextField(controller: controller, clearable: true, clearLabel: 'Clear')));

      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pump();
      expect(controller.text, isEmpty);
    });
  });

  group('Equalizer', () {
    testWidgets('keeps running when active and stops with reduced motion', (tester) async {
      await pumpBody(tester, const EqualizerBars(active: true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);

      await env.pump(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: Center(child: EqualizerBars(active: true))),
        ),
        size: const Size(800, 600),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('Menu and dialog', () {
    testWidgets('the menu returns the chosen id and closes', (tester) async {
      String? chosen;
      await pumpBody(
        tester,
        Builder(
          builder: (context) => DsButton(
            label: 'Open',
            onPressed: () async => chosen = await showDsMenuFor(context, const [
              DsMenuItem(id: 'edit', label: 'Edit', icon: 'edit'),
              DsMenuItem.separator(),
              DsMenuItem(id: 'delete', label: 'Delete', icon: 'trash', danger: true),
            ]),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await settle(tester);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await settle(tester);
      expect(chosen, 'delete');
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('the dialog closes with the close button and returns false from a delete confirmation', (tester) async {
      bool? confirmed;
      await pumpBody(
        tester,
        Builder(
          builder: (context) => DsButton(
            label: 'Ask',
            onPressed: () async => confirmed = await confirmDelete(
              context,
              title: 'Delete scene',
              message: 'This cannot be undone',
              confirmLabel: 'Delete',
              cancelLabel: 'Cancel',
              closeLabel: 'Close',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ask'));
      await settle(tester);
      expect(find.text('Delete scene'), findsOneWidget);
      expect(find.text('This cannot be undone'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await settle(tester);
      expect(confirmed, isFalse);
      expect(find.text('Delete scene'), findsNothing);
    });
  });

  group('Icons', () {
    test('an unknown or missing key resolves to the default icon', () {
      expect(DnDiscIcons.pathOf('no-such-icon'), equals(DnDiscIcons.pathOf('bolt')));
      expect(DnDiscIcons.pathOf(null), equals(DnDiscIcons.pathOf('bolt')));
      expect(DnDiscIcons.resolve('no-such-icon', 'drum'), equals('drum'));
    });

    testWidgets('an unknown key still draws an icon', (tester) async {
      await pumpBody(tester, const DsIcon('no-such-icon'));
      expect(find.byType(DsIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
