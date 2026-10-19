import 'package:audioplayers/audioplayers.dart';
import 'bus_player.dart';

/// System player (audioplayers) for formats SoLoud does not decode. Always
/// plays on the system default output device.
class LegacyBusPlayer implements BusPlayer {
  final AudioPlayer _player = AudioPlayer();

  static bool handles(String path) => !BusPlayer.soloudExtensions.contains(BusPlayer.extensionOf(path));

  @override
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  @override
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  @override
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setLooping(bool looping) => _player.setReleaseMode(looping ? ReleaseMode.loop : ReleaseMode.stop);

  @override
  Future<void> play(String path) => _player.play(DeviceFileSource(path));

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
