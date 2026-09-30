# Custom Repository Guide for DnDisc

**DnDisc** supports connecting external remote repositories of scenes, media sets, and adventure packs (hosted on GitLab, Dropbox, CDN, Amazon S3, or standard web servers).

This allows Game Masters (GMs) in tabletop RPGs to share curated atmospheric scenes, sound effects, and music with their gaming group or maintain a personal collection in the cloud.

---

## 📑 Table of Contents
1. [Content Categories: Scenes, Media, Packs](#1-content-categories-scenes-media-packs)
2. [Supported Services and URLs](#2-supported-services-and-urls)
3. [Quick Workflow: Graphical Export from the App](#3-quick-workflow-graphical-export-from-the-app)
4. [Automated Build via `generate_repository_manifest.py`](#4-automated-build-via-generate_repository_manifestpy)
5. [Specification for `repository.json` (v2) for Manual Assembly](#5-specification-for-repositoryjson-v2-for-manual-assembly)
6. [Download Archive Structures (`.scene.zip`, `.media.zip`, `.pack.zip`)](#6-download-archive-structures)
7. [Step-by-Step Repository Setup on GitLab](#7-step-by-step-repository-setup-on-gitlab)

---

## 1. Content Categories: Scenes, Media, Packs

In **DnDisc**, the catalog supports 3 fundamental content categories:

* 🎭 **Scenes (`scenes`)**: Standalone scenes with focused sets of music, ambient layers, and soundboard triggers (`.scene.zip`).
* 🎵 **Media Sets (`media`)**: Standalone collections of music tracks, ambient loops, or SFX soundboard triggers (`.media.zip`) imported directly into the global library.
* 📦 **Scene Packs (`packs`)**: Comprehensive packages combining multiple scenes and all their associated audio files (`.pack.zip`).

---

## 2. Supported Services and URLs

The app natively handles the following URL formats:

* **GitLab Repository**: Paste a standard GitLab repository URL (e.g., `https://gitlab.com/username/my-dnd-scenes`). The app automatically transforms it to direct manifest access (`gitlab.com/.../-/raw/main/repository.json`).
* **Dropbox**: Public Dropbox sharing links are supported (automatically converted to direct streaming download via `dl=1`).
* **Direct Manifest URL**: Direct link to a `repository.json` file on any HTTPS/HTTP web server or self-hosted GitLab instance.

---

## 3. Quick Workflow: Graphical Export from the App

You **do not need to write JSON files manually**. You can create content archives directly within the app UI:

1. **Export Scene**: Open the scene card menu `...` ➔ **"Export (.scene.zip)"**.
2. **Export Media Set**: On the Media Library screen, select tracks and click **"Export Media Package (.media.zip)"**.
3. **Export Scene Pack**: On the scenes panel, select multiple scenes and click **"Export Scene Pack (.pack.zip)"**.

Generated zip files already contain internal manifests (`scene.json`, `media.json`, `pack.json`).

---

## 4. Automated Build via `generate_repository_manifest.py`

To compile the final `repository.json` manifest, use the `generate_repository_manifest.py` script:

```text
my-dnd-audio-repo/
├── generate_repository_manifest.py
├── scenes/       # *.scene.zip
├── media/        # *.media.zip
├── packs/        # *.pack.zip
└── covers/       # Cover images *.jpg
```

Running `python generate_repository_manifest.py` scans archives, inspects internal manifests, and generates `repository.json` in seconds.

---

## 5. Specification for `repository.json` (v2) for Manual Assembly

The `repository.json` file must reside at the root of the repository and be encoded in **UTF-8**.

### 📋 Complete `repository.json` Example

```json
{
  "name": "D&D Fantasy Audio Treasury",
  "description": "Collection of scenes, media sets, and adventure packs",
  "version": "2.0.0",
  "author": "GameMaster3000",
  "scenes": [
    {
      "id": "scene_dragon_lair",
      "name": "Dragon's Lair",
      "description": "Cave echoing with the roar of a red dragon",
      "download_url": "scenes/dragon_lair.scene.zip",
      "cover_url": "covers/scene_dragon_lair.jpg",
      "color_hex": "0xFF673AB7",
      "tracks_count": 3,
      "size_bytes": 15420000,
      "tracks": [
        { "title": "Red Dragon Battle Theme", "bus_type": "music", "duration_ms": 180000 },
        { "title": "Cave Fire Ambience", "bus_type": "ambient", "duration_ms": 240000 },
        { "title": "Dragon Roar", "bus_type": "sfx", "duration_ms": 4500 }
      ]
    }
  ],
  "media": [
    {
      "id": "media_monsters_sfx",
      "name": "Monster Roars SFX Set",
      "description": "15 one-shot sound effects for the soundboard",
      "download_url": "media/monsters_sfx.media.zip",
      "cover_url": "covers/media_monsters_sfx.jpg",
      "color_hex": "0xFFFF9800",
      "tracks_count": 15,
      "size_bytes": 8400000,
      "tracks": [
        { "title": "Goblin Screech", "bus_type": "sfx", "duration_ms": 2300 }
      ]
    }
  ],
  "packs": [
    {
      "id": "pack_curse_of_strahd",
      "name": "Adventure Pack: Curse of Strahd",
      "description": "Campaign bundle with 8 scenes",
      "download_url": "packs/curse_of_strahd.pack.zip",
      "cover_url": "covers/pack_curse_of_strahd.jpg",
      "color_hex": "0xFFD32F2F",
      "scenes_count": 8,
      "tracks_count": 32,
      "size_bytes": 145000000,
      "scenes": [
        { "name": "Castle Ravenloft" },
        { "name": "Village of Barovia" }
      ]
    }
  ]
}
```

---

### 📐 Schema & Field Specifications

#### Table 5.1. Root Object `repository.json`

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `string` | **Yes** | `"Untitled Repository"` | Display name of repository |
| `description` | `string` | No | `""` | Detailed description of repository |
| `version` | `string` | No | `"1.0"` | Pack version string (e.g. `"2.0.0"`) |
| `author` | `string` | No | `""` | Name or nickname of author |
| `scenes` | `array` | No | `[]` | Array of scene category items |
| `media` | `array` | No | `[]` | Array of media category items |
| `packs` | `array` | No | `[]` | Array of pack category items |

---

#### Table 5.2. Item Object in `scenes`

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `string` | **Yes** | Unique scene ID (UUID or unique string) |
| `name` | `string` | **Yes** | Scene name |
| `description` | `string` | No | Scene description |
| `download_url` / `downloadUrl` | `string` | **Yes** | Link to `.scene.zip` (relative path `scenes/name.scene.zip` or full `https://...`) |
| `cover_url` / `coverUrl` | `string` | No | Link to cover image (`covers/name.jpg` or `https://...`) |
| `color_hex` / `colorHex` | `string` / `int` | No | Card color: `"0xFF673AB7"`, `"#673AB7"`, or integer `4285040567` |
| `tracks_count` | `int` | No | Number of audio tracks in scene |
| `size_bytes` | `int` | No | Size of `.scene.zip` in bytes |
| `tracks` | `array` | No | Array of track preview objects (see Table 5.5) |

---

#### Table 5.3. Item Object in `media`

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `string` | **Yes** | Unique media set ID |
| `name` | `string` | **Yes** | Name of track / effect set |
| `description` | `string` | No | Description of media set |
| `download_url` / `downloadUrl` | `string` | **Yes** | Link to `.media.zip` (e.g. `media/monsters.media.zip`) |
| `cover_url` / `coverUrl` | `string` | No | Link to set cover image |
| `color_hex` / `colorHex` | `string` / `int` | No | Card accent color (default orange) |
| `tracks_count` | `int` | No | Total tracks in media set |
| `size_bytes` | `int` | No | Size of `.media.zip` in bytes |
| `tracks` | `array` | No | Array of track preview objects (see Table 5.5) |

---

#### Table 5.4. Item Object in `packs`

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `string` | **Yes** | Unique scene pack ID |
| `name` | `string` | **Yes** | Adventure pack name |
| `description` | `string` | No | Adventure / campaign description |
| `download_url` / `downloadUrl` | `string` | **Yes** | Link to `.pack.zip` (e.g. `packs/strahd.pack.zip`) |
| `cover_url` / `coverUrl` | `string` | No | Link to pack cover image |
| `color_hex` / `colorHex` | `string` / `int` | No | Card accent color (default red) |
| `scenes_count` | `int` | No | Number of included scenes |
| `tracks_count` | `int` | No | Total tracks across all scenes |
| `size_bytes` | `int` | No | Size of `.pack.zip` in bytes |
| `scenes` | `array` | No | Preview list of scene names `[ { "name": "Scene Name" } ]` |
| `tracks` | `array` | No | Array of track preview objects (see Table 5.5) |

---

#### Table 5.5. Track Preview Object in `tracks`

| Field | Type | Required | Allowed Values | Description |
|---|---|---|---|---|
| `title` | `string` | **Yes** | Any string | Track title |
| `bus_type` | `string` | **Yes** | `"music"`, `"ambient"`, `"sfx"` | Target audio bus |
| `duration_ms` | `int` | No | Integer `>= 0` | Track duration in milliseconds |

---

## 6. Download Archive Structures

### A. Scene Archive (`.scene.zip`)
```text
dragon_lair.scene.zip
├── scene.json
├── audio/
└── images/
```

### B. Media Set Archive (`.media.zip`)
```text
monsters_sfx.media.zip
├── media.json
└── audio/
```

### C. Scene Pack Archive (`.pack.zip`)
```text
curse_of_strahd.pack.zip
├── pack.json
├── audio/
└── images/
```

---

## 7. Step-by-Step Repository Setup on GitLab

1. **Create a public GitLab repository**.
2. Copy `tools/generate_repository_manifest.py` to the repository root.
3. Place archive files into `scenes/`, `media/`, and `packs/` directories.
4. Run `python generate_repository_manifest.py`.
5. Run `git push` and paste the repository URL into **DnDisc**!
