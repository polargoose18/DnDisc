import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/models/ambient_layer.dart';
import '../services/logger_service.dart';
import 'fade_controller.dart';
import 'playback/bus_player.dart';
import 'playback/soloud_engine.dart';

class AmbientBusController extends ChangeNotifier {
  final List<AmbientLayer> _layers = [];
  final Map<String, BusPlayer> _activePlayers = {};
  final Map<String, FadeController> _fadeControllers = {};
  final Map<String, Duration> _layerDurations = {};
  final Map<String, bool> _layerLoopTransitioning = {};
  final Map<String, BusPlayer> _outgoingAmbientPlayers = {};

  /// Players of turned-off layers that are still fading out.
  final Map<BusPlayer, FadeController> _fadingOut = {};
  final Map<String, FadeController> _outgoingAmbientFadeControllers = {};
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
      _layerLoopTransitioning[layer.id] = false;

      await player.setVolume(startVolume);
      await player.setLooping(false);

      // Registered before the file loads, so a stop during loading finds it.
      final started = player;
      _activePlayers[layer.id] = started;
      bool current() => identical(_activePlayers[layer.id], started);

      player.onDurationChanged.listen(
        (d) {
          if (current()) _layerDurations[layer.id] = d;
        },
        onError: (e) {
          LoggerService().warning('AmbientBus: Error in onDurationChanged for ${layer.title}', details: '$e');
        },
      );

      player.onPositionChanged.listen(
        (pos) {
          if (!current()) return;
          final total = _layerDurations[layer.id];
          if (total != null && total.inMilliseconds > 4000) {
            final transitionDuration = total.inMilliseconds > 8000
                ? const Duration(milliseconds: 2000)
                : const Duration(milliseconds: 1000);
            final isTransitioning = _layerLoopTransitioning[layer.id] ?? false;
            final isLayerActive = _layers.firstWhere((l) => l.id == layer.id, orElse: () => layer).isActive;

            if (pos >= total - transitionDuration && !isTransitioning && isLayerActive) {
              _triggerSeamlessLayerLoopTransition(layer, transitionDuration);
            }
          }
        },
        onError: (e) {
          LoggerService().warning('AmbientBus: Error in onPositionChanged for ${layer.title}', details: '$e');
        },
      );

      player.onPlayerComplete.listen(
        (_) {
          if (!current()) return;
          final isTransitioning = _layerLoopTransitioning[layer.id] ?? false;
          final isLayerActive = _layers.firstWhere((l) => l.id == layer.id, orElse: () => layer).isActive;
          if (!isTransitioning && isLayerActive) {
            _triggerSeamlessLayerLoopTransition(layer, const Duration(milliseconds: 800));
          }
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

  Future<void> _triggerSeamlessLayerLoopTransition(AmbientLayer layer, Duration transitionDuration) async {
    final isTransitioning = _layerLoopTransitioning[layer.id] ?? false;
    if (isTransitioning) return;
    _layerLoopTransitioning[layer.id] = true;

    LoggerService().info('AmbientBus: Seamless loop crossfade triggered for layer "${layer.title}" (${transitionDuration.inMilliseconds}ms)');

    final file = File(layer.filePath).absolute;
    if (!file.existsSync()) {
      _layerLoopTransitioning[layer.id] = false;
      return;
    }

    BusPlayer? nextPlayer;
    try {
      final oldPlayer = _activePlayers[layer.id];
      final currentLayer = _layers.firstWhere((l) => l.id == layer.id, orElse: () => layer);
      final targetVolume = currentLayer.volume * _gain;

      final outgoingFader = _outgoingAmbientFadeControllers.putIfAbsent(layer.id, () => FadeController());
      outgoingFader.stop();
      _outgoingAmbientPlayers[layer.id]?.dispose();
      _outgoingAmbientPlayers[layer.id] = oldPlayer ?? BusPlayer.forFile(file.path, bus: SoLoudEngine.ambientBus(layer.id));

      nextPlayer = BusPlayer.forFile(file.path, bus: SoLoudEngine.ambientBus(layer.id));
      _activePlayers[layer.id] = nextPlayer;

      await nextPlayer.setVolume(0.0);
      await nextPlayer.setLooping(false);

      final next = nextPlayer;
      bool current() => identical(_activePlayers[layer.id], next);

      next.onDurationChanged.listen(
        (d) {
          if (current()) _layerDurations[layer.id] = d;
        },
        onError: (e) {
          LoggerService().warning('AmbientBus: Error in loop transition onDurationChanged for ${layer.title}', details: '$e');
        },
      );

      next.onPositionChanged.listen(
        (pos) {
          if (!current()) return;
          final total = _layerDurations[layer.id];
          if (total != null && total.inMilliseconds > 4000) {
            final nextTransition = total.inMilliseconds > 8000
                ? const Duration(milliseconds: 2000)
                : const Duration(milliseconds: 1000);
            final nowTransitioning = _layerLoopTransitioning[layer.id] ?? false;
            final isLayerActive = _layers.firstWhere((l) => l.id == layer.id, orElse: () => layer).isActive;

            if (pos >= total - nextTransition && !nowTransitioning && isLayerActive) {
              _triggerSeamlessLayerLoopTransition(layer, nextTransition);
            }
          }
        },
        onError: (e) {
          LoggerService().warning('AmbientBus: Error in loop transition onPositionChanged for ${layer.title}', details: '$e');
        },
      );

      next.onPlayerComplete.listen(
        (_) {
          if (!current()) return;
          final nowTransitioning = _layerLoopTransitioning[layer.id] ?? false;
          final isLayerActive = _layers.firstWhere((l) => l.id == layer.id, orElse: () => layer).isActive;
          if (!nowTransitioning && isLayerActive) {
            _triggerSeamlessLayerLoopTransition(layer, const Duration(milliseconds: 800));
          }
        },
        onError: (e) {
          LoggerService().warning('AmbientBus: Error in loop transition onPlayerComplete for ${layer.title}', details: '$e');
        },
      );

      await next.play(file.path);
      // Turned off while the next loop was loading: the stop released both.
      if (!current()) return;

      // Fade out old player
      if (oldPlayer != null) {
        outgoingFader.startFade(
          from: targetVolume,
          to: 0.0,
          duration: transitionDuration,
          onUpdate: (v) {
            try {
              oldPlayer.setVolume(v);
            } catch (_) {}
          },
          onComplete: () {
            try {
              oldPlayer.stop();
              oldPlayer.dispose();
            } catch (_) {}
            if (_outgoingAmbientPlayers[layer.id] == oldPlayer) {
              _outgoingAmbientPlayers.remove(layer.id);
            }
          },
        );
      }

      // Fade in next player
      final inFader = _fadeControllers.putIfAbsent(layer.id, () => FadeController());
      inFader.startFade(
        from: 0.0,
        to: targetVolume,
        duration: transitionDuration,
        onUpdate: (v) {
          try {
            nextPlayer?.setVolume(v);
          } catch (_) {}
        },
        onComplete: () {
          try {
            nextPlayer?.setVolume(targetVolume);
          } catch (_) {}
          _layerLoopTransitioning[layer.id] = false;
        },
      );
    } catch (e, stack) {
      LoggerService().error('AmbientBus: Error during seamless loop transition for ${layer.title}', details: '$e\n$stack');
      try {
        await nextPlayer?.stop();
        await nextPlayer?.dispose();
      } catch (_) {}
      _layerLoopTransitioning[layer.id] = false;
    }
  }

  Future<void> _stopLayerAudio(
    String layerId, {
    Duration fadeDuration = Duration.zero,
  }) async {
    _layerLoopTransitioning[layerId] = false;
    final player = _activePlayers[layerId];
    final fader = _fadeControllers.remove(layerId);
    fader?.stop();

    final outPlayer = _outgoingAmbientPlayers.remove(layerId);
    final outFader = _outgoingAmbientFadeControllers.remove(layerId);
    outFader?.stop();
    if (outPlayer != null) {
      try {
        await outPlayer.stop();
        await outPlayer.dispose();
      } catch (_) {}
    }

    if (player == null) return;
    // No longer the layer's player: turning the layer on again starts a new
    // one while this one fades out.
    _activePlayers.remove(layerId);

    if (fadeDuration.inMilliseconds > 0) {
      final stopFader = FadeController();
      _fadingOut[player] = stopFader;
      final currentLayer = _layers.firstWhere(
        (l) => l.id == layerId,
        orElse: () => AmbientLayer(id: layerId, title: '', filePath: ''),
      );
      final currentVol = currentLayer.volume * _gain;

      stopFader.startFade(
        from: currentVol,
        to: 0.0,
        duration: fadeDuration,
        onUpdate: (val) {
          try {
            player.setVolume(val);
          } catch (_) {}
        },
        onComplete: () async {
          _fadingOut.remove(player);
          stopFader.dispose();
          try {
            await player.stop();
            await player.dispose();
          } catch (e) {
            LoggerService().error('AmbientBus: Error disposing player for $layerId', details: '$e');
          }
        },
      );
    } else {
      try {
        await player.stop();
        await player.dispose();
      } catch (e) {
        LoggerService().error('AmbientBus: Error disposing player for $layerId', details: '$e');
      }
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

    for (final fader in _outgoingAmbientFadeControllers.values) {
      fader.dispose();
    }
    _outgoingAmbientFadeControllers.clear();

    for (final player in _outgoingAmbientPlayers.values) {
      try {
        player.stop();
        player.dispose();
      } catch (_) {}
    }
    _outgoingAmbientPlayers.clear();

    for (final entry in _fadingOut.entries) {
      entry.value.dispose();
      try {
        entry.key.stop();
        entry.key.dispose();
      } catch (_) {}
    }
    _fadingOut.clear();

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
