import 'package:flutter/material.dart';
import '../../services/logger_service.dart';
import 'database_service.dart';

class SettingsService extends ChangeNotifier {
  final DatabaseService? _dbService;
  int _musicFadeMs;
  int _ambientFadeMs;
  int _duckAttackMs;
  int _duckReleaseMs;
  double _duckMultiplier;
  bool _showLogConsoleIcon;
  String _appLanguage; // 'system', 'ru', 'en'
  String? _customDownloadDirectory;

  static const String _kCustomDownloadDirKey = 'custom_download_directory';

  SettingsService({
    DatabaseService? dbService,
    int musicFadeMs = 1500,
    int ambientFadeMs = 1000,
    int duckAttackMs = 300,
    int duckReleaseMs = 1200,
    double duckMultiplier = 0.4,
    bool showLogConsoleIcon = true,
    String appLanguage = 'system',
    String? customDownloadDirectory,
    bool autoLoad = false,
  })  : _dbService = dbService,
        _musicFadeMs = musicFadeMs,
        _ambientFadeMs = ambientFadeMs,
        _duckAttackMs = duckAttackMs,
        _duckReleaseMs = duckReleaseMs,
        _duckMultiplier = duckMultiplier,
        _showLogConsoleIcon = showLogConsoleIcon,
        _appLanguage = _normalizeLanguage(appLanguage),
        _customDownloadDirectory = (customDownloadDirectory != null && customDownloadDirectory.trim().isNotEmpty)
            ? customDownloadDirectory.trim()
            : null {
    if (autoLoad && _dbService != null) {
      loadSettings();
    }
  }

  static String _normalizeLanguage(String lang) {
    if (lang == 'ru' || lang == 'en') return lang;
    return 'system';
  }

  int get musicFadeMs => _musicFadeMs;
  int get ambientFadeMs => _ambientFadeMs;
  int get duckAttackMs => _duckAttackMs;
  int get duckReleaseMs => _duckReleaseMs;
  double get duckMultiplier => _duckMultiplier;
  bool get showLogConsoleIcon => _showLogConsoleIcon;
  String get appLanguage => _appLanguage;
  String? get customDownloadDirectory => _customDownloadDirectory;
  String? get catalogDownloadDirectory => _customDownloadDirectory;
  String? get audioStorageDirectory => _customDownloadDirectory;

  Locale? get currentLocale {
    if (_appLanguage == 'ru') return const Locale('ru');
    if (_appLanguage == 'en') return const Locale('en');
    return null;
  }

  Duration get musicFadeDuration => Duration(milliseconds: _musicFadeMs);
  Duration get ambientFadeDuration => Duration(milliseconds: _ambientFadeMs);
  Duration get duckAttackDuration => Duration(milliseconds: _duckAttackMs);
  Duration get duckReleaseDuration => Duration(milliseconds: _duckReleaseMs);

  /// Loads persisted settings from the database.
  Future<void> loadSettings() async {
    final db = _dbService;
    if (db == null) return;
    try {
      final savedDir = await db.getSetting(_kCustomDownloadDirKey);
      if (savedDir != null && savedDir.isNotEmpty) {
        _customDownloadDirectory = savedDir;
        LoggerService().info('SettingsService: Restored custom download directory: $_customDownloadDirectory');
        notifyListeners();
      }
    } catch (e) {
      LoggerService().warning('SettingsService: Could not restore settings from DB: $e');
    }
  }

  void setAppLanguage(String lang) {
    _appLanguage = _normalizeLanguage(lang);
    LoggerService().info('SettingsService: App language set to $_appLanguage');
    notifyListeners();
  }

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

  void setShowLogConsoleIcon(bool show) {
    _showLogConsoleIcon = show;
    LoggerService().info('SettingsService: Show log console icon set to $_showLogConsoleIcon');
    notifyListeners();
  }

  void setCustomDownloadDirectory(String? path) {
    final trimmed = path?.trim();
    _customDownloadDirectory = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    LoggerService().info('SettingsService: Custom download directory set to ${_customDownloadDirectory ?? "default"}');
    if (_dbService != null) {
      if (_customDownloadDirectory != null) {
        _dbService!.setSetting(_kCustomDownloadDirKey, _customDownloadDirectory!).catchError((e) {
          LoggerService().warning('SettingsService: Could not persist custom download dir: $e');
        });
      } else {
        _dbService!.setSetting(_kCustomDownloadDirKey, '').catchError((e) {
          LoggerService().warning('SettingsService: Could not persist custom download dir: $e');
        });
      }
    }
    notifyListeners();
  }

  void resetCustomDownloadDirectory() {
    setCustomDownloadDirectory(null);
  }

  void resetToDefaults() {
    _musicFadeMs = 1500;
    _ambientFadeMs = 1000;
    _duckAttackMs = 300;
    _duckReleaseMs = 1200;
    _duckMultiplier = 0.4;
    _showLogConsoleIcon = true;
    _appLanguage = 'system';
    _customDownloadDirectory = null;
    if (_dbService != null) {
      _dbService!.setSetting(_kCustomDownloadDirKey, '').catchError((_) {});
    }
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
      'showLogConsoleIcon': _showLogConsoleIcon,
      'appLanguage': _appLanguage,
      'customDownloadDirectory': _customDownloadDirectory,
      'catalogDownloadDirectory': _customDownloadDirectory,
      'audioStorageDirectory': _customDownloadDirectory,
    };
  }

  void loadFromMap(Map<String, dynamic> map) {
    if (map.containsKey('musicFadeMs')) _musicFadeMs = (map['musicFadeMs'] as num).toInt().clamp(0, 10000);
    if (map.containsKey('ambientFadeMs')) _ambientFadeMs = (map['ambientFadeMs'] as num).toInt().clamp(0, 10000);
    if (map.containsKey('duckAttackMs')) _duckAttackMs = (map['duckAttackMs'] as num).toInt().clamp(0, 5000);
    if (map.containsKey('duckReleaseMs')) _duckReleaseMs = (map['duckReleaseMs'] as num).toInt().clamp(0, 10000);
    if (map.containsKey('duckMultiplier')) _duckMultiplier = (map['duckMultiplier'] as num).toDouble().clamp(0.0, 1.0);
    if (map.containsKey('showLogConsoleIcon')) _showLogConsoleIcon = map['showLogConsoleIcon'] as bool;
    if (map.containsKey('appLanguage')) _appLanguage = _normalizeLanguage(map['appLanguage'] as String);
    if (map.containsKey('customDownloadDirectory')) {
      final val = map['customDownloadDirectory'] as String?;
      _customDownloadDirectory = (val != null && val.trim().isNotEmpty) ? val.trim() : null;
    } else if (map.containsKey('catalogDownloadDirectory')) {
      final val = map['catalogDownloadDirectory'] as String?;
      _customDownloadDirectory = (val != null && val.trim().isNotEmpty) ? val.trim() : null;
    } else if (map.containsKey('audioStorageDirectory')) {
      final val = map['audioStorageDirectory'] as String?;
      _customDownloadDirectory = (val != null && val.trim().isNotEmpty) ? val.trim() : null;
    }
    notifyListeners();
  }
}
