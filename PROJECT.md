# Project: TTRPG Audio Master Codebase Refactoring

## Architecture
TTRPG Audio Master is a desktop-first Flutter application structured around a layered architecture:
- **Presentation Layer** (`lib/ui/`):
  - Screens: `library_screen.dart`, `main_dashboard_screen.dart`, `repository_catalog_screen.dart`, `responsive_gm_dashboard.dart`, `settings_screen.dart`.
  - ViewModels: `media_library_view_model.dart`, `repository_view_model.dart`, `scene_view_model.dart`, `theme_view_model.dart`.
  - Widgets: `ambient_mixer_panel.dart`, `create_edit_scene_dialog.dart`, `custom_theme_editor_dialog.dart`, `import_track_dialog.dart`, `scene_repository_details_dialog.dart`, `scene_selector_panel.dart`, `soundboard_grid.dart`, `sticky_mini_player.dart`.
- **Domain Layer** (`lib/domain/`):
  - Models: `ambient_layer.dart`, `audio_track.dart`, `custom_theme_model.dart`, `library_track.dart`, `scene_model.dart`, `scene_repository_model.dart`, `sfx_trigger.dart`.
- **Data Layer** (`lib/data/`):
  - Repositories: `custom_theme_repository.dart`, `media_library_repository.dart`, `scene_repository.dart`.
  - Services: `database_service.dart`, and consolidated data services (`media_library_service.dart`, `scene_service.dart`, `settings_service.dart`, `theme_service.dart`, `scene_repository_network_service.dart`, `media_package_service.dart`, `scene_package_service.dart`).
- **Audio Engine Layer** (`lib/audio/`):
  - `audio_engine_service.dart`, `music_bus_controller.dart`, `ambient_bus_controller.dart`, `sfx_bus_controller.dart`.
- **Infrastructure Services** (`lib/services/`):
  - `logger_service.dart` (terminal logging with `HH:mm:ss.SSS` timestamps), `shortcut_service.dart` (keyboard shortcuts & window controls).
- **Localization** (`lib/l10n/`):
  - `app_ru.arb`, `app_en.arb`, generated `app_localizations.dart`.

## Code Layout
- `lib/domain/models/`: Canonical data models.
- `lib/data/services/`: All persistent storage, database, file packaging, and network services.
- `lib/data/repositories/`: Repository implementations mapping to SQLite database.
- `lib/services/`: System infrastructure services only (`logger_service.dart`, `shortcut_service.dart`).
- `lib/ui/`: UI presentation screens, widgets, dialogs, and ViewModels.
- `lib/l10n/`: ARB translation catalogs and generated localizations.
- `test/`: Automated test suite mirroring `lib/` layers.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Static Analysis Cleanliness | Eliminate all 16 `flutter analyze` issues (6 warnings, 10 infos) across 7 files | M1 | ORIGINAL_REQUEST §R1, Survey Explorer 1 |
| 2 | Legacy Models Proxy Removal | Delete 6 proxy files in `lib/models/` and redirect all imports to `lib/domain/models/` | M2 | ORIGINAL_REQUEST §R2, Survey Explorer 1 |
| 3 | Legacy Database Proxy Removal | Delete `lib/db/database_service.dart` and redirect 18 imports in `lib/` and `test/` to `lib/data/services/database_service.dart` | M2 | ORIGINAL_REQUEST §R2, Survey Explorer 1 |
| 4 | Data Services Relocation | Move 7 data services from `lib/services/` to `lib/data/services/` without circular dependencies | M3 | ORIGINAL_REQUEST §R3, Survey Explorer 2 |
| 5 | Infrastructure Services Retention | Retain `logger_service.dart` and `shortcut_service.dart` in `lib/services/` | M3 | ORIGINAL_REQUEST §R3, Survey Explorer 2 |
| 6 | Service Consumer Import Update | Update all imports across 13 `lib/` files and 17 `test/` files to new `lib/data/services/` paths | M3 | ORIGINAL_REQUEST §R3, Survey Explorer 2 |
| 7 | SQLite Settings Persistence Table | Add `app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)` table to `DatabaseService` | M4 | ORIGINAL_REQUEST §R4, Survey Explorer 3 |
| 8 | Active Theme Persistence | Add `getActiveThemeId()` / `setActiveThemeId()` in `CustomThemeRepository` and `ThemeService` | M4 | ORIGINAL_REQUEST §R4, Survey Explorer 3 |
| 9 | Startup Theme Restoration | Update `main.dart` to instantiate `ThemeService(autoLoad: true)` and reload active theme on launch | M4 | ORIGINAL_REQUEST §R4, Survey Explorer 3 |
| 10 | ARB Key Catalog Expansion | Add 60+ missing localized string keys to `lib/l10n/app_ru.arb` and `lib/l10n/app_en.arb` | M4 | ORIGINAL_REQUEST §R4, Survey Explorer 3 |
| 11 | Localization Generation Pipeline | Execute `flutter gen-l10n` to regenerate `AppLocalizations` | M4 | ORIGINAL_REQUEST §R4, Survey Explorer 3 |
| 12 | UI Hardcoded Literals Replacement | Replace all hardcoded Russian literals across screens, dialogs, widgets with `AppLocalizations.of(context)` | M4 | ORIGINAL_REQUEST §R4, Survey Explorer 3 |
| 13 | Desktop Audio Rules Compliance | Ensure direct CLI logging with `HH:mm:ss.SSS`, non-blocking audio, `existsSync` checks, and ChangeNotifier proxying | M5 | ORIGINAL_REQUEST §R5, Survey Explorer 3 |
| 14 | Test Specification Standards (AAA Pattern) | Ensure all tests adhere to AAA pattern ('should <result> when <condition>') in English | M5 | ORIGINAL_REQUEST §R5, Survey Explorer 3 |
| 15 | Theme Persistence Verification Tests | Add unit/widget tests for theme selection persistence across app restarts | M5 | ORIGINAL_REQUEST §Acceptance, Survey Explorer 3 |
| 16 | Complete Localization Verification Tests | Add unit/widget tests for dynamic language switching across UI components | M5 | ORIGINAL_REQUEST §Acceptance, Survey Explorer 3 |
| 17 | Final Project Verification | Full run of `flutter analyze` (0 issues) and `flutter test` (175+ tests passing, 0 failures) | M5 | ORIGINAL_REQUEST §Acceptance |
| 18 | UI/UX Layout & Ergonomics Overhaul | Modernize layout, color harmony, and visual ergonomics across GM Dashboard, mixer panels, and dialogs | M6 | ORIGINAL_ROADMAP §R6 |
| 19 | Responsive Component Polish | Refine track cards, sliders, soundboard triggers, and compact view adaptations | M6 | ORIGINAL_ROADMAP §R6 |
| 20 | UI Widget & Regression Test Suite | Maintain 100% test pass rate across redesigned UI components and dialogs | M6 | ORIGINAL_ROADMAP §R6 |
| 21 | Embedded HTTP & WebSocket Server | Lightweight local network server using `shelf` and WebSockets for wireless control | M7 | ORIGINAL_ROADMAP §R5, Survey Explorer |
| 22 | QR Code Pairing & Network Discovery | Local IP resolution and QR code generator for zero-configuration pairing with mobile devices | M7 | ORIGINAL_ROADMAP §R5 |
| 23 | Bi-directional Remote Control Protocol | Real-time state broadcasting (playback, scene, ducking) and incoming GM command handling | M7 | ORIGINAL_ROADMAP §R5 |
| 24 | Touch-friendly Mobile Web / Client Remote | Responsive web controller optimized for smartphones and tablets over Wi-Fi | M7 | ORIGINAL_ROADMAP §R5 |
| 25 | Google TV / Android TV Target & Engine | TV platform support, hardware audio output routing (HDMI ARC / optical), and leanback layout | M8 | ORIGINAL_ROADMAP §R5.5 |
| 26 | Spotify-style Fullscreen Atmosphere Visualizer | Immersive artwork display, dynamic mood lighting, scene title, and ambient layer indicators | M8 | ORIGINAL_ROADMAP §R5.5 |
| 27 | Slave Audio Receiver Mode | TV functions as a dedicated playback endpoint driven by remote GM controller | M8 | ORIGINAL_ROADMAP §R5.5 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Static Analysis Cleanliness | Fix all 16 analyzer warnings/infos across 7 files | none | DONE |
| M2 | Legacy Export Proxies Cleanup | Remove `lib/models/` and `lib/db/`, redirect all imports | M1 | DONE |
| M3 | Layered Architecture Alignment | Move 7 data services to `lib/data/services/`, update all imports | M2 | DONE |
| M4 | Theme Persistence & Localization Polish | SQLite app_settings, persist activeThemeId, add ARB keys, gen-l10n, update UI | M3 | DONE |
| M5 | Audio Rules & Comprehensive Acceptance | Add theme & l10n tests (3-part spec), verify audio rules, verify 0 issues & 175+ tests | M4 | DONE |
| M6 | UI/UX Overhaul & Polish | Redesign GM Dashboard, mixer panels, soundboard, and dialog ergonomics | M5 | PLANNED |
| M7 | Wi-Fi Remote Control Protocol | Embedded HTTP/WebSocket server, QR-code pairing, bi-directional control API & web remote | M6 | PLANNED |
| M8 | Android TV / Google TV Display & Receiver | TV target, Spotify-style atmosphere visualizer, slave audio playback over home theater | M7 | PLANNED |

## Interface Contracts
### SQLite Storage ↔ Repositories (`DatabaseService` ↔ `CustomThemeRepository`)
```dart
// DatabaseService:
// Table: app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)
Future<void> setSetting(String key, String value);
Future<String?> getSetting(String key);

// CustomThemeRepository:
Future<String?> getActiveThemeId();
Future<void> setActiveThemeId(String themeId);
```

### Repository ↔ Theme Service (`CustomThemeRepository` ↔ `ThemeService`)
```dart
// ThemeService:
ThemeService({CustomThemeRepository? repository, DatabaseService? dbService, bool autoLoad = false, String? initialThemeId});
Future<void> selectTheme(String themeId); // persists to repository if available
Future<void> loadSavedThemes(); // loads custom themes and restores activeThemeId
```

### Localization Contract
```dart
// All UI text displayed to the user must access:
AppLocalizations.of(context)!.someKey
// with entries present in both app_ru.arb and app_en.arb
```
