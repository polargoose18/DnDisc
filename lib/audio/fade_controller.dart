import 'dart:async';

class FadeController {
  Timer? _fadeTimer;
  double _currentValue = 1.0;
  bool _isFading = false;

  double get currentValue => _currentValue;
  bool get isFading => _isFading;

  void startFade({
    required double from,
    required double to,
    required Duration duration,
    required void Function(double value) onUpdate,
    void Function()? onComplete,
    Duration stepInterval = const Duration(milliseconds: 30),
  }) {
    _fadeTimer?.cancel();
    _currentValue = from.clamp(0.0, 1.0);
    final targetValue = to.clamp(0.0, 1.0);

    if (duration.inMilliseconds <= 0 || (from - targetValue).abs() < 0.001) {
      _currentValue = targetValue;
      _isFading = false;
      onUpdate(_currentValue);
      onComplete?.call();
      return;
    }

    _isFading = true;
    final totalSteps = (duration.inMilliseconds / stepInterval.inMilliseconds).clamp(1, 1000).toInt();
    final stepDelta = (targetValue - from) / totalSteps;
    int currentStep = 0;

    onUpdate(_currentValue);

    _fadeTimer = Timer.periodic(stepInterval, (timer) {
      currentStep++;
      if (currentStep >= totalSteps) {
        _currentValue = targetValue;
        _isFading = false;
        timer.cancel();
        _fadeTimer = null;
        onUpdate(_currentValue);
        onComplete?.call();
      } else {
        _currentValue = (_currentValue + stepDelta).clamp(0.0, 1.0);
        onUpdate(_currentValue);
      }
    });
  }

  void stop() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _isFading = false;
  }

  void dispose() {
    stop();
  }
}
