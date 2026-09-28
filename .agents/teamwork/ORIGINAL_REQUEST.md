# Original User Request

## 2026-09-28T08:42:26Z

Execute full codebase refactoring and bug fixing for the TTRPG Audio Master Flutter project across 4 distinct stages.

Working directory: c:\Users\nikit\Documents\antigravity\charming-heisenberg
Integrity mode: development

## Requirements

### R1. Static Analysis & Linter Cleanliness
Eliminate all 16 `flutter analyze` warnings and infos (unused imports, unused local variables, deprecated `.withOpacity` replaced with `.withValues(alpha: ...)`, unnecessary string interpolation braces, and missing const constructors). `flutter analyze` must report 0 issues.

### R2. Legacy Export Proxies Cleanup
Remove all legacy proxy files (`lib/models/*.dart`, `lib/db/database_service.dart`). Update all import references across `lib/` and `test/` to direct paths under `lib/domain/models/` and `lib/data/services/`.

### R3. Layered Architecture Alignment
Consolidate data services (`media_library_service.dart`, `scene_service.dart`, `settings_service.dart`, `theme_service.dart`, `scene_repository_network_service.dart`, `media_package_service.dart`, `scene_package_service.dart`) into `lib/data/services/`, while preserving system-level infrastructure services (`logger_service.dart`, `shortcut_service.dart`) in `lib/services/`. Update all references and tests accordingly.

### R4. Bug Fixes & Localization Polish
- **Theme Persistence**: Ensure active theme selection (`activeThemeId`) is saved to persistent storage (settings/database) and reloaded automatically upon application start.
- **Localization Alignment**: Audit all UI screens, widgets, and dialogs for hardcoded strings. Add missing keys to `lib/l10n/app_ru.arb` and `lib/l10n/app_en.arb`, regenerate localization classes via `flutter gen-l10n`, and replace hardcoded literals with `AppLocalizations.of(context)`.

### R5. Project Rules & Test Integrity
Strictly adhere to:
- `flutter-desktop-audio.md`: Direct terminal logging via `stdout`/`stderr` with millisecond timestamps (`HH:mm:ss.SSS`), non-blocking asynchronous audio calls, `File(filePath).existsSync()` validation before playback, and complete ChangeNotifier proxying/reactivity.
- `test-specifications.md`: Three-part test specification standard ("Что проверяем", "Входные данные", "Ожидаемый результат") in all new and existing tests.

## Acceptance Criteria

### Static Analysis
- [ ] `flutter analyze` completes with 0 warnings, 0 errors, and 0 infos (`No issues found!`).

### Automated Testing
- [ ] `flutter test` executes all tests successfully with 0 failures (145+ tests passing).
- [ ] Unit and widget tests cover theme persistence across app restarts and complete localization coverage adhering to the three-part test specification standard.

### Clean Codebase
- [ ] `lib/models/` and `lib/db/` directories are removed, with no dangling imports.
- [ ] Data services are located in `lib/data/services/`.

### Functional Verification
- [ ] Selected theme persists across restarts.
- [ ] Language switching dynamically updates all UI components cleanly.
