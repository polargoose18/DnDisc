// Proves that sound leaves the app and arrives at an output device.
//
// Run through tool/ci/audio_output_test.sh, which starts PipeWire with two
// virtual null sinks (see the AUDIO_* variables below). The test plays a
// generated sine WAV through the real SoLoud engine on the music bus, an
// ambient bus and the plain SFX path, records the sink's monitor with
// `parec` and checks the signal level and the frequency of what arrived.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ttrpg_audio_player/audio/playback/bus_player.dart';
import 'package:ttrpg_audio_player/audio/playback/linux_stream_volume.dart';
import 'package:ttrpg_audio_player/audio/playback/soloud_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const int _rate = 44100;

String _env(String name, String fallback) =>
    Platform.environment[name] ?? fallback;

/// Monitor source of the sink the engine is expected to play to.
final String _monitorA = _env('AUDIO_MONITOR_A', 'ci_sink_a.monitor');

/// Monitor of the second sink, the target of the device switch.
final String _monitorB = _env('AUDIO_MONITOR_B', 'ci_sink_b.monitor');

/// Part of the description of the second sink, to find it in the device list.
final String _deviceBName = _env('AUDIO_DEVICE_B_NAME', 'CiSinkB');

/// Normalised RMS (0..1) a tone must reach to count as heard. The tones are
/// played at amplitude 0.5, which is an RMS of about 0.35.
const double _minRms = 0.05;

const double _musicHz = 440;
const double _ambientHz = 660;
const double _sfxHz = 880;

Uint8List _sineWav(double hz, {double seconds = 4, double amplitude = 0.5}) {
  final samples = (_rate * seconds).round();
  final data = ByteData(44 + samples * 2);
  void tag(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, 36 + samples * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, _rate, Endian.little);
  data.setUint32(28, _rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  for (var i = 0; i < samples; i++) {
    final v =
        (math.sin(2 * math.pi * hz * i / _rate) * amplitude * 32767).round();
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Records a monitor source with parec (16 bit mono PCM).
class _Recording {
  final Process _process;
  final BytesBuilder _bytes = BytesBuilder(copy: false);
  late final StreamSubscription<List<int>> _sub;

  _Recording._(this._process) {
    _sub = _process.stdout.listen(_bytes.add);
  }

  static Future<_Recording> start(String monitor) async {
    final process = await Process.start('parec', [
      '-d', monitor, '--raw', '--format=s16le', '--rate=$_rate', '--channels=1',
      '--latency-msec=20', //
    ]);
    unawaited(process.stderr.drain<void>());
    return _Recording._(process);
  }

  /// Stops and returns the samples, -1..1.
  Future<Float64List> stop() async {
    _process.kill(ProcessSignal.sigterm);
    await _process.exitCode;
    await _sub.cancel();
    final raw = _bytes.takeBytes();
    final view = ByteData.sublistView(raw);
    final out = Float64List(raw.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = view.getInt16(i * 2, Endian.little) / 32768;
    }
    return out;
  }
}

double _rms(Float64List s, [int from = 0, int? to]) {
  to ??= s.length;
  if (to <= from) return 0;
  var sum = 0.0;
  for (var i = from; i < to; i++) {
    sum += s[i] * s[i];
  }
  return math.sqrt(sum / (to - from));
}

/// Share of the signal power that sits within a few Hz of [hz] (Hann-windowed
/// Goertzel, so a slightly off-grid tone still counts); near 1 for a pure
/// tone, near 0 for silence or another tone.
double _toneShare(Float64List s, double hz) {
  if (s.isEmpty) return 0;
  final n = s.length;
  final windowed = Float64List(n);
  var total = 0.0, windowPower = 0.0, windowSum = 0.0;
  for (var i = 0; i < n; i++) {
    final w = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
    windowed[i] = s[i] * w;
    total += windowed[i] * windowed[i];
    windowPower += w * w;
    windowSum += w;
  }
  if (total == 0) return 0;
  var best = 0.0;
  for (var f = hz - 4; f <= hz + 4; f += 1) {
    final coeff = 2 * math.cos(2 * math.pi * f / _rate);
    var s1 = 0.0, s2 = 0.0;
    for (final x in windowed) {
      final s0 = x + coeff * s1 - s2;
      s2 = s1;
      s1 = s0;
    }
    final power = s1 * s1 + s2 * s2 - coeff * s1 * s2;
    // A pure sine gives |X|^2 = total * windowSum^2 / (2 * windowPower).
    best = math.max(
        best, power / (total * windowSum * windowSum / (2 * windowPower)));
  }
  return best;
}

Future<void> _commandOk(String exe, List<String> args) async {
  final r = await Process.run(exe, args);
  if (r.exitCode != 0) fail('$exe ${args.join(' ')} failed: ${r.stderr}');
}

Future<Float64List> _record(
    String monitor, Future<void> Function() whilePlaying,
    {Duration settle = const Duration(milliseconds: 1200)}) async {
  final recording = await _Recording.start(monitor);
  await Future<void>.delayed(const Duration(milliseconds: 300));
  Float64List samples;
  try {
    await whilePlaying();
    await Future<void>.delayed(settle);
  } finally {
    samples = await recording.stop();
  }
  return samples;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String musicWav, ambientWav, sfxWav;
  final engine = SoLoudEngine.instance;
  final players = <BusPlayer>[];

  Future<BusPlayer> play(String path, {String? bus, bool loop = false}) async {
    final player = BusPlayer.forFile(path, bus: bus);
    players.add(player);
    await player.setLooping(loop);
    await player.play(path);
    return player;
  }

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('audio_out_');
    Future<String> write(String name, double hz) async {
      final f = File('${tmp.path}/$name.wav');
      await f.writeAsBytes(_sineWav(hz));
      return f.path;
    }

    musicWav = await write('music', _musicHz);
    ambientWav = await write('ambient', _ambientHz);
    sfxWav = await write('sfx', _sfxHz);
    // The sound server must be the one of the script: a quiet virtual sink.
    final started = await engine.ensureStarted();
    expect(started, isTrue, reason: 'SoLoud must start on the virtual output');
  });

  tearDown(() async {
    for (final p in players) {
      await p.dispose();
    }
    players.clear();
    // Leave the default device for the next test.
    try {
      await engine.changeDevice(null);
    } catch (_) {}
  });

  tearDownAll(() async {
    await tmp.delete(recursive: true);
  });

  test('the virtual sink is silent when nothing plays', () async {
    final samples = await _record(_monitorA, () async {},
        settle: const Duration(milliseconds: 800));
    expect(samples.length, greaterThan(_rate ~/ 4),
        reason: 'parec must deliver samples from $_monitorA');
    expect(_rms(samples), lessThan(0.001));
  });

  for (final c
      in <({String name, String Function() path, String? bus, double hz})>[
    (
      name: 'music',
      path: () => musicWav,
      bus: SoLoudEngine.musicBus,
      hz: _musicHz
    ),
    (
      name: 'ambient',
      path: () => ambientWav,
      bus: SoLoudEngine.ambientBus('ci'),
      hz: _ambientHz
    ),
    (name: 'sfx', path: () => sfxWav, bus: null, hz: _sfxHz),
  ]) {
    test('${c.name} reaches the output device', () async {
      final samples = await _record(_monitorA, () async {
        await play(c.path(), bus: c.bus, loop: true);
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      // Skip the first 300 ms: the stream is still starting.
      const from = _rate ~/ 3;
      final level = _rms(samples, from);
      final share = _toneShare(Float64List.sublistView(samples, from), c.hz);
      // ignore: avoid_print
      print(
          '${c.name}: rms=${level.toStringAsFixed(4)} toneShare@${c.hz}=${share.toStringAsFixed(3)}');
      expect(level, greaterThan(_minRms),
          reason: '${c.name} is silent at the output');
      expect(share, greaterThan(0.5),
          reason: '${c.name} arrives, but is not the tone that was played');
    });
  }

  test('the stream volume of the app is not 0 % or muted while playing',
      () async {
    await play(musicWav, bus: SoLoudEngine.musicBus, loop: true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final streams = await LinuxStreamVolume.ownStreams();
    expect(streams, isNotEmpty,
        reason: 'the server must show a stream of this process');
    for (final s in streams) {
      expect(s.silent, isFalse, reason: 'stream ${s.index} is at 0 % or muted');
    }
  });

  test('a stream the server left at 0 % is detected and restored', () async {
    await play(musicWav, bus: SoLoudEngine.musicBus, loop: true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final streams = await LinuxStreamVolume.ownStreams();
    expect(streams, isNotEmpty);
    final index = streams.first.index;
    await _commandOk('pactl', ['set-sink-input-volume', '$index', '0%']);
    final silent = await _record(_monitorA,
        () async => await Future<void>.delayed(const Duration(seconds: 1)));
    expect(_rms(silent, _rate ~/ 3), lessThan(0.001),
        reason: 'at 0 % nothing may arrive (test of the test)');
    expect(
        (await LinuxStreamVolume.ownStreams())
            .firstWhere((s) => s.index == index)
            .silent,
        isTrue);
    expect(await LinuxStreamVolume.restore(index), isTrue);
    final loud = await _record(_monitorA,
        () async => await Future<void>.delayed(const Duration(seconds: 1)));
    expect(_rms(loud, _rate ~/ 3), greaterThan(_minRms),
        reason: 'restore must bring the sound back');
  });

  test('switching the output device does not cut the sound', () async {
    final devices = engine.listDevices();
    final target = devices.where((d) => d.name.contains(_deviceBName)).toList();
    expect(target, isNotEmpty,
        reason:
            'device "$_deviceBName" missing; devices: ${devices.map((d) => d.name).join(', ')}');
    await play(musicWav, bus: SoLoudEngine.musicBus, loop: true);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Before the switch the sound is on sink A and not on sink B.
    final recA = await _Recording.start(_monitorA);
    final recB = await _Recording.start(_monitorB);
    await Future<void>.delayed(const Duration(seconds: 1));
    await engine.changeDevice(target.first.name);
    await Future<void>.delayed(const Duration(seconds: 2));
    final a = await recA.stop();
    final b = await recB.stop();

    final beforeA = _rms(a, _rate ~/ 4, _rate * 9 ~/ 10);
    expect(beforeA, greaterThan(_minRms),
        reason: 'no sound on the first sink before the switch');
    final afterB = _rms(b, b.length - _rate); // last second
    expect(afterB, greaterThan(_minRms),
        reason: 'the sound did not follow to the second sink');
    expect(_toneShare(Float64List.sublistView(b, b.length - _rate), _musicHz),
        greaterThan(0.5));
    final afterA = _rms(a, a.length - _rate);
    expect(afterA, lessThan(0.001),
        reason: 'the first sink still gets sound after the switch');
    // Voice is still the same one playing: the stream exists and is audible.
    final streams = await LinuxStreamVolume.ownStreams();
    expect(streams, isNotEmpty);
    expect(streams.any((s) => s.silent), isFalse);

    // And back to the first device.
    await engine.changeDevice(null);
    final back = await _record(_monitorA,
        () async => await Future<void>.delayed(const Duration(seconds: 1)));
    expect(_rms(back, _rate ~/ 2), greaterThan(_minRms),
        reason: 'the sound did not come back to the default sink');
  });
}
