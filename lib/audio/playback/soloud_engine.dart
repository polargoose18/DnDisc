import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../analysis/bus_spectrum.dart';
import '../../services/logger_service.dart';

/// The single SoLoud engine of the app: starts it on the chosen output
/// device, switches devices on the fly, shares loaded files between voices
/// (a crossfade plays the same file twice) and keeps the mixing buses the
/// visualizers read: one for music and one per ambient layer.
class SoLoudEngine {
  SoLoudEngine._();

  static final SoLoudEngine instance = SoLoudEngine._();

  /// Files up to this size are decoded into memory (short SFX start without
  /// delay); longer ones are streamed from disk.
  static const int memoryLoadLimitBytes = 2 * 1024 * 1024;

  /// Bus of the music voices.
  static const String musicBus = 'music';

  /// Bus of the voices of ambient layer [layerId].
  static String ambientBus(String layerId) => 'ambient:$layerId';

  Future<bool>? _starting;
  final Map<String, Bus> _buses = {};
  final StreamController<String> _loadFailures = StreamController.broadcast();

  /// Paths of files that could not be loaded (unsupported or broken file,
  /// or on Linux an M4A without the system FFmpeg libraries).
  Stream<String> get loadFailures => _loadFailures.stream;

  @visibleForTesting
  void debugReportLoadFailure(String path) => _loadFailures.add(path);
  String? _deviceName;
  final Map<String, _LoadedSource> _sources = {};
  final Map<String, Future<void>> _disposing = {};

  bool _started = false;

  /// The engine has started (never in tests, which have no native library).
  bool get isReady => _started && _soloud.isInitialized;

  SoLoud get _soloud => SoLoud.instance;

  /// Starts the engine once; later calls wait for the same start. Returns
  /// false when there is no output device.
  Future<bool> ensureStarted() => _starting ??= _start();

  /// Device to open on start, matched by name (ids change between runs).
  void preferDevice(String? name) => _deviceName = name;

  // Starts on the system default and then moves to the preferred device
  // (ids change between runs, so the device is matched by name). On Linux
  // the sound server (PulseAudio, or PipeWire through it) lists the real
  // outputs, Bluetooth included; ALSA alone lists its plugins.
  Future<bool> _start() async {
    try {
      if (!kIsWeb && Platform.isLinux) {
        try {
          await _soloud.init(linuxAudioBackend: LinuxAudioBackend.pulseAudio);
        } catch (e) {
          LoggerService().warning('SoLoudEngine: No sound server, using ALSA', details: '$e');
          await _soloud.init();
        }
      } else {
        await _soloud.init();
      }
    } catch (e) {
      LoggerService().error('SoLoudEngine: Could not start the audio output', details: '$e');
      _starting = null;
      return false;
    }
    _started = true;
    LoggerService().info('SoLoudEngine: Started on the system default device');
    final name = _deviceName;
    if (name != null) {
      try {
        await changeDevice(name);
      } catch (e) {
        LoggerService().warning('SoLoudEngine: Staying on the system default device', details: '$e');
      }
    }
    return true;
  }

  /// The bus [key], created and started on first use. Null before the
  /// engine has started.
  Bus? bus(String key) {
    if (!isReady) return null;
    final existing = _buses[key];
    if (existing != null) return existing;
    final created = Bus(name: key);
    created.playOnEngine();
    BusSpectrumNative.enable(created.busId);
    return _buses[key] = created;
  }

  /// Id of the bus [key] if something has played through it.
  int? busId(String key) => isReady ? _buses[key]?.busId : null;

  /// Output devices of the system; empty until the engine has started.
  List<PlaybackDevice> listDevices() {
    if (!isReady) return const [];
    try {
      return _soloud.listPlaybackDevices();
    } catch (e) {
      LoggerService().warning('SoLoudEngine: Could not list output devices', details: '$e');
      return const [];
    }
  }

  PlaybackDevice? _findDevice(String? name) {
    if (name == null) return null;
    for (final device in listDevices()) {
      if (device.name == name) return device;
    }
    return null;
  }

  /// Moves playback to the device called [name] (null: system default)
  /// without stopping the sounds. Throws when the device is gone.
  Future<void> changeDevice(String? name) async {
    _deviceName = name;
    if (!isReady) return;
    final device = _findDevice(name);
    if (name != null && device == null) throw StateError('Output device "$name" is not available');
    await _soloud.changeDevice(newDevice: device);
    LoggerService().info('SoLoudEngine: Output moved to ${name ?? 'the system default device'}');
  }

  /// Loads [path] or reuses it when another voice already holds it.
  Future<AudioSource> acquire(String path) async {
    final pending = _disposing[path];
    if (pending != null) await pending;
    final entry = _sources.putIfAbsent(path, () => _LoadedSource(_load(path)));
    entry.refs++;
    try {
      return await entry.source;
    } catch (_) {
      _release(path, entry, dispose: false);
      _loadFailures.add(path);
      rethrow;
    }
  }

  /// Frees [path] when no voice holds it any more.
  void release(String path) {
    final entry = _sources[path];
    if (entry != null) _release(path, entry, dispose: true);
  }

  void _release(String path, _LoadedSource entry, {required bool dispose}) {
    entry.refs--;
    if (entry.refs > 0 || _sources[path] != entry) return;
    _sources.remove(path);
    if (!dispose) return;
    late final Future<void> done;
    done = entry.source.then(_soloud.disposeSource).catchError((Object e) {
      LoggerService().warning('SoLoudEngine: Could not free $path', details: '$e');
    }).whenComplete(() {
      if (_disposing[path] == done) _disposing.remove(path);
    });
    _disposing[path] = done;
  }

  Future<AudioSource> _load(String path) {
    final size = File(path).lengthSync();
    return _soloud.loadFile(path, mode: size <= memoryLoadLimitBytes ? LoadMode.memory : LoadMode.disk);
  }
}

class _LoadedSource {
  final Future<AudioSource> source;
  int refs = 0;

  _LoadedSource(this.source);
}
