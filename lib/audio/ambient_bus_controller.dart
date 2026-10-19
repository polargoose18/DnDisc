import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/models/ambient_layer.dart';
import '../services/logger_service.dart';
import 'fade_controller.dart';
import 'fading_voices.dart';
import 'playback/bus_player.dart';
import 'playback/soloud_engine.dart';

class AmbientBusController extends ChangeNotifier {
  final List<AmbientLayer> _layers = [];
  final Map<String, BusPlayer> _activePlayers = {};
  final Map<String, FadeController> _fadeControllers = {};

  /// Players of turned-off layers that are still fading out.
  final FadingVoices _fadingOut = FadingVoices('AmbientBus');
  double _masterAmbientVolume = 1.0;
  double _channelVolume = 1.0;
  Duration _defaultFadeDuration;

  AmbientBusController({
    Duration defaultFadeDuration = const Duration(milliseconds: 1000),
  }) : _defaultFadeDuration = defaultFadeDuration;

  List<AmbientLayer> get layers => List.unmodifiable(_layers);
  double get masterVolume => _masterAmbientVolume;

  /// Volume of the whole Ambient channel (the mixer slider); layers keep their own volume.
  double get channelVolume => _channelVolume;

  double get _gain => _masterAmbientVolume * _channelVolume;
  Duration get defaultFadeDuration => _defaultFadeDuration;

  void setDefaultFadeDuration(Duration duration) {
    _defaultFadeDuration = duration;
  }

  void addLayer(AmbientLayer layer) {
    if (!_layers.any((l) => l.id == layer.id)) {
      _layers.add(layer);
      if (layer.isActive) {
        _startLayerAudio(layer);
      }
      notifyListeners();
    }
  }

  void togglePersistent(String layerId) {
    final index = _layers.indexWhere((l) => l.id == layerId);
    if (index != -1) {
      final layer = _layers[index];
      _layers[index] = layer.copyWith(isPersistent: !layer.isPersistent);
      notifyListeners();
    }
  }

  Future<void> removeLayer(String layerId) async {
    await _stopLayerAudio(layerId);
    _layers.removeWhere((l) => l.id == layerId);
    notifyListeners();
  }

  Future<void> toggleLayer(
    String layerId, {
    Duration? fadeDuration,
  }) async {
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;
    final index = _layers.indexWhere((l) => l.id == layerId);
    if (index != -1) {
      final layer = _layers[index];
      final newActive = !layer.isActive;
      _layers[index] = layer.copyWith(isActive: newActive);
      // The toggle answers at once; loading and the fade follow.
      notifyListeners();

      if (newActive) {
        await _startLayerAudio(_layers[index], fadeDuration: effectiveFade);
      } else {
        await _stopLayerAudio(layerId, fadeDuration: effectiveFade);
      }

      notifyListeners();
    }
  }

  void setLayerVolume(
    String layerId,
    double newVolume, {
    Duration fadeDuration = Duration.zero,
  }) {
    final index = _layers.indexWhere((l) => l.id == layerId);
    if (index != -1) {
      final layer = _layers[index];
      final clampedVol = newVolume.clamp(0.0, 1.0);
      _layers[index] = layer.copyWith(volume: clampedVol);
      LoggerService().info('AmbientBus: Layer "$layerId" volume set to $clampedVol');

      final player = _activePlayers[layerId];
      if (player != null) {
        final targetVol = clampedVol * _gain;
        if (fadeDuration.inMilliseconds > 0) {
          final fader = _fadeControllers.putIfAbsent(layerId, () => FadeController());
          fader.startFade(
            from: layer.volume * _gain,
            to: targetVol,
            duration: fadeDuration,
            onUpdate: (val) {
              try {
                player.setVolume(val);
              } catch (_) {}
            },
            onComplete: () {
              try {
                player.setVolume(targetVol);
              } catch (_) {}
            },
          );
        } else {
          try {
            player.setVolume(targetVol);
          } catch (e) {
            LoggerService().error('AmbientBus: Error setting layer volume', details: '$e');
          }
        }
      }
      notifyListeners();
    }
  }

  void setChannelVolume(double volume) {
    _channelVolume = volume.clamp(0.0, 1.0);
    _applyGainToActiveLayers();
    notifyListeners();
  }

  void _applyGainToActiveLayers() {
    for (final layer in _layers) {
      if (layer.isActive) {
        final player = _activePlayers[layer.id];
        if (player != null) {
          try {
            player.setVolume(layer.volume * _gain);
          } catch (e) {
            LoggerService().error('AmbientBus: Error setting channel volume', details: '$e');
          }
        }
      }
    }
  }

  void setMasterVolume(double volume) {
    _masterAmbientVolume = volume.clamp(0.0, 1.0);
    LoggerService().info('AmbientBus: Master volume set to $_masterAmbientVolume');
    for (final layer in _layers) {
      if (layer.isActive) {
        final player = _activePlayers[layer.id];
        if (player != null) {
          try {
            player.setVolume(layer.volume * _gain);
          } catch (e) {
            LoggerService().error('AmbientBus: Error setting master ambient volume', details: '$e');
          }
        }
      }
    }
    notifyListeners();
  }

  Future<void> stopAllLayers({
    Duration? fadeDuration,
  }) async {
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;
    final futures = <Future<void>>[];
    for (int i = 0; i < _layers.length; i++) {
      if (_layers[i].isActive) {
        final id = _layers[i].id;
        _layers[i] = _layers[i].copyWith(isActive: false);
        futures.add(_stopLayerAudio(id, fadeDuration: effectiveFade));
      }
    }
    notifyListeners();
    await Future.wait(futures);
    notifyListeners();
  }

  Future<void> _startLayerAudio(
    AmbientLayer layer, {
    Duration? fadeDuration,
  }) async {
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;
    final file = File(layer.filePath).absolute;
    if (!file.existsSync()) {
      LoggerService().warning('AmbientBus: File does not exist', details: 'Path: ${file.path}');
      return;
    }

    BusPlayer? player;
    try {
      await _stopLayerAudio(layer.id, fadeDuration: Duration.zero);

      player = BusPlayer.forFile(file.path, bus: SoLoudEngine.ambientBus(layer.id));
      final targetVolume = layer.volume * _gain;
      final startVolume = effectiveFade.inMilliseconds > 0 ? 0.0 : targetVolume;

      await player.setVolume(startVolume);
      await player.setLooping(true);

      // Registered before the file loads, so a stop during loading finds it.
      final started = player;
      _activePlayers[layer.id] = started;
      bool current() => identical(_activePlayers[layer.id], started);

      // The voice loops on its own; it ends only when it fails.
      player.onPlayerComplete.listen(
        (_) {
          if (!current()) return;
          final isLayerActive = _layers.firstWhere((l) => l.id == layer.id, orElse: () => layer).isActive;
          if (isLayerActive) _restartEndedVoice(started, file.path);
        },
        onError: (e) {
          LoggerService().warning('AmbientBus: Error in onPlayerComplete for ${layer.title}', details: '$e');
        },
      );

      LoggerService().info('AmbientBus: Starting layer "${layer.title}"');
      await player.play(file.path);

      // Turned off while the file was loading: the stop released it.
      if (!current()) return;
      LoggerService().info('AmbientBus: Layer "${layer.title}" started successfully!');

      if (effectiveFade.inMilliseconds > 0) {
        final fader = _fadeControllers.putIfAbsent(layer.id, () => FadeController());
        fader.startFade(
          from: 0.0,
          to: targetVolume,
          duration: effectiveFade,
          onUpdate: (val) {
            try {
              player?.setVolume(val);
            } catch (_) {}
          },
          onComplete: () {
            try {
              player?.setVolume(targetVolume);
            } catch (_) {}
          },
        );
      }
    } catch (e, stack) {
      LoggerService().error('AmbientBus: Exception starting ${layer.title}', details: '$e\n$stack');
      if (identical(_activePlayers[layer.id], player)) _activePlayers.remove(layer.id);
      try {
        await player?.stop();
        await player?.dispose();
      } catch (_) {}
    }
  }

  /// A voice that should loop has ended: start the file again.
  Future<void> _restartEndedVoice(BusPlayer player, String path) async {
    try {
      await player.play(path);
    } catch (e) {
      LoggerService().error('AmbientBus: Could not restart a looping layer', details: '$e');
    }
  }

  Future<void> _stopLayerAudio(
    String layerId, {
    Duration fadeDuration = Duration.zero,
  }) async {
    final player = _activePlayers[layerId];
    final fader = _fadeControllers.remove(layerId);
    fader?.stop();

    if (player == null) return;
    // No longer the layer's player: turning the layer on again starts a new
    // one while this one fades out.
    _activePlayers.remove(layerId);

    if (fadeDuration.inMilliseconds > 0) {
      final currentLayer = _layers.firstWhere(
        (l) => l.id == layerId,
        orElse: () => AmbientLayer(id: layerId, title: '', filePath: ''),
      );
      _fadingOut.fadeOutAndRelease(player, from: currentLayer.volume * _gain, duration: fadeDuration);
    } else {
      await _fadingOut.release(player);
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    for (final fader in _fadeControllers.values) {
      fader.dispose();
    }
    _fadeControllers.clear();

    _fadingOut.releaseAll();

    for (final player in _activePlayers.values) {
      try {
        player.stop();
        player.dispose();
      } catch (e) {
        // ignore errors during dispose
      }
    }
    _activePlayers.clear();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
