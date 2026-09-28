# Handoff Report: Database Proxy Cleanup in `test/` (Milestone M2 - Part 3)

**Author:** explorer_m2_3  
**Date:** 2026-09-28T09:18:30Z  
**Type:** Hard Handoff (Investigation & Assessment Complete)  
**Target:** Removal of legacy proxy `lib/db/database_service.dart` and redirection of all imports across `test/` to `package:ttrpg_audio_player/data/services/database_service.dart`.

---

## 1. Observation

### 1.1 `lib/db/` Contents
Directory inspection of `lib/db/` via `list_dir` and `find_by_name` reveals exactly one file:
- `lib/db/database_service.dart` (49 bytes)

Verbatim file content (`lib/db/database_service.dart`, lines 1-2):
```dart
1: export '../data/services/database_service.dart';
2: 
```

### 1.2 Canonical Database Service Location
The canonical implementation of `DatabaseService` exists at:
- `lib/data/services/database_service.dart` (402 lines)
Class declaration (`lib/data/services/database_service.dart`, lines 11-16):
```dart
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();
```

### 1.3 `test/` Files Importing `package:ttrpg_audio_player/db/database_service.dart`
Grep search across `test/` found exactly 12 files importing `package:ttrpg_audio_player/db/database_service.dart`:

1. `test/widget_test.dart:6`:
   ```dart
   import 'package:ttrpg_audio_player/db/database_service.dart';
   ```
2. `test/data/repositories_test.dart:6`:
   ```dart
   import 'package:ttrpg_audio_player/db/database_service.dart';
   ```
3. `test/db/database_service_test.dart:6`:
   ```dart
   import 'package:ttrpg_audio_player/db/database_service.dart';
   ```
4. `test/services/media_library_service_test.dart:8`:
   ```dart
   import 'package:ttrpg_audio_player/db/database_service.dart';
   ```
5. `test/services/media_package_service_test.dart:8`:
   ```dart
   import 'package:ttrpg_audio_player/db/database_service.dart';
   ```
6. `test/services/pack_package_service_test.dart:9`:
   ```dart
   import 'package:ttrpg_audio_player/db/database_service.dart';
   ```
7. `test/services/scene_package_service_test.dart:6`:
   ```dart
   import 'package:ttrpg_audio_player/db/database_service.dart';
   ```
8. `test/services/scene_service_test.dart:6`:
   ```dart
   import 'package:ttrpg_audio_player/db/database_service.dart';
   ```
9. `test/services/theme_service_test.dart:9`:
   ```dart
   import 'package:ttrpg_audio_player/db/database_service.dart';
   ```
10. `test/ui/milestone_3_ui_test.dart:23`:
    ```dart
    import 'package:ttrpg_audio_player/db/database_service.dart';
    ```
11. `test/ui/milestone_4_ui_test.dart:22`:
    ```dart
    import 'package:ttrpg_audio_player/db/database_service.dart';
    ```
12. `test/ui/widgets_and_screens_test.dart:17`:
    ```dart
    import 'package:ttrpg_audio_player/db/database_service.dart';
    ```

### 1.4 Existing Tests Already Using Canonical Import
- `test/ui/view_models_test.dart:6`: `import 'package:ttrpg_audio_player/data/services/database_service.dart';`
- `test/db/database_service_v4_test.dart:7`: `import 'package:ttrpg_audio_player/data/services/database_service.dart';`

### 1.5 Global References Across Workspace
A comprehensive grep for `db/database_service.dart` across the workspace confirmed:
- 7 references in `lib/`:
  - `lib/data/repositories/scene_repository.dart:2`
  - `lib/data/repositories/media_library_repository.dart:2`
  - `lib/data/repositories/custom_theme_repository.dart:2`
  - `lib/services/theme_service.dart:6`
  - `lib/services/scene_package_service.dart:7`
  - `lib/services/media_package_service.dart:7`
  - `lib/ui/view_models/theme_view_model.dart:5`
- 12 references in `test/` (the 12 files listed in 1.3).
- 1 documentation reference in `PROJECT.md:35`.
- 0 references elsewhere (e.g. `pubspec.yaml`, `analysis_options.yaml`).

### 1.6 Baseline Health Check
- `flutter analyze`: Exited with code 0 (`No issues found!`).
- `flutter test`: Exited with code 0 (148 tests passed, 0 failures).

---

## 2. Logic Chain

1. **Premise 1 (Proxy Nature):** Observation 1.1 proves `lib/db/database_service.dart` is solely an export proxy forwarding to `../data/services/database_service.dart`. It contains no logic, definitions, or state.
2. **Premise 2 (Canonical Identity):** Observation 1.2 proves `lib/data/services/database_service.dart` defines the exact singleton class `DatabaseService` with identical constructor and API signatures used by consumers.
3. **Premise 3 (Precedent & Equivalence):** Observation 1.4 proves that existing tests (`test/ui/view_models_test.dart`, `test/db/database_service_v4_test.dart`) already import `package:ttrpg_audio_player/data/services/database_service.dart` and pass without issues.
4. **Premise 4 (Exhaustiveness):** Observation 1.3 identifies all 12 test files importing the proxy. No other files in `test/` import `db/database_service.dart`.
5. **Premise 5 (Complete Deletion Feasibility):** Observation 1.5 proves that once the 7 `lib/` files and 12 `test/` files are updated to import the canonical service path, no file in the codebase will depend on `lib/db/database_service.dart`. Because `lib/db/` contains no other files (Observation 1.1), `lib/db/` can be deleted in its entirety without any lingering dependencies or broken imports.

---

## 3. Caveats

- **Scope Boundary:** This investigation focused on `test/` references. The 7 references in `lib/` are being managed under M2 Part 2. `lib/db/` must only be deleted after BOTH `lib/` and `test/` imports have been updated.
- **`test/db/` Directory:** Notice that `test/db/` is a test directory (`test/db/database_service_test.dart`, `test/db/database_service_v4_test.dart`). The removal of `lib/db/` does NOT affect or require the removal of `test/db/`.
- **Git Tracking:** When deleting `lib/db/database_service.dart`, `git rm lib/db/database_service.dart` should be used so that git cleanly stages the directory removal.

---

## 4. Conclusion

1. The exact, drop-in replacement for all 12 files in `test/` is:
   ```dart
   // Old:
   import 'package:ttrpg_audio_player/db/database_service.dart';
   // New:
   import 'package:ttrpg_audio_player/data/services/database_service.dart';
   ```
2. The replacement is 100% binary and API compatible, with zero side effects.
3. Once `lib/` and `test/` imports are updated, `lib/db/` has zero dependencies and can be safely and completely deleted.

---

## 5. Verification Method

To independently verify after the implementer applies the changes:

1. **Verify No Dangling Proxy Imports:**
   Run search for any remaining references to the old proxy:
   ```pwsh
   git grep "db/database_service.dart"
   ```
   *Expected output:* Only `PROJECT.md` or empty.

2. **Verify Static Analysis Cleanliness:**
   ```pwsh
   flutter analyze
   ```
   *Expected output:* `No issues found!` (0 errors, 0 warnings, 0 infos).

3. **Verify Test Suite Integrity:**
   ```pwsh
   flutter test
   ```
   *Expected output:* All 148 tests pass with 0 failures.
