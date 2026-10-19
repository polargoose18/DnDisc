import '../services/logger_service.dart';
import 'fade_controller.dart';
import 'playback/bus_player.dart';

/// Voices that no longer belong to a track or a layer and fade out on their
/// own before they are freed: the outgoing side of a crossfade, a stopped
/// track, a turned-off ambient layer.
class FadingVoices {
  /// Name of the owner in the log messages.
  final String owner;
  final Map<BusPlayer, FadeController> _fading = {};

  FadingVoices(this.owner);

  /// Stops and frees [player] at once.
  Future<void> release(BusPlayer player) async {
    try {
      await player.stop();
      await player.dispose();
    } catch (e) {
      LoggerService().error('$owner: Error disposing player', details: '$e');
    }
  }

  /// Fades [player] from [from] to silence and frees it. With [replaceOthers]
  /// the voices still fading out are cut off first (one crossfade at a time).
  void fadeOutAndRelease(
    BusPlayer player, {
    required double from,
    required Duration duration,
    bool replaceOthers = false,
  }) {
    if (replaceOthers) releaseAll();
    final fader = FadeController();
    _fading[player] = fader;
    fader.startFade(
      from: from,
      to: 0.0,
      duration: duration,
      onUpdate: (value) {
        try {
          player.setVolume(value);
        } catch (_) {}
      },
      onComplete: () {
        if (_fading.remove(player) == null) return;
        fader.dispose();
        release(player);
      },
    );
  }

  /// Cuts off every fading voice.
  Future<void> releaseAll() {
    final voices = _fading.keys.toList();
    for (final fader in _fading.values) {
      fader.dispose();
    }
    _fading.clear();
    return Future.wait(voices.map(release));
  }
}
