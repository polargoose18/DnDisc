import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ttrpg_audio_player/audio/analysis/music_spectrum_service.dart';
import 'package:ttrpg_audio_player/audio/analysis/spectrogram.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/playback/bus_player.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/ui/design/equalizer_bars.dart';
import 'package:ttrpg_audio_player/ui/widgets/music_equalizer.dart';
import '../helpers/fakes.dart';

Float32List tone(double hz, double seconds, double rate) =>
    Float32List.fromList([for (var i = 0; i < (seconds * rate).round(); i++) 0.5 * math.sin(2 * math.pi * hz * i / rate)]);

int loudest(List<double> levels) {
  var best = 0;
  for (var i = 1; i < levels.length; i++) {
    if (levels[i] > levels[best]) best = i;
  }
  return best;
}

/// Band `b` of 48 between 50 Hz and 95% of Nyquist holds this frequency.
int bandOf(double hz, double rate) => (48 * math.log(hz / 50) / math.log(rate / 2 * 0.95 / 50)).floor();

void main() {
  group('computeSpectrogram', () {
    const rate = 8000.0;

    test('puts a tone in its band and follows a change of tone over time', () {
      final samples = Float32List.fromList([...tone(220, 2, rate), ...tone(2000, 2, rate)]);
      final spectrum = computeSpectrogram(samples, rate);

      expect(spectrum.bands, 48);
      expect(spectrum.length.inMilliseconds, closeTo(4000, 100));
      expect(loudest(spectrum.levelsAt(const Duration(milliseconds: 1000))), closeTo(bandOf(220, rate), 1));
      expect(loudest(spectrum.levelsAt(const Duration(milliseconds: 3000))), closeTo(bandOf(2000, rate), 1));
    });

    test('keeps silence low and the loud parts near the top of the scale', () {
      final samples = Float32List.fromList([...Float32List(16000), ...tone(440, 2, rate)]);
      final spectrum = computeSpectrogram(samples, rate);

      expect(spectrum.levelsAt(const Duration(milliseconds: 1000)).reduce(math.max), lessThan(0.05));
      expect(spectrum.levelsAt(const Duration(milliseconds: 3000)).reduce(math.max), greaterThan(0.9));
    });

    test('is silent outside the track', () {
      final spectrum = computeSpectrogram(tone(440, 1, rate), rate);
      expect(spectrum.levelsAt(const Duration(seconds: 5)).every((l) => l == 0), isTrue);
      expect(spectrum.levelsAt(const Duration(seconds: -1)).every((l) => l == 0), isTrue);
    });
  });

  group('MusicSpectrumService and MusicEqualizer', () {
    late Directory dir;
    late List<FakeBusPlayer> players;
    late List<String> analysed;
    late MusicBusController music;
    late MusicSpectrumService service;

    // Bands 0-23 loud in the first second, 24-47 loud after it.
    Spectrogram fakeSpectrum() => Spectrogram(
          bands: 48,
          framesPerSecond: 10,
          data: Uint8List.fromList([
            for (var f = 0; f < 100; f++)
              for (var b = 0; b < 48; b++) (f < 10) == (b < 24) ? 255 : 0,
          ]),
        );

    setUp(() {
      dir = Directory.systemTemp.createTempSync('dndisc_spectrum_');
      players = [];
      analysed = [];
      BusPlayer.debugFactory = (path) {
        final p = FakeBusPlayer(path);
        players.add(p);
        return p;
      };
      music = MusicBusController(defaultFadeDuration: Duration.zero);
      service = MusicSpectrumService(
        music: music,
        analyzer: (path, length) async {
          analysed.add(path);
          return fakeSpectrum();
        },
      );
    });

    tearDown(() {
      service.dispose();
      music.dispose();
      BusPlayer.debugFactory = null;
      dir.deleteSync(recursive: true);
    });

    String file(String name) => (File('${dir.path}/$name')..writeAsBytesSync([0])).path;

    Future<void> play(WidgetTester tester, String path) async {
      await music.playTrack(AudioTrack(id: path, title: 'Theme', filePath: path));
      players.last.emitDuration(const Duration(seconds: 10));
      players.last.emitPosition(const Duration(milliseconds: 1));
      await tester.pump();
    }

    testWidgets('analyses the track once it plays and reuses the result', (tester) async {
      final path = file('theme.mp3');
      expect(service.current, isNull);

      await play(tester, path);
      expect(analysed, [path]);
      expect(service.current, isNotNull);

      await music.stop();
      await play(tester, path);
      expect(analysed, [path], reason: 'cached');
    });

    testWidgets('does not analyse files SoLoud cannot decode (M4A)', (tester) async {
      await play(tester, file('theme.m4a'));
      expect(analysed, isEmpty);
      expect(service.current, isNull);
    });

    Widget harness() => MaterialApp(
          theme: AppThemes.deepDark.toThemeData(),
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<MusicBusController>.value(value: music),
                ChangeNotifierProvider<MusicSpectrumService>.value(value: service),
              ],
              child: const Center(child: SizedBox(width: 300, child: MusicEqualizer(bars: 4, height: 24))),
            ),
          ),
        );

    List<double>? shown(WidgetTester tester) => tester.widget<EqualizerBars>(find.byType(EqualizerBars)).levels;

    testWidgets('the bars follow the spectrum at the playback position', (tester) async {
      await play(tester, file('theme.mp3'));
      await tester.pumpWidget(harness());
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // First second: the low half is loud.
      var levels = shown(tester)!;
      expect(levels[0], greaterThan(0.8));
      expect(levels[3], lessThan(0.2));

      players.last.emitPosition(const Duration(seconds: 3));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      levels = shown(tester)!;
      expect(levels[0], lessThan(0.2));
      expect(levels[3], greaterThan(0.8));

      await music.stop();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the bars sink when the music stops', (tester) async {
      await play(tester, file('theme.mp3'));
      await tester.pumpWidget(harness());
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(shown(tester)![0], greaterThan(0.8));

      await music.pause();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(shown(tester)!.every((l) => l < 0.05), isTrue);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('without a spectrum the motion is simulated as before', (tester) async {
      await play(tester, file('theme.m4a'));
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 100));
      expect(shown(tester), isNull);
      expect(tester.widget<EqualizerBars>(find.byType(EqualizerBars)).active, isTrue);
      await music.stop();
      await tester.pump();
    });
  });
}
