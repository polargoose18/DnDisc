import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/analysis/bus_spectrum.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/playback/bus_player.dart';
import 'package:ttrpg_audio_player/audio/playback/soloud_engine.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/ui/design/equalizer_bars.dart';
import 'package:ttrpg_audio_player/ui/widgets/bus_equalizer.dart';
import '../helpers/fakes.dart';

/// 256 bus samples of a sine at [hz] with [amplitude] (1 is full scale).
Float32List toneWave(double hz, {double magnitude = 64}) {
  final amplitude = magnitude / 128;
  return Float32List.fromList([
    for (var i = 0; i < BusSpectrum.waveSize; i++) amplitude * math.sin(2 * math.pi * hz * i / BusSpectrum.sampleRate),
  ]);
}

int loudest(List<double> levels) {
  var best = 0;
  for (var i = 1; i < levels.length; i++) {
    if (levels[i] > levels[best]) best = i;
  }
  return best;
}

void main() {
  group('BusSpectrum.bandsFromWave', () {
    List<double> bands(Float32List wave) => BusSpectrum.bandsFromWave(wave, sampleRate: BusSpectrum.sampleRate, bands: 48);

    test('puts a tone in the band of its frequency on a log scale', () {
      final low = loudest(bands(toneWave(250)));
      final mid = loudest(bands(toneWave(2000)));
      final high = loudest(bands(toneWave(8000)));
      expect(low, lessThan(mid));
      expect(mid, lessThan(high));
      // 80 Hz .. 14 kHz over 48 bands: 2 kHz sits about 30 bands up.
      expect(mid, closeTo(48 * math.log(2000 / 80) / math.log(14000 / 80), 2));
    });

    test('shows pink noise (equal energy per octave) about level', () {
      // Pink noise: dense tones with power falling as 1/f, random phases.
      final rnd = math.Random(7);
      final wave = Float32List(BusSpectrum.waveSize);
      for (var hz = 40.0; hz < 16000; hz += 20) {
        final amplitude = 0.02 / math.sqrt(hz / 100);
        final phase = rnd.nextDouble() * 2 * math.pi;
        for (var i = 0; i < wave.length; i++) {
          wave[i] += amplitude * math.sin(2 * math.pi * hz * i / BusSpectrum.sampleRate + phase);
        }
      }
      final levels = bands(wave);
      double mean(Iterable<double> l) => l.reduce((a, b) => a + b) / l.length;
      final lowHalf = mean(levels.sublist(8, 24));
      final highHalf = mean(levels.sublist(24, 44));
      expect((lowHalf - highHalf).abs(), lessThan(0.15));
    });

    test('is empty for silence and near the top for a loud tone', () {
      expect(bands(Float32List(BusSpectrum.waveSize)).every((l) => l == 0), isTrue);
      expect(bands(toneWave(1000, magnitude: 128)).reduce(math.max), greaterThan(0.9));
    });
  });

  group('BusEqualizer', () {
    late Directory dir;
    late MusicBusController music;
    late AmbientBusController ambient;
    late Map<String, Float32List> busData;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('dndisc_bus_');
      BusPlayer.debugFactory = FakeBusPlayer.new;
      music = MusicBusController(defaultFadeDuration: Duration.zero);
      ambient = AmbientBusController(defaultFadeDuration: Duration.zero);
      busData = {};
      BusSpectrum.debugReader = (bus) => busData[bus];
    });

    tearDown(() {
      music.dispose();
      ambient.dispose();
      BusPlayer.debugFactory = null;
      BusSpectrum.debugReader = null;
      dir.deleteSync(recursive: true);
    });

    String file(String name) => (File('${dir.path}/$name')..writeAsBytesSync([0])).path;

    Widget harness(Widget child) => MaterialApp(
          theme: AppThemes.deepDark.toThemeData(),
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<MusicBusController>.value(value: music),
                ChangeNotifierProvider<AmbientBusController>.value(value: ambient),
              ],
              child: Center(child: SizedBox(width: 300, child: child)),
            ),
          ),
        );

    Future<void> frames(WidgetTester tester, [int n = 20]) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    List<double>? shown(WidgetTester tester, [Finder? within]) => tester
        .widget<EqualizerBars>(within == null ? find.byType(EqualizerBars) : find.descendant(of: within, matching: find.byType(EqualizerBars)))
        .levels;

    testWidgets('the music bars follow the music bus and nothing else', (tester) async {
      await music.playTrack(AudioTrack(id: 'm', title: 'Theme', filePath: file('theme.m4a')));
      busData[SoLoudEngine.musicBus] = toneWave(150, magnitude: 120);
      busData[SoLoudEngine.ambientBus('rain')] = toneWave(9000, magnitude: 120);

      await tester.pumpWidget(harness(const MusicEqualizer(bars: 4, height: 24)));
      await frames(tester);

      final levels = shown(tester)!;
      expect(levels[0], greaterThan(0.5), reason: 'the bass of the music');
      expect(levels[3], lessThan(levels[0]), reason: 'the highs of the ambient layer are not in the music bus');

      await music.stop();
      await tester.pump();
    });

    testWidgets('the bars sink when the bus goes quiet and the ticker stops', (tester) async {
      await music.playTrack(AudioTrack(id: 'm', title: 'Theme', filePath: file('theme.mp3')));
      busData[SoLoudEngine.musicBus] = toneWave(1000, magnitude: 120);
      await tester.pumpWidget(harness(const MusicEqualizer(bars: 4, height: 24)));
      await frames(tester);
      expect(shown(tester)!.reduce(math.max), greaterThan(0.5));

      await music.pause();
      busData[SoLoudEngine.musicBus] = Float32List(BusSpectrum.waveSize);
      await frames(tester, 40);
      expect(shown(tester)!.every((l) => l < 0.05), isTrue);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('each ambient layer shows its own bus next to its name', (tester) async {
      ambient.addLayer(AmbientLayer(id: 'rain', title: 'Rain', filePath: file('rain.mp3')));
      ambient.addLayer(AmbientLayer(id: 'wind', title: 'Wind', filePath: file('wind.mp3')));
      await ambient.toggleLayer('rain');
      await ambient.toggleLayer('wind');
      busData[SoLoudEngine.ambientBus('rain')] = toneWave(150, magnitude: 120);
      busData[SoLoudEngine.ambientBus('wind')] = toneWave(9000, magnitude: 120);

      await tester.pumpWidget(harness(const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmbientEqualizer(key: ValueKey('rain'), layerId: 'rain', height: 12),
          AmbientEqualizer(key: ValueKey('wind'), layerId: 'wind', height: 12),
        ],
      )));
      await frames(tester);

      final rain = shown(tester, find.byKey(const ValueKey('rain')))!;
      final wind = shown(tester, find.byKey(const ValueKey('wind')))!;
      expect(rain, hasLength(3));
      expect(loudest(rain), 0);
      expect(loudest(wind), 2);

      await ambient.stopAllLayers();
      await frames(tester, 40);
    });

    testWidgets('without bus data the motion is simulated as before', (tester) async {
      await music.playTrack(AudioTrack(id: 'm', title: 'Theme', filePath: file('theme.mp3')));
      await tester.pumpWidget(harness(const MusicEqualizer(bars: 4, height: 24)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(shown(tester), isNull);
      expect(tester.widget<EqualizerBars>(find.byType(EqualizerBars)).active, isTrue);
      await music.stop();
      await tester.pump();
    });
  });
}
