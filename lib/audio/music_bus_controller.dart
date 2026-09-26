import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/audio_track.dart';
import '../services/logger_service.dart';
import 'fade_controller.dart';

class MusicBusController extends ChangeNotifier {
  AudioTrack? _currentTrack;
  double _volume = 1.0;
  double _duckingMultiplier = 1.0;
  double _fadeMultiplier = 1.0;
  bool _isPlaying = false;
  MusicIntensity _currentIntensity = MusicIntensity.calm;

  AudioPlayer? _player;
  AudioPlayer? _outgoingPlayer; // For crossfading
  final FadeController _fadeController = FadeController();
  final FadeController _outgoingFadeController = FadeController();

  AudioTrack? get currentTrack => _currentTrack;
  double get rawVolume => _volume;
  double get duckingMultiplier => _duckingMultiplier;
  double get fadeMultiplier => _fadeMultiplier;
  double get effectiveVolume => (_volume * _duckingMultiplier * _fadeMultiplier).clamp(0.0, 1.0);
  bool get isPlaying => _isPlaying;
  MusicIntensity get currentIntensity => _currentIntensity;

  Future<void> playTrack(
    AudioTrack track, {
    Duration fadeDuration = const Duration(milliseconds: 1500),
  }) async {
    _currentTrack = track;
    _currentIntensity = track.intensity;

    LoggerService().info('MusicBus: Start playing track "${track.title}"', details: 'Path: ${track.filePath}');

    final file = File(track.filePath);
    if (!file.existsSync()) {
      LoggerService().warning('MusicBus: Local file does not exist', details: 'Path: ${track.filePath}');
      _isPlaying = false;
      notifyListeners();
      return;
    }

    try {
      // If we already have an active player, initiate crossfade
      if (_player != null && _isPlaying && fadeDuration.inMilliseconds > 0) {
        _outgoingFadeController.stop();
        _outgoingPlayer?.dispose();
        _outgoingPlayer = _player;
        _player = null;

        final oldPlayer = _outgoingPlayer;
        final currentVol = effectiveVolume;
        _outgoingFadeController.startFade(
          from: currentVol,
          to: 0.0,
          duration: fadeDuration,
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
      _fadeMultiplier = fadeDuration.inMilliseconds > 0 ? 0.0 : 1.0;
      await _player!.setVolume(effectiveVolume);
      await _player!.setReleaseMode(ReleaseMode.loop);

      LoggerService().info('MusicBus: Invoking AudioPlayer.play for ${file.path}');
      await _player!.play(DeviceFileSource(file.path));

      _isPlaying = true;
      LoggerService().info('MusicBus: Playback started successfully!');

      if (fadeDuration.inMilliseconds > 0) {
        _fadeController.startFade(
          from: 0.0,
          to: 1.0,
          duration: fadeDuration,
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
    }

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
    _applyPlayerVolume();
    notifyListeners();
  }

  void updateDuckingMultiplier(double multiplier) {
    _duckingMultiplier = multiplier.clamp(0.0, 1.0);
    _applyPlayerVolume();
    notifyListeners();
  }

  Future<void> pause({Duration fadeDuration = const Duration(milliseconds: 600)}) async {
    if (!_isPlaying) return;

    if (fadeDuration.inMilliseconds > 0 && _player != null) {
      final startFade = _fadeMultiplier;
      _fadeController.startFade(
        from: startFade,
        to: 0.0,
        duration: fadeDuration,
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

  Future<void> resume({Duration fadeDuration = const Duration(milliseconds: 1000)}) async {
    if (_currentTrack != null) {
      _isPlaying = true;
      if (_player != null) {
        try {
          if (fadeDuration.inMilliseconds > 0) {
            _fadeMultiplier = 0.0;
            await _player!.setVolume(0.0);
            await _player!.resume();
            LoggerService().info('MusicBus: Resumed with fade-in');

            _fadeController.startFade(
              from: 0.0,
              to: 1.0,
              duration: fadeDuration,
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
      }
      notifyListeners();
    }
  }

  Future<void> stop({Duration fadeDuration = const Duration(milliseconds: 800)}) async {
    if (fadeDuration.inMilliseconds > 0 && _player != null && _isPlaying) {
      final startFade = _fadeMultiplier;
      _fadeController.startFade(
        from: startFade,
        to: 0.0,
        duration: fadeDuration,
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
