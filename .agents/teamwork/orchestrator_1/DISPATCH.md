## 2026-09-28T08:43:02Z

You are the Project Orchestrator for the TTRPG Audio Master Flutter project refactoring.

Your working directory is:
c:\Users\nikit\Documents\antigravity\charming-heisenberg\.agents\teamwork\orchestrator_1

The project root is:
c:\Users\nikit\Documents\antigravity\charming-heisenberg

The original user request is documented in:
c:\Users\nikit\Documents\antigravity\charming-heisenberg\.agents\teamwork\ORIGINAL_REQUEST.md

Please read the original request thoroughly. You are responsible for decomposing, planning, dispatching, and verifying the work across all 4 stages:
- R1. Static Analysis & Linter Cleanliness: Eliminate all 16 `flutter analyze` issues (warnings and infos). Target: 0 issues.
- R2. Legacy Export Proxies Cleanup: Remove all legacy proxy files (`lib/models/*.dart`, `lib/db/database_service.dart`). Update all imports across `lib/` and `test/` to direct paths under `lib/domain/models/` and `lib/data/services/`.
- R3. Layered Architecture Alignment: Consolidate data services (`media_library_service.dart`, `scene_service.dart`, `settings_service.dart`, `theme_service.dart`, `scene_repository_network_service.dart`, `media_package_service.dart`, `scene_package_service.dart`) into `lib/data/services/`, while preserving system-level infrastructure services (`logger_service.dart`, `shortcut_service.dart`) in `lib/services/`. Update all references and tests.
- R4. Bug Fixes & Localization Polish:
  * Theme Persistence: Ensure active theme selection (`activeThemeId`) is saved to persistent storage (settings/database) and reloaded automatically upon application start.
  * Localization Alignment: Audit all UI screens, widgets, and dialogs for hardcoded strings. Add missing keys to `lib/l10n/app_ru.arb` and `lib/l10n/app_en.arb`, regenerate localization classes via `flutter gen-l10n`, and replace hardcoded literals with `AppLocalizations.of(context)`.
- R5. Project Rules & Test Integrity:
  * `flutter-desktop-audio.md`: Direct terminal logging via `stdout`/`stderr` with millisecond timestamps (`HH:mm:ss.SSS`), non-blocking asynchronous audio calls, `File(filePath).existsSync()` validation before playback, and complete ChangeNotifier proxying/reactivity.
  * `test-specifications.md`: Three-part test specification standard ("Что проверяем", "Входные данные", "Ожидаемый результат") in all new and existing tests.

Verification criteria:
- `flutter analyze` completes with 0 warnings, 0 errors, 0 infos.
- `flutter test` completes with 0 failures (145+ tests passing).
- Tests cover theme persistence across app restarts and complete localization coverage following the 3-part test specification standard.

Maintain your `BRIEFING.md` and `progress.md` in your working directory `c:\Users\nikit\Documents\antigravity\charming-heisenberg\.agents\teamwork\orchestrator_1\`.
When all stages are completely implemented, verified with tests and static analysis, report completion back to me.
