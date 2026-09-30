import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../domain/models/audio_track.dart';
import '../services/logger_service.dart';
import 'fade_controller.dart';

class MusicBusController extends ChangeNotifier {
  AudioTrack? _currentTrack;
  double _volume = 1.0;
  double _masterVolume = 1.0;
  double _duckingMultiplier = 1.0;
  double _fadeMultiplier = 1.0;
  bool _isPlaying = false;
  MusicIntensity _currentIntensity = MusicIntensity.calm;
  Duration _defaultFadeDuration;

  AudioPlayer? _player;
  AudioPlayer? _outgoingPlayer; // For crossfading
  final FadeController _fadeController = FadeController();
  final FadeController _outgoingFadeController = FadeController();
  Duration? _currentTrackDuration;
  bool _loopTransitioning = false;

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

    LoggerService().info('MusicBus: Start playing track "${track.title}"', details: 'Path: ${track.filePath}');

    final file = File(track.filePath).absolute;
    if (!file.existsSync()) {
      LoggerService().warning('MusicBus: Local file does not exist', details: 'Path: ${file.path}');
      _isPlaying = false;
      notifyListeners();
      return;
    }

    try {
      // If we already have an active player, initiate crossfade
      if (_player != null && _isPlaying && effectiveFade.inMilliseconds > 0) {
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
        await _stopCurrentAudio();
      }

      _player = AudioPlayer();
      _fadeMultiplier = effectiveFade.inMilliseconds > 0 ? 0.0 : 1.0;
      await _player!.setVolume(effectiveVolume);
      await _player!.setReleaseMode(ReleaseMode.stop);

      _player!.onDurationChanged.listen(
        (d) {
          _currentTrackDuration = d;
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in onDurationChanged', details: '$e');
        },
      );

      _player!.onPositionChanged.listen(
        (pos) {
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

      _player!.onPlayerComplete.listen(
        (_) {
          if (!_loopTransitioning && _isPlaying && _currentTrack?.id == track.id) {
            _triggerSeamlessLoopTransition(track, const Duration(milliseconds: 800));
          }
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in onPlayerComplete', details: '$e');
        },
      );

      LoggerService().info('MusicBus: Invoking AudioPlayer.play for ${file.path}');
      await _player!.play(DeviceFileSource(file.path));

      _isPlaying = true;
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
      _isPlaying = false;
      try {
        await _player?.stop();
        await _player?.dispose();
      } catch (_) {}
      _player = null;
    }

    notifyListeners();
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

    AudioPlayer? nextPlayer;
    try {
      final oldPlayer = _player;
      _outgoingFadeController.stop();
      _outgoingPlayer?.dispose();
      _outgoingPlayer = oldPlayer;

      nextPlayer = AudioPlayer();
      _player = nextPlayer;

      await nextPlayer.setVolume(0.0);
      await nextPlayer.setReleaseMode(ReleaseMode.stop);

      nextPlayer.onDurationChanged.listen(
        (d) {
          _currentTrackDuration = d;
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in loop transition onDurationChanged', details: '$e');
        },
      );

      nextPlayer.onPositionChanged.listen(
        (pos) {
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

      nextPlayer.onPlayerComplete.listen(
        (_) {
          if (!_loopTransitioning && _isPlaying && _currentTrack?.id == track.id) {
            _triggerSeamlessLoopTransition(track, const Duration(milliseconds: 800));
          }
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in loop transition onPlayerComplete', details: '$e');
        },
      );

      await nextPlayer.play(DeviceFileSource(file.path));

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

  Future<void> prepareTrack(AudioTrack track) async {
    _currentTrack = track;
    _currentIntensity = track.intensity;
    _isPlaying = false;
    _loopTransitioning = false;
    _currentTrackDuration = null;
    await _stopCurrentAudio();
    LoggerService().info('MusicBus: Prepared track "${track.title}" (waiting for GM playback)', details: 'Path: ${track.filePath}');
    notifyListeners();
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

  Future<void> pause({Duration? fadeDuration}) async {
    if (!_isPlaying) return;
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;

    if (effectiveFade.inMilliseconds > 0 && _player != null) {
      final startFade = _fadeMultiplier;
      _fadeController.startFade(
        from: startFade,
        to: 0.0,
        duration: effectiveFade,
        onUpdate: (val) {
          _fadeMultiplier = val;
          _applyPlayerVolume();
        },
        onComplete: () async {
          _isPlaying = false;
          _fadeMultiplier = 1.0;
          try {
            await _player?.pause();
            LoggerService().info('MusicBus: Paused smoothly');
          } catch (e) {
            LoggerService().error('MusicBus: Error pausing player', details: '$e');
          }
          notifyListeners();
        },
      );
    } else {
      _isPlaying = false;
      if (_player != null) {
        try {
          await _player!.pause();
          LoggerService().info('MusicBus: Paused');
        } catch (e) {
          LoggerService().error('MusicBus: Error pausing player', details: '$e');
        }
      }
      notifyListeners();
    }
  }

  Future<void> resume({Duration? fadeDuration}) async {
    if (_currentTrack != null) {
      final effectiveFade = fadeDuration ?? _defaultFadeDuration;
      _isPlaying = true;
      if (_player == null) {
        final file = File(_currentTrack!.filePath);
        if (file.existsSync()) {
          await playTrack(_currentTrack!, fadeDuration: effectiveFade);
          return;
        }
      }
      if (_player != null) {
        try {
          if (effectiveFade.inMilliseconds > 0) {
            _fadeMultiplier = 0.0;
            await _player!.setVolume(0.0);
            await _player!.resume();
            LoggerService().info('MusicBus: Resumed with fade-in');

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
          } else {
            _fadeMultiplier = 1.0;
            await _player!.setVolume(effectiveVolume);
            await _player!.resume();
            LoggerService().info('MusicBus: Resumed');
          }
        } catch (e) {
          LoggerService().error('MusicBus: Error resuming player', details: '$e');
        }
      } else {
        if (effectiveFade.inMilliseconds > 0) {
          _fadeMultiplier = 0.0;
          _fadeController.startFade(
            from: 0.0,
            to: 1.0,
            duration: effectiveFade,
            onUpdate: (val) {
              _fadeMultiplier = val;
            },
            onComplete: () {
              _fadeMultiplier = 1.0;
            },
          );
        } else {
          _fadeMultiplier = 1.0;
        }
      }
      notifyListeners();
    }
  }

  Future<void> stop({Duration? fadeDuration}) async {
    final effectiveFade = fadeDuration ?? _defaultFadeDuration;
    if (effectiveFade.inMilliseconds > 0 && _player != null && _isPlaying) {
      final startFade = _fadeMultiplier;
      _fadeController.startFade(
        from: startFade,
        to: 0.0,
        duration: effectiveFade,
        onUpdate: (val) {
          _fadeMultiplier = val;
          _applyPlayerVolume();
        },
        onComplete: () async {
          await _stopCurrentAudio();
          _currentTrack = null;
          _isPlaying = false;
          _fadeMultiplier = 1.0;
          notifyListeners();
        },
      );
    } else {
      _fadeController.stop();
      await _stopCurrentAudio();
      _currentTrack = null;
      _isPlaying = false;
      _fadeMultiplier = 1.0;
      notifyListeners();
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
