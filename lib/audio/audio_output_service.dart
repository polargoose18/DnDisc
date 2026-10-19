import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/services/database_service.dart';
import '../services/logger_service.dart';
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

/// Choice of the output device on Linux and Windows (Android has a single
/// output). The choice is stored by device name; null is the system default.
class AudioOutputService extends ChangeNotifier {
  static const String settingKey = 'output_device';

  OutputDeviceBackend? _backend;
  final DatabaseService? _db;
  final bool isSupported;

  List<OutputDevice> _devices = const [];
  String? _selected;
  bool _missing = false;

  AudioOutputService({OutputDeviceBackend? backend, DatabaseService? db, bool? supported})
      : _backend = backend,
        _db = db,
        isSupported = supported ?? (!kIsWeb && (Platform.isLinux || Platform.isWindows));

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
    _missing = false;
    try {
      await _db?.setSetting(settingKey, id ?? '');
    } catch (e) {
      LoggerService().warning('AudioOutputService: Could not save the device', details: '$e');
    }
    notifyListeners();
  }
}
