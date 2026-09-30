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
  String get tabCatalog => 'Каталог';

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
  String get duckAttackTitle => 'Время атаки';

  @override
  String get duckAttackSubtitle => 'скорость затухания музыки при ударе SFX';

  @override
  String get duckReleaseTitle => 'Время восстановления';

  @override
  String get duckReleaseSubtitle =>
      'скорость возврата музыки на полную громкость';

  @override
  String get duckMultiplierTitle => 'Глубина приглушения';

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
  String get scenes => 'Сцены';

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

  @override
  String get pausedSuffix => '(Пауза)';

  @override
  String get noAmbientTracksInLibrary =>
      'В библиотеке нет треков с типом \"Эмбиент\".';

  @override
  String get noSfxTracksInLibrary => 'В библиотеке нет SFX-треков.';

  @override
  String get playPause => 'Воспроизведение / Пауза';

  @override
  String get playing => 'Воспроизведение';

  @override
  String get paused => 'На паузе';

  @override
  String get noMusic => 'Без музыки';

  @override
  String get noMusicSilence => 'Без музыки (тишина)';

  @override
  String get noMusicDesc =>
      'При активации сцены фоновая музыка плавно затухает';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get ambientLayers => 'Эмбиент-слои (Фоновые звуки)';

  @override
  String get addAmbientTooltip => 'Добавить слой / Постоянный эмбиент';

  @override
  String get stopAll => 'Выключить все';

  @override
  String get noActiveAmbients =>
      'Нет активных эмбиентов. Нажмите «+» для добавления постоянного фона.';

  @override
  String get addPersistentAmbient => 'Добавить постоянный эмбиент';

  @override
  String get volume => 'Громкость';

  @override
  String get persistentLayerTooltip =>
      'Постоянный слой (не сбрасывается при смене сцены)';

  @override
  String get makePersistentTooltip => 'Сделать постоянным слоем';

  @override
  String get muteLayerTooltip => 'Заглушить слой';

  @override
  String get unmuteLayerTooltip => 'Включить слой';

  @override
  String get removeLayerTooltip => 'Удалить слой';

  @override
  String get addAmbientDialogTitle => 'Добавить Эмбиент-слой';

  @override
  String get selectTrackFromLibrary => 'Выберите трек из медиабиблиотеки:';

  @override
  String get selectLocalAudioFile => 'Выбрать локальный аудиофайл...';

  @override
  String get selected => 'Выбран: ';

  @override
  String get persistentLayerCheckbox =>
      'Постоянный слой (не сбрасывать при смене сцены)';

  @override
  String get addLayerBtn => 'Добавить слой';

  @override
  String get soundboardTitle => 'Soundboard (SFX эффекты)';

  @override
  String get addSfxTooltip => 'Добавить SFX / Постоянную кнопку';

  @override
  String get panicStopBtn => 'Panic Stop [Esc]';

  @override
  String get sfxVolume => 'SFX Громкость: ';

  @override
  String get soundboardEmpty =>
      'Soundboard пуст. Добавьте SFX или постоянные быстрые кнопки.';

  @override
  String get addPersistentSfx => 'Добавить постоянный SFX';

  @override
  String get unpinSfx => 'Снять закрепление (сделать временным)';

  @override
  String get pinSfx => 'Закрепить как постоянный SFX';

  @override
  String get deleteSfxButton => 'Удалить кнопку SFX';

  @override
  String get addSfxDialogTitle => 'Добавить кнопку SFX';

  @override
  String get selectSoundFromLibrary => 'Выберите звук из библиотеки:';

  @override
  String get persistentSfxCheckbox =>
      'Постоянный SFX (не сбрасывать при смене сцены)';

  @override
  String get loopModeCheckbox => 'Режим зацикливания (Loop)';

  @override
  String get addSfxBtn => 'Добавить SFX';

  @override
  String get exportScenePackTooltip => 'Экспорт пака сцен (.pack.zip)';

  @override
  String get searchScenesPlaceholder => 'Поиск сцен...';

  @override
  String get noScenesMatching => 'Сцен по запросу не найдено.';

  @override
  String get saveSceneAs => 'Сохранить сцену как...';

  @override
  String sceneExported(String name) {
    return 'Сцена \"$name\" экспортирована!';
  }

  @override
  String sceneExportError(String error) {
    return 'Ошибка при экспорте сцены: $error';
  }

  @override
  String get exportScenePackTitle => 'Экспорт Пака сцен (.pack.zip)';

  @override
  String get packTitleLabel => 'Название пака';

  @override
  String get packDescLabel => 'Описание пака';

  @override
  String get defaultPackTitle => 'Пак Приключений';

  @override
  String get defaultPackDesc => 'Комплект атмосферных сцен';

  @override
  String get savePackAs => 'Сохранить пак сцен как...';

  @override
  String packExported(String name) {
    return 'Пак сцен \"$name\" успешно экспортирован!';
  }

  @override
  String packExportError(String error) {
    return 'Ошибка при экспорте пака сцен: $error';
  }

  @override
  String get exportSceneMenu => 'Экспорт (.scene.zip)';

  @override
  String get currentSceneBadge => 'ТЕКУЩАЯ СЦЕНА';

  @override
  String get selectScenePrompt =>
      'Выберите сцену слева для создания игрового окружения';

  @override
  String get musicIntensityLabel => 'Интенсивность музыки';

  @override
  String get createSceneTitle => 'Создание новой сцены';

  @override
  String get editSceneTitle => 'Редактирование сцены';

  @override
  String get sceneNameLabel => 'Название сцены *';

  @override
  String get sceneNameHint => 'например: Таверна «Пьяный Дракон»';

  @override
  String get sceneDescLabel => 'Описание атмосферы / Заметки мастера';

  @override
  String get sceneDescHint => 'Теплый камин, звон кружек, тихая лютня...';

  @override
  String get sceneCoverLabel => 'Путь к изображению / обложке сцены';

  @override
  String get browseBtn => 'Обзор';

  @override
  String get colorAccent => 'Цветовой акцент:';

  @override
  String get musicChannel => 'Канал Музыки';

  @override
  String get ambientChannel => 'Канал Эмбиента';

  @override
  String get sfxChannel => 'Канал SFX (Саундборд)';

  @override
  String get searchMusicHint => 'Поиск музыки по названию или тегам...';

  @override
  String get searchAmbientHint => 'Поиск эмбиента по названию или тегам...';

  @override
  String get searchSfxHint => 'Поиск SFX по названию или тегам...';

  @override
  String layersSelected(int count) {
    return '$count слоев выбрано';
  }

  @override
  String sfxSelected(int count) {
    return '$count SFX выбрано';
  }

  @override
  String get specifySceneName => 'Укажите название сцены';

  @override
  String get createCustomThemeTitle => 'Создание кастомной темы';

  @override
  String get editCustomThemeTitle => 'Редактирование темы';

  @override
  String get themeNameLabel => 'Название темы';

  @override
  String get themeNameRequired => 'Укажите название темы';

  @override
  String get baseOnPreset => 'Взять основу';

  @override
  String get baseOnPresetTooltip => 'Взять за основу пресет';

  @override
  String get themePreviewTitle => 'Предпросмотр темы';

  @override
  String get duckingActive => 'Ducking Active';

  @override
  String get cardExampleTitle => 'Пример карточки';

  @override
  String get cardExampleDesc =>
      'Текст описания сцены или трека в выбранной палитре цветов.';

  @override
  String get colorPaletteConfig => 'Настройка палитры цветов';

  @override
  String colorPickTitle(String title) {
    return 'Выбор цвета: $title';
  }

  @override
  String get saveThemeBtn => 'Сохранить тему';

  @override
  String get newThemeDefaultName => 'Новая тема';

  @override
  String get editTrackTitle => 'Редактировать аудиозапись';

  @override
  String get trackTitleLabel => 'Название трека';

  @override
  String get targetAudioBus => 'Целевая аудио-шина:';

  @override
  String get musicIntensitySetting => 'Уровень Интенсивности Музыки:';

  @override
  String get tagsLabel => 'Теги (через запятую)';

  @override
  String get tagsHint => 'Таверна, Бой, Лес, Магия';

  @override
  String get colorLabel => 'Цветовая метка:';

  @override
  String get exportMediaPackageBtn => 'Экспорт набора';

  @override
  String get selectBusForImport =>
      'Выберите целевую шину для импортируемых файлов';

  @override
  String get exportMediaPackageTitle => 'Экспорт Медиа-набора (.media.zip)';

  @override
  String get mediaPackageNameLabel => 'Название набора';

  @override
  String get mediaPackageDescLabel => 'Описание набора';

  @override
  String get defaultMediaPackageName => 'Мой Медиа Набор';

  @override
  String get defaultMediaPackageDesc => 'Коллекция аудиодорожек для TTRPG';

  @override
  String get saveMediaPackageAs => 'Сохранить медиа-набор как...';

  @override
  String mediaPackageExported(String name) {
    return 'Медиа-набор \"$name\" успешно экспортирован!';
  }

  @override
  String mediaPackageExportError(String error) {
    return 'Ошибка экспорта медиа-набора: $error';
  }

  @override
  String dispatchToBus(String bus) {
    return 'Воспроизвести на шине $bus';
  }

  @override
  String dispatchedToBus(String bus, String title) {
    return 'Отправлено на шину $bus: \"$title\"';
  }

  @override
  String get deleteFromLibrary => 'Удалить из библиотеки';

  @override
  String busInfo(String bus, String duration, String path) {
    return 'Шина: $bus | Длительность: $duration | Путь: $path';
  }

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get refreshCatalogTooltip => 'Обновить каталог';

  @override
  String get manageRepositoriesTooltip => 'Управление репозиториями';

  @override
  String get addRepositoryBtn => '+ Добавить';

  @override
  String get searchCatalogPlaceholder => 'Поиск элементов в каталоге...';

  @override
  String sourcesBtn(int count) {
    return 'Источники ($count)';
  }

  @override
  String get noRepositoriesConnected => 'Нет подключенных репозиториев';

  @override
  String get addRepositoryUrlHint =>
      'Добавьте ссылку на GitLab, Dropbox или CDN с манифестом repository.json';

  @override
  String get addRepositoryDialogTitle => 'Добавить репозиторий';

  @override
  String get editRepositoryDialogTitle => 'Редактировать репозиторий';

  @override
  String manageRepositoriesTitle(int count) {
    return 'Управление репозиториями ($count)';
  }

  @override
  String get repositoryUrlLabel =>
      'URL репозитория (GitLab / Dropbox / HTTP / JSON)';

  @override
  String get repositoryNameOptionalLabel => 'Название (опционально)';

  @override
  String get repositoryNameHint => 'Извлечётся из манифеста, если пусто';

  @override
  String get repositoryDescOptionalLabel => 'Описание (опционально)';

  @override
  String get enterRepositoryUrl => 'Введите URL репозитория';

  @override
  String get urlHttpPrefixValidation =>
      'URL должен начинаться с http:// или https://';

  @override
  String get enterRepositoryName => 'Введите название репозитория';

  @override
  String get repositoryUpdated => 'Репозиторий успешно обновлен';

  @override
  String get noConnectedRepositories => 'Нет подключенных репозиториев.';

  @override
  String get noCatalogItemsFound => 'Элементы не найдены по вашему запросу.';

  @override
  String get installedBadge => 'Загружено';

  @override
  String get noDescription => 'Без описания';

  @override
  String scenesCount(int count) {
    return '$count сцен';
  }

  @override
  String tracksCount(int count) {
    return '$count треков';
  }

  @override
  String get sizeUnknown => 'Размер неизвестен';

  @override
  String sizeMb(String size) {
    return '$size МБ';
  }

  @override
  String repositoryLabel(String name) {
    return 'Репозиторий: $name';
  }

  @override
  String get scenesInPack => 'Сцены в паке';

  @override
  String get mediaSetContent => 'Состав медиа-набора';

  @override
  String get sceneContent => 'Состав сцены';

  @override
  String get tracksMissingInManifest =>
      'Список треков отсутствует в манифесте.';

  @override
  String get scenesMissingInManifest => 'Список сцен отсутствует в манифесте.';

  @override
  String channelLabel(String channel) {
    return 'Канал: $channel';
  }

  @override
  String downloadingAndImporting(String percent) {
    return 'Скачивание и импорт... $percent%';
  }

  @override
  String removeFromApp(String type) {
    return 'Удалить $type';
  }

  @override
  String get installing => 'Установка...';

  @override
  String installItem(String type) {
    return 'Установить $type';
  }

  @override
  String deleteItemConfirmTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String deleteItemConfirmMessage(String type, String name) {
    return 'Вы уверены, что хотите удалить $type \"$name\" и связанные файлы из приложения?';
  }

  @override
  String itemUninstalled(String type, String name) {
    return '$type \"$name\" успешно удален(а) из приложения.';
  }

  @override
  String itemUninstallError(String type) {
    return 'Ошибка при удалении $type.';
  }

  @override
  String itemInstalled(String type, String name) {
    return '$type \"$name\" успешно установлен(а)!';
  }

  @override
  String itemInstallError(String type) {
    return 'Ошибка при скачивании $type.';
  }

  @override
  String get catalogStorageTitle => 'Каталог и хранилище аудиофайлов';

  @override
  String get catalogStorageDesc =>
      'Папка для загрузки и распаковки аудиофайлов из онлайн-каталога репозиториев:';

  @override
  String get customDirectory => 'Пользовательская директория';

  @override
  String get defaultDirectory => 'Директория по умолчанию';

  @override
  String get defaultStoragePath => 'По умолчанию: Documents/audio_library';

  @override
  String get resetDefaultDirTooltip => 'Сбросить к значению по умолчанию';

  @override
  String get chooseFolderBtn => 'Выбрать папку';

  @override
  String get chooseFolderDialogTitle =>
      'Выберите папку для сохранения аудиофайлов каталога';

  @override
  String get storagePathReset =>
      'Путь сохранения сброшен к значению по умолчанию.';

  @override
  String storagePathUpdated(String path) {
    return 'Папка сохранения каталога обновлена: $path';
  }

  @override
  String get shortcutPlayPauseTitle => 'Воспроизведение / Пауза';

  @override
  String get shortcutPlayPauseDesc =>
      'Старт или пауза текущего музыкального трека';

  @override
  String get shortcutIntensityCalmTitle => 'Интенсивность: Спокойствие';

  @override
  String get shortcutIntensityCalmDesc =>
      'Переключить режим музыки на Спокойствие';

  @override
  String get shortcutIntensitySuspenseTitle => 'Интенсивность: Напряжение';

  @override
  String get shortcutIntensitySuspenseDesc =>
      'Переключить режим музыки на Напряжение';

  @override
  String get shortcutIntensityBattleTitle => 'Интенсивность: Битва';

  @override
  String get shortcutIntensityBattleDesc => 'Переключить режим музыки на Битву';

  @override
  String get shortcutIntensityBossTitle => 'Интенсивность: Босс';

  @override
  String get shortcutIntensityBossDesc => 'Переключить режим музыки на Босса';

  @override
  String shortcutSfxTitle(int index) {
    return 'SFX Слот $index';
  }

  @override
  String shortcutSfxDesc(int index) {
    return 'Воспроизвести звуковой эффект $index';
  }

  @override
  String get shortcutMasterMuteTitle => 'Глушение звука (Mute)';

  @override
  String get shortcutMasterMuteDesc =>
      'Быстрое глушение или включение общего звука';

  @override
  String get shortcutManualDuckingTitle => 'Ручной Ducking';

  @override
  String get shortcutManualDuckingDesc =>
      'Принудительное приглушение музыки на время речи';

  @override
  String get shortcutPanicStopTitle => 'Экстренная остановка (Panic Stop)';

  @override
  String get shortcutPanicStopDesc =>
      'Мгновенная остановка всех играющих SFX звуков';

  @override
  String get shortcutFullscreenTitle => 'Полноэкранный режим';

  @override
  String get shortcutFullscreenDesc => 'Переключение отображения во весь экран';

  @override
  String get deleteFromApp => 'Удалить из приложения';

  @override
  String get repositoryNameLabel => 'Название';

  @override
  String get intensityCalm => 'Спокойная';

  @override
  String get intensitySuspense => 'Напряжение';

  @override
  String get intensityBattle => 'Битва';

  @override
  String get intensityBoss => 'Босс';

  @override
  String get play => 'Воспроизвести';

  @override
  String get catalogTypeScene => 'сцену';

  @override
  String get catalogTypeMedia => 'медиа-пакет';

  @override
  String get catalogTypePack => 'пак';

  @override
  String get sceneTitle => 'Сцена';

  @override
  String get mediaTitle => 'Медиа';

  @override
  String get packTitle => 'Пак';

  @override
  String get catalogSceneBadge => '🎭 Сцена';

  @override
  String get catalogMediaBadge => '🎵 Медиа';

  @override
  String get catalogPackBadge => '📦 Пак';

  @override
  String get filterAll => 'Все';

  @override
  String get filterScenes => '🎭 Сцены';

  @override
  String get filterMedia => '🎵 Медиа';

  @override
  String get filterPacks => '📦 Паки';

  @override
  String repoStats(int scenes, int media, int packs) {
    return 'Сцен: $scenes | Медиа: $media | Паков: $packs';
  }

  @override
  String get addRepositoryTooltip => 'Добавить репозиторий';

  @override
  String get repositoryUrlHint => 'https://gitlab.com/user/repo';

  @override
  String get playTooltip => 'Воспроизведение [Space]';

  @override
  String get pauseTooltip => 'Пауза [Space]';

  @override
  String get panicStopTooltip => 'Экстренная остановка SFX [Esc]';

  @override
  String get loopingBadge => 'ЦИКЛ';

  @override
  String get tagsPrefix => 'Теги: ';

  @override
  String get colorNamePrimary => 'Основной';

  @override
  String get colorNameSecondary => 'Вторичный';

  @override
  String get colorNameBackground => 'Фон';

  @override
  String get colorNameSurface => 'Поверхность';

  @override
  String get colorNameCard => 'Карточка';

  @override
  String get colorNameAccent => 'Акцент';

  @override
  String get colorNameTextPrimary => 'Основной текст';

  @override
  String get colorNameTextSecondary => 'Вторичный текст';

  @override
  String get colorNameDuckingBadge => 'Индикатор Ducking';

  @override
  String get colorNameBattleIntensity => 'Интенсивность боя';

  @override
  String get colorNameBossIntensity => 'Интенсивность босса';
}
