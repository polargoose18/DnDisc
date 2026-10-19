import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ttrpg_audio_player/audio/playback/bus_player.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/services/shortcut_service.dart';
import 'package:ttrpg_audio_player/ui/design/ds_button.dart';
import 'package:ttrpg_audio_player/ui/shell/mixer_bar.dart';
import '../helpers/fakes.dart';
import '../helpers/ui_harness.dart';

/// The controls answer on the next frame; the sound fades with the
/// crossfade setting behind them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UiTestEnv env;
  late List<FakeBusPlayer> players;
  late String file;

  setUp(() async {
    tempDir = await setUpUiTestDb();
    env = UiTestEnv();
    file = (File('${tempDir.path}/theme.mp3')..writeAsBytesSync([0])).path;
    players = [];
    BusPlayer.debugFactory = (path) {
      final player = FakeBusPlayer(path);
      players.add(player);
      return player;
    };
  });
  tearDown(() async {
    BusPlayer.debugFactory = null;
    await tearDownUiTestDb(tempDir);
  });

  String playPauseIcon(WidgetTester tester) => tester.widget<DsButton>(find.byKey(const ValueKey('mixer_play_pause_button'))).icon!;

  Future<void> pumpPlaying(WidgetTester tester) async {
    await env.pump(tester, const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: MixerBar())));
    await env.music.playTrack(AudioTrack(id: 't', title: 'Theme', filePath: file), fadeDuration: Duration.zero);
    await tester.pump();
    expect(playPauseIcon(tester), 'pause');
  }

  Duration fade() => env.music.defaultFadeDuration;

  testWidgets('the play/pause button flips on the next frame while the music fades out', (tester) async {
    await pumpPlaying(tester);

    await tester.tap(find.byKey(const ValueKey('mixer_play_pause_button')));
    await tester.pump();
    expect(playPauseIcon(tester), 'play');
    expect(players.single.paused, isFalse, reason: 'the sound is still fading out');

    await tester.pump(fade() * 2);
    expect(players.single.paused, isTrue);

    await tester.tap(find.byKey(const ValueKey('mixer_play_pause_button')));
    await tester.pump();
    expect(playPauseIcon(tester), 'pause');
    await tester.pump(fade() * 2);
  });

  testWidgets('Space pauses at once', (tester) async {
    await pumpPlaying(tester);
    // The shortcut service listens to the keyboard once it is created.
    tester.element(find.byType(MixerBar)).read<ShortcutService>();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(env.music.isPlaying, isFalse);
    expect(playPauseIcon(tester), 'play');
    await tester.pump(fade() * 2);
  });

  testWidgets('stop clears the track title at once while the sound fades', (tester) async {
    await pumpPlaying(tester);
    expect(find.text('Theme'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('mixer_stop_button')));
    await tester.pump();
    expect(find.text('Theme'), findsNothing);
    expect(players.single.stopped, isFalse);

    await tester.pump(fade() * 2);
    expect(players.single.disposed, isTrue);
  });
}
