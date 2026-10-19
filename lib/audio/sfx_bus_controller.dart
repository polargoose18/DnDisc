import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/models/sfx_trigger.dart';
import '../services/logger_service.dart';
import 'playback/bus_player.dart';

class SfxBusController extends ChangeNotifier {
  final List<SfxTrigger> _triggers = [];
  final List<BusPlayer> _activePlayers = [];
  final Map<String, BusPlayer> _loopingPlayers = {};
  double _volume = 1.0;
  double _masterVolume = 1.0;
  final Function()? onSfxTriggered;

  SfxBusController({this.onSfxTriggered});

  List<SfxTrigger> get triggers => List.unmodifiable(_triggers);
  double get volume => _volume;
  double get rawVolume => _volume;
  double get masterVolume => _masterVolume;
  double get effectiveVolume => (_volume * _masterVolume).clamp(0.0, 1.0);
  bool isTriggerLooping(String triggerId) => _loopingPlayers.containsKey(triggerId);

  void addTrigger(SfxTrigger trigger) {
    if (!_triggers.any((t) => t.id == trigger.id)) {
      _triggers.add(trigger);
      notifyListeners();
    }
  }

  void togglePersistent(String triggerId) {
    final index = _triggers.indexWhere((t) => t.id == triggerId);
    if (index != -1) {
      final trigger = _triggers[index];
      _triggers[index] = trigger.copyWith(isPersistent: !trigger.isPersistent);
      notifyListeners();
    }
  }

  void removeTrigger(String triggerId) {
    stopSfx(triggerId);
    _triggers.removeWhere((t) => t.id == triggerId);
    notifyListeners();
  }

  void toggleTriggerLoop(String triggerId) {
    final index = _triggers.indexWhere((t) => t.id == triggerId);
    if (index != -1) {
      final trigger = _triggers[index];
      final newLoop = !trigger.isLoop;
      _triggers[index] = trigger.copyWith(isLoop: newLoop);

      // If loop was turned off while currently playing as loop, stop it
      if (!newLoop && _loopingPlayers.containsKey(triggerId)) {
        stopSfx(triggerId);
      }
      notifyListeners();
    }
  }

  Future<void> triggerSfx(String triggerId) async {
    final index = _triggers.indexWhere((t) => t.id == triggerId);
    if (index != -1) {
      final trigger = _triggers[index];

      // If it's a loop and already playing, toggle it off
      if (trigger.isLoop && _loopingPlayers.containsKey(triggerId)) {
        await stopSfx(triggerId);
        return;
      }

      onSfxTriggered?.call();

      final file = File(trigger.filePath).absolute;
      if (!file.existsSync()) {
        LoggerService().warning('SfxBus: File does not exist', details: 'Path: ${file.path}');
        notifyListeners();
        return;
      }

      BusPlayer? player;
      try {
        player = BusPlayer.forFile(file.path);
        await player.setVolume(trigger.volume * effectiveVolume);
        await player.setLooping(trigger.isLoop);

        _activePlayers.add(player);
        if (trigger.isLoop) {
          _loopingPlayers[triggerId] = player;
          // The loop counts as playing before its file loads.
          notifyListeners();
        }

        LoggerService().info('SfxBus: Triggering SFX "${trigger.title}" (Loop: ${trigger.isLoop})');
        await player.play(file.path);

        if (!trigger.isLoop) {
          player.onPlayerComplete.listen(
            (_) {
              if (player != null) {
                _activePlayers.remove(player);
                player.dispose();
              }
            },
            onError: (e) {
              LoggerService().warning('SfxBus: Error in onPlayerComplete for ${trigger.title}', details: '$e');
              if (player != null) {
                _activePlayers.remove(player);
                player.dispose();
              }
            },
          );
        }
      } catch (e, stack) {
        LoggerService().error('SfxBus: Exception triggering ${trigger.title}', details: '$e\n$stack');
        if (player != null) {
          _activePlayers.remove(player);
          _loopingPlayers.remove(triggerId);
          try {
            await player.stop();
            await player.dispose();
          } catch (_) {}
        }
      }
      notifyListeners();
    }
  }

  Future<void> stopSfx(String triggerId) async {
    final player = _loopingPlayers.remove(triggerId);
    if (player != null) {
      _activePlayers.remove(player);
      notifyListeners();
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
      LoggerService().info('SfxBus: Stopped looping SFX ($triggerId)');
    }
  }

  Future<void> stopAll() async {
    LoggerService().info('SfxBus: Stopping all ${_activePlayers.length} active SFX players.');
    _loopingPlayers.clear();
    final toStop = List<BusPlayer>.from(_activePlayers);
    _activePlayers.clear();
    notifyListeners();

    for (final player in toStop) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    LoggerService().info('SfxBus: Volume set to $_volume');
    _applyPlayerVolume();
    notifyListeners();
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    LoggerService().info('SfxBus: Master volume set to $_masterVolume');
    _applyPlayerVolume();
    notifyListeners();
  }

  void _applyPlayerVolume() {
    for (final player in _activePlayers) {
      try {
        player.setVolume(effectiveVolume);
      } catch (_) {}
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    stopAll();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
