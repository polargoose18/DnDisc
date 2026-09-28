# Baseline Survey & Static Analysis Report

**Date**: 2026-09-28  
**Investigator**: `survey_explorer_1` (Teamwork Explorer)  
**Project Root**: `c:\Users\nikit\Documents\antigravity\charming-heisenberg`  
**Integrity Mode**: Read-Only Analysis  

---

## 1. Executive Summary

| Category | Observed Baseline | Target Requirement |
|---|---|---|
| **Static Analysis** (`flutter analyze`) | **16 issues** (6 warnings, 10 infos, 0 errors) | 0 issues (`No issues found!`) |
| **Test Suite** (`flutter test`) | **145 passed**, 0 failed, 0 skipped (~10s) | 145+ tests passing, 0 failures |
| **Legacy Models Proxies** (`lib/models/`) | **6 proxy files** exporting `lib/domain/models/` | Remove directory, rewrite imports |
| **Legacy DB Proxy** (`lib/db/`) | **1 proxy file** exporting `lib/data/services/` | Remove directory, rewrite imports |
| **Legacy Model Imports in Project** | **5 references** (0 in `lib/`, 5 in `test/`) | 0 references |
| **Legacy DB Imports in Project** | **18 references** (7 in `lib/`, 11 in `test/`) | 0 references |

---

## 2. Static Analysis Issue Catalog (16 Issues)

Command: `flutter analyze`  
Exit Code: `1`  
Total Issues: 16 (6 warnings, 10 infos, 0 errors)

### Summary by Lint Rule

| Rule | Count | Type | Description |
|---|---|---|---|
| `deprecated_member_use` | 6 | info | Usage of `.withOpacity(x)` instead of `.withValues(alpha: x)` |
| `unused_import` | 5 | warning | Unused `import` statements across models, screens, and tests |
| `unnecessary_brace_in_string_interps` | 2 | info | Unnecessary `{}` around variable in string interpolation |
| `unused_local_variable` | 2 | warning | Local variable defined via `context.watch<...>` but not referenced |
| `prefer_const_constructors` | 1 | info | Missing `const` keyword on widget constructor |

---

### Detailed Issue List

#### 1. `unused_import` in Domain Model
- **File**: `lib/domain/models/scene_repository_model.dart`
- **Line**: 1, Col: 8
- **Severity**: warning
- **Current Code**:
  ```dart
  import 'dart:convert';
  ```
- **Finding**: No JSON decoding/encoding or convert utilities are used in this file.
- **Fix**: Remove `import 'dart:convert';`.

#### 2. `unnecessary_brace_in_string_interps` in Library Screen
- **File**: `lib/ui/screens/library_screen.dart`
- **Line**: 320, Col: 22
- **Severity**: info
- **Current Code**:
  ```dart
  fileName: '${sanitized}.media.zip',
  ```
- **Finding**: Variable `sanitized` does not need enclosing braces.
- **Fix**: Replace with `fileName: '$sanitized.media.zip',`.

#### 3. `prefer_const_constructors` in Main Dashboard Screen
- **File**: `lib/ui/screens/main_dashboard_screen.dart`
- **Line**: 50, Col: 13
- **Severity**: info
- **Current Code**:
  ```dart
  Tab(icon: const Icon(Icons.grid_view_rounded), text: 'Каталог'),
  ```
- **Finding**: Entire `Tab` can be constant.
- **Fix**: Add `const` prefix: `const Tab(icon: Icon(Icons.grid_view_rounded), text: 'Каталог'),`.

#### 4. `deprecated_member_use` in Repository Catalog Screen
- **File**: `lib/ui/screens/repository_catalog_screen.dart`
- **Line**: 452, Col: 59
- **Severity**: info
- **Current Code**:
  ```dart
  color: Colors.black.withOpacity(0.65),
  ```
- **Finding**: Flutter 3.27+ deprecates `Color.withOpacity(opacity)` in favor of `Color.withValues(alpha: ...)`.
- **Fix**: Replace with `color: Colors.black.withValues(alpha: 0.65),`.

#### 5, 6, 7, 8, 9. Unused Imports & Variables in Settings Screen
- **File**: `lib/ui/screens/settings_screen.dart`
- **Issues**:
  - Line 3:8 (warning): `import 'package:file_picker/file_picker.dart';` (unused import)
  - Line 4:8 (warning): `import 'package:path_provider/path_provider.dart';` (unused import)
  - Line 5:8 (warning): `import 'package:path/path.dart' as p;` (unused import)
  - Line 24:11 (warning): `final mediaLibrary = context.watch<MediaLibraryViewModel>();` (unused local variable)
  - Line 25:11 (warning): `final sceneViewModel = context.watch<SceneViewModel>();` (unused local variable)
- **Cascading Warning**:
  - Notice lines 10–11 of `lib/ui/screens/settings_screen.dart`:
    ```dart
    import '../../ui/view_models/media_library_view_model.dart';
    import '../../ui/view_models/scene_view_model.dart';
    ```
  - When removing `mediaLibrary` (line 24) and `sceneViewModel` (line 25), `MediaLibraryViewModel` and `SceneViewModel` become completely unreferenced in this file.
  - **Downstream Action**: When removing variables on lines 24–25, lines 10–11 MUST also be removed, otherwise they will immediately trigger 2 new `unused_import` warnings.
- **Fix**:
  - Remove line 3: `import 'package:file_picker/file_picker.dart';`
  - Remove line 4: `import 'package:path_provider/path_provider.dart';`
  - Remove line 5: `import 'package:path/path.dart' as p;`
  - Remove line 10: `import '../../ui/view_models/media_library_view_model.dart';`
  - Remove line 11: `import '../../ui/view_models/scene_view_model.dart';`
  - Remove line 24: `final mediaLibrary = context.watch<MediaLibraryViewModel>();`
  - Remove line 25: `final sceneViewModel = context.watch<SceneViewModel>();`

#### 10, 11, 12, 13, 14. `deprecated_member_use` in Scene Repository Details Dialog
- **File**: `lib/ui/widgets/scene_repository_details_dialog.dart`
- **Issues**:
  - Line 100:46 (info): `colors: [headerColor.withOpacity(0.8), headerColor],`
    - Fix: `colors: [headerColor.withValues(alpha: 0.8), headerColor],`
  - Line 113:45 (info): `color: Colors.black.withOpacity(0.55),`
    - Fix: `color: Colors.black.withValues(alpha: 0.55),`
  - Line 158:49 (info): `color: Colors.white.withOpacity(0.85),`
    - Fix: `color: Colors.white.withValues(alpha: 0.85),`
  - Line 245:57 (info): `backgroundColor: busColor.withOpacity(0.2),`
    - Fix: `backgroundColor: busColor.withValues(alpha: 0.2),`
  - Line 270:57 (info): `backgroundColor: busColor.withOpacity(0.2),`
    - Fix: `backgroundColor: busColor.withValues(alpha: 0.2),`

#### 15. `unnecessary_brace_in_string_interps` in Scene Selector Panel
- **File**: `lib/ui/widgets/scene_selector_panel.dart`
- **Line**: 312, Col: 22
- **Severity**: info
- **Current Code**:
  ```dart
  fileName: '${sanitized}.pack.zip',
  ```
- **Finding**: Variable `sanitized` does not need enclosing braces.
- **Fix**: Replace with `fileName: '$sanitized.pack.zip',`.

#### 16. `unused_import` in Repository ViewModel Test
- **File**: `test/ui/repository_view_model_test.dart`
- **Line**: 7, Col: 8
- **Severity**: warning
- **Current Code**:
  ```dart
  import 'package:ttrpg_audio_player/data/services/database_service.dart';
  ```
- **Finding**: `DatabaseService` is not directly referenced in `repository_view_model_test.dart` (the test uses `SceneRepositorySourceRepository` directly with sqflite in-memory database).
- **Fix**: Remove `import 'package:ttrpg_audio_player/data/services/database_service.dart';`.

---

## 3. Automated Test Baseline

Command: `flutter test`  
Result: **All tests passed!**  
Total Tests: **145**  
Passing Tests: **145**  
Failing Tests: **0**  
Skipped Tests: **0**  
Execution Duration: **~10.0 seconds**  

### Test Distribution Summary
- `test/audio/`: Audio controllers, ducking, fade in/out, soundboard, panic stop.
- `test/data/`: Data repositories, CRUD operations.
- `test/db/`: SQLite schema migrations, track/scene/theme/repository persistence.
- `test/models/`: Model serialization, copyWith, equality, manifest v2 parsing.
- `test/services/`: Media library, logger, packaging (zip import/export), shortcuts, network service, settings, theme.
- `test/ui/`: View models, UI screens, widget interaction, multi-tab navigation, language switching, theme selection.

---

## 4. Survey of Legacy Export Proxies

### Directory: `lib/models/` (6 Files)
Every file in this directory is a 1-line re-export pointing into `lib/domain/models/`:

| Legacy Proxy File | Size | Export Target (Canonical Domain Model) |
|---|---|---|
| `lib/models/ambient_layer.dart` | 46 B | `export '../domain/models/ambient_layer.dart';` |
| `lib/models/audio_track.dart` | 44 B | `export '../domain/models/audio_track.dart';` |
| `lib/models/custom_theme_model.dart` | 51 B | `export '../domain/models/custom_theme_model.dart';` |
| `lib/models/library_track.dart` | 46 B | `export '../domain/models/library_track.dart';` |
| `lib/models/scene_model.dart` | 44 B | `export '../domain/models/scene_model.dart';` |
| `lib/models/sfx_trigger.dart` | 44 B | `export '../domain/models/sfx_trigger.dart';` |

*Note on Canonical Domain Models*: `lib/domain/models/` also contains a 7th model: `scene_repository_model.dart`. This model was never exposed through `lib/models/` and was always imported directly from `domain/models/`.

### Directory: `lib/db/` (1 File)
This directory contains only a single 1-line re-export pointing into `lib/data/services/`:

| Legacy Proxy File | Size | Export Target (Canonical Data Service) |
|---|---|---|
| `lib/db/database_service.dart` | 49 B | `export '../data/services/database_service.dart';` |

---

## 5. Comprehensive Import Reference Map

### A. References to `models/` (Legacy Proxies)
Exhaustive scan of `lib/` and `test/` for non-canonical imports:

| Source File | Line | Current Legacy Import | Required Canonical Replacement |
|---|---|---|---|
| `test/audio/audio_controllers_test.dart` | 7 | `import 'package:ttrpg_audio_player/models/audio_track.dart';` | `import 'package:ttrpg_audio_player/domain/models/audio_track.dart';` |
| `test/audio/audio_controllers_test.dart` | 8 | `import 'package:ttrpg_audio_player/models/ambient_layer.dart';` | `import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';` |
| `test/audio/audio_controllers_test.dart` | 9 | `import 'package:ttrpg_audio_player/models/sfx_trigger.dart';` | `import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';` |
| `test/audio/fade_and_ducking_test.dart` | 6 | `import 'package:ttrpg_audio_player/models/audio_track.dart';` | `import 'package:ttrpg_audio_player/domain/models/audio_track.dart';` |
| `test/audio/fade_and_ducking_test.dart` | 7 | `import 'package:ttrpg_audio_player/models/ambient_layer.dart';` | `import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';` |

**Crucial Finding**: There are **zero** files in `lib/` that import `lib/models/`! All production source files in `lib/` are already using canonical paths (`lib/domain/models/...` or relative `../domain/models/...`). Only 2 test files (5 import lines total) in `test/audio/` need their imports redirected to `package:ttrpg_audio_player/domain/models/...`.

---

### B. References to `db/database_service.dart` (Legacy Proxy)

#### In `lib/` (7 files):
| Source File | Line | Current Legacy Import | Required Canonical Replacement |
|---|---|---|---|
| `lib/data/repositories/custom_theme_repository.dart` | 2 | `import '../../db/database_service.dart';` | `import '../services/database_service.dart';` |
| `lib/data/repositories/media_library_repository.dart` | 2 | `import '../../db/database_service.dart';` | `import '../services/database_service.dart';` |
| `lib/data/repositories/scene_repository.dart` | 2 | `import '../../db/database_service.dart';` | `import '../services/database_service.dart';` |
| `lib/services/media_package_service.dart` | 7 | `import '../db/database_service.dart';` | `import '../data/services/database_service.dart';` |
| `lib/services/scene_package_service.dart` | 7 | `import '../db/database_service.dart';` | `import '../data/services/database_service.dart';` |
| `lib/services/theme_service.dart` | 6 | `import '../db/database_service.dart';` | `import '../data/services/database_service.dart';` |
| `lib/ui/view_models/theme_view_model.dart` | 5 | `import '../../db/database_service.dart';` | `import '../../data/services/database_service.dart';` |

*(Note: `lib/db/database_service.dart` line 1 contains the proxy export itself: `export '../data/services/database_service.dart';`. When deleting the file, this export is eliminated.)*  
*(Note: `lib/data/repositories/scene_repository_source_repository.dart` line 2 already imports `../services/database_service.dart` directly.)*

#### In `test/` (11 files):
| Source File | Line | Current Legacy Import | Required Canonical Replacement |
|---|---|---|---|
| `test/widget_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/data/repositories_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/db/database_service_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/media_library_service_test.dart` | 8 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/media_package_service_test.dart` | 8 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/pack_package_service_test.dart` | 9 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/scene_package_service_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/scene_service_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/services/theme_service_test.dart` | 9 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/ui/milestone_3_ui_test.dart` | 23 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/ui/milestone_4_ui_test.dart` | 22 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |
| `test/ui/widgets_and_screens_test.dart` | 17 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` |

*(Note: `test/db/database_service_v4_test.dart` (line 7), `test/ui/view_models_test.dart` (line 6), and `test/ui/repository_view_model_test.dart` (line 7) already use canonical `package:ttrpg_audio_player/data/services/database_service.dart`.)*

---

## 6. Actionable Roadmap for Implementation

1. **Phase 1: Fix Static Analysis Issues (R1)**:
   - Remove unused import in `lib/domain/models/scene_repository_model.dart`.
   - Remove unnecessary interpolation braces in `lib/ui/screens/library_screen.dart` and `lib/ui/widgets/scene_selector_panel.dart`.
   - Add `const` constructor in `lib/ui/screens/main_dashboard_screen.dart`.
   - Replace 6 `.withOpacity(...)` calls with `.withValues(alpha: ...)` across `lib/ui/screens/repository_catalog_screen.dart` (1) and `lib/ui/widgets/scene_repository_details_dialog.dart` (5).
   - Clean up `lib/ui/screens/settings_screen.dart`: remove 3 unused imports (lines 3-5), remove 2 unused local variables (lines 24-25), and remove the 2 view model imports (lines 10-11) rendered redundant.
   - Remove unused import in `test/ui/repository_view_model_test.dart`.
   - Verify `flutter analyze` reports 0 issues.

2. **Phase 2: Reroute Legacy Imports & Delete Proxies (R2)**:
   - In `test/audio/`: Update 5 import lines in `audio_controllers_test.dart` and `fade_and_ducking_test.dart` from `models/...` to `domain/models/...`.
   - In `lib/`: Update 7 import lines across repositories, services, and view models from `db/database_service.dart` to `data/services/database_service.dart`.
   - In `test/`: Update 11 import lines from `package:ttrpg_audio_player/db/database_service.dart` to `package:ttrpg_audio_player/data/services/database_service.dart`.
   - Delete all 6 files in `lib/models/` and remove the directory `lib/models/`.
   - Delete `lib/db/database_service.dart` and remove the directory `lib/db/`.
   - Run `flutter analyze` and `flutter test` to ensure 0 broken references and 145/145 passing tests.
