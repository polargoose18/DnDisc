# Analysis Report: Database Proxy Cleanup in `test/` (Milestone M2 - Part 3)

**Author:** explorer_m2_3  
**Date:** 2026-09-28T09:18:00Z  
**Target:** Elimination of legacy export proxy `lib/db/database_service.dart` references across `test/` suite and safe removal of `lib/db/`.

---

## 1. Executive Summary

All 12 references in `test/` importing `package:ttrpg_audio_player/db/database_service.dart` have been identified, verified with exact line numbers, and analyzed against the canonical target `package:ttrpg_audio_player/data/services/database_service.dart`. `lib/db/` contains only `database_service.dart`, which is a 2-line re-export proxy (`export '../data/services/database_service.dart';`). Once all references in `lib/` (7 files) and `test/` (12 files) are redirected to the canonical path, `lib/db/` can be deleted with zero dangling imports or side effects.

---

## 2. Test Files Reference Inventory

Across the `test/` suite, exactly 12 files import `package:ttrpg_audio_player/db/database_service.dart`. Two test files (`test/ui/view_models_test.dart` and `test/db/database_service_v4_test.dart`) already correctly use the canonical import `package:ttrpg_audio_player/data/services/database_service.dart`.

| # | Test File Path | Line # | Current Import (Target to Replace) | Canonical Replacement Import | Symbols Used |
|---|----------------|--------|------------------------------------|------------------------------|--------------|
| 1 | `test/widget_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService().close()` |
| 2 | `test/data/repositories_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService` in test setup/teardown |
| 3 | `test/db/database_service_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService` CRUD operations & transactions |
| 4 | `test/services/media_library_service_test.dart` | 8 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService dbService` |
| 5 | `test/services/media_package_service_test.dart` | 8 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService dbService` |
| 6 | `test/services/pack_package_service_test.dart` | 9 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService dbService` |
| 7 | `test/services/scene_package_service_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService dbService` |
| 8 | `test/services/scene_service_test.dart` | 6 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService dbService` |
| 9 | `test/services/theme_service_test.dart` | 9 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService dbService` |
| 10 | `test/ui/milestone_3_ui_test.dart` | 23 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService().close()` |
| 11 | `test/ui/milestone_4_ui_test.dart` | 22 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService().close()` |
| 12 | `test/ui/widgets_and_screens_test.dart` | 17 | `import 'package:ttrpg_audio_player/db/database_service.dart';` | `import 'package:ttrpg_audio_player/data/services/database_service.dart';` | `DatabaseService().close()` |

---

## 3. Detailed File-by-File Evidence & Proposed Changes

### 3.1 `test/widget_test.dart`
- **Location:** Line 6
- **Context:**
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/main.dart';
```

### 3.2 `test/data/repositories_test.dart`
- **Location:** Line 6
- **Context:**
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
```

### 3.3 `test/db/database_service_test.dart`
- **Location:** Line 6
- **Context:**
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
```

### 3.4 `test/services/media_library_service_test.dart`
- **Location:** Line 8
- **Context:**
```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/services/media_library_service.dart';
import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
```

### 3.5 `test/services/media_package_service_test.dart`
- **Location:** Line 8
- **Context:**
```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
```

### 3.6 `test/services/pack_package_service_test.dart`
- **Location:** Line 9
- **Context:**
```dart
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
```

### 3.7 `test/services/scene_package_service_test.dart`
- **Location:** Line 6
- **Context:**
```dart
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
```

### 3.8 `test/services/scene_service_test.dart`
- **Location:** Line 6
- **Context:**
```dart
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/services/scene_service.dart';
```

### 3.9 `test/services/theme_service_test.dart`
- **Location:** Line 9
- **Context:**
```dart
import 'package:ttrpg_audio_player/domain/models/custom_theme_model.dart';
import 'package:ttrpg_audio_player/services/theme_service.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
```

### 3.10 `test/ui/milestone_3_ui_test.dart`
- **Location:** Line 23
- **Context:**
```dart
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/theme_view_model.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
```

### 3.11 `test/ui/milestone_4_ui_test.dart`
- **Location:** Line 22
- **Context:**
```dart
import 'package:ttrpg_audio_player/services/theme_service.dart';
import 'package:ttrpg_audio_player/services/shortcut_service.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/ui/screens/responsive_gm_dashboard.dart';
```

### 3.12 `test/ui/widgets_and_screens_test.dart`
- **Location:** Line 17
- **Context:**
```dart
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/services/media_library_service.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
// REPLACE THIS:
import 'package:ttrpg_audio_player/db/database_service.dart';
// WITH THIS:
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
```

---

## 4. Verification of `lib/db/` Removal Safety

### 4.1 Contents of `lib/db/`
Inspection of `lib/db/` confirmed that it contains **only one file**:
- `lib/db/database_service.dart` (49 bytes)

File contents verbatim:
```dart
export '../data/services/database_service.dart';
```
There are no other files, hidden files, or subdirectories in `lib/db/`.

### 4.2 Comprehensive Reference Audit
A global search for `db/database_service.dart` across the entire codebase revealed 19 total occurrences:
- **`lib/` files (7 occurrences):**
  1. `lib/data/repositories/scene_repository.dart:2`
  2. `lib/data/repositories/media_library_repository.dart:2`
  3. `lib/data/repositories/custom_theme_repository.dart:2`
  4. `lib/services/theme_service.dart:6`
  5. `lib/services/scene_package_service.dart:7`
  6. `lib/services/media_package_service.dart:7`
  7. `lib/ui/view_models/theme_view_model.dart:5`
- **`test/` files (12 occurrences):**
  Listed in Section 2 above.

### 4.3 Deletion Safety Confirmation
Once the 7 imports in `lib/` and the 12 imports in `test/` are updated to point directly to `package:ttrpg_audio_player/data/services/database_service.dart` (or relative path `../data/services/database_service.dart` / `database_service.dart`):
1. **Zero references** will remain to `package:ttrpg_audio_player/db/database_service.dart` or `../db/database_service.dart`.
2. The entire directory `lib/db/` and its single file `lib/db/database_service.dart` can be completely deleted.
3. No build tools, pub specifications, or asset mappings rely on `lib/db/`.
4. Tests in `test/db/` (such as `test/db/database_service_test.dart` and `test/db/database_service_v4_test.dart`) reside under `test/`, and their names and locations are not affected by the removal of `lib/db/`.

---

## 5. Verification Commands for Implementer

1. Run static analysis:
   ```bash
   flutter analyze
   ```
   *Expected:* `No issues found!` (0 errors, 0 warnings, 0 infos).

2. Run full test suite:
   ```bash
   flutter test
   ```
   *Expected:* All 148 tests pass with 0 failures.
