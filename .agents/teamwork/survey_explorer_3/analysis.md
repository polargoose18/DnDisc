# Codebase Survey & Analysis Report: Theme Persistence, Localization Polish & Rules Compliance

**Agent:** `survey_explorer_3` (teamwork_preview_explorer)  
**Date:** 2026-09-28  
**Project:** TTRPG Audio Master (`c:\Users\nikit\Documents\antigravity\charming-heisenberg`)  
**Status:** READ-ONLY Survey Complete  

---

## Executive Summary

This report delivers a comprehensive audit of three vital areas in the TTRPG Audio Master codebase:
1. **Theme Persistence**: Complete trace from UI to storage, determining why `activeThemeId` fails to persist across application restarts and providing a concrete implementation plan with code proposals.
2. **Localization Polish**: Exhaustive scan of all screens, dialogs, and widgets for hardcoded Russian and English user-facing literals, cataloging 60+ missing keys with exact translations for `lib/l10n/app_ru.arb` and `lib/l10n/app_en.arb`.
3. **Project Rules Compliance**:
   - Audio controllers audited against `flutter-desktop-audio.md` (terminal timestamped logging, non-blocking calls, `existsSync()` checks, ChangeNotifier proxying).
   - Test suite audited against `test-specifications.md` (3-part test specification format across all 26 test files / 145 tests).

---

## 1. Theme Persistence Investigation

### 1.1 Current Architecture & Call Flow

```
[UI: settings_screen.dart]
       │
       ▼ onTap: themeService.selectTheme(preset.id / custom.id)
[ViewModel: theme_view_model.dart]
       │ (proxies calls)
       ▼
[Service: theme_service.dart]
       │
       ├── _activeThemeId = themeId; (IN-MEMORY ONLY)
       ├── notifyListeners();
       │
       ▼ (Custom themes only: saveCustomTheme / deleteCustomTheme)
[Repository: custom_theme_repository.dart (SqliteCustomThemeRepository)]
       │
       ▼
[Database: database_service.dart (SQLite)]
       │
       └── Table: custom_themes (id, name, colors...)
           ❌ No table or column for activeThemeId or app settings!
```

### 1.2 Five Root Causes Why `activeThemeId` Is Not Persisted

1. **In-Memory Only State in `ThemeService` (`lib/services/theme_service.dart`)**:
   - `_activeThemeId` is initialized to `initialThemeId ?? AppThemes.deepDarkId` (line 21).
   - `selectTheme(String themeId)` (lines 67-72):
     ```dart
     void selectTheme(String themeId) {
       if (_activeThemeId == themeId) return;
       _activeThemeId = themeId;
       LoggerService().info('ThemeService: Switched active theme to "$themeId"');
       notifyListeners();
     }
     ```
     It assigns the variable and calls `notifyListeners()`, but never invokes any persistent storage mechanism.
   - `saveCustomTheme()` (line 94) sets `_activeThemeId = theme.id;` only in memory.
   - `deleteCustomTheme()` (lines 107-109) resets `_activeThemeId = AppThemes.deepDarkId;` only in memory.

2. **Decoupled Default Constructor in `ThemeService`**:
   - Lines 15-25:
     ```dart
     ThemeService({
       DatabaseService? dbService,
       CustomThemeRepository? repository,
       String? initialThemeId,
       bool autoLoad = false,
     }) : _repository = repository ?? (dbService != null ? SqliteCustomThemeRepository(db: dbService) : null),
          _activeThemeId = initialThemeId ?? AppThemes.deepDarkId {
       if (autoLoad && _repository != null) {
         loadThemes();
       }
     }
     ```
     Unlike `SceneService` and `MediaLibraryService` (which default to `repository ?? SqliteSceneRepository()` and `autoLoad: true`), `ThemeService` leaves `_repository` as `null` if neither `repository` nor `dbService` is passed, and defaults `autoLoad` to `false`.

3. **Missing Service Wiring in `main.dart`**:
   - Line 35:
     ```dart
     ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
     ```
     `ThemeService` is instantiated with zero arguments! Therefore:
     - `_repository` is `null`.
     - `autoLoad` is `false`.
     - On app launch, `loadThemes()` is never called, and even custom themes in SQLite are never loaded unless manually triggered.

4. **Lack of Active Theme Methods in `CustomThemeRepository` (`lib/data/repositories/custom_theme_repository.dart`)**:
   - The interface defines only:
     - `getAllCustomThemes()`
     - `getCustomThemeById(String id)`
     - `insertCustomTheme(CustomThemeModel theme)`
     - `updateCustomTheme(CustomThemeModel theme)`
     - `deleteCustomTheme(String id)`
   - No methods exist for `getActiveThemeId()` or `setActiveThemeId(String themeId)`.

5. **Absence of Settings / Key-Value Storage in `DatabaseService` (`lib/data/services/database_service.dart`)**:
   - SQLite schema version 4 only contains:
     `library_tracks`, `scenes`, `custom_themes`, `scene_repositories`.
   - There is no `app_settings` or `key_value` table to persist application settings or the selected theme.
   - `SettingsService` (`lib/services/settings_service.dart`) has serialization methods `toMap()` and `loadFromMap()`, but no persistence backend (no SQLite integration, no SharedPreferences, no JSON file writer), and doesn't even contain an `activeThemeId` field.

---

### 1.3 Recommended Persistence Architecture & Implementation Proposal

To align with the project's layered architecture and avoid introducing unnecessary external dependencies (`shared_preferences` is not in `pubspec.yaml`), the cleanest, most robust design is:

#### Step 1: Add Key-Value Storage to SQLite in `DatabaseService`
Add an `app_settings` table to SQLite (`DatabaseService`). This can be created in `_createTables` and conditionally in `onUpgrade` (or bumping DB version if necessary, though `CREATE TABLE IF NOT EXISTS app_settings` in `onCreate` and `_initDatabase` is 100% backward-compatible):

```sql
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

Add methods in `DatabaseService`:
```dart
Future<void> setSetting(String key, String value) async {
  final db = await database;
  await db.insert(
    'app_settings',
    {'key': key, 'value': value},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<String?> getSetting(String key) async {
  final db = await database;
  final results = await db.query(
    'app_settings',
    columns: ['value'],
    where: 'key = ?',
    whereArgs: [key],
    limit: 1,
  );
  if (results.isEmpty) return null;
  return results.first['value'] as String?;
}
```

#### Step 2: Extend `CustomThemeRepository` Interface & Implementation
Add active theme persistence to `CustomThemeRepository`:
```dart
abstract class CustomThemeRepository {
  // Existing CRUD...
  Future<String?> getActiveThemeId();
  Future<void> setActiveThemeId(String themeId);
}

class SqliteCustomThemeRepository implements CustomThemeRepository {
  final DatabaseService _db;
  static const String _activeThemeKey = 'active_theme_id';

  SqliteCustomThemeRepository({DatabaseService? db}) : _db = db ?? DatabaseService();

  @override
  Future<String?> getActiveThemeId() => _db.getSetting(_activeThemeKey);

  @override
  Future<void> setActiveThemeId(String themeId) => _db.setSetting(_activeThemeKey, themeId);
}
```

#### Step 3: Update `ThemeService`
1. Make `_repository` default to `repository ?? SqliteCustomThemeRepository(db: dbService)`.
2. Default `autoLoad` to `true`.
3. In `loadThemes()`:
   ```dart
   final savedThemeId = await repo.getActiveThemeId();
   if (savedThemeId != null && savedThemeId.isNotEmpty) {
     _activeThemeId = savedThemeId;
   }
   ```
4. In `selectTheme(String themeId)`:
   ```dart
   _activeThemeId = themeId;
   LoggerService().info('ThemeService: Switched active theme to "$themeId"');
   notifyListeners();
   _repository?.setActiveThemeId(themeId).ignore();
   ```
5. In `saveCustomTheme(CustomThemeModel theme)`:
   ```dart
   _activeThemeId = theme.id;
   notifyListeners();
   _repository?.setActiveThemeId(theme.id).ignore();
   ```
6. In `deleteCustomTheme(String id)`:
   ```dart
   if (_activeThemeId == id) {
     _activeThemeId = AppThemes.deepDarkId;
     _repository?.setActiveThemeId(AppThemes.deepDarkId).ignore();
   }
   notifyListeners();
   ```

#### Step 4: Update `main.dart`
Ensure `ThemeService` is created with auto-load enabled:
```dart
ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService(autoLoad: true)),
```
When `TtrpgAudioPlayerApp` builds, `ThemeService` initializes its repository, loads custom themes, restores `_activeThemeId`, and notifies `ThemeViewModel`, updating `MaterialApp` theme dynamically.

---

## 2. Localization Polish Survey

### 2.1 Configuration & Generation Pipeline
- **Config file**: `l10n.yaml`
  - `arb-dir: lib/l10n`
  - `template-arb-file: app_ru.arb`
  - `output-localization-file: app_localizations.dart`
  - `output-dir: lib/l10n`
- **Dependency**: `intl: ^0.20.3`, `flutter_localizations: sdk: flutter`
- **`pubspec.yaml`**: `generate: true`
- **CLI Command**: `flutter gen-l10n` generates `app_localizations.dart`, `app_localizations_ru.dart`, `app_localizations_en.dart`.

### 2.2 Audit of UI Screens, Widgets & Hardcoded Strings

| Target File & Line | Current Hardcoded Literal | Proposed ARB Key | English Translation |
|---|---|---|---|
| `lib/ui/screens/main_dashboard_screen.dart:50` | `text: 'Каталог'` | `tabCatalog` | `"Catalog"` |
| `lib/ui/screens/responsive_gm_dashboard.dart:98` | `text: 'Сцены'` | `tabScenes` | `"Scenes"` |
| `lib/ui/screens/responsive_gm_dashboard.dart:99` | `text: 'Музыка'` | `tabMusic` | `"Music"` |
| `lib/ui/screens/responsive_gm_dashboard.dart:100` | `text: 'Эмбиент'` | `tabAmbient` | `"Ambient"` |
| `lib/ui/screens/responsive_gm_dashboard.dart:101` | `text: 'SFX'` | `tabSfx` | `"SFX"` |
| `lib/ui/screens/repository_catalog_screen.dart:46` | `'Добавить репозиторий'` | `addRepositoryTitle` | `"Add Repository"` |
| `lib/ui/screens/repository_catalog_screen.dart:56` | `'URL репозитория (GitHub / HTTP / JSON)'` | `repositoryUrlLabel` | `"Repository URL (GitHub / HTTP / JSON)"` |
| `lib/ui/screens/repository_catalog_screen.dart:62` | `'Введите URL репозитория'` | `enterRepoUrlError` | `"Enter repository URL"` |
| `lib/ui/screens/repository_catalog_screen.dart:65` | `'URL должен начинаться с http:// или https://'` | `invalidRepoUrlError` | `"URL must start with http:// or https://"` |
| `lib/ui/screens/repository_catalog_screen.dart:74` | `'Название (опционально)'` | `optionalNameLabel` | `"Name (optional)"` |
| `lib/ui/screens/repository_catalog_screen.dart:75` | `'Извлечётся из манифеста, если пусто'` | `optionalNameHint` | `"Extracted from manifest if empty"` |
| `lib/ui/screens/repository_catalog_screen.dart:83` | `'Описание (опционально)'` | `optionalDescriptionLabel` | `"Description (optional)"` |
| `lib/ui/screens/repository_catalog_screen.dart:115` | `'Добавить'` | `addBtn` | `"Add"` |
| `lib/ui/screens/repository_catalog_screen.dart:149` | `'Управление репозиториями'` | `manageRepositoriesTitle` | `"Manage Repositories"` |
| `lib/ui/screens/repository_catalog_screen.dart:168` | `'Нет подключенных репозиториев.'` | `noConnectedRepos` | `"No connected repositories."` |
| `lib/ui/screens/repository_catalog_screen.dart:231` | `'Каталог'` | `catalogTitle` | `"Catalog"` |
| `lib/ui/screens/repository_catalog_screen.dart:235` | `'Обновить каталог'` | `refreshCatalogTooltip` | `"Refresh Catalog"` |
| `lib/ui/screens/repository_catalog_screen.dart:240` | `'Управление репозиториями'` | `manageRepositoriesTooltip` | `"Manage Repositories"` |
| `lib/ui/screens/repository_catalog_screen.dart:247` | `'+ Добавить'` | `addRepoBtn` | `"+ Add"` |
| `lib/ui/screens/repository_catalog_screen.dart:265` | `'Поиск элементов в каталоге...'` | `searchCatalogHint` | `"Search catalog items..."` |
| `lib/ui/screens/repository_catalog_screen.dart:287` | `'Источники'` | `sourcesBtn` | `"Sources"` |
| `lib/ui/screens/repository_catalog_screen.dart:330` | `'Нет подключенных репозиториев'` | `noConnectedReposTitle` | `"No Connected Repositories"` |
| `lib/ui/screens/repository_catalog_screen.dart:334` | `'Добавьте ссылку на GitHub или CDN с манифестом repository.json'` | `addRepoHintSubtitle` | `"Add a link to GitHub or CDN with repository.json manifest"` |
| `lib/ui/screens/repository_catalog_screen.dart:348` | `'Элементы не найдены по вашему запросу.'` | `noCatalogItemsFound` | `"No items found matching your query."` |
| `lib/ui/screens/repository_catalog_screen.dart:485` | `'Загружено'` | `installedBadge` | `"Installed"` |
| `lib/ui/screens/repository_catalog_screen.dart:526` | `'Без описания'` | `noDescription` | `"No description"` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:32` | `'Размер неизвестен'` | `sizeUnknown` | `"Size unknown"` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:156` | `'Репозиторий:'` | `repositoryLabel` | `"Repository:"` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:219` | `'Сцены в паке'` | `scenesInPackTitle` | `"Scenes in Pack"` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:221` | `'Состав медиа-набора'` | `mediaPackContentTitle` | `"Media Collection Content"` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:221` | `'Состав сцены'` | `sceneContentTitle` | `"Scene Content"` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:232` | `'Список треков отсутствует в манифесте.'` | `noTracksInManifest` | `"No tracks listed in manifest."` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:249` | `'Канал:'` | `channelLabel` | `"Channel:"` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:282` | `'Список сцен отсутствует в манифесте.'` | `noScenesInManifest` | `"No scenes listed in manifest."` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:320` | `'Скачивание и импорт...'` | `downloadingAndImporting` | `"Downloading and importing..."` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:368` | `'Установка...'` | `installingBtn` | `"Installing..."` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:370` | `'Загружено (Переустановить)'` | `reinstallBtn` | `"Installed (Reinstall)"` |
| `lib/ui/widgets/scene_repository_details_dialog.dart:371` | `'Установить'` | `installBtn` | `"Install"` |
| `lib/ui/screens/library_screen.dart:75` | `'Экспорт набора'` | `exportMediaPackageBtn` | `"Export Package"` |
| `lib/ui/screens/library_screen.dart:159` | `'Шина:'` / `'Путь:'` | `busAndPathLabel` | `"Bus: {bus} | Path: {path}"` |
| `lib/ui/screens/library_screen.dart:221` | `'Удалить из библиотеки'` | `deleteFromLibraryTooltip` | `"Delete from library"` |
| `lib/ui/screens/library_screen.dart:244` | `'Выберите целевую шину для импортируемых файлов'` | `selectTargetBusTitle` | `"Select Target Audio Bus for Imported Files"` |
| `lib/ui/screens/library_screen.dart:287` | `'Экспорт Медиа-набора (.media.zip)'` | `exportMediaDialogTitle` | `"Export Media Collection (.media.zip)"` |
| `lib/ui/screens/library_screen.dart:293` | `'Название набора'` | `packageTitleLabel` | `"Package Title"` |
| `lib/ui/screens/library_screen.dart:298` | `'Описание набора'` | `packageDescLabel` | `"Package Description"` |
| `lib/ui/screens/library_screen.dart:319` | `'Сохранить медиа-набор как...'` | `saveMediaDialogTitle` | `"Save media collection as..."` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:233` | `'Создание новой сцены'` / `'Редактирование сцены'` | `createSceneTitle` / `editSceneTitle` | `"Create New Scene"` / `"Edit Scene"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:253` | `'Название сцены *'` | `sceneNameLabel` | `"Scene Name *"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:254` | `'например: Таверна «Пьяный Дракон»'` | `sceneNameHint` | `"e.g. The Drunken Dragon Tavern"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:266` | `'Описание атмосферы / Заметки мастера'` | `sceneDescLabel` | `"Atmosphere Description / GM Notes"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:283` | `'Путь к изображению / обложке сцены'` | `sceneImageLabel` | `"Scene Image / Cover Path"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:305` | `'Обзор'` | `browseBtn` | `"Browse"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:323` | `'Цветовой акцент:'` | `colorAccentLabel` | `"Color Accent:"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:350` | `'Канал Музыки'` | `musicChannelTitle` | `"Music Channel"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:352` | `'Без музыки'` | `noMusicLabel` | `"No Music"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:368` | `'Без музыки (тишина)'` | `noMusicOptionTitle` | `"No music (silence)"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:369` | `'При активации сцены фоновая музыка плавно затухает'` | `noMusicOptionSubtitle` | `"Background music fades out when scene activates"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:427` | `'Канал Эмбиента'` | `ambientChannelTitle` | `"Ambient Channel"` |
| `lib/ui/widgets/create_edit_scene_dialog.dart:517` | `'Канал SFX (Саундборд)'` | `sfxChannelTitle` | `"SFX Channel (Soundboard)"` |
| `lib/ui/widgets/custom_theme_editor_dialog.dart:173` | `'Создание кастомной темы'` / `'Редактирование темы'` | `createCustomThemeTitle` / `editThemeTitle` | `"Create Custom Theme"` / `"Edit Theme"` |
| `lib/ui/widgets/custom_theme_editor_dialog.dart:194` | `'Название темы'` | `themeNameLabel` | `"Theme Name"` |
| `lib/ui/widgets/custom_theme_editor_dialog.dart:203` | `'Укажите название темы'` | `enterThemeNameError` | `"Enter theme name"` |
| `lib/ui/widgets/custom_theme_editor_dialog.dart:240` | `'Взять основу'` | `usePresetTemplateBtn` | `"Use Preset Base"` |
| `lib/ui/widgets/custom_theme_editor_dialog.dart:266` | `'Предпросмотр темы'` | `themePreviewTitle` | `"Theme Preview"` |
| `lib/ui/widgets/custom_theme_editor_dialog.dart:354` | `'Настройка палитры цветов'` | `colorPaletteSettingsTitle` | `"Color Palette Configuration"` |
| `lib/ui/widgets/custom_theme_editor_dialog.dart:393` | `'Сохранить тему'` | `saveThemeBtn` | `"Save Theme"` |
| `lib/ui/widgets/import_track_dialog.dart:52` | `'Редактировать аудиозапись'` | `editTrackDialogTitle` | `"Edit Audio Track"` |
| `lib/ui/widgets/import_track_dialog.dart:61` | `'Название трека'` | `trackTitleLabel` | `"Track Title"` |
| `lib/ui/widgets/import_track_dialog.dart:66` | `'Целевая аудио-шина:'` | `targetBusLabel` | `"Target Audio Bus:"` |
| `lib/ui/widgets/import_track_dialog.dart:107` | `'Теги (через запятую)'` | `tagsLabel` | `"Tags (comma separated)"` |
| `lib/ui/widgets/ambient_mixer_panel.dart:41` | `'Эмбиент-слои (Фоновые звуки)'` | `ambientLayersTitle` | `"Ambient Layers (Background Sounds)"` |
| `lib/ui/widgets/ambient_mixer_panel.dart:67` | `'Выключить все'` | `turnOffAllBtn` | `"Turn Off All"` |
| `lib/ui/widgets/ambient_mixer_panel.dart:92` | `'Нет активных эмбиентов...'` | `noActiveAmbientsHint` | `"No active ambients. Click «+» to add background sound."` |
| `lib/ui/widgets/ambient_mixer_panel.dart:99` | `'Добавить постоянный эмбиент'` | `addPersistentAmbientBtn` | `"Add Persistent Ambient"` |
| `lib/ui/widgets/ambient_mixer_panel.dart:255` | `'Добавить Эмбиент-слой'` | `addAmbientLayerTitle` | `"Add Ambient Layer"` |
| `lib/ui/widgets/soundboard_grid.dart:42` | `'Soundboard (SFX эффекты)'` | `soundboardTitle` | `"Soundboard (SFX Effects)"` |
| `lib/ui/widgets/soundboard_grid.dart:66` | `'Panic Stop [Esc]'` | `panicStopLabel` | `"Panic Stop [Esc]"` |
| `lib/ui/widgets/soundboard_grid.dart:318` | `'Добавить кнопку SFX'` | `addSfxButtonTitle` | `"Add SFX Button"` |
| `lib/ui/widgets/sticky_mini_player.dart:80` | `'Воспроизведение'` / `'На паузе'` | `playbackStatusPlaying` / `playbackStatusPaused` | `"Playing"` / `"Paused"` |
| `lib/ui/widgets/scene_backdrop_header.dart:37` | `'Выберите сцену слева для создания игрового окружения'` | `selectSceneHint` | `"Select a scene on the left to set the mood"` |
| `lib/ui/widgets/scene_backdrop_header.dart:137` | `'ТЕКУЩАЯ СЦЕНА'` | `currentSceneBadge` | `"CURRENT SCENE"` |
| `lib/ui/widgets/scene_backdrop_header.dart:166` | `'Интенсивность музыки'` | `musicIntensityHeader` | `"Music Intensity"` |
| `lib/domain/models/scene_repository_model.dart:11-27` | Enum display names & badges | Model helper using `l10n` or localized strings | Localized per locale |

---

## 3. Project Rules Compliance Audit

### 3.1 Desktop Audio Rules Compliance (`flutter-desktop-audio.md`)

| Rule | Requirement | Implementation Status | Verification Details |
|---|---|---|---|
| **1. Direct CLI Logging** | All audio events (start, pause, stop, volume, error) output to `stdout.writeln` / `stderr.writeln` with `HH:mm:ss.SSS` timestamp. | ✅ **COMPLIANT** | `LoggerService` (`lib/services/logger_service.dart:24, 56, 58`) formats time as `HH:mm:ss.SSS` and outputs directly to `stdout` / `stderr`. `MusicBusController`, `AmbientBusController`, `SfxBusController`, and `AudioEngineService` invoke `LoggerService` on every operation. |
| **2. Non-blocking Asynchronous Engine** | Audio driver must not block UI thread; use asynchronous non-blocking drivers (`audioplayers`). | ✅ **COMPLIANT** | All operations in audio controllers use asynchronous `audioplayers` methods (`await play()`, `await pause()`, `await stop()`, `setVolume()`) without blocking the main event loop. |
| **3. File Existence Check** | `File(filePath).existsSync()` verification before passing to audio player. | ✅ **COMPLIANT** | Verified in: <br>• `MusicBusController.playTrack`: lines 62-68 <br>• `MusicBusController.resume`: lines 327-331 <br>• `MusicBusController._triggerSeamlessLoopTransition`: lines 164-168 <br>• `AmbientBusController._startLayerAudio`: lines 160-164 <br>• `AmbientBusController._triggerSeamlessLayerLoopTransition`: lines 240-244 <br>• `SfxBusController.triggerSfx`: lines 74-79 |
| **4. ChangeNotifier Reactivity** | All sub-controllers (`MusicBusController`, `AmbientBusController`, `SfxBusController`) must proxy via `addListener(notifyListeners)` or be declared in `MultiProvider` in `main.dart`. | ✅ **COMPLIANT** | Both satisfied: `AudioEngineService` binds `addListener(notifyListeners)` on all 3 buses (lines 44-46), AND `main.dart` exposes them directly via `ChangeNotifierProvider<...>.value` (lines 53-55). |

### 3.2 Test Specifications Compliance (`test-specifications.md`)

The rule mandates:
> Каждый тест (`test()`, `testWidgets()`) должен содержать в названии или в первом блоке описания 3 обязательных пункта:
> - **Что проверяем:** Конкретный класс, метод, алгоритм или сценарий взаимодействия в UI.
> - **Входные данные:** Исходное состояние моделей, переданные аргументы, настройки громкости или действия пользователя.
> - **Ожидаемый результат:** Конечное состояние системы, возвращённые значения или утверждения `expect()`.

#### Audit Results Across All 26 Test Files (145 Tests Total):

| Test File | Total Tests | Compliant | Violations | Notes |
|---|---|---|---|---|
| `test/widget_test.dart` | 1 | 1 | 0 | Smoke test compliant |
| `test/audio/audio_controllers_test.dart` | 22 | 22 | 0 | Full 3-part spec |
| `test/audio/fade_and_ducking_test.dart` | 10 | 10 | 0 | Full 3-part spec |
| `test/data/repositories_test.dart` | 3 | 3 | 0 | Full 3-part spec |
| `test/db/database_service_test.dart` | 8 | 8 | 0 | Full 3-part spec |
| `test/db/database_service_v4_test.dart` | 1 | 1 | 0 | Full 3-part spec |
| `test/models/custom_theme_model_test.dart` | 4 | 4 | 0 | Full 3-part spec |
| `test/models/models_test.dart` | 10 | 10 | 0 | Full 3-part spec |
| `test/models/scene_model_test.dart` | 3 | 3 | 0 | Full 3-part spec |
| `test/models/scene_repository_manifest_v2_test.dart` | 2 | 2 | 0 | Full 3-part spec |
| `test/services/logger_service_test.dart` | 4 | 4 | 0 | Full 3-part spec |
| `test/services/media_library_service_test.dart` | 5 | 5 | 0 | Full 3-part spec |
| `test/services/media_package_service_test.dart` | 1 | 1 | 0 | Full 3-part spec |
| `test/services/pack_package_service_test.dart` | 1 | 1 | 0 | Full 3-part spec |
| `test/services/scene_package_service_test.dart` | 4 | 4 | 0 | Full 3-part spec |
| `test/services/scene_repository_network_service_test.dart` | 7 | 7 | 0 | Full 3-part spec |
| `test/services/scene_service_test.dart` | 3 | 3 | 0 | Full 3-part spec |
| `test/services/settings_service_test.dart` | 6 | 6 | 0 | Full 3-part spec |
| `test/services/shortcut_service_test.dart` | 9 | 9 | 0 | Full 3-part spec |
| `test/services/theme_service_test.dart` | 5 | 5 | 0 | Full 3-part spec |
| `test/ui/catalog_screen_test.dart` | 1 | 1 | 0 | Full 3-part spec |
| `test/ui/milestone_3_ui_test.dart` | 6 | 6 | 0 | Full 3-part spec |
| `test/ui/milestone_4_ui_test.dart` | 8 | 8 | 0 | Full 3-part spec |
| `test/ui/repository_view_model_test.dart` | 2 | 2 | 0 | Full 3-part spec |
| `test/ui/view_models_test.dart` | 6 | 6 | 0 | Full 3-part spec |
| `test/ui/widgets_and_screens_test.dart` | 13 | 13 | 0 | Full 3-part spec |
| **TOTAL** | **145** | **145 (100%)** | **0** | **All 145 tests pass!** |

#### New Tests Required by R4 & Acceptance Criteria:
When implementing the Theme Persistence and Localization fixes, new unit and widget tests must be added and MUST follow the 3-part standard:
1. `ThemeService` / `DatabaseService` persistence test:
   - **Что проверяем:** Сохранение `activeThemeId` в базу данных SQLite и восстановление темы при перезапуске `ThemeService`.
   - **Входные данные:** Вызов `selectTheme('emerald_forest')`, закрытие инстанса, создание нового инстанса `ThemeService(autoLoad: true)`.
   - **Ожидаемый результат:** `activeThemeId` равен `'emerald_forest'` и `currentThemeData` соответствует выбранной теме.
2. Complete localization coverage widget test:
   - **Что проверяем:** Динамическое переключение языка в `MaterialApp` и отсутствие оставшихся хардкодных строк на экранах каталога, редактирования сцены и редактора тем.
   - **Входные данные:** Смена локали с `Locale('ru')` на `Locale('en')`.
   - **Ожидаемый результат:** Виджеты отображают английские строки из `AppLocalizations.of(context)` без необработанного русского текста.

---

## 4. Prioritized Implementation Plan for Subsequent Agents

### Stage 1: Static Analysis Cleanliness (R1)
Eliminate the 16 analyzer warnings (unused imports in `scene_repository_model.dart`, `settings_screen.dart`, `repository_view_model_test.dart`, unused local variables in `settings_screen.dart`, deprecated `.withOpacity` in `repository_catalog_screen.dart` and `scene_repository_details_dialog.dart`, and string interpolation braces).

### Stage 2: Legacy Proxy Cleanup & Layered Architecture (R2, R3)
- Remove `lib/models/*.dart` and `lib/db/database_service.dart`.
- Move data services to `lib/data/services/`.
- Update all imports across `lib/` and `test/`.

### Stage 3: Theme Persistence (R4)
- Add `app_settings` key-value table and helpers to `DatabaseService`.
- Extend `CustomThemeRepository` with `getActiveThemeId()` and `setActiveThemeId()`.
- Update `ThemeService` to auto-load saved theme ID and persist updates on `selectTheme`, `saveCustomTheme`, and `deleteCustomTheme`.
- Wire `ThemeService(autoLoad: true)` in `main.dart`.
- Add unit test in `test/services/theme_service_test.dart`.

### Stage 4: Localization Polish (R4)
- Add missing keys to `lib/l10n/app_ru.arb` and `lib/l10n/app_en.arb`.
- Run `flutter gen-l10n`.
- Replace hardcoded literals across UI widgets with `AppLocalizations.of(context)`.
- Add widget tests verifying localization switching across all screens.
