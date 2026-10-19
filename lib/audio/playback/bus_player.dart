import 'dart:async';
import 'package:path/path.dart' as p;
import 'legacy_bus_player.dart';
import 'soloud_bus_player.dart';

/// One voice of a bus: plays a file, reports its length, position and end.
/// The bus controllers drive fades, crossfades and ducking through
/// [setVolume]; the player only follows.
abstract class BusPlayer {
  /// Picks the backend for [path]: SoLoud (follows the chosen output device)
  /// for the formats it decodes, the system player for the rest (M4A/AAC).
  factory BusPlayer.forFile(String path) =>
      LegacyBusPlayer.handles(path) ? LegacyBusPlayer() : SoLoudBusPlayer();

  /// Extensions SoLoud decodes; others go to [LegacyBusPlayer].
  static const List<String> soloudExtensions = ['mp3', 'wav', 'ogg', 'flac'];

  static String extensionOf(String path) => p.extension(path).replaceFirst('.', '').toLowerCase();

  Stream<Duration> get onDurationChanged;
  Stream<Duration> get onPositionChanged;
  Stream<void> get onPlayerComplete;

  Future<void> setVolume(double volume);
  Future<void> setLooping(bool looping);

  /// Starts [path] from the beginning. Throws when the file cannot be played.
  Future<void> play(String path);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}
