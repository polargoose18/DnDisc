import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/playback/bus_player.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import '../helpers/fakes.dart';

void main() {
  late Directory dir;
  late String file;
  late List<FakeBusPlayer> players;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dndisc_loop_');
    file = (File('${dir.path}/loop.mp3')..writeAsBytesSync([0])).path;
    players = [];
    BusPlayer.debugFactory = (path) {
      final player = FakeBusPlayer(path);
      players.add(player);
      return player;
    };
  });

  tearDown(() {
    BusPlayer.debugFactory = null;
    dir.deleteSync(recursive: true);
  });

  group('Music loops on one voice', () {
    late MusicBusController music;

    setUp(() {
      music = MusicBusController();
      addTearDown(music.dispose);
    });

    test('the voice loops the whole file and no second player appears near the end', () async {
      await music.playTrack(AudioTrack(id: 't', title: 'T', filePath: file), fadeDuration: Duration.zero);
      final player = players.single;
      expect(player.looping, isTrue);
      expect(player.loopStart, Duration.zero);
      expect(player.loopEnd, isNull);

      player.emitDuration(const Duration(seconds: 60));
      player.emitPosition(const Duration(seconds: 59));
      await Future<void>.delayed(Duration.zero);
      expect(players, hasLength(1));
      expect(music.position.value, const Duration(seconds: 59));
    });

    test('the loop region of the track is handed to the voice', () async {
      await music.playTrack(
        AudioTrack(id: 't', title: 'T', filePath: file, loopStartMs: 5000, loopEndMs: 175000),
        fadeDuration: Duration.zero,
      );
      expect(players.single.loopStart, const Duration(seconds: 5));
      expect(players.single.loopEnd, const Duration(seconds: 175));
    });

    test('an end before the start is ignored and the loop runs to the end of the file', () async {
      await music.playTrack(
        AudioTrack(id: 't', title: 'T', filePath: file, loopStartMs: 9000, loopEndMs: 4000),
        fadeDuration: Duration.zero,
      );
      expect(players.single.loopStart, const Duration(seconds: 9));
      expect(players.single.loopEnd, isNull);
    });

    test('a voice that ends anyway is started again on the same player', () async {
      await music.playTrack(AudioTrack(id: 't', title: 'T', filePath: file), fadeDuration: Duration.zero);
      final player = players.single;
      expect(player.plays, 1);

      player.emitComplete();
      await Future<void>.delayed(Duration.zero);
      expect(players, hasLength(1));
      expect(player.plays, 2);
    });
  });

  group('Ambient layers loop on one voice', () {
    test('a layer loops and is restarted in place when its voice ends', () async {
      final ambient = AmbientBusController(defaultFadeDuration: Duration.zero);
      addTearDown(ambient.dispose);
      ambient.addLayer(AmbientLayer(id: 'rain', title: 'Rain', filePath: file, isActive: true));
      await Future<void>.delayed(Duration.zero);

      final player = players.single;
      expect(player.looping, isTrue);

      player.emitPosition(const Duration(seconds: 59));
      player.emitComplete();
      await Future<void>.delayed(Duration.zero);
      expect(players, hasLength(1));
      expect(player.plays, 2);
    });
  });
}
