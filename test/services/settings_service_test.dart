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

    test(
      'Что проверяем: Значения по умолчанию в SettingsService. '
      'Входные данные: Новый экземпляр SettingsService. '
      'Ожидаемый результат: musicFadeMs=1500, ambientFadeMs=1000, duckAttackMs=300, duckReleaseMs=1200, duckMultiplier=0.4, showLogConsoleIcon=true, appLanguage="system", currentLocale=null.',
      () {
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
      },
    );

    test(
      'Что проверяем: Установка параметров фейда, даккинга и отображения консоли логов с уведомлением слушателей. '
      'Входные данные: setMusicFadeMs(2000), setAmbientFadeMs(800), setDuckAttackMs(250), setDuckReleaseMs(1500), setDuckMultiplier(0.5), setShowLogConsoleIcon(false). '
      'Ожидаемый результат: Все поля обновляются, notifyListeners вызывается на каждое изменение.',
      () {
        int notifyCount = 0;
        settings.addListener(() => notifyCount++);

        settings.setMusicFadeMs(2000);
        expect(settings.musicFadeMs, equals(2000));
        expect(notifyCount, equals(1));

        settings.setAmbientFadeMs(800);
        expect(settings.ambientFadeMs, equals(800));
        expect(notifyCount, equals(2));

        settings.setDuckAttackMs(250);
        expect(settings.duckAttackMs, equals(250));
        expect(notifyCount, equals(3));

        settings.setDuckReleaseMs(1500);
        expect(settings.duckReleaseMs, equals(1500));
        expect(notifyCount, equals(4));

        settings.setDuckMultiplier(0.5);
        expect(settings.duckMultiplier, equals(0.5));
        expect(notifyCount, equals(5));

        settings.setShowLogConsoleIcon(false);
        expect(settings.showLogConsoleIcon, isFalse);
        expect(notifyCount, equals(6));
      },
    );

    test(
      'Что проверяем: Изменение языка приложения через setAppLanguage. '
      'Входные данные: Вызовы setAppLanguage("ru"), setAppLanguage("en"), setAppLanguage("invalid"). '
      'Ожидаемый результат: appLanguage и currentLocale обновляются соответственно (ru -> Locale("ru"), en -> Locale("en"), invalid -> system / null), notifyListeners вызывается.',
      () {
        int notifyCount = 0;
        settings.addListener(() => notifyCount++);

        settings.setAppLanguage('ru');
        expect(settings.appLanguage, equals('ru'));
        expect(settings.currentLocale, equals(const Locale('ru')));
        expect(notifyCount, equals(1));

        settings.setAppLanguage('en');
        expect(settings.appLanguage, equals('en'));
        expect(settings.currentLocale, equals(const Locale('en')));
        expect(notifyCount, equals(2));

        settings.setAppLanguage('unknown');
        expect(settings.appLanguage, equals('system'));
        expect(settings.currentLocale, isNull);
        expect(notifyCount, equals(3));
      },
    );

    test(
      'Что проверяем: Ограничение значений (clamping) при некорректных аргументах. '
      'Входные данные: Отрицательные значения и значения выше допустимого максимума. '
      'Ожидаемый результат: Значения ограничиваются в заданных диапазонах.',
      () {
        settings.setMusicFadeMs(-500);
        expect(settings.musicFadeMs, equals(0));

        settings.setMusicFadeMs(99999);
        expect(settings.musicFadeMs, equals(10000));

        settings.setDuckMultiplier(-0.2);
        expect(settings.duckMultiplier, equals(0.0));

        settings.setDuckMultiplier(2.5);
        expect(settings.duckMultiplier, equals(1.0));
      },
    );

    test(
      'Что проверяем: Сброс настроек к дефолтным значениям (resetToDefaults). '
      'Входные данные: Измененные настройки и вызов resetToDefaults(). '
      'Ожидаемый результат: Все поля возвращаются к начальным значениям (1500, 1000, 300, 1200, 0.4, showLogConsoleIcon=true, appLanguage="system").',
      () {
        settings.setMusicFadeMs(3500);
        settings.setDuckMultiplier(0.8);
        settings.setShowLogConsoleIcon(false);
        settings.setAppLanguage('en');

        settings.resetToDefaults();

        expect(settings.musicFadeMs, equals(1500));
        expect(settings.ambientFadeMs, equals(1000));
        expect(settings.duckAttackMs, equals(300));
        expect(settings.duckReleaseMs, equals(1200));
        expect(settings.duckMultiplier, equals(0.4));
        expect(settings.showLogConsoleIcon, isTrue);
        expect(settings.appLanguage, equals('system'));
        expect(settings.currentLocale, isNull);
      },
    );

    test(
      'Что проверяем: Сериализация и восстановление из Map (toMap и loadFromMap). '
      'Входные данные: Экспорт в Map и загрузка из Map с кастомными значениями и языком. '
      'Ожидаемый результат: Сохраняются и восстанавливаются корректные числовые, булевые и языковые параметры.',
      () {
        settings.setMusicFadeMs(2200);
        settings.setDuckMultiplier(0.35);
        settings.setShowLogConsoleIcon(false);
        settings.setAppLanguage('ru');

        final map = settings.toMap();
        expect(map['musicFadeMs'], equals(2200));
        expect(map['duckMultiplier'], equals(0.35));
        expect(map['showLogConsoleIcon'], equals(false));
        expect(map['appLanguage'], equals('ru'));

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

        expect(newSettings.musicFadeMs, equals(4000));
        expect(newSettings.ambientFadeMs, equals(1200));
        expect(newSettings.duckAttackMs, equals(150));
        expect(newSettings.duckReleaseMs, equals(800));
        expect(newSettings.duckMultiplier, equals(0.25));
        expect(newSettings.showLogConsoleIcon, isFalse);
        expect(newSettings.appLanguage, equals('en'));
        expect(newSettings.currentLocale, equals(const Locale('en')));
        expect(newSettings.customDownloadDirectory, equals('D:/MyTtrpgAudio'));
      },
    );

    test(
      'Что проверяем: Установка, сброс и геттеры для пользовательской директории каталога в SettingsService. '
      'Входные данные: Вызовы setCustomDownloadDirectory("C:/AudioDir"), resetCustomDownloadDirectory() и resetToDefaults(). '
      'Ожидаемый результат: customDownloadDirectory, catalogDownloadDirectory и audioStorageDirectory возвращают актуальное значение и сбрасываются в null при сбросе.',
      () {
        int notifyCount = 0;
        settings.addListener(() => notifyCount++);

        expect(settings.customDownloadDirectory, isNull);
        expect(settings.catalogDownloadDirectory, isNull);
        expect(settings.audioStorageDirectory, isNull);

        settings.setCustomDownloadDirectory('C:/CustomAudio/Library');
        expect(settings.customDownloadDirectory, equals('C:/CustomAudio/Library'));
        expect(settings.catalogDownloadDirectory, equals('C:/CustomAudio/Library'));
        expect(settings.audioStorageDirectory, equals('C:/CustomAudio/Library'));
        expect(notifyCount, equals(1));

        settings.resetCustomDownloadDirectory();
        expect(settings.customDownloadDirectory, isNull);
        expect(notifyCount, equals(2));

        settings.setCustomDownloadDirectory('  E:/OtherPath  ');
        expect(settings.customDownloadDirectory, equals('E:/OtherPath'));
        expect(notifyCount, equals(3));

        settings.resetToDefaults();
        expect(settings.customDownloadDirectory, isNull);
        expect(notifyCount, equals(4));
      },
    );
  });
}
