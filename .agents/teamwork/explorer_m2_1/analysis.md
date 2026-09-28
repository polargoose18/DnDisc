# Technical Analysis: Legacy Export Proxies Cleanup — Part 1 (Domain Models)

**Author:** explorer_m2_1  
**Milestone:** M2 (Legacy Export Proxies Cleanup - Part 1: Domain Models)  
**Date:** 2026-09-28  
**Scope:** `lib/models/` legacy export proxies removal and consumer imports migration across `lib/` and `test/`  

---

## 1. Executive Summary

As part of Milestone M2 (Requirement R2 from `ORIGINAL_REQUEST.md`), the codebase is being cleaned of legacy proxy export files. Part 1 focuses on `lib/models/`.

Key findings:
1. **Directory Contents**: `lib/models/` consists of exactly 6 Dart files, each containing a single-line export directive redirecting to `../domain/models/<filename>.dart`. There are no subdirectories or actual implementations in `lib/models/`.
2. **Current Consumer Audit**:
   - In `lib/`: **0** files import from `lib/models/`. All source code files under presentation, audio, data, and service layers already directly import canonical models from `lib/domain/models/` using relative paths (`../domain/models/...` or `../../domain/models/...`).
   - In `test/`: Exactly **2** test files import from `package:ttrpg_audio_player/models/...`, accounting for exactly **5** import statements.
   - All other test suites (`test/models/`, `test/data/`, `test/db/`, `test/services/`, `test/ui/`) already import directly from `package:ttrpg_audio_player/domain/models/...`.
3. **Tooling / Search Note**: Line 51 of `.gitignore` specifies `audio/` (intended for local music assets). Because it is not anchored to root (`/audio/`), search tools respecting gitignore (such as ripgrep / fd) skip directories named `audio/` by default. Using `git grep` and targeted scans across all directories confirmed all files exhaustively.
4. **Safety & Deletion Feasibility**: Once the 5 imports in the 2 test files are redirected to `package:ttrpg_audio_player/domain/models/...`, the entire directory `lib/models/` can be safely deleted with zero dangling references and zero compilation errors.

---

## 2. Inspection of `lib/models/`

The directory `lib/models/` contains exactly 6 proxy files. Below are their details:

| File Path | Size (Bytes) | Lines | Verbatim Content | Canonical Target |
|-----------|--------------|-------|------------------|------------------|
| `lib/models/ambient_layer.dart` | 46 B | 2 | `export '../domain/models/ambient_layer.dart';\n` | `lib/domain/models/ambient_layer.dart` |
| `lib/models/audio_track.dart` | 44 B | 2 | `export '../domain/models/audio_track.dart';\n` | `lib/domain/models/audio_track.dart` |
| `lib/models/custom_theme_model.dart` | 51 B | 2 | `export '../domain/models/custom_theme_model.dart';\n` | `lib/domain/models/custom_theme_model.dart` |
| `lib/models/library_track.dart` | 46 B | 2 | `export '../domain/models/library_track.dart';\n` | `lib/domain/models/library_track.dart` |
| `lib/models/scene_model.dart` | 44 B | 2 | `export '../domain/models/scene_model.dart';\n` | `lib/domain/models/scene_model.dart` |
| `lib/models/sfx_trigger.dart` | 44 B | 2 | `export '../domain/models/sfx_trigger.dart';\n` | `lib/domain/models/sfx_trigger.dart` |

Each file is an export trampoline that was originally put in place to maintain backward compatibility during the domain-layer modularization.

---

## 3. Reference Inventory Across `lib/` and `test/`

A comprehensive search was performed across all 87 Dart files in the workspace.

### 3.1 Status of `lib/` (Application Code)
Every single file in `lib/` already consumes canonical domain models directly from `lib/domain/models/`:
- `lib/audio/ambient_bus_controller.dart:4`: `import '../domain/models/ambient_layer.dart';`
- `lib/audio/music_bus_controller.dart:4`: `import '../domain/models/audio_track.dart';`
- `lib/audio/sfx_bus_controller.dart:4`: `import '../domain/models/sfx_trigger.dart';`
- `lib/data/repositories/custom_theme_repository.dart:1`: `import '../../domain/models/custom_theme_model.dart';`
- `lib/data/repositories/media_library_repository.dart:1`: `import '../../domain/models/library_track.dart';`
- `lib/data/repositories/scene_repository.dart:1`: `import '../../domain/models/scene_model.dart';`
- `lib/data/repositories/scene_repository_source_repository.dart:1`: `import '../../domain/models/scene_repository_model.dart';`
- `lib/data/services/database_service.dart:6-9`: imports from `../../domain/models/`
- `lib/services/media_library_service.dart:6-9`: imports from `../domain/models/`
- `lib/services/media_package_service.dart:8`: imports from `../domain/models/`
- `lib/services/scene_package_service.dart:8-9`: imports from `../domain/models/`
- `lib/services/scene_repository_network_service.dart:4`: imports from `../domain/models/`
- `lib/services/scene_service.dart:4-7`: imports from `../domain/models/`
- `lib/services/shortcut_service.dart:4`: imports from `../domain/models/`
- `lib/services/theme_service.dart:4`: imports from `../domain/models/`
- `lib/theme/app_themes.dart:1`: imports from `../domain/models/`
- `lib/ui/widgets/*`: all import from `../../domain/models/`
- `lib/ui/screens/*`: all import from `../../domain/models/`
- `lib/ui/view_models/*`: all import from `../../domain/models/`

**Conclusion for `lib/`**: There are **0** references to `lib/models/` within `lib/`.

---

### 3.2 Status of `test/` (Test Suites)

The test suites are organized into subdirectories:
- `test/models/`: 4 test files (`custom_theme_model_test.dart`, `models_test.dart`, `scene_model_test.dart`, `scene_repository_manifest_v2_test.dart`). All import `package:ttrpg_audio_player/domain/models/...`.
- `test/data/`: `repositories_test.dart`. Imports `package:ttrpg_audio_player/domain/models/...`.
- `test/db/`: `database_service_test.dart` and `database_service_v4_test.dart`. Both import `package:ttrpg_audio_player/domain/models/...`.
- `test/services/`: 7 test files. All import `package:ttrpg_audio_player/domain/models/...`.
- `test/ui/`: 7 test files. All import `package:ttrpg_audio_player/domain/models/...`.
- Root test files (`test/m1_empirical_verification_test.dart`, `test/widget_test.dart`): Do not import domain models.
- `test/audio/`: Exactly 2 test files, which contain the legacy imports:
  1. **`test/audio/audio_controllers_test.dart`** (lines 7–9):
     ```dart
     import 'package:ttrpg_audio_player/models/audio_track.dart';
     import 'package:ttrpg_audio_player/models/ambient_layer.dart';
     import 'package:ttrpg_audio_player/models/sfx_trigger.dart';
     ```
  2. **`test/audio/fade_and_ducking_test.dart`** (lines 6–7):
     ```dart
     import 'package:ttrpg_audio_player/models/audio_track.dart';
     import 'package:ttrpg_audio_player/models/ambient_layer.dart';
     ```

**Total Legacy Model References**: Exactly **5** import statements across **2** files.

---

## 4. Exact Diff Specifications

The following unified diffs specify the exact replacements required.

### 4.1 `test/audio/audio_controllers_test.dart`

```diff
--- a/test/audio/audio_controllers_test.dart
+++ b/test/audio/audio_controllers_test.dart
@@ -7,3 +7,3 @@
-import 'package:ttrpg_audio_player/models/audio_track.dart';
-import 'package:ttrpg_audio_player/models/ambient_layer.dart';
-import 'package:ttrpg_audio_player/models/sfx_trigger.dart';
+import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
+import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
+import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';
```

#### Detailed Replacement Chunk
- **Target File**: `c:\Users\nikit\Documents\antigravity\charming-heisenberg\test\audio\audio_controllers_test.dart`
- **StartLine**: 7
- **EndLine**: 9
- **TargetContent**:
```dart
import 'package:ttrpg_audio_player/models/audio_track.dart';
import 'package:ttrpg_audio_player/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/models/sfx_trigger.dart';
```
- **ReplacementContent**:
```dart
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';
```

---

### 4.2 `test/audio/fade_and_ducking_test.dart`

```diff
--- a/test/audio/fade_and_ducking_test.dart
+++ b/test/audio/fade_and_ducking_test.dart
@@ -6,2 +6,2 @@
-import 'package:ttrpg_audio_player/models/audio_track.dart';
-import 'package:ttrpg_audio_player/models/ambient_layer.dart';
+import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
+import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
```

#### Detailed Replacement Chunk
- **Target File**: `c:\Users\nikit\Documents\antigravity\charming-heisenberg\test\audio\fade_and_ducking_test.dart`
- **StartLine**: 6
- **EndLine**: 7
- **TargetContent**:
```dart
import 'package:ttrpg_audio_player/models/audio_track.dart';
import 'package:ttrpg_audio_player/models/ambient_layer.dart';
```
- **ReplacementContent**:
```dart
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
```

---

## 5. Deletion & Zero Dangling References Verification

### 5.1 Verification Checklist
1. **No External Dependents**: No packages outside this repository depend on `lib/models/` (`publish_to: 'none'` in `pubspec.yaml`).
2. **No Build Tooling Dependents**: `build.yaml`, `pubspec.yaml`, and `analysis_options.yaml` make no reference to `lib/models/`.
3. **No Internal Dependents**: With the 5 imports in `test/audio/audio_controllers_test.dart` and `test/audio/fade_and_ducking_test.dart` updated, grep search confirms `git grep "models/"` returns zero matches outside `domain/models/` and `ui/view_models/`.
4. **All Types Available in Domain**:
   - `AudioTrack`, `MusicIntensity` are exported by `lib/domain/models/audio_track.dart`.
   - `AmbientLayer` is exported by `lib/domain/models/ambient_layer.dart`.
   - `SfxTrigger` is exported by `lib/domain/models/sfx_trigger.dart`.
   - `CustomThemeModel` is exported by `lib/domain/models/custom_theme_model.dart`.
   - `LibraryTrack` is exported by `lib/domain/models/library_track.dart`.
   - `SceneModel` is exported by `lib/domain/models/scene_model.dart`.
   All exports and signatures match identically without breaking changes.

### 5.2 Files to Delete in Milestone M2 Execution (Worker Step)
Once the test imports are modified:
```
lib/models/ambient_layer.dart
lib/models/audio_track.dart
lib/models/custom_theme_model.dart
lib/models/library_track.dart
lib/models/scene_model.dart
lib/models/sfx_trigger.dart
lib/models/ (directory)
```

### 5.3 Automated Verification Commands
After applying the diffs and deleting `lib/models/`:
1. Check for dangling imports:
   ```pwsh
   git grep "models/" | Select-String -NotMatch "domain/models", "view_models", "test/models"
   ```
   *Expected result: Empty (no output).*
2. Verify static analysis:
   ```pwsh
   flutter analyze
   ```
   *Expected result: 0 errors, 0 warnings.*
3. Execute affected tests:
   ```pwsh
   flutter test test/audio/audio_controllers_test.dart test/audio/fade_and_ducking_test.dart
   ```
   *Expected result: All 32 tests pass.*
4. Execute full test suite:
   ```pwsh
   flutter test
   ```
   *Expected result: All 145+ tests pass.*
