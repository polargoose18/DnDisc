import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/models/audio_track.dart';
import '../services/logger_service.dart';
import 'fade_controller.dart';
import 'playback/bus_player.dart';

class MusicBusController extends ChangeNotifier {
  AudioTrack? _currentTrack;
  double _volume = 1.0;
  double _masterVolume = 1.0;
  double _duckingMultiplier = 1.0;
  double _fadeMultiplier = 1.0;
  bool _isPlaying = false;
  MusicIntensity _currentIntensity = MusicIntensity.calm;
  Duration _defaultFadeDuration;

  BusPlayer? _player;
  BusPlayer? _outgoingPlayer; // For crossfading
  final FadeController _fadeController = FadeController();
  final FadeController _outgoingFadeController = FadeController();
  Duration? _currentTrackDuration;

  /// Playback position of the current track; updated by the player without notifying listeners.
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  bool _loopTransitioning = false;

  /// The player itself is paused (the pause fade has finished).
  bool _playerPaused = false;

  MusicBusController({
    Duration defaultFadeDuration = const Duration(milliseconds: 1500),
  }) : _defaultFadeDuration = defaultFadeDuration;

  AudioTrack? get currentTrack => _currentTrack;
  double get rawVolume => _volume;
  double get masterVolume => _masterVolume;
  double get duckingMultiplier => _duckingMultiplier;
  double get fadeMultiplier => _fadeMultiplier;
  Duration get defaultFadeDuration => _defaultFadeDuration;
  double get effectiveVolume => (_volume * _masterVolume * _duckingMultiplier * _fadeMultiplier).clamp(0.0, 1.0);
  bool get isPlaying => _isPlaying;
  MusicIntensity get currentIntensity => _currentIntensity;
  Duration? get trackDuration => _currentTrackDuration;

  void setDefaultFadeDuration(Duration duration) {
    _defaultFadeDuration = duration;
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    LoggerService().info('MusicBus: Master volume set to $_masterVolume');
    _applyPlayerVolume();
    notifyListeners();
  }

  Future<void> playTrack(
    AudioTrack track, {
    Duration? fadeDuration,
  }) async {
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;
    _currentTrack = track;
    _currentIntensity = track.intensity;
    _loopTransitioning = false;
    _currentTrackDuration = null;
    position.value = Duration.zero;

    LoggerService().info('MusicBus: Start playing track "${track.title}"', details: 'Path: ${track.filePath}');

    final file = File(track.filePath).absolute;
    if (!file.existsSync()) {
      LoggerService().warning('MusicBus: Local file does not exist', details: 'Path: ${file.path}');
      _isPlaying = false;
      notifyListeners();
      return;
    }

    // The state changes before the file loads, so the controls answer at once.
    // Audible: playing, or a pause still fading out.
    final wasAudible = _player != null && !_playerPaused;
    _isPlaying = true;
    _playerPaused = false;
    notifyListeners();

    final player = BusPlayer.forFile(file.path);
    try {
      // If we already have an active player, initiate crossfade
      if (wasAudible && effectiveFade.inMilliseconds > 0) {
        _fadeController.stop();
        _outgoingFadeController.stop();
        _outgoingPlayer?.dispose();
        _outgoingPlayer = _player;
        _player = null;

        final oldPlayer = _outgoingPlayer;
        final currentVol = effectiveVolume;
        _outgoingFadeController.startFade(
          from: currentVol,
          to: 0.0,
          duration: effectiveFade,
          onUpdate: (val) {
            try {
              oldPlayer?.setVolume(val);
            } catch (_) {}
          },
          onComplete: () {
            try {
              oldPlayer?.stop();
              oldPlayer?.dispose();
            } catch (_) {}
            if (_outgoingPlayer == oldPlayer) {
              _outgoingPlayer = null;
            }
          },
        );
      } else {
        // A paused player stops; a track fading out after stop() keeps fading.
        _fadeController.stop();
        final previous = _player;
        _player = null;
        if (previous != null) await _release(previous);
      }

      _player = player;
      _fadeMultiplier = effectiveFade.inMilliseconds > 0 ? 0.0 : 1.0;
      await player.setVolume(effectiveVolume);
      await player.setLooping(false);

      player.onDurationChanged.listen(
        (d) {
          if (identical(player, _player)) _currentTrackDuration = d;
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in onDurationChanged', details: '$e');
        },
      );

      player.onPositionChanged.listen(
        (pos) {
          if (!identical(player, _player)) return;
          position.value = pos;
          final total = _currentTrackDuration;
          if (total != null && total.inMilliseconds > 4000) {
            final transitionDuration = total.inMilliseconds > 8000
                ? const Duration(milliseconds: 2000)
                : const Duration(milliseconds: 1000);
            if (pos >= total - transitionDuration && !_loopTransitioning && _isPlaying) {
              _triggerSeamlessLoopTransition(track, transitionDuration);
            }
          }
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in onPositionChanged', details: '$e');
        },
      );

      player.onPlayerComplete.listen(
        (_) {
          if (!identical(player, _player)) return;
          if (!_isPlaying) {
            _endedWhilePaused(player);
          } else if (!_loopTransitioning && _currentTrack?.id == track.id) {
            _triggerSeamlessLoopTransition(track, const Duration(milliseconds: 800));
          }
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in onPlayerComplete', details: '$e');
        },
      );

      LoggerService().info('MusicBus: Invoking BusPlayer.play for ${file.path}');
      await player.play(file.path);

      // Stopped or replaced by another track while the file was loading.
      if (!identical(player, _player)) return;
      // Paused while the file was loading.
      if (!_isPlaying) {
        _fadeController.stop();
        _fadeMultiplier = 1.0;
        await _pausePlayer(player);
        return;
      }
      LoggerService().info('MusicBus: Playback started successfully!');

      if (effectiveFade.inMilliseconds > 0) {
        _fadeController.startFade(
          from: 0.0,
          to: 1.0,
          duration: effectiveFade,
          onUpdate: (val) {
            _fadeMultiplier = val;
            _applyPlayerVolume();
          },
          onComplete: () {
            _fadeMultiplier = 1.0;
            _applyPlayerVolume();
          },
        );
      }
    } catch (e, stack) {
      LoggerService().error('MusicBus: Exception during playback', details: '$e\n$stack');
      await _release(player);
      if (identical(player, _player)) {
        _player = null;
        _isPlaying = false;
        notifyListeners();
      }
    }
  }

  Future<void> _triggerSeamlessLoopTransition(AudioTrack track, Duration transitionDuration) async {
    if (_loopTransitioning || !_isPlaying) return;
    _loopTransitioning = true;
    LoggerService().info('MusicBus: Seamless loop crossfade triggered for "${track.title}" (${transitionDuration.inMilliseconds}ms)');

    final file = File(track.filePath).absolute;
    if (!file.existsSync()) {
      _loopTransitioning = false;
      return;
    }

    BusPlayer? nextPlayer;
    try {
      final oldPlayer = _player;
      _outgoingFadeController.stop();
      _outgoingPlayer?.dispose();
      _outgoingPlayer = oldPlayer;

      nextPlayer = BusPlayer.forFile(file.path);
      _player = nextPlayer;

      await nextPlayer.setVolume(0.0);
      await nextPlayer.setLooping(false);

      final next = nextPlayer;
      next.onDurationChanged.listen(
        (d) {
          if (identical(next, _player)) _currentTrackDuration = d;
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in loop transition onDurationChanged', details: '$e');
        },
      );

      next.onPositionChanged.listen(
        (pos) {
          if (!identical(next, _player)) return;
          position.value = pos;
          final total = _currentTrackDuration;
          if (total != null && total.inMilliseconds > 4000) {
            final nextTransition = total.inMilliseconds > 8000
                ? const Duration(milliseconds: 2000)
                : const Duration(milliseconds: 1000);
            if (pos >= total - nextTransition && !_loopTransitioning && _isPlaying) {
              _triggerSeamlessLoopTransition(track, nextTransition);
            }
          }
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in loop transition onPositionChanged', details: '$e');
        },
      );

      next.onPlayerComplete.listen(
        (_) {
          if (!identical(next, _player)) return;
          if (!_isPlaying) {
            _endedWhilePaused(next);
          } else if (!_loopTransitioning && _currentTrack?.id == track.id) {
            _triggerSeamlessLoopTransition(track, const Duration(milliseconds: 800));
          }
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in loop transition onPlayerComplete', details: '$e');
        },
      );

      await next.play(file.path);
      // Stopped while the next loop was loading; stop() released both players.
      if (!identical(next, _player)) return;

      // Crossfade: fade out oldPlayer, fade in nextPlayer
      if (oldPlayer != null) {
        final currentVol = effectiveVolume;
        _outgoingFadeController.startFade(
          from: currentVol,
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
            if (_outgoingPlayer == oldPlayer) {
              _outgoingPlayer = null;
            }
          },
        );
      }

      _fadeMultiplier = 0.0;
      _fadeController.startFade(
        from: 0.0,
        to: 1.0,
        duration: transitionDuration,
        onUpdate: (v) {
          _fadeMultiplier = v;
          _applyPlayerVolume();
        },
        onComplete: () {
          _fadeMultiplier = 1.0;
          _applyPlayerVolume();
          _loopTransitioning = false;
        },
      );
    } catch (e, stack) {
      LoggerService().error('MusicBus: Error during seamless loop transition', details: '$e\n$stack');
      try {
        await nextPlayer?.stop();
        await nextPlayer?.dispose();
      } catch (_) {}
      _loopTransitioning = false;
    }
  }

  /// Shows [track] as the next one without playing it (scene change). The
  /// state changes at once; a playing track fades out with the crossfade.
  Future<void> prepareTrack(AudioTrack track, {Duration? fadeDuration}) async {
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;
    final player = _player;
    final audible = _isPlaying || (player != null && !_playerPaused) ? effectiveVolume : 0.0;

    _fadeController.stop();
    _player = null;
    _playerPaused = false;
    _currentTrack = track;
    _currentIntensity = track.intensity;
    _isPlaying = false;
    _loopTransitioning = false;
    _fadeMultiplier = 1.0;
    _currentTrackDuration = null;
    position.value = Duration.zero;
    LoggerService().info('MusicBus: Prepared track "${track.title}" (waiting for GM playback)', details: 'Path: ${track.filePath}');
    notifyListeners();

    if (player != null && effectiveFade.inMilliseconds > 0 && audible > 0) {
      _fadeOutAndRelease(player, from: audible, duration: effectiveFade);
    } else {
      await _stopCurrentAudio();
      if (player != null) await _release(player);
    }
  }

  void setIntensity(MusicIntensity newIntensity) {
    if (_currentIntensity == newIntensity) return;
    _currentIntensity = newIntensity;
    LoggerService().info('MusicBus: Intensity changed to ${newIntensity.name}');
    notifyListeners();
  }

  void setVolume(double newVolume) {
    _volume = newVolume.clamp(0.0, 1.0);
    LoggerService().info('MusicBus: Volume set to $_volume');
    _applyPlayerVolume();
    notifyListeners();
  }

  void updateDuckingMultiplier(double multiplier) {
    _duckingMultiplier = multiplier.clamp(0.0, 1.0);
    _applyPlayerVolume();
    notifyListeners();
  }

  // Pause, resume and stop change the state (and the play/pause icon) at
  // once; only the sound follows the fade.

  Future<void> pause({Duration? fadeDuration}) async {
    if (!_isPlaying) return;
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;
    _isPlaying = false;
    notifyListeners();

    final player = _player;
    if (player == null) return;
    if (effectiveFade.inMilliseconds > 0) {
      _fadeController.startFade(
        from: _fadeMultiplier,
        to: 0.0,
        duration: effectiveFade,
        onUpdate: (val) {
          _fadeMultiplier = val;
          _applyPlayerVolume();
        },
        onComplete: () {
          // Resumed or replaced while fading out.
          if (_isPlaying || !identical(player, _player)) return;
          _fadeMultiplier = 1.0;
          _pausePlayer(player);
        },
      );
    } else {
      _fadeController.stop();
      _fadeMultiplier = 1.0;
      await _pausePlayer(player);
    }
  }

  /// The track reached its end while a pause was fading out; resume starts
  /// it again from the beginning.
  void _endedWhilePaused(BusPlayer player) {
    _player = null;
    _playerPaused = false;
    _release(player);
  }

  Future<void> _pausePlayer(BusPlayer player) async {
    try {
      await player.pause();
      _playerPaused = true;
      LoggerService().info('MusicBus: Paused');
    } catch (e) {
      LoggerService().error('MusicBus: Error pausing player', details: '$e');
    }
  }

  Future<void> resume({Duration? fadeDuration}) async {
    final track = _currentTrack;
    if (track == null || _isPlaying) return;
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;
    _isPlaying = true;
    notifyListeners();

    final player = _player;
    if (player == null) {
      if (File(track.filePath).existsSync()) {
        await playTrack(track, fadeDuration: effectiveFade);
        return;
      }
      if (effectiveFade.inMilliseconds > 0) {
        _fadeMultiplier = 0.0;
        _fadeController.startFade(
          from: 0.0,
          to: 1.0,
          duration: effectiveFade,
          onUpdate: (val) => _fadeMultiplier = val,
          onComplete: () => _fadeMultiplier = 1.0,
        );
      } else {
        _fadeMultiplier = 1.0;
      }
      return;
    }

    try {
      // A pause that is still fading out turns back from the current level;
      // a paused player starts from silence.
      if (_playerPaused) {
        _fadeMultiplier = effectiveFade.inMilliseconds > 0 ? 0.0 : 1.0;
        await player.setVolume(effectiveVolume);
        await player.resume();
        _playerPaused = false;
      }
      if (!identical(player, _player) || !_isPlaying) return;
      LoggerService().info('MusicBus: Resumed');
      _fadeController.startFade(
        from: _fadeMultiplier,
        to: 1.0,
        duration: effectiveFade,
        onUpdate: (val) {
          _fadeMultiplier = val;
          _applyPlayerVolume();
        },
        onComplete: () {
          _fadeMultiplier = 1.0;
          _applyPlayerVolume();
        },
      );
    } catch (e) {
      LoggerService().error('MusicBus: Error resuming player', details: '$e');
    }
  }

  /// Clears the track at once; the playing sound fades out on its own like
  /// the outgoing side of a crossfade, so a new track can start right away.
  Future<void> stop({Duration? fadeDuration}) async {
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;
    final player = _player;
    final audible = _isPlaying || (player != null && !_playerPaused) ? effectiveVolume : 0.0;

    _fadeController.stop();
    _player = null;
    _playerPaused = false;
    _currentTrack = null;
    _isPlaying = false;
    _loopTransitioning = false;
    _fadeMultiplier = 1.0;
    _currentTrackDuration = null;
    position.value = Duration.zero;
    notifyListeners();

    if (player == null) {
      await _stopCurrentAudio();
      return;
    }
    if (effectiveFade.inMilliseconds > 0 && audible > 0) {
      _fadeOutAndRelease(player, from: audible, duration: effectiveFade);
    } else {
      await _stopCurrentAudio();
      await _release(player);
    }
  }

  /// Fades [player] out on the outgoing fader and frees it at the end.
  void _fadeOutAndRelease(BusPlayer player, {required double from, required Duration duration}) {
    _outgoingFadeController.stop();
    final previous = _outgoingPlayer;
    if (previous != null && !identical(previous, player)) _release(previous);
    _outgoingPlayer = player;
    _outgoingFadeController.startFade(
      from: from,
      to: 0.0,
      duration: duration,
      onUpdate: (val) {
        try {
          player.setVolume(val);
        } catch (_) {}
      },
      onComplete: () {
        if (identical(_outgoingPlayer, player)) _outgoingPlayer = null;
        _release(player);
      },
    );
  }

  Future<void> _release(BusPlayer player) async {
    try {
      await player.stop();
      await player.dispose();
    } catch (e) {
      LoggerService().error('MusicBus: Error disposing player', details: '$e');
    }
  }

  void _applyPlayerVolume() {
    if (_player != null) {
      try {
        _player!.setVolume(effectiveVolume);
      } catch (e) {
        LoggerService().error('MusicBus: Error setting volume', details: '$e');
      }
    }
  }

  Future<void> _stopCurrentAudio() async {
    _fadeController.stop();
    _outgoingFadeController.stop();

    if (_outgoingPlayer != null) {
      try {
        await _outgoingPlayer!.stop();
        await _outgoingPlayer!.dispose();
      } catch (_) {}
      _outgoingPlayer = null;
    }

    if (_player != null) {
      try {
        await _player!.stop();
        await _player!.dispose();
      } catch (e) {
        LoggerService().error('MusicBus: Error disposing player', details: '$e');
      }
      _player = null;
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _fadeController.dispose();
    _outgoingFadeController.dispose();
    _stopCurrentAudio();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
