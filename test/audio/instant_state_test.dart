import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/playback/bus_player.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';
import '../helpers/fakes.dart';

void main() {
  late Directory dir;
  late String musicFile;
  late String rainFile;
  late List<FakeBusPlayer> players;
  bool slowLoading = false;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dndisc_instant_');
    musicFile = (File('${dir.path}/music.mp3')..writeAsBytesSync([0])).path;
    rainFile = (File('${dir.path}/rain.mp3')..writeAsBytesSync([0])).path;
    players = [];
    slowLoading = false;
    BusPlayer.debugFactory = (path) {
      final player = FakeBusPlayer(path);
      if (slowLoading) player.loading = Completer<void>();
      players.add(player);
      return player;
    };
  });

  tearDown(() {
    BusPlayer.debugFactory = null;
    dir.deleteSync(recursive: true);
  });

  const fade = Duration(milliseconds: 1500);

  group('Music', () {
    late MusicBusController music;
    late List<bool> notified;

    AudioTrack track() => AudioTrack(id: 't', title: 'Theme', filePath: musicFile);

    Future<void> startPlaying(WidgetTester tester) async {
      music = MusicBusController(defaultFadeDuration: fade);
      addTearDown(music.dispose);
      notified = [];
      music.addListener(() => notified.add(music.isPlaying));
      await music.playTrack(track(), fadeDuration: Duration.zero);
      notified.clear();
    }

    testWidgets('pause shows as paused at once and the sound fades out first', (tester) async {
      await startPlaying(tester);
      final player = players.single;

      unawaited(music.pause());
      expect(music.isPlaying, isFalse);
      expect(notified, [false]);
      expect(player.paused, isFalse);

      await tester.pump(fade ~/ 2);
      expect(player.volume, inExclusiveRange(0.0, 1.0));
      expect(player.paused, isFalse);

      await tester.pump(fade);
      expect(player.paused, isTrue);
      expect(player.volume, 0.0);
    });

    testWidgets('resume during the pause fade turns the sound back up without pausing it', (tester) async {
      await startPlaying(tester);
      final player = players.single;

      unawaited(music.pause());
      await tester.pump(fade ~/ 2);
      final low = player.volume;

      unawaited(music.resume());
      expect(music.isPlaying, isTrue);
      await tester.pump(fade * 2);

      expect(player.paused, isFalse);
      expect(player.volume, greaterThan(low));
      expect(player.volume, 1.0);
    });

    testWidgets('resume after a finished pause fades in from silence', (tester) async {
      await startPlaying(tester);
      final player = players.single;
      unawaited(music.pause());
      await tester.pump(fade * 2);

      unawaited(music.resume());
      expect(music.isPlaying, isTrue);
      await tester.pump();
      expect(player.paused, isFalse);
      expect(player.volume, lessThan(0.1));
      await tester.pump(fade * 2);
      expect(player.volume, 1.0);
    });

    testWidgets('stop clears the track at once and the sound fades out', (tester) async {
      await startPlaying(tester);
      final player = players.single;

      unawaited(music.stop());
      expect(music.isPlaying, isFalse);
      expect(music.currentTrack, isNull);
      expect(notified, [false]);
      expect(player.stopped, isFalse);

      await tester.pump(fade ~/ 2);
      expect(player.volume, inExclusiveRange(0.0, 1.0));

      await tester.pump(fade);
      expect(player.stopped, isTrue);
      expect(player.disposed, isTrue);
    });

    testWidgets('a new track right after stop starts while the old one fades out', (tester) async {
      await startPlaying(tester);
      final old = players.single;

      unawaited(music.stop());
      unawaited(music.playTrack(track()));
      await tester.pump(fade ~/ 2);

      expect(music.isPlaying, isTrue);
      expect(players, hasLength(2));
      expect(old.stopped, isFalse);
      await tester.pump(fade * 2);
      expect(old.disposed, isTrue);
      expect(players.last.audible, isTrue);
    });

    testWidgets('play shows as playing before the file has loaded', (tester) async {
      music = MusicBusController(defaultFadeDuration: fade);
      addTearDown(music.dispose);
      slowLoading = true;

      final done = music.playTrack(track());
      await tester.pump();
      expect(music.isPlaying, isTrue);
      expect(players.single.playing, isFalse);

      players.single.loading!.complete();
      await done;
      expect(players.single.audible, isTrue);
      await tester.pump(fade * 2);
    });

    testWidgets('pause while the file loads keeps the track paused once it has loaded', (tester) async {
      music = MusicBusController(defaultFadeDuration: fade);
      addTearDown(music.dispose);
      slowLoading = true;

      final done = music.playTrack(track());
      await tester.pump();
      unawaited(music.pause());
      expect(music.isPlaying, isFalse);

      players.single.loading!.complete();
      await done;
      await tester.pump(fade * 2);
      expect(players.single.paused, isTrue);
      expect(music.isPlaying, isFalse);
    });

    testWidgets('stop while the file loads frees the player and keeps the state stopped', (tester) async {
      music = MusicBusController(defaultFadeDuration: fade);
      addTearDown(music.dispose);
      slowLoading = true;

      final done = music.playTrack(track());
      await tester.pump();
      unawaited(music.stop());
      expect(music.isPlaying, isFalse);

      players.single.loading!.complete();
      await done;
      await tester.pump(fade * 2);
      expect(players.single.audible, isFalse);
      expect(music.isPlaying, isFalse);
      expect(music.currentTrack, isNull);
    });

    testWidgets('a scene change shows the next track at once and fades the playing one out', (tester) async {
      await startPlaying(tester);
      final player = players.single;

      unawaited(music.prepareTrack(AudioTrack(id: 'n', title: 'Next', filePath: musicFile)));
      expect(music.currentTrack!.id, 'n');
      expect(music.isPlaying, isFalse);
      expect(player.stopped, isFalse);

      await tester.pump(fade * 2);
      expect(player.disposed, isTrue);
    });
  });

  group('Ambient', () {
    late AmbientBusController ambient;

    AmbientLayer rain({bool active = false}) => AmbientLayer(id: 'rain', title: 'Rain', filePath: rainFile, isActive: active);

    testWidgets('a layer shows as off at once and its sound fades out', (tester) async {
      ambient = AmbientBusController(defaultFadeDuration: fade);
      addTearDown(ambient.dispose);
      ambient.addLayer(rain());
      await ambient.toggleLayer('rain', fadeDuration: Duration.zero);
      final player = players.single;

      final states = <bool>[];
      ambient.addListener(() => states.add(ambient.layers.single.isActive));
      unawaited(ambient.toggleLayer('rain'));
      expect(states.first, isFalse);
      expect(player.stopped, isFalse);

      await tester.pump(fade * 2);
      expect(player.stopped, isTrue);
    });

    testWidgets('turning a layer on while it fades out starts a new player that the old fade leaves alone', (tester) async {
      ambient = AmbientBusController(defaultFadeDuration: fade);
      addTearDown(ambient.dispose);
      ambient.addLayer(rain());
      await ambient.toggleLayer('rain', fadeDuration: Duration.zero);
      final first = players.single;

      unawaited(ambient.toggleLayer('rain'));
      await tester.pump(fade ~/ 2);
      await ambient.toggleLayer('rain');
      expect(ambient.layers.single.isActive, isTrue);
      final second = players.last;
      expect(second, isNot(same(first)));

      await tester.pump(fade * 2);
      expect(first.stopped, isTrue);
      expect(second.audible, isTrue);
      expect(second.volume, greaterThan(0));
    });

    testWidgets('turning a layer off while its file loads leaves it silent', (tester) async {
      ambient = AmbientBusController(defaultFadeDuration: Duration.zero);
      addTearDown(ambient.dispose);
      ambient.addLayer(rain());
      slowLoading = true;

      final on = ambient.toggleLayer('rain');
      await tester.pump();
      expect(ambient.layers.single.isActive, isTrue);
      await ambient.toggleLayer('rain');
      expect(ambient.layers.single.isActive, isFalse);

      players.single.loading!.complete();
      await on;
      expect(players.single.audible, isFalse);
    });

    testWidgets('stop all shows every layer as off at once', (tester) async {
      ambient = AmbientBusController(defaultFadeDuration: fade);
      addTearDown(ambient.dispose);
      ambient.addLayer(rain());
      await ambient.toggleLayer('rain', fadeDuration: Duration.zero);

      unawaited(ambient.stopAllLayers());
      expect(ambient.layers.single.isActive, isFalse);
      await tester.pump(fade * 2);
      expect(players.single.stopped, isTrue);
    });
  });

  group('SFX', () {
    testWidgets('a loop shows as playing before its file loads and as stopped at once', (tester) async {
      final sfx = SfxBusController();
      addTearDown(sfx.dispose);
      sfx.addTrigger(SfxTrigger(id: 'fire', title: 'Fire', filePath: rainFile, isLoop: true));
      slowLoading = true;

      final start = sfx.triggerSfx('fire');
      await tester.pump();
      expect(sfx.isTriggerLooping('fire'), isTrue);

      players.single.loading!.complete();
      await start;
      unawaited(sfx.triggerSfx('fire'));
      expect(sfx.isTriggerLooping('fire'), isFalse);
    });
  });
}
