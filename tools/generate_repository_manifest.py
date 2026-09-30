#!/usr/bin/env python3
"""
tools/generate_repository_manifest.py

Automatically scans repository directory structure for:
  - scenes/*.scene.zip
  - media/*.media.zip
  - packs/*.pack.zip
Inspects internal ZIP manifests (scene.json, media.json, pack.json), calculates size_bytes,
reads audio track durations from zip archives or metadata,
checks covers/ directory for matching cover images, and generates or updates repository.json (Schema v2).
"""

import os
import sys
import json
import zipfile
import io
import struct
import subprocess
import tempfile
from pathlib import Path

def extract_audio_duration_ms(audio_bytes, filename="audio.mp3"):
    """
    Extracts duration in milliseconds from audio bytes using multiple strategies:
    1. mutagen (if installed)
    2. tinytag (if installed)
    3. wave module (built-in, for WAV)
    4. pure-python binary parsers (WAV, FLAC, MP3)
    5. ffprobe (if available on system)
    """
    if not audio_bytes:
        return None

    # 1. Mutagen
    try:
        import mutagen
        audio = mutagen.File(io.BytesIO(audio_bytes))
        if audio is not None and audio.info and audio.info.length:
            return int(audio.info.length * 1000)
    except Exception:
        pass

    # 2. TinyTag
    try:
        from tinytag import TinyTag
        tag = TinyTag.get(file_obj=io.BytesIO(audio_bytes))
        if tag and tag.duration:
            return int(tag.duration * 1000)
    except Exception:
        pass

    # 3. Built-in wave
    try:
        import wave
        with wave.open(io.BytesIO(audio_bytes), 'rb') as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            if rate > 0 and frames > 0:
                return int((frames / rate) * 1000)
    except Exception:
        pass

    # 4. Pure Python binary parsers
    # 4a. FLAC
    try:
        if audio_bytes.startswith(b'fLaC') and len(audio_bytes) >= 42:
            if (audio_bytes[4] & 0x7F) == 0:  # STREAMINFO block
                si = audio_bytes[8:42]
                sr = (si[10] << 12) | (si[11] << 4) | (si[12] >> 4)
                total_samples = ((si[13] & 0x0F) << 32) | (si[14] << 24) | (si[15] << 16) | (si[16] << 8) | si[17]
                if sr > 0 and total_samples > 0:
                    return int((total_samples / sr) * 1000)
    except Exception:
        pass

    # 4b. WAV RIFF
    try:
        if audio_bytes.startswith(b'RIFF') and len(audio_bytes) >= 44 and audio_bytes[8:12] == b'WAVE':
            pos = 12
            fmt_byte_rate = 0
            data_len = 0
            while pos + 8 <= len(audio_bytes):
                chunk_id = audio_bytes[pos:pos+4]
                chunk_len = struct.unpack('<I', audio_bytes[pos+4:pos+8])[0]
                if chunk_id == b'fmt ' and chunk_len >= 16:
                    _, _, fmt_byte_rate = struct.unpack('<HII', audio_bytes[pos+8:pos+18])
                elif chunk_id == b'data':
                    data_len = chunk_len
                    break
                pos += 8 + chunk_len
                if chunk_len % 2 == 1:
                    pos += 1
            if fmt_byte_rate > 0 and data_len > 0:
                return int((data_len / fmt_byte_rate) * 1000)
    except Exception:
        pass

    # 4c. MP3 Frame & Xing / VBRI parser
    try:
        data = audio_bytes
        pos = 0
        if data.startswith(b'ID3') and len(data) >= 10:
            tag_size = ((data[6] & 0x7F) << 21) | ((data[7] & 0x7F) << 14) | ((data[8] & 0x7F) << 7) | (data[9] & 0x7F)
            pos = 10 + tag_size

        v1_l3_bitrates = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
        v2_l3_bitrates = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0]
        v1_samplerates = [44100, 48000, 32000, 0]
        v2_samplerates = [22050, 24000, 16000, 0]
        v25_samplerates = [11025, 12000, 8000, 0]

        while pos + 4 <= len(data):
            if data[pos] == 0xFF and (data[pos+1] & 0xE0) == 0xE0:
                header = (data[pos] << 24) | (data[pos+1] << 16) | (data[pos+2] << 8) | data[pos+3]
                version_id = (header >> 19) & 0x3
                layer = (header >> 17) & 0x3
                bitrate_idx = (header >> 12) & 0xF
                sr_idx = (header >> 10) & 0x3
                channel_mode = (header >> 6) & 0x3

                if layer == 1 and bitrate_idx != 0 and bitrate_idx != 0xF and sr_idx != 3:
                    if version_id == 3:
                        sr = v1_samplerates[sr_idx]
                        br = v1_l3_bitrates[bitrate_idx] * 1000
                        samples_per_frame = 1152
                    elif version_id in (0, 2):
                        sr = v2_samplerates[sr_idx] if version_id == 2 else v25_samplerates[sr_idx]
                        br = v2_l3_bitrates[bitrate_idx] * 1000
                        samples_per_frame = 576
                    else:
                        pos += 1
                        continue

                    if sr > 0 and br > 0:
                        side_info_size = (17 if channel_mode == 3 else 32) if version_id == 3 else (9 if channel_mode == 3 else 17)
                        xing_offset = pos + 4 + side_info_size
                        if xing_offset + 12 <= len(data):
                            tag = data[xing_offset:xing_offset+4]
                            if tag in (b'Xing', b'Info'):
                                flags = (data[xing_offset+4] << 24) | (data[xing_offset+5] << 16) | (data[xing_offset+6] << 8) | data[xing_offset+7]
                                if (flags & 1) and xing_offset + 12 <= len(data):
                                    frames = (data[xing_offset+8] << 24) | (data[xing_offset+9] << 16) | (data[xing_offset+10] << 8) | data[xing_offset+11]
                                    if frames > 0:
                                        return int((frames * samples_per_frame / sr) * 1000)

                        audio_len = len(data) - pos
                        duration_sec = (audio_len * 8.0) / br
                        return int(duration_sec * 1000)
            pos += 1
    except Exception:
        pass

    # 5. FFprobe fallback
    try:
        ext = Path(filename).suffix or ".mp3"
        with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as tf:
            tf.write(audio_bytes)
            tf_path = tf.name
        try:
            cmd = ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", tf_path]
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            if res.returncode == 0 and res.stdout.strip():
                dur_sec = float(res.stdout.strip())
                return int(dur_sec * 1000)
        finally:
            if os.path.exists(tf_path):
                os.remove(tf_path)
    except Exception:
        pass

    return None

def find_audio_file_in_zip(zf, track_item):
    rel_path = track_item.get("file_path") or track_item.get("filePath") or ""
    if rel_path:
        norm_rel = rel_path.replace("\\", "/")
        if norm_rel in zf.namelist():
            return norm_rel
        base_name = os.path.basename(norm_rel)
        for name in zf.namelist():
            if name.replace("\\", "/").endswith(base_name):
                return name

    track_id = track_item.get("id") or ""
    if track_id:
        for name in zf.namelist():
            if track_id in name:
                return name

    return None

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
                        dur = t.get("duration_ms") or t.get("durationMs")
                        if dur is None or dur <= 0:
                            audio_entry = find_audio_file_in_zip(zf, t)
                            if audio_entry:
                                try:
                                    audio_bytes = zf.read(audio_entry)
                                    dur = extract_audio_duration_ms(audio_bytes, audio_entry)
                                except Exception as err:
                                    print(f"Warning: Could not extract duration for {audio_entry} in {rel_zip_path}: {err}", file=sys.stderr)

                        tracks_list.append({
                            "title": t.get("title", "Untitled Track"),
                            "bus_type": t.get("bus_type") or t.get("busType") or "music",
                            "duration_ms": dur
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
                        dur = t.get("duration_ms") or t.get("durationMs")
                        if dur is None or dur <= 0:
                            audio_entry = find_audio_file_in_zip(zf, t)
                            if audio_entry:
                                try:
                                    audio_bytes = zf.read(audio_entry)
                                    dur = extract_audio_duration_ms(audio_bytes, audio_entry)
                                except Exception as err:
                                    print(f"Warning: Could not extract duration for {audio_entry} in {rel_zip_path}: {err}", file=sys.stderr)

                        tracks_list.append({
                            "title": t.get("title", "Untitled Track"),
                            "bus_type": t.get("bus_type") or t.get("busType") or "sfx",
                            "duration_ms": dur
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
