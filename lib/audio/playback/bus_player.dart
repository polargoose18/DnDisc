import 'dart:async';
import 'package:flutter/foundation.dart';
import 'soloud_bus_player.dart';

/// One voice of a bus: plays a file, reports its length, position and end.
/// The bus controllers drive fades, crossfades and ducking through
/// [setVolume]; the player only follows.
abstract class BusPlayer {
  /// A SoLoud voice for [path] (MP3, WAV, OGG, FLAC and, through the
  /// system decoders, M4A/AAC). With [bus] it plays through that mixing bus
  /// of the engine, whose spectrum the visualizers read (see
  /// [SoLoudEngine.musicBus] and [SoLoudEngine.ambientBus]).
  factory BusPlayer.forFile(String path, {String? bus}) {
    final override = debugFactory;
    if (override != null) return override(path);
    return SoLoudBusPlayer(bus: bus);
  }

  /// Replaces the backend in tests (there is no audio output there).
  @visibleForTesting
  static BusPlayer Function(String path)? debugFactory;

  Stream<Duration> get onDurationChanged;
  Stream<Duration> get onPositionChanged;
  Stream<void> get onPlayerComplete;

  Future<void> setVolume(double volume);
  Future<void> setLooping(bool looping);

  /// The part of the file a looping voice repeats, [start] to [end] (null:
  /// the end of the file), sample-exact. Applies to the next [play].
  Future<void> setLoopRegion({Duration start = Duration.zero, Duration? end});

  /// Starts [path] from the beginning. Throws when the file cannot be played.
  Future<void> play(String path);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}
