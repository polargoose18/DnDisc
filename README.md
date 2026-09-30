# DnDisc — TTRPG Audio Master

**DnDisc** is a modern cross-platform audio player, atmospheric sound mixer, and soundboard designed specifically for Game Masters / Dungeon Masters in tabletop role-playing games (D&D, Pathfinder, Warhammer Fantasy, Call of Cthulhu, etc.).

The application enables GMs to instantly set the right mood at the table: from a cozy tavern to an epic dragon battle or gloomy catacombs.

---

## 🚀 Key Features

### 🎧 Three-Layer Audio Engine
* **Music Channel (`Music`)**: Background music playback with smooth crossfading on track change.
* **Ambient Sound Channel (`Ambient`)**: Independent mixer for background layers (rain, wind, tavern noise, campfire) with individual volume sliders.
* **Sound Effects Channel (`SFX`)**: Instant one-shot soundboard triggers (monster roars, sword strikes, explosions, coin clinks) via an interactive grid.

### 🎭 Scenes, Media Sets & Packs (Isolated Export/Import)
* **1-Click Atmosphere Changes**: Save music, ambient volumes, and soundboard trigger configurations into Scenes.
* **Single Scene Export (`.scene.zip`)**: Export standalone scenes with all bundled audio files.
* **Media Set Export (`.media.zip`)**: Curated track and sound collections imported directly into the global library.
* **Adventure Scene Packs (`.pack.zip`)**: Multi-scene adventure packs bundling campaigns and modules.
* **Automatic Deduplication**: Imports content safely without duplicating existing audio files.

### 🌐 Repository Catalog (Jellyfin Style Catalog)
* **Catalog Categories**: Filter content using category chips: **`[All]`**, **`[🎭 Scenes]`**, **`[🎵 Media]`**, **`[📦 Packs]`**.
* **Metadata Preview (`repository.json v2`)**: Preview covers, descriptions, authors, and track listings **prior to downloading**.
* **GitLab & Dropbox URL Auto-Transformation**: Native support for connecting GitLab repositories and Dropbox manifest links.
* **Automated Manifest Generator**: Built-in [`tools/generate_repository_manifest.py`](tools/generate_repository_manifest.py) tool to index repository archives and output `repository.json` in seconds.

---

## 📖 Content Author Documentation

* 📄 **[Custom Repository Guide for DnDisc](docs/CUSTOM_REPOSITORY_GUIDE.md)** — Comprehensive specification for `repository.json v2`, download archive formats (`.scene.zip`, `.media.zip`, `.pack.zip`), and manifest generator usage.

---

## 🎛 Advanced Audio Capabilities

* **Auto-Ducking**: Automatically lowers background music volume when SFX triggers or speech occurs.
* **Fading & Crossfade**: Smooth transition curves for music tracks and ambient layers.
* **Panic Stop**: Instantly halt all active sound effects or the entire audio engine with a single hotkey [Esc].
* **Shortcuts & Hotkeys**: Customizable keyboard shortcuts for rapid game session control.
* **Custom Themes**: Built-in color theme editor.
* **Localization**: Full internationalization with English and Russian language support (i10n).

---

## 🛠 Technology Stack

* **Framework:** Flutter Desktop (Windows / Linux)
* **State Management:** `provider` (ChangeNotifier)
* **Audio Engine:** `audioplayers` and `flutter_soloud`
* **Database:** SQLite (`sqflite` / `sqflite_common_ffi`, DB schema v4)
* **Archive Handling:** `archive` (`.scene.zip`, `.media.zip`, `.pack.zip`)
* **Tooling:** Python 3 manifest generator script

---

## 🧪 Testing & Code Quality

The project features a comprehensive test suite (145+ tests):
* Unit tests for audio bus controllers, ducking/fading algorithms, and data models.
* Database migration tests for SQLite schema v4 and repository persistence layers.
* Network parser tests for repository manifest v2 and archive security checks (Zip Slip validation).
* Widget & UI integration tests for GM dashboard, media library, catalog, and settings.

Run the test suite:
```bash
flutter test
```

---

## 🏁 Getting Started

Ensure you have Flutter SDK (>=3.0.0) installed.

```bash
# 1. Install dependencies
flutter pub get

# 2. Run application on Windows
flutter run -d windows
```
