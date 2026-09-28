# Analysis Report: Milestone M3 Lib Consumer Imports

**Author**: `explorer_m3_2` (teamwork_preview_explorer)  
**Date**: 2026-09-28  
**Scope**: Milestone M3 — Layered Architecture Alignment (Part 2: Lib Consumer Imports)  
**Objective**: Inventory all consumer files under `lib/` importing any of the 7 data services from `services/`, provide exact unified diffs redirecting them to `lib/data/services/<service_name>.dart`, and verify zero dangling data service imports remain pointing to `lib/services/`.

---

## 1. Executive Summary

In Milestone M3, 7 data services are relocated from `lib/services/` to `lib/data/services/`:
1. `media_library_service.dart`
2. `scene_service.dart`
3. `settings_service.dart`
4. `theme_service.dart`
5. `scene_repository_network_service.dart`
6. `media_package_service.dart`
7. `scene_package_service.dart`

Infrastructure services (`logger_service.dart`, `shortcut_service.dart`) remain in `lib/services/`.

A full scan of all 53 Dart files across `lib/` identified **12 consumer files** containing **18 import statements** that target these 7 data services:
- **Root Entrypoint**: `lib/main.dart` (4 imports)
- **Audio Layer**: `lib/audio/audio_engine_service.dart` (1 import)
- **ViewModels (`lib/ui/view_models/`)**: 4 files (7 imports total)
- **Screens (`lib/ui/screens/`)**: 4 files (4 imports total)
- **Widgets (`lib/ui/widgets/`)**: 2 files (2 imports total)

All 18 imports must be updated from `services/<name>.dart` (or relative `../services/` / `../../services/`) to point directly to `lib/data/services/<name>.dart`.

Following this change, **0 references** to the 7 data services remain pointing to `lib/services/`. All remaining imports referencing `services/` across `lib/` point exclusively to infrastructure services (`logger_service.dart` and `shortcut_service.dart`).

---

## 2. Inventory of Consumer Files & Imports

| # | File Path | Layer / Role | Data Service Imported | Current Import Statement | Proposed New Import Statement | Line # |
|---|-----------|--------------|-----------------------|--------------------------|-------------------------------|--------|
| 1 | `lib/main.dart` | Application Entrypoint | `media_library_service.dart` | `import 'services/media_library_service.dart';` | `import 'data/services/media_library_service.dart';` | 9 |
| 2 | `lib/main.dart` | Application Entrypoint | `settings_service.dart` | `import 'services/settings_service.dart';` | `import 'data/services/settings_service.dart';` | 10 |
| 3 | `lib/main.dart` | Application Entrypoint | `scene_service.dart` | `import 'services/scene_service.dart';` | `import 'data/services/scene_service.dart';` | 11 |
| 4 | `lib/main.dart` | Application Entrypoint | `theme_service.dart` | `import 'services/theme_service.dart';` | `import 'data/services/theme_service.dart';` | 13 |
| 5 | `lib/audio/audio_engine_service.dart` | Audio Engine Layer | `settings_service.dart` | `import '../services/settings_service.dart';` | `import '../data/services/settings_service.dart';` | 7 |
| 6 | `lib/ui/view_models/media_library_view_model.dart` | Presentation / ViewModel | `media_library_service.dart` | `import '../../services/media_library_service.dart';` | `import '../../data/services/media_library_service.dart';` | 2 |
| 7 | `lib/ui/view_models/scene_view_model.dart` | Presentation / ViewModel | `scene_service.dart` | `import '../../services/scene_service.dart';` | `import '../../data/services/scene_service.dart';` | 2 |
| 8 | `lib/ui/view_models/scene_view_model.dart` | Presentation / ViewModel | `media_library_service.dart` | `import '../../services/media_library_service.dart';` | `import '../../data/services/media_library_service.dart';` | 6 |
| 9 | `lib/ui/view_models/theme_view_model.dart` | Presentation / ViewModel | `theme_service.dart` | `import '../../services/theme_service.dart';` | `import '../../data/services/theme_service.dart';` | 2 |
| 10 | `lib/ui/view_models/repository_view_model.dart` | Presentation / ViewModel | `media_package_service.dart` | `import '../../services/media_package_service.dart';` | `import '../../data/services/media_package_service.dart';` | 9 |
| 11 | `lib/ui/view_models/repository_view_model.dart` | Presentation / ViewModel | `scene_package_service.dart` | `import '../../services/scene_package_service.dart';` | `import '../../data/services/scene_package_service.dart';` | 10 |
| 12 | `lib/ui/view_models/repository_view_model.dart` | Presentation / ViewModel | `scene_repository_network_service.dart` | `import '../../services/scene_repository_network_service.dart';` | `import '../../data/services/scene_repository_network_service.dart';` | 11 |
| 13 | `lib/ui/screens/library_screen.dart` | Presentation / Screen | `media_package_service.dart` | `import '../../services/media_package_service.dart';` | `import '../../data/services/media_package_service.dart';` | 8 |
| 14 | `lib/ui/screens/main_dashboard_screen.dart` | Presentation / Screen | `settings_service.dart` | `import '../../services/settings_service.dart';` | `import '../../data/services/settings_service.dart';` | 5 |
| 15 | `lib/ui/screens/repository_catalog_screen.dart` | Presentation / Screen | `scene_repository_network_service.dart` | `import '../../services/scene_repository_network_service.dart';` | `import '../../data/services/scene_repository_network_service.dart';` | 4 |
| 16 | `lib/ui/screens/settings_screen.dart` | Presentation / Screen | `settings_service.dart` | `import '../../services/settings_service.dart';` | `import '../../data/services/settings_service.dart';` | 4 |
| 17 | `lib/ui/widgets/scene_repository_details_dialog.dart` | Presentation / Widget | `scene_repository_network_service.dart` | `import '../../services/scene_repository_network_service.dart';` | `import '../../data/services/scene_repository_network_service.dart';` | 4 |
| 18 | `lib/ui/widgets/scene_selector_panel.dart` | Presentation / Widget | `scene_package_service.dart` | `import '../../services/scene_package_service.dart';` | `import '../../data/services/scene_package_service.dart';` | 12 |

---

## 3. Preserved Infrastructure Services Imports in `lib/`

The following imports target infrastructure services (`lib/services/logger_service.dart` and `lib/services/shortcut_service.dart`) and **must NOT be modified**:

- `lib/main.dart:12`: `import 'services/logger_service.dart';`
- `lib/main.dart:14`: `import 'services/shortcut_service.dart';`
- `lib/audio/ambient_bus_controller.dart:5`: `import '../services/logger_service.dart';`
- `lib/audio/audio_engine_service.dart:6`: `import '../services/logger_service.dart';`
- `lib/audio/ducking_controller.dart:3`: `import '../services/logger_service.dart';`
- `lib/audio/music_bus_controller.dart:5`: `import '../services/logger_service.dart';`
- `lib/audio/sfx_bus_controller.dart:5`: `import '../services/logger_service.dart';`
- `lib/ui/screens/settings_screen.dart:5`: `import '../../services/shortcut_service.dart';`
- `lib/ui/view_models/repository_view_model.dart:8`: `import '../../services/logger_service.dart';`
- `lib/ui/widgets/logger_console_drawer.dart:4`: `import '../../services/logger_service.dart';`

---

## 4. Exact Diff Replacements for Every Consumer File

### 4.1. `lib/main.dart`
```diff
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -9,6 +9,6 @@
-import 'services/media_library_service.dart';
-import 'services/settings_service.dart';
-import 'services/scene_service.dart';
+import 'data/services/media_library_service.dart';
+import 'data/services/settings_service.dart';
+import 'data/services/scene_service.dart';
 import 'services/logger_service.dart';
-import 'services/theme_service.dart';
+import 'data/services/theme_service.dart';
 import 'services/shortcut_service.dart';
```

### 4.2. `lib/audio/audio_engine_service.dart`
```diff
--- a/lib/audio/audio_engine_service.dart
+++ b/lib/audio/audio_engine_service.dart
@@ -6,3 +6,3 @@
 import '../services/logger_service.dart';
-import '../services/settings_service.dart';
+import '../data/services/settings_service.dart';
 
```

### 4.3. `lib/ui/view_models/media_library_view_model.dart`
```diff
--- a/lib/ui/view_models/media_library_view_model.dart
+++ b/lib/ui/view_models/media_library_view_model.dart
@@ -1,3 +1,3 @@
 import 'package:flutter/foundation.dart';
-import '../../services/media_library_service.dart';
+import '../../data/services/media_library_service.dart';
 import '../../data/repositories/media_library_repository.dart';
```

### 4.4. `lib/ui/view_models/scene_view_model.dart`
```diff
--- a/lib/ui/view_models/scene_view_model.dart
+++ b/lib/ui/view_models/scene_view_model.dart
@@ -1,7 +1,7 @@
 import 'package:flutter/foundation.dart';
-import '../../services/scene_service.dart';
+import '../../data/services/scene_service.dart';
 import '../../data/repositories/scene_repository.dart';
 import '../../domain/models/scene_model.dart';
 import '../../audio/audio_engine_service.dart';
-import '../../services/media_library_service.dart';
+import '../../data/services/media_library_service.dart';
 
```

### 4.5. `lib/ui/view_models/theme_view_model.dart`
```diff
--- a/lib/ui/view_models/theme_view_model.dart
+++ b/lib/ui/view_models/theme_view_model.dart
@@ -1,4 +1,4 @@
 import 'package:flutter/material.dart';
-import '../../services/theme_service.dart';
+import '../../data/services/theme_service.dart';
 import '../../data/repositories/custom_theme_repository.dart';
```

### 4.6. `lib/ui/view_models/repository_view_model.dart`
```diff
--- a/lib/ui/view_models/repository_view_model.dart
+++ b/lib/ui/view_models/repository_view_model.dart
@@ -8,5 +8,5 @@
 import '../../services/logger_service.dart';
-import '../../services/media_package_service.dart';
-import '../../services/scene_package_service.dart';
-import '../../services/scene_repository_network_service.dart';
+import '../../data/services/media_package_service.dart';
+import '../../data/services/scene_package_service.dart';
+import '../../data/services/scene_repository_network_service.dart';
 
```

### 4.7. `lib/ui/screens/library_screen.dart`
```diff
--- a/lib/ui/screens/library_screen.dart
+++ b/lib/ui/screens/library_screen.dart
@@ -7,3 +7,3 @@
 import 'package:file_picker/file_picker.dart';
-import '../../services/media_package_service.dart';
+import '../../data/services/media_package_service.dart';
 import '../widgets/import_track_dialog.dart';
```

### 4.8. `lib/ui/screens/main_dashboard_screen.dart`
```diff
--- a/lib/ui/screens/main_dashboard_screen.dart
+++ b/lib/ui/screens/main_dashboard_screen.dart
@@ -4,3 +4,3 @@
 import '../../audio/audio_engine_service.dart';
-import '../../services/settings_service.dart';
+import '../../data/services/settings_service.dart';
 import '../widgets/logger_console_drawer.dart';
```

### 4.9. `lib/ui/screens/repository_catalog_screen.dart`
```diff
--- a/lib/ui/screens/repository_catalog_screen.dart
+++ b/lib/ui/screens/repository_catalog_screen.dart
@@ -3,3 +3,3 @@
 import '../../domain/models/scene_repository_model.dart';
-import '../../services/scene_repository_network_service.dart';
+import '../../data/services/scene_repository_network_service.dart';
 import '../view_models/repository_view_model.dart';
```

### 4.10. `lib/ui/screens/settings_screen.dart`
```diff
--- a/lib/ui/screens/settings_screen.dart
+++ b/lib/ui/screens/settings_screen.dart
@@ -3,3 +3,3 @@
 import '../../l10n/app_localizations.dart';
-import '../../services/settings_service.dart';
+import '../../data/services/settings_service.dart';
 import '../../services/shortcut_service.dart';
```

### 4.11. `lib/ui/widgets/scene_repository_details_dialog.dart`
```diff
--- a/lib/ui/widgets/scene_repository_details_dialog.dart
+++ b/lib/ui/widgets/scene_repository_details_dialog.dart
@@ -3,3 +3,3 @@
 import '../../domain/models/scene_repository_model.dart';
-import '../../services/scene_repository_network_service.dart';
+import '../../data/services/scene_repository_network_service.dart';
 import '../view_models/media_library_view_model.dart';
```

### 4.12. `lib/ui/widgets/scene_selector_panel.dart`
```diff
--- a/lib/ui/widgets/scene_selector_panel.dart
+++ b/lib/ui/widgets/scene_selector_panel.dart
@@ -11,3 +11,3 @@
 import 'package:file_picker/file_picker.dart';
-import '../../services/scene_package_service.dart';
+import '../../data/services/scene_package_service.dart';
 import 'create_edit_scene_dialog.dart';
```

---

## 5. Verification of Zero Dangling Data Service References

To verify that after these edits are applied, zero references to the 7 data services remain pointing to `lib/services/`, execute:

```powershell
Get-ChildItem -Recurse -Filter *.dart lib | ForEach-Object {
    $file = $_.FullName
    $rel = $_.FullName.Substring((Get-Location).Path.Length + 1)
    $lines = Get-Content $file
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if ($line -match "services/(media_library_service|scene_service|settings_service|theme_service|scene_repository_network_service|media_package_service|scene_package_service)\.dart") {
            Write-Output "$($rel):$($i+1): $line"
        }
    }
}
```

Expected output: **empty (0 lines matched)**.

Any remaining occurrences of `services/` will match only `services/logger_service.dart` and `services/shortcut_service.dart`.
