import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/models/audio_track.dart';
import '../services/logger_service.dart';
import 'fade_controller.dart';
import 'fading_voices.dart';
import 'playback/bus_player.dart';
import 'playback/soloud_engine.dart';

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
  final FadingVoices _outgoing = FadingVoices('MusicBus');
  final FadeController _fadeController = FadeController();
  Duration? _currentTrackDuration;

  /// Playback position of the current track; updated by the player without notifying listeners.
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

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

  /// Sound comes out now: playing, or a pause still fading out.
  bool get isAudible => _player != null && !_playerPaused;

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

    final player = BusPlayer.forFile(file.path, bus: SoLoudEngine.musicBus);
    try {
      // If we already have an active player, initiate crossfade
      if (wasAudible && effectiveFade.inMilliseconds > 0) {
        _fadeController.stop();
        final outgoing = _player!;
        _player = null;
        _outgoing.fadeOutAndRelease(outgoing, from: effectiveVolume, duration: effectiveFade, replaceOthers: true);
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
      await player.setLooping(true);
      await player.setLoopRegion(start: _loopStart(track), end: _loopEnd(track));

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
          if (identical(player, _player)) position.value = pos;
        },
        onError: (e) {
          LoggerService().warning('MusicBus: Error in onPositionChanged', details: '$e');
        },
      );

      // The voice loops on its own; it ends only when it fails or a pause
      // fade ran out the file.
      player.onPlayerComplete.listen(
        (_) {
          if (!identical(player, _player)) return;
          if (!_isPlaying) {
            _endedWhilePaused(player);
          } else if (_currentTrack?.id == track.id) {
            _restartEndedVoice(player, file.path);
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

  /// Loop region of [track] in the file; SoLoud loops it sample-exact.
  static Duration _loopStart(AudioTrack track) => Duration(milliseconds: track.loopStartMs ?? 0);

  static Duration? _loopEnd(AudioTrack track) {
    final end = track.loopEndMs;
    if (end == null || end <= (track.loopStartMs ?? 0)) return null;
    return Duration(milliseconds: end);
  }

  /// A voice that should loop has ended: start the file again.
  Future<void> _restartEndedVoice(BusPlayer player, String path) async {
    try {
      await player.play(path);
    } catch (e) {
      LoggerService().error('MusicBus: Could not restart the looping track', details: '$e');
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
    _fadeMultiplier = 1.0;
    _currentTrackDuration = null;
    position.value = Duration.zero;
    LoggerService().info('MusicBus: Prepared track "${track.title}" (waiting for GM playback)', details: 'Path: ${track.filePath}');
    notifyListeners();

    if (player != null && effectiveFade.inMilliseconds > 0 && audible > 0) {
      _outgoing.fadeOutAndRelease(player, from: audible, duration: effectiveFade, replaceOthers: true);
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
    // Changes every ~30 ms and no screen shows it, so listeners are not told.
    _applyPlayerVolume();
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
    _fadeMultiplier = 1.0;
    _currentTrackDuration = null;
    position.value = Duration.zero;
    notifyListeners();

    if (player == null) {
      await _stopCurrentAudio();
      return;
    }
    if (effectiveFade.inMilliseconds > 0 && audible > 0) {
      _outgoing.fadeOutAndRelease(player, from: audible, duration: effectiveFade, replaceOthers: true);
    } else {
      await _stopCurrentAudio();
      await _release(player);
    }
  }

  Future<void> _release(BusPlayer player) => _outgoing.release(player);

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
    await _outgoing.releaseAll();

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
