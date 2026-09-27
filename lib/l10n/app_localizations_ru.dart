// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'TTRPG Audio Master';

  @override
  String get tabGmDashboard => 'Панель Мастера';

  @override
  String get tabLibrary => 'Общая Библиотека';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get manualDuckingTooltip => 'Ручной Ducking [D]';

  @override
  String get muteTooltip => 'Заглушить [M]';

  @override
  String get unmuteTooltip => 'Включить звук [M]';

  @override
  String get fullscreenTooltip => 'Полноэкранный режим [F11]';

  @override
  String get logConsoleTooltip => 'Открыть консоль логов и отладки';

  @override
  String get logConsoleTitle => 'Консоль логов и отладки';

  @override
  String get clearLogs => 'Очистить логи';

  @override
  String get noLogs => 'Логи пусты';

  @override
  String get language => 'Язык интерфейса';

  @override
  String get languageSystem => 'Системный';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTitle => 'Настройки звукового движка';

  @override
  String get settingsSubtitle =>
      'Темы оформления, горячие клавиши, звуковой движок и управление пресетами';

  @override
  String get fadeEngineTitle => 'Плавные переходы (Fade Engine)';

  @override
  String get musicFadeTitle => 'Длительность нарастания/затухания музыки';

  @override
  String get ambientFadeTitle =>
      'Длительность плавного включения/выключения эмбиента';

  @override
  String get duckingTitle => 'Авто-приглушение музыки при SFX (Ducking)';

  @override
  String get duckAttackTitle => 'Время атаки (Duck Attack Time)';

  @override
  String get duckAttackSubtitle => 'скорость затухания музыки при ударе SFX';

  @override
  String get duckReleaseTitle => 'Время восстановления (Duck Release Time)';

  @override
  String get duckReleaseSubtitle =>
      'скорость возврата музыки на полную громкость';

  @override
  String get duckMultiplierTitle => 'Глубина приглушения (Ducking Depth)';

  @override
  String get duckMultiplierSubtitle => 'от исходной громкости музыки';

  @override
  String get presetPacksTitle => 'Пакеты Пресетов (ZIP Архивы)';

  @override
  String get presetPacksSubtitle =>
      'Экспортируйте созданные сцены и аудиодорожки в единый архив для обмена с другими мастерами или импортируйте готовые пакеты приключений.';

  @override
  String get importPresetBtn => 'Импорт пресета (ZIP)';

  @override
  String get exportPresetBtn => 'Экспорт пресета в ZIP';

  @override
  String get interfaceTitle => 'Интерфейс и панель управления';

  @override
  String get showLogConsoleTitle => 'Отображать иконку консоли логов';

  @override
  String get showLogConsoleSubtitle =>
      'Показывать кнопку быстрого открытия консоли логов в верхней панели мастера';

  @override
  String get resetDefaultsBtn => 'Сбросить все настройки по умолчанию';

  @override
  String get settingsResetToast => 'Настройки звукового движка сброшены.';

  @override
  String get themesTitle => 'Темы оформления (Themes)';

  @override
  String get builtinThemes => 'Встроенные пресеты (5 вариантов)';

  @override
  String get customThemes => 'Пользовательские темы';

  @override
  String get noCustomThemes =>
      'У вас пока нет кастомных тем. Создайте свою тему с уникальной палитрой цветов!';

  @override
  String get createThemeBtn => '+ Создать новую тему';

  @override
  String get hotkeysTitle => 'Централизованные горячие клавиши';

  @override
  String get hotkeysSubtitle =>
      'Управляйте звуковым окружением во время игровой сессии не отвлекаясь от книги правил:';

  @override
  String get actionCol => 'Действие';

  @override
  String get descriptionCol => 'Описание';

  @override
  String get keyCol => 'Клавиша';

  @override
  String get scenesTitle => 'Атмосферные Сцены';

  @override
  String get createSceneBtn => 'Создать сцену';

  @override
  String get noScenesHint =>
      'Сцены пока не созданы. Нажмите \"Создать сцену\" для комбинации музыки и эмбиентов.';

  @override
  String get activeBadge => 'АКТИВНА';

  @override
  String get enableSceneBtn => 'Включить';

  @override
  String get libraryTitle => 'Медиабиблиотека';

  @override
  String get libraryEmpty => 'Медиатека пуста';

  @override
  String get libraryEmptyHint =>
      'Нажмите \"Импорт файлов\", чтобы добавить музыку, эмбиент или SFX.';

  @override
  String get importFilesBtn => 'Импорт файлов';

  @override
  String get allSounds => 'Все звуки';

  @override
  String get music => 'Музыка';

  @override
  String get ambient => 'Эмбиент';

  @override
  String get sfx => 'SFX Эффект';

  @override
  String get searchPlaceholder =>
      'Поиск по названию или тегам (например, Таверна, Бой)...';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get create => 'Создать';

  @override
  String get edit => 'Редактировать';

  @override
  String get export => 'Экспортировать';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get musicNotPlaying => 'Музыка не воспроизводится';

  @override
  String get musicTrack => 'Музыкальная дорожка';

  @override
  String get intensityLevel => 'Уровень Интенсивности';

  @override
  String get stopMusic => 'Остановить музыку';
}
