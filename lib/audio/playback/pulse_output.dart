import 'dart:convert';
import 'dart:io';
import '../../services/logger_service.dart';
import '../audio_output_service.dart';
import 'process_env.dart';
import 'soloud_engine.dart';

/// Output devices of the Linux sound server (PulseAudio or PipeWire) through
/// `pactl`. flutter_soloud builds miniaudio without PulseAudio and plays
/// through ALSA, whose list has plugins instead of the user's outputs and no
/// Bluetooth devices. The engine plays one stream on the server; switching
/// moves that stream to another sink, and `PULSE_SINK` makes the stream
/// start there.
class PulseOutputBackend implements OutputDeviceBackend {
  final SoLoudEngine _engine;

  PulseOutputBackend([SoLoudEngine? engine]) : _engine = engine ?? SoLoudEngine.instance;

  /// Whether a sound server answers to `pactl`.
  static Future<bool> isAvailable() async {
    try {
      final result = await Process.run('pactl', ['info']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<OutputDevice>> listDevices() async {
    final defaultSink = await _pactl(['get-default-sink']);
    final json = await _pactl(['-f', 'json', 'list', 'sinks']);
    if (json != null) {
      try {
        return [
          for (final sink in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
            OutputDevice(
              sink['name'] as String,
              label: (sink['description'] as String?) ?? sink['name'] as String,
              isDefault: sink['name'] == defaultSink?.trim(),
            ),
        ];
      } catch (e) {
        LoggerService().warning('PulseOutputBackend: Could not read the sink list', details: '$e');
      }
    }
    // pactl before 16 has no JSON output: names only.
    final short = await _pactl(['list', 'short', 'sinks']) ?? '';
    return [
      for (final line in const LineSplitter().convert(short))
        if (line.split('\t').length > 1)
          OutputDevice(line.split('\t')[1], isDefault: line.split('\t')[1] == defaultSink?.trim()),
    ];
  }

  @override
  Future<bool> start({String? deviceId}) async {
    setProcessEnvironment('PULSE_SINK', deviceId);
    _engine.preferDevice(null);
    return _engine.ensureStarted();
  }

  @override
  Future<void> changeDevice(String? deviceId) async {
    setProcessEnvironment('PULSE_SINK', deviceId);
    final target = deviceId ?? (await _pactl(['get-default-sink']))?.trim();
    if (target == null || target.isEmpty) return;
    for (final input in await _ownStreams()) {
      final moved = await _pactl(['move-sink-input', '$input', target]);
      if (moved == null) throw StateError('Could not move the sound to "$target"');
    }
    LoggerService().info('PulseOutputBackend: Output moved to $target');
  }

  /// Streams of this process on the server (the engine plays one).
  Future<List<int>> _ownStreams() async {
    final json = await _pactl(['-f', 'json', 'list', 'sink-inputs']);
    if (json == null) return const [];
    try {
      final own = '$pid';
      return [
        for (final input in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
          if ((input['properties'] as Map?)?['application.process.id'] == own) input['index'] as int,
      ];
    } catch (e) {
      LoggerService().warning('PulseOutputBackend: Could not read the stream list', details: '$e');
      return const [];
    }
  }

  Future<String?> _pactl(List<String> args) async {
    try {
      final result = await Process.run('pactl', args);
      if (result.exitCode == 0) return result.stdout as String;
      LoggerService().warning('PulseOutputBackend: pactl ${args.join(' ')} failed', details: '${result.stderr}');
    } catch (e) {
      LoggerService().warning('PulseOutputBackend: pactl is not available', details: '$e');
    }
    return null;
  }
}
