import 'dart:convert';
import 'dart:io';
import '../../services/logger_service.dart';

/// Volume the Linux sound server (PulseAudio, or PipeWire through it) keeps
/// for this app's stream, read and set through `pactl`.
///
/// The server remembers the last volume of an app and gives it to its next
/// stream. Builds that played through audioplayers set that volume from
/// their fades (GStreamer drives the stream volume), so a stop at the end
/// of a fade-out could leave it at 0 %, and SoLoud, which never touches the
/// stream volume, then played silently.
abstract class LinuxStreamVolume {
  /// Streams of this process on the server, and whether each is silenced
  /// (0 % or muted).
  static Future<List<({int index, bool silent})>> ownStreams() async {
    final json = await _pactl(['-f', 'json', 'list', 'sink-inputs']);
    if (json == null) return const [];
    try {
      final own = '$pid';
      return [
        for (final input in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
          if ((input['properties'] as Map?)?['application.process.id'] == own)
            (index: input['index'] as int, silent: _isSilent(input)),
      ];
    } catch (e) {
      LoggerService().warning('LinuxStreamVolume: Could not read the stream list', details: '$e');
      return const [];
    }
  }

  static bool _isSilent(Map<String, dynamic> input) {
    if (input['mute'] == true) return true;
    final channels = (input['volume'] as Map?)?.values ?? const [];
    return channels.isNotEmpty && channels.every((c) => c is Map && c['value'] == 0);
  }

  /// Unmutes [index] and sets it to 100 %.
  static Future<bool> restore(int index) async {
    final unmuted = await _pactl(['set-sink-input-mute', '$index', '0']);
    final raised = await _pactl(['set-sink-input-volume', '$index', '100%']);
    return unmuted != null && raised != null;
  }

  static Future<String?> _pactl(List<String> args) async {
    try {
      final result = await Process.run('pactl', args);
      if (result.exitCode == 0) return result.stdout as String;
      LoggerService().warning('LinuxStreamVolume: pactl ${args.join(' ')} failed', details: '${result.stderr}');
    } catch (e) {
      LoggerService().warning('LinuxStreamVolume: pactl is not available', details: '$e');
    }
    return null;
  }
}
