import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'TTRPG Audio Master'**
  String get appTitle;

  /// No description provided for @tabGmDashboard.
  ///
  /// In ru, this message translates to:
  /// **'Панель Мастера'**
  String get tabGmDashboard;

  /// No description provided for @tabLibrary.
  ///
  /// In ru, this message translates to:
  /// **'Общая Библиотека'**
  String get tabLibrary;

  /// No description provided for @tabSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get tabSettings;

  /// No description provided for @manualDuckingTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Ручной Ducking [D]'**
  String get manualDuckingTooltip;

  /// No description provided for @muteTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Заглушить [M]'**
  String get muteTooltip;

  /// No description provided for @unmuteTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Включить звук [M]'**
  String get unmuteTooltip;

  /// No description provided for @fullscreenTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Полноэкранный режим [F11]'**
  String get fullscreenTooltip;

  /// No description provided for @logConsoleTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Открыть консоль логов и отладки'**
  String get logConsoleTooltip;

  /// No description provided for @logConsoleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Консоль логов и отладки'**
  String get logConsoleTitle;

  /// No description provided for @clearLogs.
  ///
  /// In ru, this message translates to:
  /// **'Очистить логи'**
  String get clearLogs;

  /// No description provided for @noLogs.
  ///
  /// In ru, this message translates to:
  /// **'Логи пусты'**
  String get noLogs;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык интерфейса'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ru, this message translates to:
  /// **'Системный'**
  String get languageSystem;

  /// No description provided for @languageRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки звукового движка'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Темы оформления, горячие клавиши, звуковой движок и управление пресетами'**
  String get settingsSubtitle;

  /// No description provided for @fadeEngineTitle.
  ///
  /// In ru, this message translates to:
  /// **'Плавные переходы (Fade Engine)'**
  String get fadeEngineTitle;

  /// No description provided for @musicFadeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Длительность нарастания/затухания музыки'**
  String get musicFadeTitle;

  /// No description provided for @ambientFadeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Длительность плавного включения/выключения эмбиента'**
  String get ambientFadeTitle;

  /// No description provided for @duckingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Авто-приглушение музыки при SFX (Ducking)'**
  String get duckingTitle;

  /// No description provided for @duckAttackTitle.
  ///
  /// In ru, this message translates to:
  /// **'Время атаки'**
  String get duckAttackTitle;

  /// No description provided for @duckAttackSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'скорость затухания музыки при ударе SFX'**
  String get duckAttackSubtitle;

  /// No description provided for @duckReleaseTitle.
  ///
  /// In ru, this message translates to:
  /// **'Время восстановления'**
  String get duckReleaseTitle;

  /// No description provided for @duckReleaseSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'скорость возврата музыки на полную громкость'**
  String get duckReleaseSubtitle;

  /// No description provided for @duckMultiplierTitle.
  ///
  /// In ru, this message translates to:
  /// **'Глубина приглушения'**
  String get duckMultiplierTitle;

  /// No description provided for @duckMultiplierSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'от исходной громкости музыки'**
  String get duckMultiplierSubtitle;

  /// No description provided for @presetPacksTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пакеты Пресетов (ZIP Архивы)'**
  String get presetPacksTitle;

  /// No description provided for @presetPacksSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Экспортируйте созданные сцены и аудиодорожки в единый архив для обмена с другими мастерами или импортируйте готовые пакеты приключений.'**
  String get presetPacksSubtitle;

  /// No description provided for @importPresetBtn.
  ///
  /// In ru, this message translates to:
  /// **'Импорт пресета (ZIP)'**
  String get importPresetBtn;

  /// No description provided for @exportPresetBtn.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт пресета в ZIP'**
  String get exportPresetBtn;

  /// No description provided for @interfaceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Интерфейс и панель управления'**
  String get interfaceTitle;

  /// No description provided for @showLogConsoleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отображать иконку консоли логов'**
  String get showLogConsoleTitle;

  /// No description provided for @showLogConsoleSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Показывать кнопку быстрого открытия консоли логов в верхней панели мастера'**
  String get showLogConsoleSubtitle;

  /// No description provided for @resetDefaultsBtn.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить все настройки по умолчанию'**
  String get resetDefaultsBtn;

  /// No description provided for @settingsResetToast.
  ///
  /// In ru, this message translates to:
  /// **'Настройки звукового движка сброшены.'**
  String get settingsResetToast;

  /// No description provided for @themesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Темы оформления (Themes)'**
  String get themesTitle;

  /// No description provided for @builtinThemes.
  ///
  /// In ru, this message translates to:
  /// **'Встроенные пресеты (5 вариантов)'**
  String get builtinThemes;

  /// No description provided for @customThemes.
  ///
  /// In ru, this message translates to:
  /// **'Пользовательские темы'**
  String get customThemes;

  /// No description provided for @noCustomThemes.
  ///
  /// In ru, this message translates to:
  /// **'У вас пока нет кастомных тем. Создайте свою тему с уникальной палитрой цветов!'**
  String get noCustomThemes;

  /// No description provided for @createThemeBtn.
  ///
  /// In ru, this message translates to:
  /// **'+ Создать новую тему'**
  String get createThemeBtn;

  /// No description provided for @hotkeysTitle.
  ///
  /// In ru, this message translates to:
  /// **'Централизованные горячие клавиши'**
  String get hotkeysTitle;

  /// No description provided for @hotkeysSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Управляйте звуковым окружением во время игровой сессии не отвлекаясь от книги правил:'**
  String get hotkeysSubtitle;

  /// No description provided for @actionCol.
  ///
  /// In ru, this message translates to:
  /// **'Действие'**
  String get actionCol;

  /// No description provided for @descriptionCol.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get descriptionCol;

  /// No description provided for @keyCol.
  ///
  /// In ru, this message translates to:
  /// **'Клавиша'**
  String get keyCol;

  /// No description provided for @scenesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Атмосферные Сцены'**
  String get scenesTitle;

  /// No description provided for @createSceneBtn.
  ///
  /// In ru, this message translates to:
  /// **'Создать сцену'**
  String get createSceneBtn;

  /// No description provided for @noScenesHint.
  ///
  /// In ru, this message translates to:
  /// **'Сцены пока не созданы. Нажмите \"Создать сцену\" для комбинации музыки и эмбиентов.'**
  String get noScenesHint;

  /// No description provided for @activeBadge.
  ///
  /// In ru, this message translates to:
  /// **'АКТИВНА'**
  String get activeBadge;

  /// No description provided for @enableSceneBtn.
  ///
  /// In ru, this message translates to:
  /// **'Включить'**
  String get enableSceneBtn;

  /// No description provided for @libraryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Медиабиблиотека'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Медиатека пуста'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите \"Импорт файлов\", чтобы добавить музыку, эмбиент или SFX.'**
  String get libraryEmptyHint;

  /// No description provided for @importFilesBtn.
  ///
  /// In ru, this message translates to:
  /// **'Импорт файлов'**
  String get importFilesBtn;

  /// No description provided for @allSounds.
  ///
  /// In ru, this message translates to:
  /// **'Все звуки'**
  String get allSounds;

  /// No description provided for @music.
  ///
  /// In ru, this message translates to:
  /// **'Музыка'**
  String get music;

  /// No description provided for @ambient.
  ///
  /// In ru, this message translates to:
  /// **'Эмбиент'**
  String get ambient;

  /// No description provided for @sfx.
  ///
  /// In ru, this message translates to:
  /// **'SFX Эффект'**
  String get sfx;

  /// No description provided for @searchPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию или тегам (например, Таверна, Бой)...'**
  String get searchPlaceholder;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @duplicate.
  ///
  /// In ru, this message translates to:
  /// **'Дублировать'**
  String get duplicate;

  /// No description provided for @create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get edit;

  /// No description provided for @export.
  ///
  /// In ru, this message translates to:
  /// **'Экспортировать'**
  String get export;

  /// No description provided for @nowPlaying.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас играет'**
  String get nowPlaying;

  /// No description provided for @musicNotPlaying.
  ///
  /// In ru, this message translates to:
  /// **'Музыка не воспроизводится'**
  String get musicNotPlaying;

  /// No description provided for @musicTrack.
  ///
  /// In ru, this message translates to:
  /// **'Музыкальная дорожка'**
  String get musicTrack;

  /// No description provided for @intensityLevel.
  ///
  /// In ru, this message translates to:
  /// **'Уровень Интенсивности'**
  String get intensityLevel;

  /// No description provided for @stopMusic.
  ///
  /// In ru, this message translates to:
  /// **'Остановить музыку'**
  String get stopMusic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
