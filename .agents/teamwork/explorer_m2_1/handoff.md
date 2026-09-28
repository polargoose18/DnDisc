# Handoff Report: Legacy Export Proxies Cleanup — Part 1 (Domain Models)

**Agent:** explorer_m2_1  
**Milestone:** M2 (Legacy Export Proxies Cleanup - Part 1: Domain Models)  
**Status:** Complete (Hard Handoff)  
**Artifact:** `c:\Users\nikit\Documents\antigravity\charming-heisenberg\.agents\teamwork\explorer_m2_1\analysis.md`  

---

## 1. Observation

1. **Content of `lib/models/`**:
   The directory contains exactly 6 proxy files forwarding to `../domain/models/`:
   - `lib/models/ambient_layer.dart:1`: `export '../domain/models/ambient_layer.dart';`
   - `lib/models/audio_track.dart:1`: `export '../domain/models/audio_track.dart';`
   - `lib/models/custom_theme_model.dart:1`: `export '../domain/models/custom_theme_model.dart';`
   - `lib/models/library_track.dart:1`: `export '../domain/models/library_track.dart';`
   - `lib/models/scene_model.dart:1`: `export '../domain/models/scene_model.dart';`
   - `lib/models/sfx_trigger.dart:1`: `export '../domain/models/sfx_trigger.dart';`

2. **Tooling & Gitignore Impact**:
   - `c:\Users\nikit\Documents\antigravity\charming-heisenberg\.gitignore` line 51 contains unanchored `audio/`.
   - As a consequence, default file search tools respecting gitignore (e.g., standard `rg` or `fd`) skip `test/audio/` and `lib/audio/`.
   - Execution of `git grep -n -E "(import|export).*models/"` and targeted filesystem checks exhaustively verified all files across the repository.

3. **Consumers in `lib/`**:
   - All files under `lib/audio/`, `lib/data/`, `lib/services/`, `lib/theme/`, and `lib/ui/` import canonical models directly from `../domain/models/` or `../../domain/models/`.
   - Exactly **0** files in `lib/` import from `lib/models/`.

4. **Consumers in `test/`**:
   - `test/models/`, `test/data/`, `test/db/`, `test/services/`, `test/ui/`: all 21 test files already import from `package:ttrpg_audio_player/domain/models/...`.
   - `test/m1_empirical_verification_test.dart` and `test/widget_test.dart`: do not import domain models.
   - Only 2 test files import from `package:ttrpg_audio_player/models/...`, accounting for exactly **5** imports:
     - `test/audio/audio_controllers_test.dart:7`: `import 'package:ttrpg_audio_player/models/audio_track.dart';`
     - `test/audio/audio_controllers_test.dart:8`: `import 'package:ttrpg_audio_player/models/ambient_layer.dart';`
     - `test/audio/audio_controllers_test.dart:9`: `import 'package:ttrpg_audio_player/models/sfx_trigger.dart';`
     - `test/audio/fade_and_ducking_test.dart:6`: `import 'package:ttrpg_audio_player/models/audio_track.dart';`
     - `test/audio/fade_and_ducking_test.dart:7`: `import 'package:ttrpg_audio_player/models/ambient_layer.dart';`

5. **Current Test Status**:
   - Running `flutter test test/audio/audio_controllers_test.dart test/audio/fade_and_ducking_test.dart` passes completely: 32 tests passed (exit code 0).

---

## 2. Logic Chain

1. **Step 1 (Observation 1)**: `lib/models/` serves purely as an export proxy facade for `lib/domain/models/` and contains no distinct business logic or declarations.
2. **Step 2 (Observations 3 & 4)**: Across the entire codebase, only 5 import statements in 2 test files (`test/audio/audio_controllers_test.dart` and `test/audio/fade_and_ducking_test.dart`) reference `package:ttrpg_audio_player/models/...`.
3. **Step 3 (Observations 1 & 4)**: The required classes (`AudioTrack`, `AmbientLayer`, `SfxTrigger`, and `MusicIntensity`) are defined and exported identically in `package:ttrpg_audio_player/domain/models/...`.
4. **Step 4 (Step 2 + Step 3)**: Redirecting those 5 imports to `package:ttrpg_audio_player/domain/models/...` preserves identical semantic resolution with zero syntax or type mismatches.
5. **Step 5 (Step 1 + Step 4)**: Once those 5 imports are updated, zero files in the repository will reference `lib/models/`.
6. **Step 6 (Step 5)**: The 6 proxy files and the `lib/models/` folder can be deleted with 100% guarantee of zero dangling references and zero broken dependencies.

---

## 3. Caveats

1. **Scope Boundary**: This investigation covers Milestone M2 Part 1 (`lib/models/`). Part 2 (`lib/db/database_service.dart`) is a separate proxy removal task.
2. **Gitignore Awareness**: Because `.gitignore` line 51 contains `audio/`, any future search or grep commands must either target `test/audio/` directly or use `git grep` / `--no-ignore` flags to avoid false negatives.
3. No other caveats.

---

## 4. Conclusion

1. Update the 3 imports in `test/audio/audio_controllers_test.dart` (lines 7–9) to `package:ttrpg_audio_player/domain/models/...`.
2. Update the 2 imports in `test/audio/fade_and_ducking_test.dart` (lines 6–7) to `package:ttrpg_audio_player/domain/models/...`.
3. Delete all 6 files in `lib/models/` (`ambient_layer.dart`, `audio_track.dart`, `custom_theme_model.dart`, `library_track.dart`, `scene_model.dart`, `sfx_trigger.dart`) and the `lib/models/` directory.
4. The exact unified diffs are ready and documented in `analysis.md` for immediate application by the worker agent.

---

## 5. Verification Method

### Independent Verification Commands

1. **Dangling Import Search**:
   Run in PowerShell from repository root:
   ```pwsh
   git grep "models/" | Select-String -NotMatch "domain/models", "view_models", "test/models"
   ```
   **Expected**: No output (0 lines returned).

2. **Static Analysis**:
   ```pwsh
   flutter analyze
   ```
   **Expected**: `No issues found!`.

3. **Audio Controller Tests**:
   ```pwsh
   flutter test test/audio/audio_controllers_test.dart test/audio/fade_and_ducking_test.dart
   ```
   **Expected**: All 32 tests pass.

4. **Complete Test Suite**:
   ```pwsh
   flutter test
   ```
   **Expected**: All 145+ tests pass with 0 failures.

### Invalidation Conditions
- Any file failing to resolve `AudioTrack`, `AmbientLayer`, or `SfxTrigger`.
- Any remaining import path containing `package:ttrpg_audio_player/models/` or relative path into `lib/models/`.
