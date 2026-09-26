import 'dart:async';
import 'fade_controller.dart';
import '../services/logger_service.dart';

class DuckingController {
  double duckedVolumeMultiplier;
  Duration attackDuration;
  Duration releaseDuration;

  Timer? _holdTimer;
  final FadeController _fadeController = FadeController();
  double _currentMultiplier = 1.0;
  bool _isDucked = false;

  DuckingController({
    this.duckedVolumeMultiplier = 0.4,
    this.attackDuration = Duration.zero,
    this.releaseDuration = const Duration(milliseconds: 1200),
  });

  bool get isDucked => _isDucked;
  double get currentMultiplier => _currentMultiplier;

  void updateSettings({
    double? duckMultiplier,
    Duration? attack,
    Duration? release,
  }) {
    if (duckMultiplier != null) duckedVolumeMultiplier = duckMultiplier.clamp(0.0, 1.0);
    if (attack != null) attackDuration = attack;
    if (release != null) releaseDuration = release;
  }

  void triggerDuck({
    required Function(double multiplier) onVolumeUpdate,
    Duration? holdDuration,
  }) {
    _isDucked = true;
    _holdTimer?.cancel();
    _fadeController.stop();

    LoggerService().info(
      'Ducking: Triggering ducking curve',
      details: 'Attack: ${attackDuration.inMilliseconds}ms, Release: ${releaseDuration.inMilliseconds}ms, Target: $duckedVolumeMultiplier',
    );

    void scheduleRelease() {
      final hold = holdDuration ?? (releaseDuration > const Duration(milliseconds: 200) ? const Duration(milliseconds: 400) : Duration.zero);
      _holdTimer = Timer(hold, () {
        if (releaseDuration.inMilliseconds > 0) {
          _fadeController.startFade(
            from: _currentMultiplier,
            to: 1.0,
            duration: releaseDuration,
            onUpdate: (val) {
              _currentMultiplier = val;
              onVolumeUpdate(_currentMultiplier);
            },
            onComplete: () {
              _currentMultiplier = 1.0;
              _isDucked = false;
              onVolumeUpdate(1.0);
              LoggerService().info('Ducking: Released and restored to full volume');
            },
          );
        } else {
          _currentMultiplier = 1.0;
          _isDucked = false;
          onVolumeUpdate(1.0);
        }
      });
    }

    if (attackDuration.inMilliseconds > 0) {
      _fadeController.startFade(
        from: _currentMultiplier,
        to: duckedVolumeMultiplier,
        duration: attackDuration,
        onUpdate: (val) {
          _currentMultiplier = val;
          onVolumeUpdate(_currentMultiplier);
        },
        onComplete: () {
          _currentMultiplier = duckedVolumeMultiplier;
          onVolumeUpdate(_currentMultiplier);
          scheduleRelease();
        },
      );
    } else {
      _currentMultiplier = duckedVolumeMultiplier;
      onVolumeUpdate(_currentMultiplier);
      scheduleRelease();
    }
  }

  void reset({required Function(double multiplier) onVolumeUpdate}) {
    _holdTimer?.cancel();
    _fadeController.stop();
    _currentMultiplier = 1.0;
    _isDucked = false;
    onVolumeUpdate(1.0);
  }

  void dispose() {
    _holdTimer?.cancel();
    _fadeController.dispose();
  }
}
