import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/data/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService Unit Tests', () {
    late SettingsService settings;

    setUp(() {
      settings = SettingsService();
    });

    test('should initialize with correct default configuration settings', () {
      // Arrange & Act
      // Initialized in setUp

      // Assert
      expect(settings.musicFadeMs, equals(1500));
      expect(settings.ambientFadeMs, equals(1000));
      expect(settings.duckAttackMs, equals(300));
      expect(settings.duckReleaseMs, equals(1200));
      expect(settings.duckMultiplier, equals(0.4));
      expect(settings.showLogConsoleIcon, isTrue);
      expect(settings.appLanguage, equals('system'));
      expect(settings.currentLocale, isNull);
      expect(settings.musicFadeDuration, equals(const Duration(milliseconds: 1500)));
      expect(settings.ambientFadeDuration, equals(const Duration(milliseconds: 1000)));
      expect(settings.duckAttackDuration, equals(const Duration(milliseconds: 300)));
      expect(settings.duckReleaseDuration, equals(const Duration(milliseconds: 1200)));
    });

    test('should update audio engine parameters and notify listeners on every modification', () {
      // Arrange
      int notifyCount = 0;
      settings.addListener(() => notifyCount++);

      // Act & Assert - music fade
      settings.setMusicFadeMs(2000);
      expect(settings.musicFadeMs, equals(2000));
      expect(notifyCount, equals(1));

      // Act & Assert - ambient fade
      settings.setAmbientFadeMs(800);
      expect(settings.ambientFadeMs, equals(800));
      expect(notifyCount, equals(2));

      // Act & Assert - duck attack
      settings.setDuckAttackMs(250);
      expect(settings.duckAttackMs, equals(250));
      expect(notifyCount, equals(3));

      // Act & Assert - duck release
      settings.setDuckReleaseMs(1500);
      expect(settings.duckReleaseMs, equals(1500));
      expect(notifyCount, equals(4));

      // Act & Assert - duck multiplier
      settings.setDuckMultiplier(0.5);
      expect(settings.duckMultiplier, equals(0.5));
      expect(notifyCount, equals(5));

      // Act & Assert - log console toggle
      settings.setShowLogConsoleIcon(false);
      expect(settings.showLogConsoleIcon, isFalse);
      expect(notifyCount, equals(6));
    });

    test('should update application language and active locale when setAppLanguage is called', () {
      // Arrange
      int notifyCount = 0;
      settings.addListener(() => notifyCount++);

      // Act & Assert - Russian
      settings.setAppLanguage('ru');
      expect(settings.appLanguage, equals('ru'));
      expect(settings.currentLocale, equals(const Locale('ru')));
      expect(notifyCount, equals(1));

      // Act & Assert - English
      settings.setAppLanguage('en');
      expect(settings.appLanguage, equals('en'));
      expect(settings.currentLocale, equals(const Locale('en')));
      expect(notifyCount, equals(2));

      // Act & Assert - Fallback system language
      settings.setAppLanguage('unknown');
      expect(settings.appLanguage, equals('system'));
      expect(settings.currentLocale, isNull);
      expect(notifyCount, equals(3));
    });

    test('should clamp configuration numeric values within permissible ranges', () {
      // Arrange & Act
      settings.setMusicFadeMs(-500);
      expect(settings.musicFadeMs, equals(0));

      settings.setMusicFadeMs(99999);
      expect(settings.musicFadeMs, equals(10000));

      settings.setDuckMultiplier(-0.2);
      expect(settings.duckMultiplier, equals(0.0));

      settings.setDuckMultiplier(2.5);
      expect(settings.duckMultiplier, equals(1.0));
    });

    test('should reset all parameters back to default configuration when resetToDefaults is called', () {
      // Arrange
      settings.setMusicFadeMs(3500);
      settings.setDuckMultiplier(0.8);
      settings.setShowLogConsoleIcon(false);
      settings.setAppLanguage('en');

      // Act
      settings.resetToDefaults();

      // Assert
      expect(settings.musicFadeMs, equals(1500));
      expect(settings.ambientFadeMs, equals(1000));
      expect(settings.duckAttackMs, equals(300));
      expect(settings.duckReleaseMs, equals(1200));
      expect(settings.duckMultiplier, equals(0.4));
      expect(settings.showLogConsoleIcon, isTrue);
      expect(settings.appLanguage, equals('system'));
      expect(settings.currentLocale, isNull);
    });

    test('should serialize to Map and restore configuration settings from Map', () {
      // Arrange
      settings.setMusicFadeMs(2200);
      settings.setDuckMultiplier(0.35);
      settings.setShowLogConsoleIcon(false);
      settings.setAppLanguage('ru');

      // Act - export
      final map = settings.toMap();
      expect(map['musicFadeMs'], equals(2200));
      expect(map['duckMultiplier'], equals(0.35));
      expect(map['showLogConsoleIcon'], equals(false));
      expect(map['appLanguage'], equals('ru'));

      // Act - import into fresh instance
      final newSettings = SettingsService();
      newSettings.loadFromMap({
        'musicFadeMs': 4000,
        'ambientFadeMs': 1200,
        'duckAttackMs': 150,
        'duckReleaseMs': 800,
        'duckMultiplier': 0.25,
        'showLogConsoleIcon': false,
        'appLanguage': 'en',
        'customDownloadDirectory': 'D:/MyTtrpgAudio',
      });

      // Assert
      expect(newSettings.musicFadeMs, equals(4000));
      expect(newSettings.ambientFadeMs, equals(1200));
      expect(newSettings.duckAttackMs, equals(150));
      expect(newSettings.duckReleaseMs, equals(800));
      expect(newSettings.duckMultiplier, equals(0.25));
      expect(newSettings.showLogConsoleIcon, isFalse);
      expect(newSettings.appLanguage, equals('en'));
      expect(newSettings.currentLocale, equals(const Locale('en')));
      expect(newSettings.customDownloadDirectory, equals('D:/MyTtrpgAudio'));
    });

    test('should manage custom download directory path and reset appropriately', () {
      // Arrange
      int notifyCount = 0;
      settings.addListener(() => notifyCount++);

      expect(settings.customDownloadDirectory, isNull);
      expect(settings.catalogDownloadDirectory, isNull);
      expect(settings.audioStorageDirectory, isNull);

      // Act & Assert - Set directory
      settings.setCustomDownloadDirectory('C:/CustomAudio/Library');
      expect(settings.customDownloadDirectory, equals('C:/CustomAudio/Library'));
      expect(settings.catalogDownloadDirectory, equals('C:/CustomAudio/Library'));
      expect(settings.audioStorageDirectory, equals('C:/CustomAudio/Library'));
      expect(notifyCount, equals(1));

      // Act & Assert - Reset directory
      settings.resetCustomDownloadDirectory();
      expect(settings.customDownloadDirectory, isNull);
      expect(notifyCount, equals(2));

      // Act & Assert - Trim whitespace
      settings.setCustomDownloadDirectory('  E:/OtherPath  ');
      expect(settings.customDownloadDirectory, equals('E:/OtherPath'));
      expect(notifyCount, equals(3));

      // Act & Assert - Reset via resetToDefaults
      settings.resetToDefaults();
      expect(settings.customDownloadDirectory, isNull);
      expect(notifyCount, equals(4));
    });
  });
}
