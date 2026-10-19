import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../../services/logger_service.dart';
import 'bus_player.dart';
import 'soloud_engine.dart';

/// Voice on the shared SoLoud engine, so it follows the chosen output device.
class SoLoudBusPlayer implements BusPlayer {
  /// How often the position is reported while playing.
  static const Duration positionInterval = Duration(milliseconds: 200);

  final SoLoudEngine _engine;
  final StreamController<Duration> _duration = StreamController.broadcast();
  final StreamController<Duration> _position = StreamController.broadcast();
  final StreamController<void> _complete = StreamController.broadcast();

  double _volume = 1;
  bool _looping = false;
  Duration _loopStart = Duration.zero;
  Duration? _loopEnd;
  bool _paused = false;
  bool _disposed = false;
  String? _path;
  SoundHandle? _handle;
  StreamSubscription<StreamSoundEvent>? _events;
  Timer? _ticker;

  /// Mixing bus the voice plays through; null plays on the main mix.
  final String? bus;

  SoLoudBusPlayer({this.bus, SoLoudEngine? engine}) : _engine = engine ?? SoLoudEngine.instance;

  SoLoud get _soloud => SoLoud.instance;

  bool get _hasVoice {
    final handle = _handle;
    return handle != null && _engine.isReady && _soloud.getIsValidVoiceHandle(handle);
  }

  @override
  Stream<Duration> get onDurationChanged => _duration.stream;

  @override
  Stream<Duration> get onPositionChanged => _position.stream;

  @override
  Stream<void> get onPlayerComplete => _complete.stream;

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    _guard('setVolume', () {
      if (_hasVoice) _soloud.setVolume(_handle!, _volume);
    });
  }

  @override
  Future<void> setLooping(bool looping) async {
    _looping = looping;
    _guard('setLooping', () {
      if (_hasVoice) _soloud.setLooping(_handle!, looping);
    });
  }

  @override
  Future<void> setLoopRegion({Duration start = Duration.zero, Duration? end}) async {
    _loopStart = start;
    _loopEnd = end;
  }

  @override
  Future<void> play(String path) async {
    await _endVoice();
    if (!await _engine.ensureStarted()) throw StateError('No audio output device is available');
    final source = await _engine.acquire(path);
    if (_disposed) {
      _engine.release(path);
      return;
    }
    _path = path;
    _events = source.soundEvents.listen((event) {
      if (event.event == SoundEventType.handleIsNoMoreValid && event.handle == _handle) _finished();
    });
    final through = bus == null ? null : _engine.bus(bus!);
    _handle = through != null
        ? through.play(source,
            volume: _volume, looping: _looping, loopingStartAt: _loopStart, loopingEndAt: _loopEnd)
        : _soloud.play(source,
            volume: _volume, looping: _looping, loopingStartAt: _loopStart, loopingEndAt: _loopEnd);
    _paused = false;
    if (!_duration.isClosed) _duration.add(_soloud.getLength(source));
    _ticker = Timer.periodic(positionInterval, (_) => _tick());
  }

  void _tick() {
    if (_handle == null || _paused) return;
    if (!_hasVoice) {
      _finished();
      return;
    }
    if (!_position.isClosed) _position.add(_soloud.getPosition(_handle!));
  }

  /// The voice reached its end on its own.
  void _finished() {
    if (_handle == null) return;
    _handle = null;
    _detach();
    if (!_complete.isClosed) _complete.add(null);
  }

  void _detach() {
    _ticker?.cancel();
    _ticker = null;
    _events?.cancel();
    _events = null;
    final path = _path;
    _path = null;
    if (path != null) _engine.release(path);
  }

  /// Stops the voice without reporting completion (like a manual stop).
  Future<void> _endVoice() async {
    final handle = _handle;
    final playing = _hasVoice;
    _handle = null;
    _detach();
    if (handle != null && playing) {
      try {
        await _soloud.stop(handle);
      } catch (e) {
        LoggerService().warning('SoLoudBusPlayer: Could not stop a voice', details: '$e');
      }
    }
  }

  @override
  Future<void> pause() async {
    _guard('pause', () {
      if (_hasVoice) _soloud.setPause(_handle!, true);
    });
    _paused = true;
  }

  @override
  Future<void> resume() async {
    _guard('resume', () {
      if (_hasVoice) _soloud.setPause(_handle!, false);
    });
    _paused = false;
  }

  @override
  Future<void> stop() => _endVoice();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _endVoice();
    await _duration.close();
    await _position.close();
    await _complete.close();
  }

  void _guard(String action, void Function() body) {
    try {
      body();
    } catch (e) {
      LoggerService().warning('SoLoudBusPlayer: $action failed', details: '$e');
    }
  }
}
