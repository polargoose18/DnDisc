import 'package:flutter/foundation.dart';
import 'logger_service.dart';

class SettingsService extends ChangeNotifier {
  int _musicFadeMs;
  int _ambientFadeMs;
  int _duckAttackMs;
  int _duckReleaseMs;
  double _duckMultiplier;

  SettingsService({
    int musicFadeMs = 1500,
    int ambientFadeMs = 1000,
    int duckAttackMs = 300,
    int duckReleaseMs = 1200,
    double duckMultiplier = 0.4,
  })  : _musicFadeMs = musicFadeMs,
        _ambientFadeMs = ambientFadeMs,
        _duckAttackMs = duckAttackMs,
        _duckReleaseMs = duckReleaseMs,
        _duckMultiplier = duckMultiplier;

  int get musicFadeMs => _musicFadeMs;
  int get ambientFadeMs => _ambientFadeMs;
  int get duckAttackMs => _duckAttackMs;
  int get duckReleaseMs => _duckReleaseMs;
  double get duckMultiplier => _duckMultiplier;

  Duration get musicFadeDuration => Duration(milliseconds: _musicFadeMs);
  Duration get ambientFadeDuration => Duration(milliseconds: _ambientFadeMs);
  Duration get duckAttackDuration => Duration(milliseconds: _duckAttackMs);
  Duration get duckReleaseDuration => Duration(milliseconds: _duckReleaseMs);

  void setMusicFadeMs(int ms) {
    _musicFadeMs = ms.clamp(0, 10000);
    LoggerService().info('SettingsService: Music fade duration set to ${_musicFadeMs}ms');
    notifyListeners();
  }

  void setAmbientFadeMs(int ms) {
    _ambientFadeMs = ms.clamp(0, 10000);
    LoggerService().info('SettingsService: Ambient fade duration set to ${_ambientFadeMs}ms');
    notifyListeners();
  }

  void setDuckAttackMs(int ms) {
    _duckAttackMs = ms.clamp(0, 5000);
    LoggerService().info('SettingsService: Duck attack duration set to ${_duckAttackMs}ms');
    notifyListeners();
  }

  void setDuckReleaseMs(int ms) {
    _duckReleaseMs = ms.clamp(0, 10000);
    LoggerService().info('SettingsService: Duck release duration set to ${_duckReleaseMs}ms');
    notifyListeners();
  }

  void setDuckMultiplier(double multiplier) {
    _duckMultiplier = multiplier.clamp(0.0, 1.0);
    LoggerService().info('SettingsService: Duck multiplier set to ${(multiplier * 100).toStringAsFixed(0)}%');
    notifyListeners();
  }

  void resetToDefaults() {
    _musicFadeMs = 1500;
    _ambientFadeMs = 1000;
    _duckAttackMs = 300;
    _duckReleaseMs = 1200;
    _duckMultiplier = 0.4;
    LoggerService().info('SettingsService: Reset all settings to default values');
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'musicFadeMs': _musicFadeMs,
      'ambientFadeMs': _ambientFadeMs,
      'duckAttackMs': _duckAttackMs,
      'duckReleaseMs': _duckReleaseMs,
      'duckMultiplier': _duckMultiplier,
    };
  }

  void loadFromMap(Map<String, dynamic> map) {
    if (map.containsKey('musicFadeMs')) _musicFadeMs = (map['musicFadeMs'] as num).toInt().clamp(0, 10000);
    if (map.containsKey('ambientFadeMs')) _ambientFadeMs = (map['ambientFadeMs'] as num).toInt().clamp(0, 10000);
    if (map.containsKey('duckAttackMs')) _duckAttackMs = (map['duckAttackMs'] as num).toInt().clamp(0, 5000);
    if (map.containsKey('duckReleaseMs')) _duckReleaseMs = (map['duckReleaseMs'] as num).toInt().clamp(0, 10000);
    if (map.containsKey('duckMultiplier')) _duckMultiplier = (map['duckMultiplier'] as num).toDouble().clamp(0.0, 1.0);
    notifyListeners();
  }
}
