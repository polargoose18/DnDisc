# Technical Analysis: Layered Architecture Survey & Service Consolidation

**Surveyor**: survey_explorer_2 (teamwork_preview_explorer)  
**Date**: 2026-09-28  
**Project**: TTRPG Audio Master (`polar_goose/dndisc`)  
**Mission**: Comprehensive survey of service layout, data vs infrastructure separation, dependency mapping, DI setup in `lib/main.dart`, and circular dependency/migration risk analysis for Requirement R3 (Layered Architecture Alignment) and R2 (Legacy Export Proxies Cleanup).

---

## 1. Executive Summary

- **Current Service Directory Layout**:
  - `lib/services/`: Contains **9 files** — 7 data/feature services (`media_library_service.dart`, `scene_service.dart`, `settings_service.dart`, `theme_service.dart`, `scene_repository_network_service.dart`, `media_package_service.dart`, `scene_package_service.dart`) and 2 system-level infrastructure services (`logger_service.dart`, `shortcut_service.dart`).
  - `lib/data/services/`: Currently contains only **1 file** (`database_service.dart`).
  - `lib/db/`: Contains 1 legacy proxy file (`database_service.dart` exporting `../data/services/database_service.dart`).
  - `lib/models/`: Contains 6 legacy proxy files exporting `../domain/models/*.dart`.
- **Target Architecture (R3 & R2)**:
  - Consolidate all 7 data services into `lib/data/services/` alongside `database_service.dart`.
  - Preserve `logger_service.dart` and `shortcut_service.dart` in `lib/services/` as system/infrastructure services.
  - Delete `lib/db/database_service.dart` and `lib/models/*.dart`, updating all import references across `lib/` and `test/`.
- **Dependency & Cycle Assessment**:
  - Moving the 7 data services introduces **zero circular dependencies**.
  - All data services depend downward on domain models (`lib/domain/models/`), data repositories (`lib/data/repositories/`), sibling services (`lib/data/services/database_service.dart`), and outward on infrastructure logging (`lib/services/logger_service.dart`).
  - Two services (`media_library_service.dart` and `scene_service.dart`) interact with `lib/audio/audio_engine_service.dart` for direct bus playback and scene activation. This dependency is strictly one-way (`MediaLibraryService`/`SceneService` -> `AudioEngineService`).
- **Baseline Quality Checks**:
  - `flutter analyze`: Reports exactly **16 issues** (unused imports, unused local variables, deprecated `.withOpacity`, string interpolation braces, missing const).
  - `flutter test`: All **145 tests pass** with 0 failures across the test suite.

---

## 2. Directory Layout & Existing Files

### 2.1 `lib/services/` (Current: 9 files)
| Filename | Nature / Role | Target Destination (R3) |
|---|---|---|
| `media_library_service.dart` | Data Service (ChangeNotifier) | `lib/data/services/media_library_service.dart` |
| `scene_service.dart` | Data Service (ChangeNotifier) | `lib/data/services/scene_service.dart` |
| `settings_service.dart` | Data Service (ChangeNotifier) | `lib/data/services/settings_service.dart` |
| `theme_service.dart` | Data Service (ChangeNotifier) | `lib/data/services/theme_service.dart` |
| `scene_repository_network_service.dart` | Data Service (Network client) | `lib/data/services/scene_repository_network_service.dart` |
| `media_package_service.dart` | Data Service (Zip packaging / import) | `lib/data/services/media_package_service.dart` |
| `scene_package_service.dart` | Data Service (Zip packaging / import) | `lib/data/services/scene_package_service.dart` |
| `logger_service.dart` | Infrastructure Service (Singleton ChangeNotifier) | **STAYS** in `lib/services/logger_service.dart` |
| `shortcut_service.dart` | Infrastructure Service (ChangeNotifier keyboard listener) | **STAYS** in `lib/services/shortcut_service.dart` |

### 2.2 `lib/data/` (Current Layout)
```
lib/data/
├── repositories/
│   ├── custom_theme_repository.dart
│   ├── media_library_repository.dart
│   ├── scene_repository.dart
│   └── scene_repository_source_repository.dart
└── services/
    └── database_service.dart
```

### 2.3 Legacy Proxies (`lib/db/` and `lib/models/`)
- `lib/db/database_service.dart`:
  ```dart
  export '../data/services/database_service.dart';
  ```
- `lib/models/ambient_layer.dart`: `export '../domain/models/ambient_layer.dart';`
- `lib/models/audio_track.dart`: `export '../domain/models/audio_track.dart';`
- `lib/models/custom_theme_model.dart`: `export '../domain/models/custom_theme_model.dart';`
- `lib/models/library_track.dart`: `export '../domain/models/library_track.dart';`
- `lib/models/scene_model.dart`: `export '../domain/models/scene_model.dart';`
- `lib/models/sfx_trigger.dart`: `export '../domain/models/sfx_trigger.dart';`

*Duplication check*: None of the 7 data services currently exist in `lib/data/services/`. There are no conflicting or duplicate implementations in the codebase.

---

## 3. Deep-Dive Inspection of the 7 Data Services

### 3.1 `MediaLibraryService` (`lib/services/media_library_service.dart`)
- **Type**: `ChangeNotifier`
- **Responsibilities**:
  - Manages track catalog state (`_tracks`, `_isLoading`, `_activeBusFilter`, `_searchQuery`).
  - Interacts with `MediaLibraryRepository` (`getAllTracks`, `insertTrack`, `updateTrack`, `deleteTrack`).
  - Handles file picking (`FilePicker.platform.pickFiles`) and batch importing audio files (`mp3`, `wav`, `ogg`, `flac`, `m4a`).
  - Dispatches tracks directly to `AudioEngineService` bus controllers (`playTrackToEngine`).
- **Dependencies**:
  - Package dependencies: `package:file_picker`, `package:uuid`, `package:path`
  - Domain models: `LibraryTrack`, `AudioTrack`, `AmbientLayer`, `SfxTrigger`
  - Repositories: `MediaLibraryRepository` (defaults to `SqliteMediaLibraryRepository`)
  - Subsystems: `AudioEngineService` (`lib/audio/audio_engine_service.dart`)
- **Relative Path Changes on Move to `lib/data/services/`**:
  - `../data/repositories/media_library_repository.dart` $\rightarrow$ `../repositories/media_library_repository.dart`
  - `../domain/models/...` $\rightarrow$ `../../domain/models/...`
  - `../audio/audio_engine_service.dart` $\rightarrow$ `../../audio/audio_engine_service.dart`

### 3.2 `SceneService` (`lib/services/scene_service.dart`)
- **Type**: `ChangeNotifier`
- **Responsibilities**:
  - Manages scene collections, active scene selection, CRUD, duplication.
  - Scene activation logic (`activateScene`), configuring music bus track preparation, ambient layer fading/volumes, and soundboard SFX triggers.
- **Dependencies**:
  - Package dependencies: `package:uuid`
  - Domain models: `SceneModel`, `AudioTrack`, `AmbientLayer`, `SfxTrigger`
  - Repositories: `SceneRepository` (defaults to `SqliteSceneRepository`)
  - Subsystems: `AudioEngineService` (`lib/audio/audio_engine_service.dart`)
  - Services: `MediaLibraryService`, `LoggerService`
- **Relative Path Changes on Move to `lib/data/services/`**:
  - `../data/repositories/scene_repository.dart` $\rightarrow$ `../repositories/scene_repository.dart`
  - `../domain/models/...` $\rightarrow$ `../../domain/models/...`
  - `../audio/audio_engine_service.dart` $\rightarrow$ `../../audio/audio_engine_service.dart`
  - `media_library_service.dart` $\rightarrow$ `media_library_service.dart` (same folder!)
  - `logger_service.dart` $\rightarrow$ `../../services/logger_service.dart`

### 3.3 `SettingsService` (`lib/services/settings_service.dart`)
- **Type**: `ChangeNotifier`
- **Responsibilities**:
  - Holds audio fade durations (`musicFadeMs`, `ambientFadeMs`), ducking parameters (`duckAttackMs`, `duckReleaseMs`, `duckMultiplier`).
  - Holds UI preferences (`showLogConsoleIcon`, `appLanguage` with system/ru/en normalization and `currentLocale`).
  - Serialization methods: `toMap()` and `loadFromMap()`.
  - Note for R4: Persistence of active theme (`activeThemeId`) will integrate with settings/persistence.
- **Dependencies**:
  - Services: `LoggerService`
- **Relative Path Changes on Move to `lib/data/services/`**:
  - `logger_service.dart` $\rightarrow$ `../../services/logger_service.dart`

### 3.4 `ThemeService` (`lib/services/theme_service.dart`)
- **Type**: `ChangeNotifier`
- **Responsibilities**:
  - Manages active theme ID, built-in presets (`AppThemes.presets`), custom themes in database.
  - CRUD operations for custom themes (`saveCustomTheme`, `deleteCustomTheme`, `duplicateCustomTheme`).
  - Computes `currentThemeData` via `activeTheme.toThemeData()`.
- **Dependencies**:
  - Package dependencies: `package:uuid`
  - Domain models: `CustomThemeModel`
  - Repositories: `CustomThemeRepository`
  - Database: Currently imports `../db/database_service.dart` (legacy proxy)
  - Theme definitions: `../theme/app_themes.dart`
  - Services: `LoggerService`
- **Relative Path Changes on Move to `lib/data/services/`**:
  - `../data/repositories/custom_theme_repository.dart` $\rightarrow$ `../repositories/custom_theme_repository.dart`
  - `../domain/models/custom_theme_model.dart` $\rightarrow$ `../../domain/models/custom_theme_model.dart`
  - `../theme/app_themes.dart` $\rightarrow$ `../../theme/app_themes.dart`
  - `../db/database_service.dart` $\rightarrow$ `database_service.dart` (direct sibling import, eliminating legacy proxy!)
  - `logger_service.dart` $\rightarrow$ `../../services/logger_service.dart`

### 3.5 `SceneRepositoryNetworkService` (`lib/services/scene_repository_network_service.dart`)
- **Type**: Standalone service (HTTP client)
- **Responsibilities**:
  - URL normalization and GitHub raw manifest translation (`transformRepositoryUrl`, `resolveUrl`).
  - Fetches scene repository manifests (`SceneRepositoryManifest`) via `HttpClient`.
  - Downloads `.zip` scene packages with progress tracking (`downloadScenePackage`).
- **Dependencies**:
  - Core: `dart:convert`, `dart:io`
  - Domain models: `SceneRepositoryManifest` (`lib/domain/models/scene_repository_model.dart`)
  - Services: `LoggerService`
- **Relative Path Changes on Move to `lib/data/services/`**:
  - `../domain/models/scene_repository_model.dart` $\rightarrow$ `../../domain/models/scene_repository_model.dart`
  - `logger_service.dart` $\rightarrow$ `../../services/logger_service.dart`

### 3.6 `MediaPackageService` (`lib/services/media_package_service.dart`)
- **Type**: Standalone service (Archive / zip file I/O & batch repo operations)
- **Responsibilities**:
  - Exports tracks and audio files to a media ZIP package (`media.json` manifest + `audio/` directory).
  - Imports media ZIP packages, verifies against Zip Slip vulnerabilities, unpacks audio files to destination, and batch-inserts tracks via `MediaLibraryRepository.insertTracksBatch`.
- **Dependencies**:
  - Core / Packages: `dart:convert`, `dart:io`, `package:archive`, `package:path`
  - Repositories: `MediaLibraryRepository`
  - Database: Currently imports `../db/database_service.dart` (legacy proxy)
  - Domain models: `LibraryTrack`
  - Services: `LoggerService`
- **Relative Path Changes on Move to `lib/data/services/`**:
  - `../data/repositories/media_library_repository.dart` $\rightarrow$ `../repositories/media_library_repository.dart`
  - `../db/database_service.dart` $\rightarrow$ `database_service.dart` (direct sibling import!)
  - `../domain/models/library_track.dart` $\rightarrow$ `../../domain/models/library_track.dart`
  - `logger_service.dart` $\rightarrow$ `../../services/logger_service.dart`

### 3.7 `ScenePackageService` (`lib/services/scene_package_service.dart`)
- **Type**: Standalone service (Archive / zip file I/O & batch repo operations)
- **Responsibilities**:
  - Exports single scene (`scene.json` + referenced audio files) or scene packs (`scenes.json` + `audio/`).
  - Imports single scene packages and scene packs with Zip Slip protection and ID collision resolution.
- **Dependencies**:
  - Core / Packages: `dart:convert`, `dart:io`, `package:archive`, `package:path`
  - Repositories: `MediaLibraryRepository`, `SceneRepository`
  - Database: Currently imports `../db/database_service.dart` (legacy proxy)
  - Domain models: `LibraryTrack`, `SceneModel`
  - Services: `LoggerService`
- **Relative Path Changes on Move to `lib/data/services/`**:
  - `../data/repositories/media_library_repository.dart` $\rightarrow$ `../repositories/media_library_repository.dart`
  - `../data/repositories/scene_repository.dart` $\rightarrow$ `../repositories/scene_repository.dart`
  - `../db/database_service.dart` $\rightarrow$ `database_service.dart` (direct sibling import!)
  - `../domain/models/library_track.dart` $\rightarrow$ `../../domain/models/library_track.dart`
  - `../domain/models/scene_model.dart` $\rightarrow$ `../../domain/models/scene_model.dart`
  - `logger_service.dart` $\rightarrow$ `../../services/logger_service.dart`

---

## 4. Deep-Dive Inspection of the 2 Infrastructure Services

### 4.1 `LoggerService` (`lib/services/logger_service.dart`)
- **Current Location**: `lib/services/logger_service.dart` (Preserved in `lib/services/`)
- **Type**: Singleton `ChangeNotifier`
- **Duties**:
  - Collects log history (`LogEntry` with timestamp, level, message, details).
  - Emits real-time logs to CLI console via `stdout.writeln()` / `stderr.writeln()` formatted with timestamps `HH:mm:ss.SSS` as required by `flutter-desktop-audio.md`.
  - Informs UI drawer `LoggerConsoleDrawer`.
- **Architectural Layer**: Infrastructure / System diagnostics.
- **Dependencies**: `dart:io`, `package:flutter/foundation.dart`. Zero domain or data dependencies.

### 4.2 `ShortcutService` (`lib/services/shortcut_service.dart`)
- **Current Location**: `lib/services/shortcut_service.dart` (Preserved in `lib/services/`)
- **Type**: `ChangeNotifier`
- **Duties**:
  - Registers hardware keyboard hook via `HardwareKeyboard.instance.addHandler`.
  - Translates hotkeys (Space, 1..4, Numpad 1..9, Mute 'M', Ducking 'D', Panic Stop 'Escape', Fullscreen 'F11') into audio engine commands or window actions.
  - Manages action definitions and descriptions displayed in the Settings UI.
- **Architectural Layer**: Infrastructure / Platform Hardware Input.
- **Dependencies**: `package:flutter/material.dart`, `package:flutter/services.dart`, `../audio/audio_engine_service.dart`, `../domain/models/audio_track.dart`, `logger_service.dart`.
- **Why it must remain in `lib/services/`**:
  Hardware keyboard event hooking and OS window management (fullscreen) are platform/system infrastructure concerns, not data persistence or retrieval.

---

## 5. Dependency & Reference Mapping

### 5.1 Consumers in `lib/`

| File | Current Import | Required Updated Import (R2 / R3) |
|---|---|---|
| `lib/main.dart` | `import 'services/media_library_service.dart';` | `import 'data/services/media_library_service.dart';` |
| `lib/main.dart` | `import 'services/settings_service.dart';` | `import 'data/services/settings_service.dart';` |
| `lib/main.dart` | `import 'services/scene_service.dart';` | `import 'data/services/scene_service.dart';` |
| `lib/main.dart` | `import 'services/theme_service.dart';` | `import 'data/services/theme_service.dart';` |
| `lib/main.dart` | `import 'services/logger_service.dart';` | **STAYS**: `import 'services/logger_service.dart';` |
| `lib/main.dart` | `import 'services/shortcut_service.dart';` | **STAYS**: `import 'services/shortcut_service.dart';` |
| `lib/audio/audio_engine_service.dart` | `import '../services/settings_service.dart';` | `import '../data/services/settings_service.dart';` |
| `lib/audio/audio_engine_service.dart` | `import '../services/logger_service.dart';` | **STAYS**: `import '../services/logger_service.dart';` |
| `lib/audio/ambient_bus_controller.dart` | `import '../services/logger_service.dart';` | **STAYS**: `import '../services/logger_service.dart';` |
| `lib/audio/ducking_controller.dart` | `import '../services/logger_service.dart';` | **STAYS**: `import '../services/logger_service.dart';` |
| `lib/audio/music_bus_controller.dart` | `import '../services/logger_service.dart';` | **STAYS**: `import '../services/logger_service.dart';` |
| `lib/audio/sfx_bus_controller.dart` | `import '../services/logger_service.dart';` | **STAYS**: `import '../services/logger_service.dart';` |
| `lib/ui/view_models/media_library_view_model.dart` | `import '../../services/media_library_service.dart';` | `import '../../data/services/media_library_service.dart';` |
| `lib/ui/view_models/scene_view_model.dart` | `import '../../services/scene_service.dart';` | `import '../../data/services/scene_service.dart';` |
| `lib/ui/view_models/scene_view_model.dart` | `import '../../services/media_library_service.dart';` | `import '../../data/services/media_library_service.dart';` |
| `lib/ui/view_models/theme_view_model.dart` | `import '../../services/theme_service.dart';` | `import '../../data/services/theme_service.dart';` |
| `lib/ui/view_models/theme_view_model.dart` | `import '../../db/database_service.dart';` (R2) | `import '../../data/services/database_service.dart';` |
| `lib/ui/view_models/repository_view_model.dart` | `import '../../services/media_package_service.dart';` | `import '../../data/services/media_package_service.dart';` |
| `lib/ui/view_models/repository_view_model.dart` | `import '../../services/scene_package_service.dart';` | `import '../../data/services/scene_package_service.dart';` |
| `lib/ui/view_models/repository_view_model.dart` | `import '../../services/scene_repository_network_service.dart';` | `import '../../data/services/scene_repository_network_service.dart';` |
| `lib/ui/view_models/repository_view_model.dart` | `import '../../services/logger_service.dart';` | **STAYS**: `import '../../services/logger_service.dart';` |
| `lib/ui/screens/library_screen.dart` | `import '../../services/media_package_service.dart';` | `import '../../data/services/media_package_service.dart';` |
| `lib/ui/screens/main_dashboard_screen.dart` | `import '../../services/settings_service.dart';` | `import '../../data/services/settings_service.dart';` |
| `lib/ui/screens/repository_catalog_screen.dart` | `import '../../services/scene_repository_network_service.dart';` | `import '../../data/services/scene_repository_network_service.dart';` |
| `lib/ui/screens/settings_screen.dart` | `import '../../services/settings_service.dart';` | `import '../../data/services/settings_service.dart';` |
| `lib/ui/screens/settings_screen.dart` | `import '../../services/shortcut_service.dart';` | **STAYS**: `import '../../services/shortcut_service.dart';` |
| `lib/ui/widgets/logger_console_drawer.dart` | `import '../../services/logger_service.dart';` | **STAYS**: `import '../../services/logger_service.dart';` |
| `lib/ui/widgets/scene_repository_details_dialog.dart` | `import '../../services/scene_repository_network_service.dart';` | `import '../../data/services/scene_repository_network_service.dart';` |
| `lib/ui/widgets/scene_selector_panel.dart` | `import '../../services/scene_package_service.dart';` | `import '../../data/services/scene_package_service.dart';` |
| `lib/data/repositories/custom_theme_repository.dart` | `import '../../db/database_service.dart';` (R2) | `import '../services/database_service.dart';` |
| `lib/data/repositories/media_library_repository.dart` | `import '../../db/database_service.dart';` (R2) | `import '../services/database_service.dart';` |
| `lib/data/repositories/scene_repository.dart` | `import '../../db/database_service.dart';` (R2) | `import '../services/database_service.dart';` |
| `lib/data/repositories/scene_repository_source_repository.dart` | `import '../services/database_service.dart';` | **STAYS**: `import '../services/database_service.dart';` |

### 5.2 Consumers in `test/`

| Test File | Current Import | Required Updated Import (R2 / R3) |
|---|---|---|
| `test/widget_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/data/repositories_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/db/database_service_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/db/database_service_v4_test.dart` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | Already updated! |
| `test/services/logger_service_test.dart` | `import 'package:ttrpg_audio_player/services/logger_service.dart';` | **STAYS** |
| `test/services/shortcut_service_test.dart` | `import 'package:ttrpg_audio_player/services/shortcut_service.dart';` | **STAYS** |
| `test/services/media_library_service_test.dart` | `import 'package:ttrpg_audio_player/services/media_library_service.dart';` | `import 'package:ttrpg_audio_player/data/services/media_library_service.dart';` |
| `test/services/media_library_service_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/scene_service_test.dart` | `import 'package:ttrpg_audio_player/services/scene_service.dart';` | `import 'package:ttrpg_audio_player/data/services/scene_service.dart';` |
| `test/services/scene_service_test.dart` | `import 'package:ttrpg_audio_player/services/media_library_service.dart';` | `import 'package:ttrpg_audio_player/data/services/media_library_service.dart';` |
| `test/services/scene_service_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/settings_service_test.dart` | `import 'package:ttrpg_audio_player/services/settings_service.dart';` | `import 'package:ttrpg_audio_player/data/services/settings_service.dart';` |
| `test/services/theme_service_test.dart` | `import 'package:ttrpg_audio_player/services/theme_service.dart';` | `import 'package:ttrpg_audio_player/data/services/theme_service.dart';` |
| `test/services/theme_service_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/scene_repository_network_service_test.dart` | `import 'package:ttrpg_audio_player/services/scene_repository_network_service.dart';` | `import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';` |
| `test/services/media_package_service_test.dart` | `import 'package:ttrpg_audio_player/services/media_package_service.dart';` | `import 'package:ttrpg_audio_player/data/services/media_package_service.dart';` |
| `test/services/media_package_service_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/scene_package_service_test.dart` | `import 'package:ttrpg_audio_player/services/scene_package_service.dart';` | `import 'package:ttrpg_audio_player/data/services/scene_package_service.dart';` |
| `test/services/scene_package_service_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/pack_package_service_test.dart` | `import 'package:ttrpg_audio_player/services/scene_package_service.dart';` | `import 'package:ttrpg_audio_player/data/services/scene_package_service.dart';` |
| `test/services/pack_package_service_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/ui/catalog_screen_test.dart` | `import 'package:ttrpg_audio_player/services/scene_repository_network_service.dart';` | `import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';` |
| `test/ui/repository_view_model_test.dart` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | Already updated! (Note: has unused import warning) |
| `test/ui/view_models_test.dart` | `import 'package:ttrpg_audio_player/services/scene_service.dart';` | `import 'package:ttrpg_audio_player/data/services/scene_service.dart';` |
| `test/ui/view_models_test.dart` | `import 'package:ttrpg_audio_player/services/media_library_service.dart';` | `import 'package:ttrpg_audio_player/data/services/media_library_service.dart';` |
| `test/ui/view_models_test.dart` | `import 'package:ttrpg_audio_player/services/theme_service.dart';` | `import 'package:ttrpg_audio_player/data/services/theme_service.dart';` |
| `test/ui/view_models_test.dart` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | Already updated! |
| `test/ui/milestone_3_ui_test.dart` | `import 'package:ttrpg_audio_player/services/media_library_service.dart';` | `import 'package:ttrpg_audio_player/data/services/media_library_service.dart';` |
| `test/ui/milestone_3_ui_test.dart` | `import 'package:ttrpg_audio_player/services/settings_service.dart';` | `import 'package:ttrpg_audio_player/data/services/settings_service.dart';` |
| `test/ui/milestone_3_ui_test.dart` | `import 'package:ttrpg_audio_player/services/scene_service.dart';` | `import 'package:ttrpg_audio_player/data/services/scene_service.dart';` |
| `test/ui/milestone_3_ui_test.dart` | `import 'package:ttrpg_audio_player/services/theme_service.dart';` | `import 'package:ttrpg_audio_player/data/services/theme_service.dart';` |
| `test/ui/milestone_3_ui_test.dart` | `import 'package:ttrpg_audio_player/services/logger_service.dart';` | **STAYS** |
| `test/ui/milestone_3_ui_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/ui/milestone_4_ui_test.dart` | `import 'package:ttrpg_audio_player/services/media_library_service.dart';` | `import 'package:ttrpg_audio_player/data/services/media_library_service.dart';` |
| `test/ui/milestone_4_ui_test.dart` | `import 'package:ttrpg_audio_player/services/scene_service.dart';` | `import 'package:ttrpg_audio_player/data/services/scene_service.dart';` |
| `test/ui/milestone_4_ui_test.dart` | `import 'package:ttrpg_audio_player/services/settings_service.dart';` | `import 'package:ttrpg_audio_player/data/services/settings_service.dart';` |
| `test/ui/milestone_4_ui_test.dart` | `import 'package:ttrpg_audio_player/services/theme_service.dart';` | `import 'package:ttrpg_audio_player/data/services/theme_service.dart';` |
| `test/ui/milestone_4_ui_test.dart` | `import 'package:ttrpg_audio_player/services/shortcut_service.dart';` | **STAYS** |
| `test/ui/milestone_4_ui_test.dart` | `import 'package:ttrpg_audio_player/services/logger_service.dart';` | **STAYS** |
| `test/ui/milestone_4_ui_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/ui/widgets_and_screens_test.dart` | `import 'package:ttrpg_audio_player/services/media_library_service.dart';` | `import 'package:ttrpg_audio_player/data/services/media_library_service.dart';` |
| `test/ui/widgets_and_screens_test.dart` | `import 'package:ttrpg_audio_player/services/settings_service.dart';` | `import 'package:ttrpg_audio_player/data/services/settings_service.dart';` |
| `test/ui/widgets_and_screens_test.dart` | `import 'package:ttrpg_audio_player/services/scene_service.dart';` | `import 'package:ttrpg_audio_player/data/services/scene_service.dart';` |
| `test/ui/widgets_and_screens_test.dart` | `import 'package:ttrpg_audio_player/services/theme_service.dart';` | `import 'package:ttrpg_audio_player/data/services/theme_service.dart';` |
| `test/ui/widgets_and_screens_test.dart` | `import 'package:ttrpg_audio_player/services/logger_service.dart';` | **STAYS** |
| `test/ui/widgets_and_screens_test.dart` | `import 'package:ttrpg_audio_player/db/database_service.dart';` (R2) | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |

---

## 6. DI and Provider Setup in `lib/main.dart`

`lib/main.dart` sets up dependency injection using nested `MultiProvider` widgets:

```
Root MultiProvider:
├── LoggerService (ChangeNotifierProvider)
├── SettingsService (ChangeNotifierProvider)
├── ThemeService (ChangeNotifierProvider)
├── ThemeViewModel (ChangeNotifierProxyProvider<ThemeService, ThemeViewModel>)
└── AudioEngineService (ChangeNotifierProxyProvider<SettingsService, AudioEngineService>)
    └── Builder
        └── Nested MultiProvider:
            ├── MusicBusController.value (from audioEngine.musicBus)
            ├── AmbientBusController.value (from audioEngine.ambientBus)
            ├── SfxBusController.value (from audioEngine.sfxBus)
            ├── ShortcutService (ChangeNotifierProvider, injects audioEngine)
            ├── MediaLibraryService (ChangeNotifierProvider)
            ├── MediaLibraryViewModel (ChangeNotifierProxyProvider<MediaLibraryService, MediaLibraryViewModel>)
            ├── SceneService (ChangeNotifierProvider)
            ├── SceneViewModel (ChangeNotifierProxyProvider<SceneService, SceneViewModel>)
            └── RepositoryViewModel (ChangeNotifierProvider, internally instantiates sourceRepo, networkService, packageService, mediaPackageService)
```

### Analysis of DI Changes
1. Moving data services to `lib/data/services/` requires only updating the 4 import paths in `main.dart` (`media_library_service.dart`, `settings_service.dart`, `scene_service.dart`, `theme_service.dart`).
2. The registration syntax and provider hierarchy remain completely identical.
3. No breaking lifecycle or scoping changes occur.

---

## 7. Circular Dependency & Architectural Risk Analysis

### 7.1 Cross-Layer Dependency Graph

```
Presentation Layer (UI Screens, Widgets, ViewModels)
  │
  ├──> Infrastructure Layer (`lib/services/logger_service.dart`, `shortcut_service.dart`)
  ├──> Audio Engine Layer (`lib/audio/audio_engine_service.dart`)
  └──> Data Layer (`lib/data/services/`, `lib/data/repositories/`)
         │
         ├──> Domain Models (`lib/domain/models/`)
         └──> Infrastructure Layer (`lib/services/logger_service.dart`)
```

### 7.2 Detailed Cycle Invariant Checks
1. **`lib/services/logger_service.dart`**:
   - Imports: `dart:io`, `flutter/foundation.dart`.
   - Dependents: All data services, audio engine, controllers, view models, and UI.
   - Cycle risk: **None** (leaf node with zero project dependencies).
2. **`lib/services/shortcut_service.dart`**:
   - Imports: `flutter/material.dart`, `flutter/services.dart`, `audio_engine_service.dart`, `audio_track.dart`, `logger_service.dart`.
   - Dependents: `main.dart`, `settings_screen.dart`.
   - Cycle risk: **None** (does not import any data service or repository).
3. **Data Services $\leftrightarrow$ Database Service**:
   - `ThemeService`, `MediaPackageService`, `ScenePackageService` depend on `DatabaseService`.
   - When all four are in `lib/data/services/`, they share a clean horizontal relationship where `DatabaseService` is the storage engine leaf.
   - Cycle risk: **None** (`DatabaseService` does not import any other service).
4. **Data Services $\leftrightarrow$ AudioEngineService**:
   - `MediaLibraryService` and `SceneService` import `AudioEngineService` for direct track playback and scene activation.
   - `AudioEngineService` imports only `SettingsService` and `LoggerService`.
   - `SettingsService` does NOT import `AudioEngineService`.
   - Cycle risk: **None** (strict Directed Acyclic Graph).

### 7.3 Identified Risks & Mitigations
- **Risk 1: Relative Path Invalidation During Move**:
  - *Risk*: Moving 7 files from `lib/services/` to `lib/data/services/` moves them one level deeper relative to `lib/domain/` and `lib/audio/`.
  - *Mitigation*: Ensure all relative paths inside the moved files are updated (`../domain` $\rightarrow$ `../../domain`, `../audio` $\rightarrow$ `../../audio`, `../data/repositories` $\rightarrow$ `../repositories`, `logger_service.dart` $\rightarrow$ `../../services/logger_service.dart`). Alternatively, standardizing on package imports (`package:ttrpg_audio_player/...`) eliminates depth-relative breakage.
- **Risk 2: Unused Import in Test File**:
  - *Observation*: `test/ui/repository_view_model_test.dart:7:8` currently triggers an unused import warning: `import 'package:ttrpg_audio_player/data/services/database_service.dart'`.
  - *Mitigation*: Flag this for the implementation agent addressing R1 static analysis cleanup.
- **Risk 3: Co-location of Service Tests**:
  - *Observation*: `test/services/` currently houses all service tests.
  - *Assessment*: R3 specifically requires consolidating data services into `lib/data/services/` and updating all references and tests. All 145 tests pass when importing from `package:ttrpg_audio_player/data/services/...`. Keeping tests in `test/services/` (with updated package imports) maintains co-location and avoids breaking CI test discovery, while updating their package imports preserves full green status.

---

## 8. Baseline Quality & Verification

- **Static Analysis (`flutter analyze`)**:
  - Total issues: **16 issues** found (matching user request R1).
  - Breakdown:
    - 6 unused imports (`scene_repository_model.dart`, `settings_screen.dart` $\times 3$, `repository_view_model_test.dart`)
    - 2 unused local variables (`settings_screen.dart`: `mediaLibrary`, `sceneViewModel`)
    - 6 deprecated `withOpacity` calls (`repository_catalog_screen.dart` $\times 1$, `scene_repository_details_dialog.dart` $\times 5$)
    - 2 unnecessary string interpolation braces (`library_screen.dart`, `scene_selector_panel.dart`)
    - 1 missing const constructor (`main_dashboard_screen.dart`)
- **Automated Tests (`flutter test`)**:
  - Executed: **145 tests**.
  - Passed: **145 tests**.
  - Failures: **0**.
  - Duration: ~10 seconds.
