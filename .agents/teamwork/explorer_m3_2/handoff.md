# Handoff Report: Milestone M3 Lib Consumer Imports

**Agent**: `explorer_m3_2` (teamwork_preview_explorer)  
**Parent**: `40418846-e0b1-401a-8c73-44bb8f71b0a0`  
**Milestone**: M3 — Layered Architecture Alignment (Part 2: Lib Consumer Imports)  
**Date**: 2026-09-28  
**Artifacts**:
- `c:\Users\nikit\Documents\antigravity\charming-heisenberg\.agents\teamwork\explorer_m3_2\analysis.md`
- `c:\Users\nikit\Documents\antigravity\charming-heisenberg\.agents\teamwork\explorer_m3_2\lib_consumer_imports.patch`

---

## 1. Observation

A full recursive scan across all 53 `.dart` files in `lib/` was conducted to find all import statements referencing the 7 data services (`media_library_service`, `scene_service`, `settings_service`, `theme_service`, `scene_repository_network_service`, `media_package_service`, `scene_package_service`).

### 1.1. Discovery of `.gitignore` Masking
Tool execution revealed that `.gitignore` line 46 contains `audio/`, causing standard `git` and `ripgrep` commands to ignore `lib/audio/` by default unless explicitly targeted or run with `--no-ignore`. Using explicit filesystem enumeration (`Get-ChildItem -Recurse -Filter *.dart lib`), `lib/audio/audio_engine_service.dart` was inspected and verified.

### 1.2. 18 Import Statements Across 12 Consumer Files
Direct examination of each file confirmed the following verbatim lines:

1. **`lib/main.dart`**:
   - Line 9: `import 'services/media_library_service.dart';`
   - Line 10: `import 'services/settings_service.dart';`
   - Line 11: `import 'services/scene_service.dart';`
   - Line 13: `import 'services/theme_service.dart';`
   *(Lines 12 & 14 import infrastructure services `services/logger_service.dart` and `services/shortcut_service.dart`)*

2. **`lib/audio/audio_engine_service.dart`**:
   - Line 7: `import '../services/settings_service.dart';`
   *(Line 6 imports infrastructure service `../services/logger_service.dart`)*

3. **`lib/ui/view_models/media_library_view_model.dart`**:
   - Line 2: `import '../../services/media_library_service.dart';`

4. **`lib/ui/view_models/scene_view_model.dart`**:
   - Line 2: `import '../../services/scene_service.dart';`
   - Line 6: `import '../../services/media_library_service.dart';`

5. **`lib/ui/view_models/theme_view_model.dart`**:
   - Line 2: `import '../../services/theme_service.dart';`
   *(Line 5 already imports `../../data/services/database_service.dart`)*

6. **`lib/ui/view_models/repository_view_model.dart`**:
   - Line 9: `import '../../services/media_package_service.dart';`
   - Line 10: `import '../../services/scene_package_service.dart';`
   - Line 11: `import '../../services/scene_repository_network_service.dart';`
   *(Line 8 imports infrastructure service `../../services/logger_service.dart`)*

7. **`lib/ui/screens/library_screen.dart`**:
   - Line 8: `import '../../services/media_package_service.dart';`

8. **`lib/ui/screens/main_dashboard_screen.dart`**:
   - Line 5: `import '../../services/settings_service.dart';`

9. **`lib/ui/screens/repository_catalog_screen.dart`**:
   - Line 4: `import '../../services/scene_repository_network_service.dart';`

10. **`lib/ui/screens/settings_screen.dart`**:
    - Line 4: `import '../../services/settings_service.dart';`
    *(Line 5 imports infrastructure service `../../services/shortcut_service.dart`)*

11. **`lib/ui/widgets/scene_repository_details_dialog.dart`**:
    - Line 4: `import '../../services/scene_repository_network_service.dart';`

12. **`lib/ui/widgets/scene_selector_panel.dart`**:
    - Line 12: `import '../../services/scene_package_service.dart';`

### 1.3. Infrastructure Imports (Must be preserved)
The following 10 imports across `lib/` point to `logger_service.dart` or `shortcut_service.dart` and must remain untouched:
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

## 2. Logic Chain

1. **Premise 1 (R3 / Feature 4)**: The 7 data services (`media_library_service.dart`, `scene_service.dart`, `settings_service.dart`, `theme_service.dart`, `scene_repository_network_service.dart`, `media_package_service.dart`, `scene_package_service.dart`) are being relocated from `lib/services/` to `lib/data/services/`.
2. **Premise 2 (R3 / Feature 5)**: Infrastructure services (`logger_service.dart` and `shortcut_service.dart`) are retained in `lib/services/`.
3. **Observation Reference (§1.2)**: 12 consumer files under `lib/` import these 7 data services using paths pointing to `services/<name>.dart`.
4. **Step 1 (Path Resolution)**:
   - Files at `lib/` (`main.dart`): `services/` becomes `data/services/`.
   - Files at `lib/audio/` (`audio_engine_service.dart`): `../services/` becomes `../data/services/`.
   - Files at `lib/ui/view_models/`: `../../services/` becomes `../../data/services/`.
   - Files at `lib/ui/screens/`: `../../services/` becomes `../../data/services/`.
   - Files at `lib/ui/widgets/`: `../../services/` becomes `../../data/services/`.
5. **Step 2 (Selective Replacement)**:
   - For all 18 matching import lines, update the path component to `data/services/`.
   - Leave the 10 infrastructure service imports (§1.3) unchanged.
6. **Inference / Result**:
   - Zero references to the 7 data services will remain pointing to `lib/services/`.
   - All consumer files cleanly resolve types from `lib/data/services/`.

---

## 3. Caveats

1. **Test Suite Scope**: Imports in `test/` (17 test files) are outside this subtask's scope and handled under Milestone M3 Part 3 (`explorer_m3_3` / executor).
2. **Relocation Prerequisite**: These consumer import changes require the physical relocation of the 7 service files to `lib/data/services/` (handled in Milestone M3 Part 1 by `explorer_m3_1` / executor).
3. **Gitignore Behavior**: When staging or running git diffs, ensure `lib/audio/` is tracked explicitly (`git add -f lib/audio/audio_engine_service.dart` if needed, or refine `.gitignore` to `/audio/` so that it doesn't match `lib/audio/`).
4. No other assumptions were made.

---

## 4. Conclusion

- Exactly 12 consumer files under `lib/` require import updates across 18 specific lines.
- Complete unified diffs and patch are documented in `analysis.md` and saved to `lib_consumer_imports.patch`.
- Zero references to the 7 data services will point to `lib/services/` after applying this patch.
- The plan is ready for immediate application by the executor agent.

---

## 5. Verification Method

### 5.1. Static Path Verification Command
Run the following PowerShell script from the repository root:
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
**Expected Result**: Zero output (0 matching lines).

### 5.2. Analyzer Verification (Post-Relocation)
Once the 7 service files are relocated to `lib/data/services/` and this patch is applied:
```powershell
flutter analyze lib/
```
**Expected Result**: Zero URI/import errors in `lib/`.

### 5.3. Invalidation Conditions
- If any data service is left in `lib/services/`, imports pointing to `lib/data/services/` will produce target-does-not-exist analyzer errors.
- If infrastructure services (`logger_service.dart`, `shortcut_service.dart`) are accidentally modified to point to `lib/data/services/`, analyzer errors will occur.
