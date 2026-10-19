import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/services/database_service.dart';
import '../services/logger_service.dart';
import 'playback/linux_stream_volume.dart';
import 'playback/soloud_engine.dart';

/// Output device: [id] is stored and passed to the backend, [label] is shown.
@immutable
class OutputDevice {
  final String id;
  final String label;
  final bool isDefault;

  const OutputDevice(this.id, {String? label, this.isDefault = false}) : label = label ?? id;

  @override
  bool operator ==(Object other) =>
      other is OutputDevice && other.id == id && other.label == label && other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(id, label, isDefault);
}

/// Where [AudioOutputService] lists and switches devices.
abstract class OutputDeviceBackend {
  Future<List<OutputDevice>> listDevices();

  /// Starts the audio output, on [deviceId] when it is connected.
  Future<bool> start({String? deviceId});

  /// Moves the sound to [deviceId] (null: system default) while it plays.
  Future<void> changeDevice(String? deviceId);
}

/// Devices of the SoLoud engine: WASAPI endpoints on Windows, the outputs
/// of the sound server (PulseAudio or PipeWire) on Linux.
class SoLoudOutputBackend implements OutputDeviceBackend {
  final SoLoudEngine _engine;

  SoLoudOutputBackend([SoLoudEngine? engine]) : _engine = engine ?? SoLoudEngine.instance;

  @override
  Future<List<OutputDevice>> listDevices() async =>
      [for (final d in _engine.listDevices()) OutputDevice(d.name, isDefault: d.isDefault)];

  @override
  Future<bool> start({String? deviceId}) {
    _engine.preferDevice(deviceId);
    return _engine.ensureStarted();
  }

  @override
  Future<void> changeDevice(String? deviceId) => _engine.changeDevice(deviceId);
}

/// The volume the sound server keeps for this app's stream (Linux).
abstract class StreamVolume {
  Future<List<({int index, bool silent})>> ownStreams();
  Future<bool> restore(int index);
}

class PactlStreamVolume implements StreamVolume {
  const PactlStreamVolume();

  @override
  Future<List<({int index, bool silent})>> ownStreams() => LinuxStreamVolume.ownStreams();

  @override
  Future<bool> restore(int index) => LinuxStreamVolume.restore(index);
}

/// Choice of the output device on Linux and Windows (Android has a single
/// output). The choice is stored by device name; null is the system default.
class AudioOutputService extends ChangeNotifier {
  static const String settingKey = 'output_device';

  /// Set once the silenced stream volume left by builds before SoLoud has
  /// been reset; later a silenced stream is the user's choice and is only
  /// reported.
  static const String streamVolumeResetKey = 'stream_volume_reset_v1';

  /// How long to wait for the engine's stream to appear on the server.
  static const Duration streamLookup = Duration(milliseconds: 200);
  static const int streamLookupTries = 10;

  OutputDeviceBackend? _backend;
  final DatabaseService? _db;
  final bool isSupported;

  List<OutputDevice> _devices = const [];
  String? _selected;
  bool _missing = false;

  final StreamVolume? _streamVolume;
  final StreamController<void> _silenced = StreamController.broadcast();

  AudioOutputService({OutputDeviceBackend? backend, DatabaseService? db, bool? supported, StreamVolume? streamVolume})
      : _backend = backend,
        _db = db,
        // The real sound server only with the real backend (not in tests).
        _streamVolume = streamVolume ?? (backend == null && !kIsWeb && Platform.isLinux ? const PactlStreamVolume() : null),
        isSupported = supported ?? (!kIsWeb && (Platform.isLinux || Platform.isWindows));

  /// The system mixer has this app at 0 % or muted: playback is inaudible.
  Stream<void> get systemSilenced => _silenced.stream;

  List<OutputDevice> get devices => _devices;

  /// Id of the chosen device; null follows the system default.
  String? get selectedDevice => _selected;

  /// Label of the chosen device, or its id when it is not connected.
  String? get selectedLabel {
    for (final d in _devices) {
      if (d.id == _selected) return d.label;
    }
    return _selected;
  }

  /// The saved device is not connected now; sound goes to the default.
  bool get selectedIsMissing => _missing;

  /// Restores the saved device and starts the output on it.
  Future<void> init() async {
    final backend = _backend ??= SoLoudOutputBackend();
    if (isSupported) {
      try {
        final saved = await _db?.getSetting(settingKey);
        _selected = (saved == null || saved.isEmpty) ? null : saved;
      } catch (e) {
        LoggerService().warning('AudioOutputService: Could not read the saved device', details: '$e');
      }
    }
    // SoLoud lists its devices only once the output has started.
    await backend.start(deviceId: _selected);
    await refresh();
    await checkStreamVolume();
  }

  /// Looks at the volume the sound server gives this app's stream: the
  /// first time, a silenced stream (left by builds before SoLoud) is reset
  /// to 100 %; after that it is reported on [systemSilenced].
  Future<void> checkStreamVolume() async {
    final volume = _streamVolume;
    if (volume == null) return;
    var streams = await volume.ownStreams();
    for (var i = 1; i < streamLookupTries && streams.isEmpty; i++) {
      await Future<void>.delayed(streamLookup);
      streams = await volume.ownStreams();
    }
    if (streams.isEmpty) return;
    final silenced = [for (final s in streams) if (s.silent) s.index];
    var resetDone = false;
    try {
      resetDone = await _db?.getSetting(streamVolumeResetKey) == '1';
    } catch (_) {}
    if (silenced.isNotEmpty && !resetDone) {
      for (final index in silenced) {
        final ok = await volume.restore(index);
        LoggerService().info('AudioOutputService: Stream volume was 0 %, ${ok ? 'reset to 100 %' : 'could not reset it'}');
        if (!ok && !_silenced.isClosed) _silenced.add(null);
      }
    } else if (silenced.isNotEmpty) {
      LoggerService().warning('AudioOutputService: The system mixer has this app at 0 % or muted');
      if (!_silenced.isClosed) _silenced.add(null);
    }
    try {
      await _db?.setSetting(streamVolumeResetKey, '1');
    } catch (_) {}
  }

  /// Reads the device list again (a headset was plugged in).
  Future<void> refresh() async {
    final backend = _backend;
    if (!isSupported || backend == null) return;
    _devices = await backend.listDevices();
    _missing = _selected != null && !_devices.any((d) => d.id == _selected);
    notifyListeners();
  }

  /// Moves playback to [id] (null: system default) and remembers it.
  Future<void> select(String? id) async {
    final backend = _backend;
    if (!isSupported || backend == null) return;
    await backend.changeDevice(id);
    _selected = id;
    // A new device gets a new stream, with the volume the server keeps.
    unawaited(checkStreamVolume());
    _missing = false;
    try {
      await _db?.setSetting(settingKey, id ?? '');
    } catch (e) {
      LoggerService().warning('AudioOutputService: Could not save the device', details: '$e');
    }
    notifyListeners();
  }
}
