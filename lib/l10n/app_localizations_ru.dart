// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'DnDisc';

  @override
  String get tabGmDashboard => 'Пульт мастера';

  @override
  String get tabLibrary => 'Медиатека';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get tabCatalog => 'Каталог';

  @override
  String get muteTooltip => 'Выключить звук';

  @override
  String get unmuteTooltip => 'Включить звук';

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
  String get musicFadeTitle => 'Кроссфейд музыки';

  @override
  String get ambientFadeTitle => 'Кроссфейд эмбиента';

  @override
  String get duckingTitle => 'Приглушение';

  @override
  String get duckAttackTitle => 'Скорость приглушения';

  @override
  String get duckAttackSubtitle =>
      'Как быстро музыка затихает, когда начинается эффект';

  @override
  String get duckReleaseTitle => 'Скорость возврата';

  @override
  String get duckReleaseSubtitle =>
      'Как быстро музыка возвращается к полной громкости';

  @override
  String get duckMultiplierTitle => 'Глубина приглушения';

  @override
  String get duckMultiplierSubtitle =>
      'Доля громкости музыки, которая остаётся, пока играет эффект';

  @override
  String get resetDefaultsBtn => 'Сбросить настройки';

  @override
  String get customThemes => 'Пользовательские темы';

  @override
  String get createThemeBtn => 'Создать тему';

  @override
  String get hotkeysTitle => 'Горячие клавиши';

  @override
  String get hotkeysSubtitle => 'Работают, пока окно приложения в фокусе';

  @override
  String get scenesTitle => 'Сцены';

  @override
  String get createSceneBtn => 'Создать сцену';

  @override
  String get noScenesHint =>
      'Создайте сцену, чтобы собрать музыку, фоновые слои и звуковые эффекты';

  @override
  String get libraryEmpty => 'Медиатека пуста';

  @override
  String get libraryEmptyHint =>
      'Импортируйте аудиофайлы, чтобы использовать их в сценах';

  @override
  String get importFilesBtn => 'Импортировать файлы';

  @override
  String get music => 'Музыка';

  @override
  String get ambient => 'Эмбиент';

  @override
  String get sfx => 'SFX';

  @override
  String get scenes => 'Сцены';

  @override
  String get searchPlaceholder => 'Поиск по названию или тегу';

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
  String get musicTrack => 'Музыкальная дорожка';

  @override
  String get stopMusic => 'Стоп';

  @override
  String get noAmbientTracksInLibrary => 'В медиатеке нет эмбиент-треков';

  @override
  String get noSfxTracksInLibrary => 'В медиатеке нет звуковых эффектов';

  @override
  String get playing => 'Играет';

  @override
  String get paused => 'Пауза';

  @override
  String get noMusic => 'Нет музыки';

  @override
  String get ambientLayers => 'Фоновые слои';

  @override
  String get addAmbientTooltip => 'Добавить слой';

  @override
  String get stopAll => 'Выключить все';

  @override
  String get volume => 'Громкость';

  @override
  String get addAmbientDialogTitle => 'Добавить фоновый слой';

  @override
  String get selected => 'Выбрано';

  @override
  String get persistentLayerCheckbox => 'Закрепить во всех сценах';

  @override
  String get addLayerBtn => 'Добавить слой';

  @override
  String get soundboardTitle => 'SFX';

  @override
  String get unpinSfx => 'Открепить';

  @override
  String get pinSfx => 'Закрепить во всех сценах';

  @override
  String get deleteSfxButton => 'Убрать с пульта';

  @override
  String get addSfxDialogTitle => 'Добавить звуковой эффект';

  @override
  String get persistentSfxCheckbox => 'Закрепить во всех сценах';

  @override
  String get loopModeCheckbox => 'Зациклить';

  @override
  String get addSfxBtn => 'Добавить эффект';

  @override
  String get searchScenesPlaceholder => 'Поиск сцен';

  @override
  String get noScenesMatching => 'Попробуйте другое название';

  @override
  String get saveSceneAs => 'Сохранить сцену как';

  @override
  String get exportScenePackTitle => 'Экспорт набора';

  @override
  String get packTitleLabel => 'Название набора';

  @override
  String get packDescLabel => 'Описание';

  @override
  String get defaultPackTitle => 'Набор приключения';

  @override
  String get defaultPackDesc => 'Коллекция атмосферных сцен';

  @override
  String get savePackAs => 'Сохранить набор как';

  @override
  String get selectScenePrompt => 'Выберите сцену, чтобы настроить звук стола';

  @override
  String get musicIntensityLabel => 'Интенсивность музыки';

  @override
  String get createSceneTitle => 'Создание сцены';

  @override
  String get editSceneTitle => 'Изменение сцены';

  @override
  String get sceneNameLabel => 'Название сцены';

  @override
  String get sceneNameHint => 'Гавань на закате';

  @override
  String get specifySceneName => 'Введите название сцены';

  @override
  String get createCustomThemeTitle => 'Создание темы';

  @override
  String get editCustomThemeTitle => 'Изменение темы';

  @override
  String get themeNameLabel => 'Название темы';

  @override
  String get themeNameRequired => 'Введите название темы';

  @override
  String get baseOnPreset => 'Начать с пресета';

  @override
  String colorPickTitle(String title) {
    return 'Цвет: $title';
  }

  @override
  String get saveThemeBtn => 'Сохранить тему';

  @override
  String get newThemeDefaultName => 'Новая тема';

  @override
  String get editTrackTitle => 'Изменение трека';

  @override
  String get trackTitleLabel => 'Название';

  @override
  String get tagsLabel => 'Теги';

  @override
  String get tagsHint => 'Через запятую, например таверна, бой';

  @override
  String get exportMediaPackageBtn => 'Экспорт набора';

  @override
  String get exportMediaPackageTitle => 'Экспорт набора';

  @override
  String get mediaPackageNameLabel => 'Название набора';

  @override
  String get mediaPackageDescLabel => 'Описание';

  @override
  String get defaultMediaPackageName => 'Мой набор';

  @override
  String get defaultMediaPackageDesc => 'Коллекция аудиотреков';

  @override
  String get saveMediaPackageAs => 'Сохранить набор как';

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get refreshCatalogTooltip => 'Обновить';

  @override
  String get searchCatalogPlaceholder => 'Поиск по каталогу';

  @override
  String sourcesBtn(int count) {
    return 'Источники · $count';
  }

  @override
  String get urlHttpPrefixValidation => 'Введите полный адрес вида https://';

  @override
  String get noCatalogItemsFound =>
      'Попробуйте другое название или смените фильтр';

  @override
  String get installedBadge => 'Установлено';

  @override
  String get noDescription => 'Нет описания';

  @override
  String scenesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сцены',
      many: '$count сцен',
      few: '$count сцены',
      one: '$count сцена',
    );
    return '$_temp0';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count трека',
      many: '$count треков',
      few: '$count трека',
      one: '$count трек',
    );
    return '$_temp0';
  }

  @override
  String get sizeUnknown => 'Размер неизвестен';

  @override
  String sizeMb(String size) {
    return '$size МБ';
  }

  @override
  String repositoryLabel(String name) {
    return 'Источник: $name';
  }

  @override
  String get scenesInPack => 'Сцены в наборе';

  @override
  String get mediaSetContent => 'Состав медиапака';

  @override
  String get sceneContent => 'Состав сцены';

  @override
  String get tracksMissingInManifest => 'В манифесте нет списка треков';

  @override
  String get scenesMissingInManifest => 'В манифесте нет списка сцен';

  @override
  String get removeFromApp => 'Удалить из приложения';

  @override
  String get installItem => 'Установить';

  @override
  String get catalogStorageDesc =>
      'Папка для аудиофайлов, скачанных из каталога';

  @override
  String get customDirectory => 'Своя папка';

  @override
  String get defaultDirectory => 'Папка по умолчанию';

  @override
  String get defaultStoragePath => 'Documents/audio_library';

  @override
  String get resetDefaultDirTooltip => 'Вернуть по умолчанию';

  @override
  String get chooseFolderBtn => 'Выбрать папку';

  @override
  String get chooseFolderDialogTitle => 'Выберите папку для аудио из каталога';

  @override
  String get shortcutPlayPauseTitle => 'Пуск / пауза';

  @override
  String get shortcutPlayPauseDesc => 'Текущий трек музыки';

  @override
  String get shortcutIntensityCalmTitle => 'Спокойно';

  @override
  String get shortcutIntensityCalmDesc =>
      'Переключить режим музыки на Спокойствие';

  @override
  String get shortcutIntensitySuspenseTitle => 'Тревога';

  @override
  String get shortcutIntensitySuspenseDesc =>
      'Переключить режим музыки на Напряжение';

  @override
  String get shortcutIntensityBattleTitle => 'Бой';

  @override
  String get shortcutIntensityBattleDesc => 'Переключить режим музыки на Битву';

  @override
  String get shortcutIntensityBossTitle => 'Босс';

  @override
  String get shortcutIntensityBossDesc => 'Переключить режим музыки на Босса';

  @override
  String shortcutSfxTitle(int index) {
    return 'Слот SFX $index';
  }

  @override
  String shortcutSfxDesc(int index) {
    return 'Запустить эффект $index';
  }

  @override
  String get shortcutMasterMuteTitle => 'Выключить звук';

  @override
  String get shortcutMasterMuteDesc => 'Быстро выключить или включить звук';

  @override
  String get shortcutFullscreenTitle => 'Полный экран';

  @override
  String get shortcutFullscreenDesc =>
      'Включить или выключить полноэкранный режим';

  @override
  String get intensityCalm => 'Спокойно';

  @override
  String get intensitySuspense => 'Тревога';

  @override
  String get intensityBattle => 'Бой';

  @override
  String get intensityBoss => 'Босс';

  @override
  String get play => 'Воспроизвести';

  @override
  String get catalogTypeScene => 'сцену';

  @override
  String get catalogTypeMedia => 'медиа-пакет';

  @override
  String get catalogTypePack => 'коллекция';

  @override
  String get sceneTitle => 'Сцена';

  @override
  String get mediaTitle => 'Медиа';

  @override
  String get packTitle => 'Коллекция';

  @override
  String get catalogSceneBadge => 'Сцена';

  @override
  String get catalogMediaBadge => 'Медиапак';

  @override
  String get catalogPackBadge => 'Набор';

  @override
  String get filterAll => 'Все';

  @override
  String get filterScenes => 'Сцены';

  @override
  String get filterMedia => 'Медиа';

  @override
  String get filterPacks => 'Наборы';

  @override
  String get playTooltip => 'Воспроизвести';

  @override
  String get pauseTooltip => 'Пауза';

  @override
  String get colorNamePrimary => 'Акцент';

  @override
  String get colorNameBackground => 'Фон';

  @override
  String get colorNameSurface => 'Панели';

  @override
  String get seconds => 'с';

  @override
  String get milliseconds => 'мс';

  @override
  String get collapseSidebarTooltip => 'Свернуть панель';

  @override
  String get expandSidebarTooltip => 'Развернуть панель';

  @override
  String get aboutDesc => 'Аудиопульт для мастеров настольных игр';

  @override
  String get appVersion => 'Версия 1.0.0';

  @override
  String get master => 'Общая';

  @override
  String get close => 'Закрыть';

  @override
  String get moreActions => 'Ещё';

  @override
  String get showScenes => 'Показать сцены';

  @override
  String get openNavigation => 'Открыть навигацию';

  @override
  String get channelVolumes => 'Громкость каналов';

  @override
  String get noScenesTitle => 'Сцен пока нет';

  @override
  String get noScenesFoundTitle => 'Сцены не найдены';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String get editDetails => 'Изменить';

  @override
  String get exportAction => 'Экспортировать';

  @override
  String ambientCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слоя',
      many: '$count слоёв',
      few: '$count слоя',
      one: '$count слой',
    );
    return '$_temp0';
  }

  @override
  String sfxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count эффекта',
      many: '$count эффектов',
      few: '$count эффекта',
      one: '$count эффект',
    );
    return '$_temp0';
  }

  @override
  String sceneMeta(String intensity, String layers, String sfx) {
    return '$intensity · $layers · $sfx';
  }

  @override
  String get deleteSceneTitle => 'Удалить сцену?';

  @override
  String deleteSceneMessage(String name) {
    return 'Сцена «$name» и её раскладка будут удалены. Аудиофайлы останутся в медиатеке.';
  }

  @override
  String get exportBundleTooltip => 'Экспортировать все сцены набором';

  @override
  String get toastSceneExported => 'Сцена экспортирована';

  @override
  String get toastBundleExported => 'Набор экспортирован';

  @override
  String get toastExportFailed => 'Не удалось экспортировать';

  @override
  String ambientOnCount(int on, int total) {
    return 'Включено $on из $total';
  }

  @override
  String get stopAllLayers => 'Остановить все слои';

  @override
  String get noAmbientTitle => 'Фоновых слоёв нет';

  @override
  String get noAmbientHint =>
      'Добавьте слой, чтобы под музыку звучали дождь, ветер или толпа';

  @override
  String get addAmbientLayer => 'Добавить слой';

  @override
  String get pinEverywhere => 'Закрепить во всех сценах';

  @override
  String get removeLayer => 'Убрать слой';

  @override
  String get addAmbientDialogDesc => 'Выберите трек из медиатеки или файл';

  @override
  String get fromLibrary => 'Из медиатеки';

  @override
  String get chooseLocalFile => 'Выбрать файл';

  @override
  String get soundIcon => 'Значок';

  @override
  String get persistentLayerDesc => 'Слой продолжит звучать при смене сцены';

  @override
  String get filterLibrary => 'Фильтр по медиатеке';

  @override
  String get addSfxSlot => 'Добавить эффект';

  @override
  String get addSfxDialogDesc => 'Выберите звук из медиатеки или файл';

  @override
  String get persistentSfxDesc => 'Плитка останется на пульте при смене сцены';

  @override
  String get loopModeDesc =>
      'Звук повторяется, пока вы снова не нажмёте плитку';

  @override
  String get createSceneDesc =>
      'Название, обложка, стартовая интенсивность и звуки';

  @override
  String get coverLabel => 'Обложка';

  @override
  String get coverHint =>
      'Если пропустить, выберется случайная. Своё изображение её заменит.';

  @override
  String get uploadCover => 'Загрузить';

  @override
  String get startingIntensity => 'Стартовая интенсивность';

  @override
  String soundsSelected(int count) {
    return 'Звуки · выбрано $count';
  }

  @override
  String get soundsHint => 'Музыка, фоновые слои и плитки SFX';

  @override
  String get noSoundsFound => 'Звуки не найдены';

  @override
  String get everythingEditableLater => 'Всё можно изменить позже';

  @override
  String get saveBtn => 'Сохранить';

  @override
  String get discardChangesTitle => 'Отменить изменения?';

  @override
  String get discardChangesMessage => 'В форме есть несохранённые изменения.';

  @override
  String get discard => 'Отменить';

  @override
  String get keepEditing => 'Продолжить';

  @override
  String get importBtn => 'Импорт';

  @override
  String get noTracksFound => 'Ничего не найдено';

  @override
  String get noTracksFoundHint => 'Попробуйте другое название или тег';

  @override
  String get previewTrack => 'Прослушать';

  @override
  String get stopPreview => 'Остановить';

  @override
  String get locateFile => 'Указать файл';

  @override
  String get fileMissing => 'Файл не найден';

  @override
  String get deleteTrackTitle => 'Удалить трек?';

  @override
  String deleteTrackMessage(String title) {
    return 'Трек «$title» исчезнет из медиатеки. Аудиофайл останется на диске.';
  }

  @override
  String get importDialogTitle => 'Импорт аудио';

  @override
  String get importDialogDesc => 'Выберите канал и добавьте файлы';

  @override
  String get importTarget => 'Канал';

  @override
  String get dropFilesTitle => 'Перетащите аудиофайлы сюда';

  @override
  String get dropFilesHint =>
      'MP3, WAV, OGG, FLAC или M4A, либо нажмите для выбора';

  @override
  String get releaseToImport => 'Отпустите для импорта';

  @override
  String importNFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировать $count файла',
      many: 'Импортировать $count файлов',
      few: 'Импортировать $count файла',
      one: 'Импортировать $count файл',
      zero: 'Импортировать',
    );
    return '$_temp0';
  }

  @override
  String get removeFromList => 'Убрать из списка';

  @override
  String toastImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count файла',
      many: 'Импортировано $count файлов',
      few: 'Импортировано $count файла',
      one: 'Импортирован $count файл',
    );
    return '$_temp0';
  }

  @override
  String toastImportSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пропущено $count файла: не аудиоформат',
      many: 'Пропущено $count файлов: не аудиоформат',
      few: 'Пропущено $count файла: не аудиоформат',
      one: 'Пропущен $count файл: не аудиоформат',
    );
    return '$_temp0';
  }

  @override
  String get trackTypeLabel => 'Тип';

  @override
  String get intensityLabel => 'Интенсивность';

  @override
  String get filePathLabel => 'Файл';

  @override
  String get toastMediaPackageExported => 'Набор экспортирован';

  @override
  String get addSourceBtn => 'Добавить источник';

  @override
  String get downloadingLabel => 'Загрузка';

  @override
  String get viewDetails => 'Подробнее';

  @override
  String removeItemTitle(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get removeItemMessage =>
      'Он и установленные им файлы будут удалены из приложения.';

  @override
  String get toastInstalled => 'Установлено';

  @override
  String get toastInstallFailed => 'Не удалось установить';

  @override
  String get toastInstallFailedHint => 'Проверьте соединение и повторите';

  @override
  String get toastRemoved => 'Удалено';

  @override
  String get toastRemoveFailed => 'Не удалось удалить';

  @override
  String get sourcesDialogTitle => 'Источники';

  @override
  String get sourcesDialogDesc => 'Репозитории, из которых читается каталог';

  @override
  String get addSourceTitle => 'Добавление источника';

  @override
  String get editSourceTitle => 'Изменение источника';

  @override
  String get sourceUrlLabel => 'Адрес';

  @override
  String get sourceUrlHint => 'https://gitlab.com/user/repo';

  @override
  String get sourceNameLabel => 'Название';

  @override
  String get sourceNameHint => 'Если пусто, возьмётся из манифеста';

  @override
  String get sourceDescLabel => 'Описание';

  @override
  String get enterSourceUrl => 'Введите адрес источника';

  @override
  String get enterSourceName => 'Введите название';

  @override
  String sourceStats(int scenes, int media, int packs) {
    return 'Сцены $scenes · Медиа $media · Наборы $packs';
  }

  @override
  String get deleteSourceTitle => 'Удалить источник?';

  @override
  String deleteSourceMessage(String name) {
    return '«$name» исчезнет из каталога. Установленное останется.';
  }

  @override
  String get noSourcesTitle => 'Источников нет';

  @override
  String get noSourcesHint =>
      'Добавьте ссылку на GitLab, Dropbox или веб-сервер с манифестом repository.json';

  @override
  String get sourceUnavailableTitle => 'Источник недоступен';

  @override
  String get sourceUnavailableHint => 'Проверьте соединение и повторите';

  @override
  String get retry => 'Повторить';

  @override
  String get noCatalogItemsTitle => 'Ничего не найдено';

  @override
  String get appearanceTitle => 'Оформление';

  @override
  String get appearanceDesc =>
      'Тема применяется ко всем экранам. Свои темы проверяются на контраст в редакторе.';

  @override
  String get customThemeTag => 'Своя';

  @override
  String get deleteThemeTitle => 'Удалить тему?';

  @override
  String deleteThemeMessage(String name) {
    return 'Тема «$name» будет удалена. Если она активна, приложение вернётся к Deep Dark.';
  }

  @override
  String get audioTitle => 'Звук';

  @override
  String get duckingDesc => 'Музыка тише, пока играет звуковой эффект';

  @override
  String get storageTitle => 'Хранение';

  @override
  String get toastStoragePathUpdated => 'Папка хранения обновлена';

  @override
  String get toastStoragePathReset => 'Папка хранения сброшена';

  @override
  String get shortcutGroupPlayback => 'Воспроизведение';

  @override
  String get shortcutGroupIntensity => 'Интенсивность';

  @override
  String get shortcutGroupSfx => 'Слоты SFX';

  @override
  String get shortcutSfxSlotsDesc => 'Слоты 2–9 работают так же';

  @override
  String get openLogs => 'Открыть логи';

  @override
  String get toastSettingsReset => 'Настройки сброшены';

  @override
  String get themeEditorDesc => 'Выберите восемь цветов, остальное вычислится';

  @override
  String get colorNameText => 'Текст';

  @override
  String get hexLabel => 'Цвет в hex';

  @override
  String get hexInvalid => 'Введите цвет вида #D4A373';

  @override
  String get contrastChecksTitle => 'Проверка контраста';

  @override
  String get contrastTextBg => 'Текст на фоне';

  @override
  String get contrastTextSurface => 'Текст на панелях';

  @override
  String get contrastPrimaryBg => 'Акцент на фоне';

  @override
  String get contrastPrimarySurface => 'Акцент на панелях';

  @override
  String contrastIntensityOnSurface(String name) {
    return '«$name» на панелях';
  }

  @override
  String get contrastFix => 'Исправить';

  @override
  String get contrastWarning =>
      'Некоторые пары ниже читаемого минимума. Тему всё равно можно сохранить.';

  @override
  String get contrastOk => 'Норма';

  @override
  String get orWord => 'или';

  @override
  String get choosePreset => 'Выберите пресет';
}
