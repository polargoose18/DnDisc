# Comprehensive Analysis Report: Test Consumer Imports for Layered Architecture Alignment (Milestone M3, Part 3)

**Author**: `explorer_m3_3`  
**Date**: 2026-09-28  
**Scope**: All automated test files under `test/` importing data services  

---

## 1. Executive Summary

As part of Milestone M3 (Layered Architecture Alignment), 7 data services are being relocated from `lib/services/` to `lib/data/services/`:
1. `media_library_service.dart`
2. `scene_service.dart`
3. `settings_service.dart`
4. `theme_service.dart`
5. `scene_repository_network_service.dart`
6. `media_package_service.dart`
7. `scene_package_service.dart`

Meanwhile, system-level infrastructure services remain in `lib/services/`:
1. `logger_service.dart`
2. `shortcut_service.dart`

And `database_service.dart` was already relocated to `lib/data/services/database_service.dart` in Milestone M2.

This investigation conducted a full scan across all 28 Dart test files in `test/`. Exactly **13 test files** import one or more of the 7 data services and require updating to `package:ttrpg_audio_player/data/services/...`. No test files use relative imports (`../services/...`). 

Every test file retaining infrastructure imports (`logger_service.dart`, `shortcut_service.dart`) continues to correctly import them from `package:ttrpg_audio_player/services/...`.

---

## 2. Exhaustive Audit of Test Suite (`test/`)

All 28 test files in the workspace were analyzed.

### 2.1 Test Files Requiring Import Updates (13 Files)

| # | Test File Path | Data Service Imports to Migrate |
|---|----------------|---------------------------------|
| 1 | `test/services/media_library_service_test.dart` | `services/media_library_service.dart` $\rightarrow$ `data/services/media_library_service.dart` |
| 2 | `test/services/scene_service_test.dart` | `services/scene_service.dart` $\rightarrow$ `data/services/scene_service.dart`<br>`services/media_library_service.dart` $\rightarrow$ `data/services/media_library_service.dart` |
| 3 | `test/services/theme_service_test.dart` | `services/theme_service.dart` $\rightarrow$ `data/services/theme_service.dart` |
| 4 | `test/services/media_package_service_test.dart` | `services/media_package_service.dart` $\rightarrow$ `data/services/media_package_service.dart` |
| 5 | `test/services/scene_package_service_test.dart` | `services/scene_package_service.dart` $\rightarrow$ `data/services/scene_package_service.dart` |
| 6 | `test/services/pack_package_service_test.dart` | `services/scene_package_service.dart` $\rightarrow$ `data/services/scene_package_service.dart` |
| 7 | `test/services/scene_repository_network_service_test.dart` | `services/scene_repository_network_service.dart` $\rightarrow$ `data/services/scene_repository_network_service.dart` |
| 8 | `test/services/settings_service_test.dart` | `services/settings_service.dart` $\rightarrow$ `data/services/settings_service.dart` |
| 9 | `test/ui/milestone_3_ui_test.dart` | `services/media_library_service.dart` $\rightarrow$ `data/services/media_library_service.dart`<br>`services/settings_service.dart` $\rightarrow$ `data/services/settings_service.dart`<br>`services/scene_service.dart` $\rightarrow$ `data/services/scene_service.dart`<br>`services/theme_service.dart` $\rightarrow$ `data/services/theme_service.dart`<br>*(Preserves `services/logger_service.dart`)* |
| 10 | `test/ui/milestone_4_ui_test.dart` | `services/media_library_service.dart` $\rightarrow$ `data/services/media_library_service.dart`<br>`services/scene_service.dart` $\rightarrow$ `data/services/scene_service.dart`<br>`services/settings_service.dart` $\rightarrow$ `data/services/settings_service.dart`<br>`services/theme_service.dart` $\rightarrow$ `data/services/theme_service.dart`<br>*(Preserves `services/shortcut_service.dart` & `services/logger_service.dart`)* |
| 11 | `test/ui/widgets_and_screens_test.dart` | `services/media_library_service.dart` $\rightarrow$ `data/services/media_library_service.dart`<br>`services/settings_service.dart` $\rightarrow$ `data/services/settings_service.dart`<br>`services/scene_service.dart` $\rightarrow$ `data/services/scene_service.dart`<br>`services/theme_service.dart` $\rightarrow$ `data/services/theme_service.dart`<br>*(Preserves `services/logger_service.dart`)* |
| 12 | `test/ui/view_models_test.dart` | `services/scene_service.dart` $\rightarrow$ `data/services/scene_service.dart`<br>`services/media_library_service.dart` $\rightarrow$ `data/services/media_library_service.dart`<br>`services/theme_service.dart` $\rightarrow$ `data/services/theme_service.dart` |
| 13 | `test/ui/catalog_screen_test.dart` | `services/scene_repository_network_service.dart` $\rightarrow$ `data/services/scene_repository_network_service.dart` |

### 2.2 Test Files Already Clean / Unaffected (15 Files)

| # | Test File Path | Status / Retained Imports |
|---|----------------|---------------------------|
| 1 | `test/services/logger_service_test.dart` | Only imports `services/logger_service.dart` (Infrastructure service; stays) |
| 2 | `test/services/shortcut_service_test.dart` | Only imports `services/shortcut_service.dart` (Infrastructure service; stays) |
| 3 | `test/ui/repository_view_model_test.dart` | No service imports (uses mock repositories) |
| 4 | `test/data/repositories_test.dart` | Imports `data/services/database_service.dart` (Migrated in M2) |
| 5 | `test/widget_test.dart` | Imports `data/services/database_service.dart` (Migrated in M2) |
| 6 | `test/db/database_service_test.dart` | Imports `data/services/database_service.dart` (Migrated in M2) |
| 7 | `test/db/database_service_v4_test.dart` | Imports `data/services/database_service.dart` (Migrated in M2) |
| 8 | `test/audio/audio_controllers_test.dart` | No service imports |
| 9 | `test/audio/fade_and_ducking_test.dart` | No service imports |
| 10 | `test/m1_empirical_verification_test.dart` | No service imports |
| 11 | `test/m2_empirical_verification_test.dart` | Imports `data/services/database_service.dart` (Migrated in M2) |
| 12 | `test/models/custom_theme_model_test.dart` | No service imports |
| 13 | `test/models/models_test.dart` | No service imports |
| 14 | `test/models/scene_model_test.dart` | No service imports |
| 15 | `test/models/scene_repository_manifest_v2_test.dart` | No service imports |

---

## 3. Exact Unified Diff Replacements for All 13 Test Files

Below are the exact unified diffs ready for direct application by the implementation worker.

### File 1: `test/services/media_library_service_test.dart`
```diff
--- a/test/services/media_library_service_test.dart
+++ b/test/services/media_library_service_test.dart
@@ -6,1 +6,1 @@
-import 'package:ttrpg_audio_player/services/media_library_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
```

### File 2: `test/services/scene_service_test.dart`
```diff
--- a/test/services/scene_service_test.dart
+++ b/test/services/scene_service_test.dart
@@ -7,2 +7,2 @@
-import 'package:ttrpg_audio_player/services/scene_service.dart';
-import 'package:ttrpg_audio_player/services/media_library_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
```

### File 3: `test/services/theme_service_test.dart`
```diff
--- a/test/services/theme_service_test.dart
+++ b/test/services/theme_service_test.dart
@@ -7,1 +7,1 @@
-import 'package:ttrpg_audio_player/services/theme_service.dart';
+import 'package:ttrpg_audio_player/data/services/theme_service.dart';
```

### File 4: `test/services/media_package_service_test.dart`
```diff
--- a/test/services/media_package_service_test.dart
+++ b/test/services/media_package_service_test.dart
@@ -10,1 +10,1 @@
-import 'package:ttrpg_audio_player/services/media_package_service.dart';
+import 'package:ttrpg_audio_player/data/services/media_package_service.dart';
```

### File 5: `test/services/scene_package_service_test.dart`
```diff
--- a/test/services/scene_package_service_test.dart
+++ b/test/services/scene_package_service_test.dart
@@ -10,1 +10,1 @@
-import 'package:ttrpg_audio_player/services/scene_package_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_package_service.dart';
```

### File 6: `test/services/pack_package_service_test.dart`
```diff
--- a/test/services/pack_package_service_test.dart
+++ b/test/services/pack_package_service_test.dart
@@ -12,1 +12,1 @@
-import 'package:ttrpg_audio_player/services/scene_package_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_package_service.dart';
```

### File 7: `test/services/scene_repository_network_service_test.dart`
```diff
--- a/test/services/scene_repository_network_service_test.dart
+++ b/test/services/scene_repository_network_service_test.dart
@@ -2,1 +2,1 @@
-import 'package:ttrpg_audio_player/services/scene_repository_network_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
```

### File 8: `test/services/settings_service_test.dart`
```diff
--- a/test/services/settings_service_test.dart
+++ b/test/services/settings_service_test.dart
@@ -3,1 +3,1 @@
-import 'package:ttrpg_audio_player/services/settings_service.dart';
+import 'package:ttrpg_audio_player/data/services/settings_service.dart';
```

### File 9: `test/ui/milestone_3_ui_test.dart`
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

### File 10: `test/ui/milestone_4_ui_test.dart`
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

### File 11: `test/ui/widgets_and_screens_test.dart`
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

### File 12: `test/ui/view_models_test.dart`
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

### File 13: `test/ui/catalog_screen_test.dart`
```diff
--- a/test/ui/catalog_screen_test.dart
+++ b/test/ui/catalog_screen_test.dart
@@ -7,1 +7,1 @@
-import 'package:ttrpg_audio_player/services/scene_repository_network_service.dart';
+import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
```

---

## 4. Verification Plan for Worker

When `worker_m3_1` executes Milestone M3:
1. Move the 7 files from `lib/services/` to `lib/data/services/`.
2. Update internal relative imports inside the 7 data services.
3. Update `lib/` consumer imports (identified by `explorer_m3_2`).
4. Update `test/` consumer imports using the exact diffs documented above (13 files).
5. Run `flutter analyze` — verify 0 errors, 0 warnings, 0 infos.
6. Run `flutter test` — verify all tests compile and pass (145+ tests, 0 failures).
