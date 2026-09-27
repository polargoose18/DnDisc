#!/usr/bin/env python3
"""
tools/generate_repository_manifest.py

Automatically scans repository directory structure for:
  - scenes/*.scene.zip
  - media/*.media.zip
  - packs/*.pack.zip
Inspects internal ZIP manifests (scene.json, media.json, pack.json), calculates size_bytes,
checks covers/ directory for matching cover images, and generates or updates repository.json (Schema v2).
"""

import os
import sys
import json
import zipfile
from pathlib import Path

def parse_color_hex(color_val):
    if color_val is None:
        return None
    if isinstance(color_val, int):
        if color_val <= 0xFFFFFF:
            return 0xFF000000 | color_val
        return color_val
    if isinstance(color_val, str):
        val_str = color_val.strip().lstrip('#')
        if val_str.startswith('0x') or val_str.startswith('0X'):
            val_str = val_str[2:]
        try:
            val = int(val_str, 16)
            if val <= 0xFFFFFF and len(val_str) <= 6:
                return 0xFF000000 | val
            return val
        except ValueError:
            return None
    return None

def find_cover_image(repo_dir, stem):
    covers_dir = os.path.join(repo_dir, "covers")
    if not os.path.exists(covers_dir):
        return None
    extensions = [".jpg", ".jpeg", ".png", ".webp"]
    for ext in extensions:
        cover_path = os.path.join("covers", f"{stem}{ext}")
        if os.path.exists(os.path.join(repo_dir, cover_path)):
            return cover_path.replace("\\", "/")
    return None

def scan_scenes(repo_dir):
    scenes_dir = os.path.join(repo_dir, "scenes")
    if not os.path.exists(scenes_dir):
        return []

    items = []
    for root, _, files in os.walk(scenes_dir):
        for file in files:
            if not file.endswith(".zip"):
                continue
            zip_path = os.path.join(root, file)
            rel_zip_path = os.path.relpath(zip_path, repo_dir).replace("\\", "/")
            stem = Path(file).stem.replace(".scene", "")
            size_bytes = os.path.getsize(zip_path)

            try:
                with zipfile.ZipFile(zip_path, 'r') as zf:
                    manifest_name = "scene.json" if "scene.json" in zf.namelist() else ("preset.json" if "preset.json" in zf.namelist() else None)
                    if not manifest_name:
                        continue
                    with zf.open(manifest_name) as mf:
                        manifest_data = json.load(mf)
                    
                    scene_obj = manifest_data.get("scene") or (manifest_data.get("scenes")[0] if manifest_data.get("scenes") else {})
                    tracks_data = manifest_data.get("tracks", [])

                    scene_id = scene_obj.get("id") or stem
                    name = scene_obj.get("name") or stem
                    description = scene_obj.get("description")
                    color_hex = parse_color_hex(scene_obj.get("color_hex") or scene_obj.get("colorHex"))
                    cover_url = find_cover_image(repo_dir, stem)

                    tracks_list = []
                    for t in tracks_data:
                        tracks_list.append({
                            "title": t.get("title", "Untitled Track"),
                            "bus_type": t.get("bus_type") or t.get("busType") or "music",
                            "duration_ms": t.get("duration_ms") or t.get("durationMs")
                        })

                    items.append({
                        "id": scene_id,
                        "name": name,
                        "description": description,
                        "download_url": rel_zip_path,
                        "cover_url": cover_url,
                        "color_hex": color_hex,
                        "tracks_count": len(tracks_list),
                        "size_bytes": size_bytes,
                        "tracks": tracks_list
                    })
            except Exception as e:
                print(f"Warning: Could not process scene archive {rel_zip_path}: {e}", file=sys.stderr)

    return items

def scan_media(repo_dir):
    media_dir = os.path.join(repo_dir, "media")
    if not os.path.exists(media_dir):
        return []

    items = []
    for root, _, files in os.walk(media_dir):
        for file in files:
            if not file.endswith(".zip"):
                continue
            zip_path = os.path.join(root, file)
            rel_zip_path = os.path.relpath(zip_path, repo_dir).replace("\\", "/")
            stem = Path(file).stem.replace(".media", "")
            size_bytes = os.path.getsize(zip_path)

            try:
                with zipfile.ZipFile(zip_path, 'r') as zf:
                    manifest_name = "media.json" if "media.json" in zf.namelist() else ("scene.json" if "scene.json" in zf.namelist() else None)
                    if not manifest_name:
                        continue
                    with zf.open(manifest_name) as mf:
                        manifest_data = json.load(mf)

                    media_id = manifest_data.get("id") or stem
                    name = manifest_data.get("title") or manifest_data.get("name") or stem
                    description = manifest_data.get("description")
                    color_hex = parse_color_hex(manifest_data.get("color_hex") or manifest_data.get("colorHex"))
                    cover_url = find_cover_image(repo_dir, stem)
                    tracks_data = manifest_data.get("tracks", [])

                    tracks_list = []
                    for t in tracks_data:
                        tracks_list.append({
                            "title": t.get("title", "Untitled Track"),
                            "bus_type": t.get("bus_type") or t.get("busType") or "sfx",
                            "duration_ms": t.get("duration_ms") or t.get("durationMs")
                        })

                    items.append({
                        "id": media_id,
                        "name": name,
                        "description": description,
                        "download_url": rel_zip_path,
                        "cover_url": cover_url,
                        "color_hex": color_hex,
                        "tracks_count": len(tracks_list),
                        "size_bytes": size_bytes,
                        "tracks": tracks_list
                    })
            except Exception as e:
                print(f"Warning: Could not process media archive {rel_zip_path}: {e}", file=sys.stderr)

    return items

def scan_packs(repo_dir):
    packs_dir = os.path.join(repo_dir, "packs")
    if not os.path.exists(packs_dir):
        return []

    items = []
    for root, _, files in os.walk(packs_dir):
        for file in files:
            if not file.endswith(".zip"):
                continue
            zip_path = os.path.join(root, file)
            rel_zip_path = os.path.relpath(zip_path, repo_dir).replace("\\", "/")
            stem = Path(file).stem.replace(".pack", "")
            size_bytes = os.path.getsize(zip_path)

            try:
                with zipfile.ZipFile(zip_path, 'r') as zf:
                    manifest_name = "pack.json" if "pack.json" in zf.namelist() else None
                    if not manifest_name:
                        continue
                    with zf.open(manifest_name) as mf:
                        manifest_data = json.load(mf)

                    pack_id = manifest_data.get("id") or stem
                    name = manifest_data.get("title") or manifest_data.get("name") or stem
                    description = manifest_data.get("description")
                    color_hex = parse_color_hex(manifest_data.get("color_hex") or manifest_data.get("colorHex"))
                    cover_url = find_cover_image(repo_dir, stem)
                    scenes_data = manifest_data.get("scenes", [])
                    tracks_data = manifest_data.get("tracks", [])

                    scenes_summary = []
                    for s in scenes_data:
                        trks = s.get("tracks", [])
                        tracks_cnt = s.get("tracks_count") or (len(trks) if isinstance(trks, list) else 0)
                        scenes_summary.append({
                            "name": s.get("name", "Untitled Scene"),
                            "tracks_count": tracks_cnt
                        })

                    items.append({
                        "id": pack_id,
                        "name": name,
                        "description": description,
                        "download_url": rel_zip_path,
                        "cover_url": cover_url,
                        "color_hex": color_hex,
                        "scenes_count": len(scenes_summary),
                        "tracks_count": len(tracks_data),
                        "size_bytes": size_bytes,
                        "scenes": scenes_summary
                    })
            except Exception as e:
                print(f"Warning: Could not process pack archive {rel_zip_path}: {e}", file=sys.stderr)

    return items

def generate_manifest(repo_dir="."):
    repo_dir = os.path.abspath(repo_dir)
    manifest_path = os.path.join(repo_dir, "repository.json")

    existing_data = {}
    if os.path.exists(manifest_path):
        try:
            with open(manifest_path, "r", encoding="utf-8") as f:
                existing_data = json.load(f)
        except Exception:
            pass

    scenes = scan_scenes(repo_dir)
    media = scan_media(repo_dir)
    packs = scan_packs(repo_dir)

    output = {
        "name": existing_data.get("name", "TTRPG Audio Repository"),
        "description": existing_data.get("description", "Каталог сцен, медиа-наборов и паков"),
        "version": existing_data.get("version", "2.0.0"),
        "author": existing_data.get("author", "GameMaster"),
        "scenes": scenes,
        "media": media,
        "packs": packs
    }

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"Successfully generated {manifest_path} with {len(scenes)} scenes, {len(media)} media sets, {len(packs)} packs.")

if __name__ == "__main__":
    target_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    generate_manifest(target_dir)
