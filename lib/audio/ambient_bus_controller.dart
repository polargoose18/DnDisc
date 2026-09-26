import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/ambient_layer.dart';
import '../services/logger_service.dart';
import 'fade_controller.dart';

class AmbientBusController extends ChangeNotifier {
  final List<AmbientLayer> _layers = [];
  final Map<String, AudioPlayer> _activePlayers = {};
  final Map<String, FadeController> _fadeControllers = {};
  double _masterAmbientVolume = 1.0;

  List<AmbientLayer> get layers => List.unmodifiable(_layers);
  double get masterVolume => _masterAmbientVolume;

  void addLayer(AmbientLayer layer) {
    if (!_layers.any((l) => l.id == layer.id)) {
      _layers.add(layer);
      if (layer.isActive) {
        _startLayerAudio(layer);
      }
      notifyListeners();
    }
  }

  Future<void> toggleLayer(
    String layerId, {
    Duration fadeDuration = const Duration(milliseconds: 1000),
  }) async {
    final index = _layers.indexWhere((l) => l.id == layerId);
    if (index != -1) {
      final layer = _layers[index];
      final newActive = !layer.isActive;
      _layers[index] = layer.copyWith(isActive: newActive);

      if (newActive) {
        await _startLayerAudio(_layers[index], fadeDuration: fadeDuration);
      } else {
        await _stopLayerAudio(layerId, fadeDuration: fadeDuration);
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

      final player = _activePlayers[layerId];
      if (player != null) {
        final targetVol = clampedVol * _masterAmbientVolume;
        if (fadeDuration.inMilliseconds > 0) {
          final fader = _fadeControllers.putIfAbsent(layerId, () => FadeController());
          fader.startFade(
            from: layer.volume * _masterAmbientVolume,
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

  void setMasterVolume(double volume) {
    _masterAmbientVolume = volume.clamp(0.0, 1.0);
    for (final layer in _layers) {
      if (layer.isActive) {
        final player = _activePlayers[layer.id];
        if (player != null) {
          try {
            player.setVolume(layer.volume * _masterAmbientVolume);
          } catch (e) {
            LoggerService().error('AmbientBus: Error setting master ambient volume', details: '$e');
          }
        }
      }
    }
    notifyListeners();
  }

  Future<void> stopAllLayers({
    Duration fadeDuration = const Duration(milliseconds: 1000),
  }) async {
    final futures = <Future<void>>[];
    for (int i = 0; i < _layers.length; i++) {
      if (_layers[i].isActive) {
        final id = _layers[i].id;
        _layers[i] = _layers[i].copyWith(isActive: false);
        futures.add(_stopLayerAudio(id, fadeDuration: fadeDuration));
      }
    }
    await Future.wait(futures);
    notifyListeners();
  }

  Future<void> _startLayerAudio(
    AmbientLayer layer, {
    Duration fadeDuration = const Duration(milliseconds: 1000),
  }) async {
    final file = File(layer.filePath);
    if (!file.existsSync()) {
      LoggerService().warning('AmbientBus: File does not exist', details: 'Path: ${layer.filePath}');
      return;
    }

    try {
      await _stopLayerAudio(layer.id, fadeDuration: Duration.zero);

      final player = AudioPlayer();
      final targetVolume = layer.volume * _masterAmbientVolume;
      final startVolume = fadeDuration.inMilliseconds > 0 ? 0.0 : targetVolume;

      await player.setVolume(startVolume);
      await player.setReleaseMode(ReleaseMode.loop);

      LoggerService().info('AmbientBus: Starting layer "${layer.title}"');
      await player.play(DeviceFileSource(file.path));

      _activePlayers[layer.id] = player;
      LoggerService().info('AmbientBus: Layer "${layer.title}" started successfully!');

      if (fadeDuration.inMilliseconds > 0) {
        final fader = _fadeControllers.putIfAbsent(layer.id, () => FadeController());
        fader.startFade(
          from: 0.0,
          to: targetVolume,
          duration: fadeDuration,
          onUpdate: (val) {
            try {
              player.setVolume(val);
            } catch (_) {}
          },
          onComplete: () {
            try {
              player.setVolume(targetVolume);
            } catch (_) {}
          },
        );
      }
    } catch (e, stack) {
      LoggerService().error('AmbientBus: Exception starting ${layer.title}', details: '$e\n$stack');
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

    if (fadeDuration.inMilliseconds > 0) {
      final stopFader = FadeController();
      final currentLayer = _layers.firstWhere(
        (l) => l.id == layerId,
        orElse: () => AmbientLayer(id: layerId, title: '', filePath: ''),
      );
      final currentVol = currentLayer.volume * _masterAmbientVolume;

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
          _activePlayers.remove(layerId);
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
      _activePlayers.remove(layerId);
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
