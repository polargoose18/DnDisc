# Handoff Report: Layered Architecture Alignment - Part 3: Test Consumer Imports (Milestone M3)

**Agent**: `explorer_m3_3`  
**Working Directory**: `c:\Users\nikit\Documents\antigravity\charming-heisenberg\.agents\teamwork\explorer_m3_3`  
**Milestone**: M3 (Layered Architecture Alignment - Part 3: Test Consumer Imports)  
**Target Recipient**: `orchestrator_1` / `worker_m3_1`  

---

## 1. Observation

### 1.1 Full Test Suite Inventory
A scan using `find_by_name` across `test/` returned 28 Dart test files:
- `test/audio/audio_controllers_test.dart`
- `test/audio/fade_and_ducking_test.dart`
- `test/data/repositories_test.dart`
- `test/db/database_service_test.dart`
- `test/db/database_service_v4_test.dart`
- `test/m1_empirical_verification_test.dart`
- `test/m2_empirical_verification_test.dart`
- `test/models/custom_theme_model_test.dart`
- `test/models/models_test.dart`
- `test/models/scene_model_test.dart`
- `test/models/scene_repository_manifest_v2_test.dart`
- `test/services/logger_service_test.dart`
- `test/services/media_library_service_test.dart`
- `test/services/media_package_service_test.dart`
- `test/services/pack_package_service_test.dart`
- `test/services/scene_package_service_test.dart`
- `test/services/scene_repository_network_service_test.dart`
- `test/services/scene_service_test.dart`
- `test/services/settings_service_test.dart`
- `test/services/shortcut_service_test.dart`
- `test/services/theme_service_test.dart`
- `test/ui/catalog_screen_test.dart`
- `test/ui/milestone_3_ui_test.dart`
- `test/ui/milestone_4_ui_test.dart`
- `test/ui/repository_view_model_test.dart`
- `test/ui/view_models_test.dart`
- `test/ui/widgets_and_screens_test.dart`
- `test/widget_test.dart`

### 1.2 Test Files Importing Data Services from `package:ttrpg_audio_player/services/...`
Using `grep_search` with query `package:ttrpg_audio_player/services/` in `test/`, exact line matches were identified:

1. `test/services/media_library_service_test.dart`
   - Line 6: `import 'package:ttrpg_audio_player/services/media_library_service.dart';`
2. `test/services/scene_service_test.dart`
   - Line 7: `import 'package:ttrpg_audio_player/services/scene_service.dart';`
   - Line 8: `import 'package:ttrpg_audio_player/services/media_library_service.dart';`
3. `test/services/theme_service_test.dart`
   - Line 7: `import 'package:ttrpg_audio_player/services/theme_service.dart';`
4. `test/services/media_package_service_test.dart`
   - Line 10: `import 'package:ttrpg_audio_player/services/media_package_service.dart';`
5. `test/services/scene_package_service_test.dart`
   - Line 10: `import 'package:ttrpg_audio_player/services/scene_package_service.dart';`
6. `test/services/pack_package_service_test.dart`
   - Line 12: `import 'package:ttrpg_audio_player/services/scene_package_service.dart';`
7. `test/services/scene_repository_network_service_test.dart`
   - Line 2: `import 'package:ttrpg_audio_player/services/scene_repository_network_service.dart';`
8. `test/services/settings_service_test.dart`
   - Line 3: `import 'package:ttrpg_audio_player/services/settings_service.dart';`
9. `test/ui/milestone_3_ui_test.dart`
   - Line 15: `import 'package:ttrpg_audio_player/services/media_library_service.dart';`
   - Line 16: `import 'package:ttrpg_audio_player/services/settings_service.dart';`
   - Line 17: `import 'package:ttrpg_audio_player/services/scene_service.dart';`
   - Line 18: `import 'package:ttrpg_audio_player/services/logger_service.dart';` *(Infrastructure service — must remain in `services/`)*
   - Line 19: `import 'package:ttrpg_audio_player/services/theme_service.dart';`
10. `test/ui/milestone_4_ui_test.dart`
    - Line 16: `import 'package:ttrpg_audio_player/services/media_library_service.dart';`
    - Line 17: `import 'package:ttrpg_audio_player/services/scene_service.dart';`
    - Line 18: `import 'package:ttrpg_audio_player/services/settings_service.dart';`
    - Line 19: `import 'package:ttrpg_audio_player/services/theme_service.dart';`
    - Line 20: `import 'package:ttrpg_audio_player/services/shortcut_service.dart';` *(Infrastructure service — must remain in `services/`)*
    - Line 21: `import 'package:ttrpg_audio_player/services/logger_service.dart';` *(Infrastructure service — must remain in `services/`)*
11. `test/ui/widgets_and_screens_test.dart`
    - Line 15: `import 'package:ttrpg_audio_player/services/media_library_service.dart';`
    - Line 16: `import 'package:ttrpg_audio_player/services/logger_service.dart';` *(Infrastructure service — must remain in `services/`)*
    - Line 30: `import 'package:ttrpg_audio_player/services/settings_service.dart';`
    - Line 31: `import 'package:ttrpg_audio_player/services/scene_service.dart';`
    - Line 32: `import 'package:ttrpg_audio_player/services/theme_service.dart';`
12. `test/ui/view_models_test.dart`
    - Line 10: `import 'package:ttrpg_audio_player/services/scene_service.dart';`
    - Line 11: `import 'package:ttrpg_audio_player/services/media_library_service.dart';`
    - Line 12: `import 'package:ttrpg_audio_player/services/theme_service.dart';`
13. `test/ui/catalog_screen_test.dart`
    - Line 7: `import 'package:ttrpg_audio_player/services/scene_repository_network_service.dart';`

### 1.3 Infrastructure Service Test Files
- `test/services/logger_service_test.dart` (Line 2: `import 'package:ttrpg_audio_player/services/logger_service.dart';`) — Infrastructure service; preserved in `lib/services/`.
- `test/services/shortcut_service_test.dart` (Line 4: `import 'package:ttrpg_audio_player/services/shortcut_service.dart';`) — Infrastructure service; preserved in `lib/services/`.

### 1.4 Baseline Test Execution Output
Command `flutter test` was executed in `c:\Users\nikit\Documents\antigravity\charming-heisenberg`:
```
00:12 +152: All tests passed!
```
Exit code: `0`. All 152 existing tests pass in the current working copy.

---

## 2. Logic Chain

1. **Identification of Relocated Target**:
   Per `ORIGINAL_REQUEST.md` (§R3) and `PROJECT.md`, exactly 7 services are classified as data services and moved from `lib/services/` to `lib/data/services/`:
   `media_library_service.dart`, `scene_service.dart`, `settings_service.dart`, `theme_service.dart`, `scene_repository_network_service.dart`, `media_package_service.dart`, and `scene_package_service.dart`.
2. **Infrastructure Boundaries**:
   `logger_service.dart` and `shortcut_service.dart` are explicitly retained in `lib/services/`. Any import of these two in tests (e.g., in `logger_service_test.dart`, `shortcut_service_test.dart`, `milestone_3_ui_test.dart:18`, `milestone_4_ui_test.dart:20-21`, `widgets_and_screens_test.dart:16`) MUST NOT be changed to `data/services/`.
3. **Absence of Relative Imports in Tests**:
   A search across `test/` for relative imports (`import '..` or `import '.`) returned zero results. All test imports are canonical package imports (`package:ttrpg_audio_player/...`).
4. **Scope of Test File Changes**:
   Exactly 13 test files contain imports targeting the 7 data services. Updating these package URIs from `package:ttrpg_audio_player/services/<service>.dart` to `package:ttrpg_audio_player/data/services/<service>.dart` produces clean compile-time resolution with zero breaking API changes, since only the import path changes while class names and APIs remain identical.

---

## 3. Caveats

1. **Read-Only Exploration**: No files in `test/` or `lib/` were modified by `explorer_m3_3`. The actual application of the diffs must be performed by `worker_m3_1` alongside the file moves and `lib/` consumer updates.
2. **Test File Relocation Not Required**: Test files themselves currently reside under `test/services/` (e.g. `test/services/media_library_service_test.dart`). As documented in `PROJECT.md` and `survey_explorer_2`, Milestone M3 moves the source services to `lib/data/services/` and updates consumer imports; test files remain in their existing paths to avoid disrupting test runner scripts or test directory conventions.
3. **Database Service Already Migrated**: `database_service.dart` was already relocated in Milestone M2, so test references to `package:ttrpg_audio_player/data/services/database_service.dart` are already correct and require no edits.

---

## 4. Conclusion

Exactly 13 test files need import updates across 22 import lines. All 13 diff blocks are mapped with exact line numbers below. Once applied after the 7 data services are moved to `lib/data/services/`, all 152 tests will compile and pass cleanly without any lingering legacy service imports.

### Exact Diff Replacements to Apply:

#### 1. `test/services/media_library_service_test.dart`
```diff
--- a/test/services/media_library_service_test.dart
+++ b/test/services/media_library_service_test.dart
@@ -6,1 +6,1 @@
-import 'package:ttrpg_audio_player/services/media_library_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
```

#### 2. `test/services/scene_service_test.dart`
```diff
--- a/test/services/scene_service_test.dart
+++ b/test/services/scene_service_test.dart
@@ -7,2 +7,2 @@
-import 'package:ttrpg_audio_player/services/scene_service.dart';
-import 'package:ttrpg_audio_player/services/media_library_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
```

#### 3. `test/services/theme_service_test.dart`
```diff
--- a/test/services/theme_service_test.dart
+++ b/test/services/theme_service_test.dart
@@ -7,1 +7,1 @@
-import 'package:ttrpg_audio_player/services/theme_service.dart';
+import 'package:ttrpg_audio_player/data/services/theme_service.dart';
```

#### 4. `test/services/media_package_service_test.dart`
```diff
--- a/test/services/media_package_service_test.dart
+++ b/test/services/media_package_service_test.dart
@@ -10,1 +10,1 @@
-import 'package:ttrpg_audio_player/services/media_package_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_package_service.dart';
```

#### 5. `test/services/scene_package_service_test.dart`
```diff
--- a/test/services/scene_package_service_test.dart
+++ b/test/services/scene_package_service_test.dart
@@ -10,1 +10,1 @@
-import 'package:ttrpg_audio_player/services/scene_package_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_package_service.dart';
```

#### 6. `test/services/pack_package_service_test.dart`
```diff
--- a/test/services/pack_package_service_test.dart
+++ b/test/services/pack_package_service_test.dart
@@ -12,1 +12,1 @@
-import 'package:ttrpg_audio_player/services/scene_package_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_package_service.dart';
```

#### 7. `test/services/scene_repository_network_service_test.dart`
```diff
--- a/test/services/scene_repository_network_service_test.dart
+++ b/test/services/scene_repository_network_service_test.dart
@@ -2,1 +2,1 @@
-import 'package:ttrpg_audio_player/services/scene_repository_network_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
```

#### 8. `test/services/settings_service_test.dart`
```diff
--- a/test/services/settings_service_test.dart
+++ b/test/services/settings_service_test.dart
@@ -3,1 +3,1 @@
-import 'package:ttrpg_audio_player/services/settings_service.dart';
+import 'package:ttrpg_audio_player/data/services/settings_service.dart';
```

#### 9. `test/ui/milestone_3_ui_test.dart`
```diff
--- a/test/ui/milestone_3_ui_test.dart
+++ b/test/ui/milestone_3_ui_test.dart
@@ -15,5 +15,5 @@
-import 'package:ttrpg_audio_player/services/media_library_service.dart';
-import 'package:ttrpg_audio_player/services/settings_service.dart';
-import 'package:ttrpg_audio_player/services/scene_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
+import 'package:ttrpg_audio_player/data/services/settings_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_service.dart';
 import 'package:ttrpg_audio_player/services/logger_service.dart';
-import 'package:ttrpg_audio_player/services/theme_service.dart';
+import 'package:ttrpg_audio_player/data/services/theme_service.dart';
```

#### 10. `test/ui/milestone_4_ui_test.dart`
```diff
--- a/test/ui/milestone_4_ui_test.dart
+++ b/test/ui/milestone_4_ui_test.dart
@@ -16,4 +16,4 @@
-import 'package:ttrpg_audio_player/services/media_library_service.dart';
-import 'package:ttrpg_audio_player/services/scene_service.dart';
-import 'package:ttrpg_audio_player/services/settings_service.dart';
-import 'package:ttrpg_audio_player/services/theme_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_service.dart';
+import 'package:ttrpg_audio_player/data/services/settings_service.dart';
+import 'package:ttrpg_audio_player/data/services/theme_service.dart';
```

#### 11. `test/ui/widgets_and_screens_test.dart`
```diff
--- a/test/ui/widgets_and_screens_test.dart
+++ b/test/ui/widgets_and_screens_test.dart
@@ -15,1 +15,1 @@
-import 'package:ttrpg_audio_player/services/media_library_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
@@ -30,3 +30,3 @@
-import 'package:ttrpg_audio_player/services/settings_service.dart';
-import 'package:ttrpg_audio_player/services/scene_service.dart';
-import 'package:ttrpg_audio_player/services/theme_service.dart';
+import 'package:ttrpg_audio_player/data/services/settings_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_service.dart';
+import 'package:ttrpg_audio_player/data/services/theme_service.dart';
```

#### 12. `test/ui/view_models_test.dart`
```diff
--- a/test/ui/view_models_test.dart
+++ b/test/ui/view_models_test.dart
@@ -10,3 +10,3 @@
-import 'package:ttrpg_audio_player/services/scene_service.dart';
-import 'package:ttrpg_audio_player/services/media_library_service.dart';
-import 'package:ttrpg_audio_player/services/theme_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
+import 'package:ttrpg_audio_player/data/services/theme_service.dart';
```

#### 13. `test/ui/catalog_screen_test.dart`
```diff
--- a/test/ui/catalog_screen_test.dart
+++ b/test/ui/catalog_screen_test.dart
@@ -7,1 +7,1 @@
-import 'package:ttrpg_audio_player/services/scene_repository_network_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
```

---

## 5. Verification Method

To independently verify after worker changes are applied:

1. **Verify No Dangling Service Imports in `test/`**:
   ```pwsh
   Get-ChildItem -Path test -Recurse -Filter *.dart | Select-String "package:ttrpg_audio_player/services/(media_library_service|scene_service|settings_service|theme_service|scene_repository_network_service|media_package_service|scene_package_service).dart"
   ```
   **Expected**: 0 matches.

2. **Verify Retained Infrastructure Services in `test/`**:
   ```pwsh
   Get-ChildItem -Path test -Recurse -Filter *.dart | Select-String "package:ttrpg_audio_player/services/"
   ```
   **Expected**: Only lines importing `logger_service.dart` and `shortcut_service.dart`.

3. **Run Static Analysis**:
   ```pwsh
   flutter analyze
   ```
   **Expected**: `No issues found!`.

4. **Run Complete Automated Test Suite**:
   ```pwsh
   flutter test
   ```
   **Expected**: 152+ passed tests, 0 failures.
