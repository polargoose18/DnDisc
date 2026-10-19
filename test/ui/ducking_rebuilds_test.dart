import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/ui/screens/library_screen.dart';
import 'package:ttrpg_audio_player/ui/shell/mixer_bar.dart';
import 'package:ttrpg_audio_player/ui/widgets/scene_selector_panel.dart';
import '../helpers/ui_harness.dart';

/// Counts how often each widget of interest is rebuilt while an SFX ducks the
/// music (the multiplier changes every ~30 ms during the release).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UiTestEnv env;

  setUp(() async {
    tempDir = await setUpUiTestDb();
    env = UiTestEnv();
  });

  tearDown(() => tearDownUiTestDb(tempDir));

  testWidgets(
      'ducking does not rebuild the mixer, the library or the scene list',
      (tester) async {
    await env.addTracks(tester, [testTrack('m1', 'Theme', AudioBusType.music)]);
    await env.pump(
      tester,
      const Scaffold(
        body: Column(
          children: [
            MixerBar(),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: SceneSelectorPanel()),
                  Expanded(child: LibraryScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final counts = <String, int>{};
    const watched = {'MixerBar', 'LibraryScreen', 'SceneSelectorPanel'};
    final previous = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      final name = element.widget.runtimeType.toString();
      if (watched.contains(name)) counts[name] = (counts[name] ?? 0) + 1;
    };
    debugPrintRebuildDirtyWidgets = false;
    addTearDown(() => debugOnRebuildDirtyWidget = previous);

    var engineNotifications = 0;
    env.engine.addListener(() => engineNotifications++);

    env.sfx.onSfxTriggered!();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pump(const Duration(seconds: 2));

    // ignore: avoid_print
    print('REBUILDS engineNotifications=$engineNotifications $counts');
    expect(env.music.duckingMultiplier, 1.0);
    expect(engineNotifications, 0);
    expect(counts, isEmpty);

    // A real change still reaches the mixer.
    env.music.setVolume(0.5);
    await tester.pump();
    expect(counts['MixerBar'], 1);
  });
}
