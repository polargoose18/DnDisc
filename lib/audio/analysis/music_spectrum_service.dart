import 'dart:collection';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../../services/logger_service.dart';
import '../music_bus_controller.dart';
import '../playback/bus_player.dart';
import 'spectrogram.dart';
import 'track_samples.dart';

/// Computes the spectrum of a file of [length]; null when it cannot.
typedef SpectrumAnalyzer = Future<Spectrogram?> Function(String path, Duration length);

/// Spectrum of the music track that plays now, for the music visualizer.
/// Only the music bus is analysed: ambient layers and SFX never show in it.
///
/// The track's file is decoded once in the background when it starts
/// (its length is known then); until it is ready, and for files SoLoud
/// does not decode (M4A), [current] is null.
class MusicSpectrumService extends ChangeNotifier {
  static const int cacheSize = 6;

  final MusicBusController music;
  final SpectrumAnalyzer _analyze;
  final LinkedHashMap<String, Spectrogram?> _cache = LinkedHashMap();
  final Set<String> _running = {};
  String? _path;

  MusicSpectrumService({required this.music, SpectrumAnalyzer? analyzer}) : _analyze = analyzer ?? analyzeInBackground {
    music.addListener(_onMusic);
    // The length arrives with playback, which reports through the position.
    music.position.addListener(_onMusic);
    _onMusic();
  }

  /// Spectrum of the current track, or null while it is not available.
  Spectrogram? get current => _path == null ? null : _cache[_path];

  void _onMusic() {
    final track = music.currentTrack;
    final path = track?.filePath;
    if (path != _path) {
      _path = path;
      notifyListeners();
    }
    final length = music.trackDuration;
    if (path == null || length == null || _cache.containsKey(path) || _running.contains(path)) return;
    if (!BusPlayer.soloudExtensions.contains(BusPlayer.extensionOf(path))) return;
    _start(path, length);
  }

  Future<void> _start(String path, Duration length) async {
    _running.add(path);
    Spectrogram? result;
    try {
      result = await _analyze(path, length);
    } catch (e) {
      LoggerService().warning('MusicSpectrum: Could not analyse $path', details: '$e');
    }
    _running.remove(path);
    if (_disposed) return;
    _cache.remove(path);
    _cache[path] = result;
    while (_cache.length > cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    if (path == _path) notifyListeners();
  }

  /// Decodes and analyses on another isolate, so the UI never waits.
  static Future<Spectrogram?> analyzeInBackground(String path, Duration length) => Isolate.run(() {
        final reader = TrackSampleReader.open();
        final decoded = reader?.read(path, length);
        if (decoded == null) return null;
        return computeSpectrogram(decoded.samples, decoded.sampleRate);
      });

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    music.removeListener(_onMusic);
    music.position.removeListener(_onMusic);
    super.dispose();
  }
}
