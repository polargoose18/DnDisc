# Milestone M3 (Part 1): Service Files & Internal Imports Analysis Report

**Date**: 2026-09-28  
**Author**: `explorer_m3_1` (Teamwork Explorer)  
**Scope**: 7 Data Services relocation from `lib/services/` to `lib/data/services/`, internal import mapping, retention of infrastructure services, and layered architecture integrity.

---

## 1. Executive Summary

- **Current `lib/services/` content**: Exactly 9 files.
- **Relocation target**: 7 data services moved to `lib/data/services/`:
  1. `media_library_service.dart`
  2. `scene_service.dart`
  3. `settings_service.dart`
  4. `theme_service.dart`
  5. `scene_repository_network_service.dart`
  6. `media_package_service.dart`
  7. `scene_package_service.dart`
- **Infrastructure retention**: Exactly 2 files remain in `lib/services/`:
  1. `logger_service.dart` (system logging engine with `HH:mm:ss.SSS` CLI output)
  2. `shortcut_service.dart` (global hotkeys and keyboard event dispatcher)
- **Path delta**: Depth increases from 2 (`lib/services/`) to 3 (`lib/data/services/`).
  - References to `lib/domain/models/`: `../domain/models/` -> `../../domain/models/`
  - References to `lib/audio/`: `../audio/` -> `../../audio/`
  - References to `lib/data/repositories/`: `../data/repositories/` -> `../repositories/`
  - References to `lib/services/logger_service.dart`: `'logger_service.dart'` -> `'../../services/logger_service.dart'`
  - References to sibling data services (`database_service.dart`, `media_library_service.dart`): now co-located directly in `lib/data/services/` (e.g. `'database_service.dart'`).

---

## 2. Directory Layout Verification

### 2.1 Current `lib/services/` (9 files)
| # | File Name | Size (Bytes) | Nature / Layer | Action in M3 |
|---|-----------|--------------|----------------|--------------|
| 1 | `logger_service.dart` | 1,900 | Infrastructure | **Retain** in `lib/services/` |
| 2 | `shortcut_service.dart` | 12,008 | Infrastructure | **Retain** in `lib/services/` |
| 3 | `media_library_service.dart` | 5,865 | Data Service | **Relocate** to `lib/data/services/` |
| 4 | `scene_service.dart` | 8,010 | Data Service | **Relocate** to `lib/data/services/` |
| 5 | `settings_service.dart` | 4,675 | Data Service | **Relocate** to `lib/data/services/` |
| 6 | `theme_service.dart` | 4,248 | Data Service | **Relocate** to `lib/data/services/` |
| 7 | `scene_repository_network_service.dart` | 5,916 | Data Service | **Relocate** to `lib/data/services/` |
| 8 | `media_package_service.dart` | 7,589 | Data Service | **Relocate** to `lib/data/services/` |
| 9 | `scene_package_service.dart` | 19,806 | Data Service | **Relocate** to `lib/data/services/` |

### 2.2 Post-Relocation Target State
- `lib/services/` will contain **exactly 2 files**:
  - `logger_service.dart`
  - `shortcut_service.dart`
- `lib/data/services/` will contain **8 files**:
  - `database_service.dart` (pre-existing)
  - `media_library_service.dart`
  - `media_package_service.dart`
  - `scene_package_service.dart`
  - `scene_repository_network_service.dart`
  - `scene_service.dart`
  - `settings_service.dart`
  - `theme_service.dart`

---

## 3. Detailed Internal Import Adjustments for the 7 Services

### 3.1 `media_library_service.dart`
- **Source**: `lib/services/media_library_service.dart`
- **Destination**: `lib/data/services/media_library_service.dart`

#### Lines 1–10 (Imports):
```dart
// BEFORE (in lib/services/media_library_service.dart):
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../data/repositories/media_library_repository.dart';
import '../domain/models/library_track.dart';
import '../domain/models/audio_track.dart';
import '../domain/models/ambient_layer.dart';
import '../domain/models/sfx_trigger.dart';
import '../audio/audio_engine_service.dart';

// AFTER (in lib/data/services/media_library_service.dart):
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../repositories/media_library_repository.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/ambient_layer.dart';
import '../../domain/models/sfx_trigger.dart';
import '../../audio/audio_engine_service.dart';
```

#### Line Change Breakdown:
| Original Line | Original Import | New Import in `lib/data/services/` | Rationale |
|---------------|-----------------|-----------------------------------|-----------|
| 1–4 | `package:*` imports | Unchanged | Package imports are absolute |
| 5 | `import '../data/repositories/media_library_repository.dart';` | `import '../repositories/media_library_repository.dart';` | Sibling `repositories/` within `lib/data/` |
| 6 | `import '../domain/models/library_track.dart';` | `import '../../domain/models/library_track.dart';` | Requires 2 parent hops (`../../`) from `lib/data/services/` to `lib/` |
| 7 | `import '../domain/models/audio_track.dart';` | `import '../../domain/models/audio_track.dart';` | 2 parent hops (`../../`) |
| 8 | `import '../domain/models/ambient_layer.dart';` | `import '../../domain/models/ambient_layer.dart';` | 2 parent hops (`../../`) |
| 9 | `import '../domain/models/sfx_trigger.dart';` | `import '../../domain/models/sfx_trigger.dart';` | 2 parent hops (`../../`) |
| 10 | `import '../audio/audio_engine_service.dart';` | `import '../../audio/audio_engine_service.dart';` | 2 parent hops (`../../`) to `lib/audio/` |

---

### 3.2 `scene_service.dart`
- **Source**: `lib/services/scene_service.dart`
- **Destination**: `lib/data/services/scene_service.dart`

#### Lines 1–10 (Imports):
```dart
// BEFORE (in lib/services/scene_service.dart):
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/repositories/scene_repository.dart';
import '../domain/models/scene_model.dart';
import '../domain/models/audio_track.dart';
import '../domain/models/ambient_layer.dart';
import '../domain/models/sfx_trigger.dart';
import '../audio/audio_engine_service.dart';
import 'media_library_service.dart';
import 'logger_service.dart';

// AFTER (in lib/data/services/scene_service.dart):
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../repositories/scene_repository.dart';
import '../../domain/models/scene_model.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/ambient_layer.dart';
import '../../domain/models/sfx_trigger.dart';
import '../../audio/audio_engine_service.dart';
import 'media_library_service.dart';
import '../../services/logger_service.dart';
```

#### Line Change Breakdown:
| Original Line | Original Import | New Import in `lib/data/services/` | Rationale |
|---------------|-----------------|-----------------------------------|-----------|
| 1–2 | `package:*` imports | Unchanged | Package imports are absolute |
| 3 | `import '../data/repositories/scene_repository.dart';` | `import '../repositories/scene_repository.dart';` | Sibling `repositories/` within `lib/data/` |
| 4 | `import '../domain/models/scene_model.dart';` | `import '../../domain/models/scene_model.dart';` | 2 parent hops (`../../`) to `lib/domain/models/` |
| 5 | `import '../domain/models/audio_track.dart';` | `import '../../domain/models/audio_track.dart';` | 2 parent hops (`../../`) to `lib/domain/models/` |
| 6 | `import '../domain/models/ambient_layer.dart';` | `import '../../domain/models/ambient_layer.dart';` | 2 parent hops (`../../`) to `lib/domain/models/` |
| 7 | `import '../domain/models/sfx_trigger.dart';` | `import '../../domain/models/sfx_trigger.dart';` | 2 parent hops (`../../`) to `lib/domain/models/` |
| 8 | `import '../audio/audio_engine_service.dart';` | `import '../../audio/audio_engine_service.dart';` | 2 parent hops (`../../`) to `lib/audio/` |
| 9 | `import 'media_library_service.dart';` | `import 'media_library_service.dart';` | **Unchanged**: Both services relocated to `lib/data/services/` as siblings |
| 10 | `import 'logger_service.dart';` | `import '../../services/logger_service.dart';` | `logger_service.dart` remains in `lib/services/`; requires `../../services/` |

---

### 3.3 `settings_service.dart`
- **Source**: `lib/services/settings_service.dart`
- **Destination**: `lib/data/services/settings_service.dart`

#### Lines 1–2 (Imports):
```dart
// BEFORE (in lib/services/settings_service.dart):
import 'package:flutter/material.dart';
import 'logger_service.dart';

// AFTER (in lib/data/services/settings_service.dart):
import 'package:flutter/material.dart';
import '../../services/logger_service.dart';
```

#### Line Change Breakdown:
| Original Line | Original Import | New Import in `lib/data/services/` | Rationale |
|---------------|-----------------|-----------------------------------|-----------|
| 1 | `import 'package:flutter/material.dart';` | Unchanged | Package import |
| 2 | `import 'logger_service.dart';` | `import '../../services/logger_service.dart';` | `logger_service.dart` remains in `lib/services/` |

---

### 3.4 `theme_service.dart`
- **Source**: `lib/services/theme_service.dart`
- **Destination**: `lib/data/services/theme_service.dart`

#### Lines 1–7 (Imports):
```dart
// BEFORE (in lib/services/theme_service.dart):
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/repositories/custom_theme_repository.dart';
import '../domain/models/custom_theme_model.dart';
import '../theme/app_themes.dart';
import '../data/services/database_service.dart';
import 'logger_service.dart';

// AFTER (in lib/data/services/theme_service.dart):
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../repositories/custom_theme_repository.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../theme/app_themes.dart';
import 'database_service.dart';
import '../../services/logger_service.dart';
```

#### Line Change Breakdown:
| Original Line | Original Import | New Import in `lib/data/services/` | Rationale |
|---------------|-----------------|-----------------------------------|-----------|
| 1–2 | `package:*` imports | Unchanged | Package imports |
| 3 | `import '../data/repositories/custom_theme_repository.dart';` | `import '../repositories/custom_theme_repository.dart';` | Sibling `repositories/` within `lib/data/` |
| 4 | `import '../domain/models/custom_theme_model.dart';` | `import '../../domain/models/custom_theme_model.dart';` | 2 parent hops (`../../`) to `lib/domain/models/` |
| 5 | `import '../theme/app_themes.dart';` | `import '../../theme/app_themes.dart';` | 2 parent hops (`../../`) to `lib/theme/` |
| 6 | `import '../data/services/database_service.dart';` | `import 'database_service.dart';` | Co-located in same folder `lib/data/services/` |
| 7 | `import 'logger_service.dart';` | `import '../../services/logger_service.dart';` | `logger_service.dart` remains in `lib/services/` |

---

### 3.5 `scene_repository_network_service.dart`
- **Source**: `lib/services/scene_repository_network_service.dart`
- **Destination**: `lib/data/services/scene_repository_network_service.dart`

#### Lines 1–4 (Imports):
```dart
// BEFORE (in lib/services/scene_repository_network_service.dart):
import 'dart:convert';
import 'dart:io';
import 'logger_service.dart';
import '../domain/models/scene_repository_model.dart';

// AFTER (in lib/data/services/scene_repository_network_service.dart):
import 'dart:convert';
import 'dart:io';
import '../../services/logger_service.dart';
import '../../domain/models/scene_repository_model.dart';
```

#### Line Change Breakdown:
| Original Line | Original Import | New Import in `lib/data/services/` | Rationale |
|---------------|-----------------|-----------------------------------|-----------|
| 1–2 | `dart:convert`, `dart:io` | Unchanged | SDK libraries |
| 3 | `import 'logger_service.dart';` | `import '../../services/logger_service.dart';` | `logger_service.dart` remains in `lib/services/` |
| 4 | `import '../domain/models/scene_repository_model.dart';` | `import '../../domain/models/scene_repository_model.dart';` | 2 parent hops (`../../`) to `lib/domain/models/` |

---

### 3.6 `media_package_service.dart`
- **Source**: `lib/services/media_package_service.dart`
- **Destination**: `lib/data/services/media_package_service.dart`

#### Lines 1–9 (Imports):
```dart
// BEFORE (in lib/services/media_package_service.dart):
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../data/repositories/media_library_repository.dart';
import '../data/services/database_service.dart';
import '../domain/models/library_track.dart';
import 'logger_service.dart';

// AFTER (in lib/data/services/media_package_service.dart):
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../repositories/media_library_repository.dart';
import 'database_service.dart';
import '../../domain/models/library_track.dart';
import '../../services/logger_service.dart';
```

#### Line Change Breakdown:
| Original Line | Original Import | New Import in `lib/data/services/` | Rationale |
|---------------|-----------------|-----------------------------------|-----------|
| 1–4 | `dart:*`, `package:*` imports | Unchanged | Absolute imports |
| 6 | `import '../data/repositories/media_library_repository.dart';` | `import '../repositories/media_library_repository.dart';` | Sibling `repositories/` within `lib/data/` |
| 7 | `import '../data/services/database_service.dart';` | `import 'database_service.dart';` | Co-located in same folder `lib/data/services/` |
| 8 | `import '../domain/models/library_track.dart';` | `import '../../domain/models/library_track.dart';` | 2 parent hops (`../../`) to `lib/domain/models/` |
| 9 | `import 'logger_service.dart';` | `import '../../services/logger_service.dart';` | `logger_service.dart` remains in `lib/services/` |

---

### 3.7 `scene_package_service.dart`
- **Source**: `lib/services/scene_package_service.dart`
- **Destination**: `lib/data/services/scene_package_service.dart`

#### Lines 1–10 (Imports):
```dart
// BEFORE (in lib/services/scene_package_service.dart):
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../data/repositories/media_library_repository.dart';
import '../data/repositories/scene_repository.dart';
import '../data/services/database_service.dart';
import '../domain/models/library_track.dart';
import '../domain/models/scene_model.dart';
import 'logger_service.dart';

// AFTER (in lib/data/services/scene_package_service.dart):
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../repositories/media_library_repository.dart';
import '../repositories/scene_repository.dart';
import 'database_service.dart';
import '../../domain/models/library_track.dart';
import '../../domain/models/scene_model.dart';
import '../../services/logger_service.dart';
```

#### Line Change Breakdown:
| Original Line | Original Import | New Import in `lib/data/services/` | Rationale |
|---------------|-----------------|-----------------------------------|-----------|
| 1–4 | `dart:*`, `package:*` imports | Unchanged | Absolute imports |
| 5 | `import '../data/repositories/media_library_repository.dart';` | `import '../repositories/media_library_repository.dart';` | Sibling `repositories/` within `lib/data/` |
| 6 | `import '../data/repositories/scene_repository.dart';` | `import '../repositories/scene_repository.dart';` | Sibling `repositories/` within `lib/data/` |
| 7 | `import '../data/services/database_service.dart';` | `import 'database_service.dart';` | Co-located in same folder `lib/data/services/` |
| 8 | `import '../domain/models/library_track.dart';` | `import '../../domain/models/library_track.dart';` | 2 parent hops (`../../`) to `lib/domain/models/` |
| 9 | `import '../domain/models/scene_model.dart';` | `import '../../domain/models/scene_model.dart';` | 2 parent hops (`../../`) to `lib/domain/models/` |
| 10 | `import 'logger_service.dart';` | `import '../../services/logger_service.dart';` | `logger_service.dart` remains in `lib/services/` |

---

## 4. Retained Infrastructure Services Inspection

### 4.1 `logger_service.dart` (`lib/services/logger_service.dart`)
- **Imports**:
  ```dart
  import 'dart:io';
  import 'package:flutter/foundation.dart';
  ```
- **Dependencies**: None on project files.
- **Relocation needed?**: No, remains in `lib/services/logger_service.dart`.
- **Status**: Stable, zero internal import changes needed.

### 4.2 `shortcut_service.dart` (`lib/services/shortcut_service.dart`)
- **Imports**:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import '../audio/audio_engine_service.dart';
  import '../domain/models/audio_track.dart';
  import 'logger_service.dart';
  ```
- **Dependencies**:
  - `../audio/audio_engine_service.dart` (correct relative path from `lib/services/`)
  - `../domain/models/audio_track.dart` (correct relative path from `lib/services/`)
  - `logger_service.dart` (co-located sibling in `lib/services/`)
- **Dependencies on any of the 7 relocated services?**: **None**.
- **Relocation needed?**: No, remains in `lib/services/shortcut_service.dart`.
- **Status**: Stable, zero internal import changes needed.

---

## 5. Architectural & Dependency Integrity Check

1. **Acyclicity**:
   - `lib/services/logger_service.dart` has zero internal imports.
   - `lib/services/shortcut_service.dart` depends only on `AudioEngineService`, `AudioTrack`, and `LoggerService`.
   - None of the services in `lib/data/services/` depend on `ShortcutService`.
   - Data services depend on `LoggerService` via `../../services/logger_service.dart`, which is unidirectional from data layer to infrastructure.
   - Sibling dependencies within `lib/data/services/`:
     - `theme_service.dart` -> `database_service.dart`
     - `media_package_service.dart` -> `database_service.dart`
     - `scene_package_service.dart` -> `database_service.dart`
     - `scene_service.dart` -> `media_library_service.dart`
   - None of these siblings import in the reverse direction:
     - `database_service.dart` does not import `theme_service.dart`, `media_package_service.dart`, or `scene_package_service.dart`.
     - `media_library_service.dart` does not import `scene_service.dart`.
   - Result: **Strictly directed acyclic graph (DAG)**.

2. **Clean Layer Separation**:
   - Presentation (`lib/ui/`) consumes Data Services (`lib/data/services/`), Infrastructure Services (`lib/services/`), and Audio Engine (`lib/audio/`).
   - Data Services (`lib/data/services/`) consume Repositories (`lib/data/repositories/`), Models (`lib/domain/models/`), and Infrastructure (`lib/services/`).
   - Repositories (`lib/data/repositories/`) consume `DatabaseService` (`lib/data/services/database_service.dart`) and Domain Models.
   - Presentation layer is never imported by Data Services or Repositories.

---

## 6. Execution Plan for the Implementer

When the implementation agent carries out Milestone M3:
1. **Move files**:
   Transfer the 7 `.dart` files from `lib/services/` to `lib/data/services/`.
2. **Apply internal import changes**:
   Update the imports in the 7 newly moved files according to the tables above.
3. **Verify `lib/services/` directory**:
   Ensure only `logger_service.dart` and `shortcut_service.dart` remain in `lib/services/`.
4. **Update consumers (external imports)**:
   Update all import references in `lib/` and `test/` (e.g., `import 'services/media_library_service.dart';` -> `import 'data/services/media_library_service.dart';` or `package:ttrpg_audio_player/data/services/...`).
5. **Run test suite and static analysis**:
   Execute `flutter analyze` and `flutter test` to ensure zero compilation or runtime regressions.
