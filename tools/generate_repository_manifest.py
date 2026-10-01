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

def _parse_wav_duration(data):
    try:
        import wave
        with wave.open(io.BytesIO(data), 'rb') as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            if rate > 0 and frames > 0:
                return int((frames / rate) * 1000)
    except Exception:
        pass

    try:
        if data.startswith(b'RIFF') and len(data) >= 44 and data[8:12] == b'WAVE':
            pos = 12
            fmt_byte_rate = 0
            data_len = 0
            while pos + 8 <= len(data):
                chunk_id = data[pos:pos+4]
                chunk_len = struct.unpack('<I', data[pos+4:pos+8])[0]
                if chunk_id == b'fmt ' and chunk_len >= 16:
                    fmt_byte_rate = struct.unpack('<I', data[pos+16:pos+20])[0]
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
    return None

def _parse_flac_duration(data):
    try:
        if data.startswith(b'fLaC') and len(data) >= 42:
            if (data[4] & 0x7F) == 0:  # STREAMINFO block
                si = data[8:42]
                sr = (si[10] << 12) | (si[11] << 4) | (si[12] >> 4)
                total_samples = ((si[13] & 0x0F) << 32) | (si[14] << 24) | (si[15] << 16) | (si[16] << 8) | si[17]
                if sr > 0 and total_samples > 0:
                    return int((total_samples / sr) * 1000)
    except Exception:
        pass
    return None

def _parse_mp3_duration(data):
    if not data or len(data) < 4:
        return None

    pos = 0
    # Skip ID3v2 header if present
    if data.startswith(b'ID3') and len(data) >= 10:
        tag_size = ((data[6] & 0x7F) << 21) | ((data[7] & 0x7F) << 14) | ((data[8] & 0x7F) << 7) | (data[9] & 0x7F)
        pos = 10 + tag_size
        if len(data) > 5 and (data[5] & 0x10):  # ID3v2 footer
            pos += 10

    bitrates_v1_l1 = [0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0]
    bitrates_v1_l2 = [0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 0]
    bitrates_v1_l3 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
    bitrates_v2_l1 = [0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0]
    bitrates_v2_l23 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0]

    samplerates = {
        3: [44100, 48000, 32000, 0],
        2: [22050, 24000, 16000, 0],
        0: [11025, 12000, 8000, 0],
    }

    def get_bitrate(v_id, l_id, idx):
        if idx == 0 or idx == 15:
            return 0
        if v_id == 3:
            if l_id == 3: return bitrates_v1_l1[idx] * 1000
            if l_id == 2: return bitrates_v1_l2[idx] * 1000
            if l_id == 1: return bitrates_v1_l3[idx] * 1000
        elif v_id in (0, 2):
            if l_id == 3: return bitrates_v2_l1[idx] * 1000
            if l_id in (1, 2): return bitrates_v2_l23[idx] * 1000
        return 0

    def get_samples_per_frame(v_id, l_id):
        if l_id == 3: return 384
        if l_id == 2: return 1152
        if l_id == 1: return 1152 if v_id == 3 else 576
        return 0

    total_duration_sec = 0.0
    first_frame = True
    data_len = len(data)

    while pos + 4 <= data_len:
        if data[pos] == 0xFF and (data[pos+1] & 0xE0) == 0xE0:
            header = (data[pos] << 24) | (data[pos+1] << 16) | (data[pos+2] << 8) | data[pos+3]
            v_id = (header >> 19) & 0x3
            l_id = (header >> 17) & 0x3
            bitrate_idx = (header >> 12) & 0xF
            sr_idx = (header >> 10) & 0x3
            padding = (header >> 9) & 0x1
            channel_mode = (header >> 6) & 0x3
            has_crc = ((header >> 16) & 1) == 0
            header_size = 6 if has_crc else 4

            if v_id != 1 and l_id != 0 and bitrate_idx != 0 and bitrate_idx != 0xF and sr_idx != 3:
                sr = samplerates[v_id][sr_idx]
                br = get_bitrate(v_id, l_id, bitrate_idx)
                spf = get_samples_per_frame(v_id, l_id)

                if sr > 0 and br > 0 and spf > 0:
                    if l_id == 3:
                        frame_len = (int(12 * br / sr) + padding) * 4
                    elif l_id == 2:
                        frame_len = int(144 * br / sr) + padding
                    else:
                        multiplier = 144 if v_id == 3 else 72
                        frame_len = int(multiplier * br / sr) + padding

                    if frame_len >= 4:
                        if first_frame:
                            # Check Xing / Info header
                            side_info_size = (17 if channel_mode == 3 else 32) if v_id == 3 else (9 if channel_mode == 3 else 17)
                            xing_offsets = [pos + header_size + side_info_size, pos + 4 + side_info_size, pos + 6 + side_info_size]
                            for xing_offset in set(xing_offsets):
                                if xing_offset + 8 <= data_len:
                                    tag = data[xing_offset:xing_offset+4]
                                    if tag in (b'Xing', b'Info'):
                                        flags = struct.unpack('>I', data[xing_offset+4:xing_offset+8])[0]
                                        if (flags & 1) and xing_offset + 12 <= data_len:
                                            frames = struct.unpack('>I', data[xing_offset+8:xing_offset+12])[0]
                                            if frames > 0:
                                                return int((frames * spf / sr) * 1000)

                            # Check VBRI header
                            vbri_offsets = [pos + header_size + 32, pos + 36, pos + 38]
                            for vbri_offset in set(vbri_offsets):
                                if vbri_offset + 18 <= data_len and data[vbri_offset:vbri_offset+4] == b'VBRI':
                                    frames = struct.unpack('>I', data[vbri_offset+14:vbri_offset+18])[0]
                                    if frames > 0:
                                        return int((frames * spf / sr) * 1000)

                            first_frame = False

                        total_duration_sec += spf / sr
                        pos += frame_len
                        continue
        pos += 1

    if total_duration_sec > 0:
        return int(total_duration_sec * 1000)

    return None

def _parse_ogg_duration(data):
    if not data or len(data) < 28 or not data.startswith(b'OggS'):
        return None

    sample_rate = None
    pos = 0
    while pos + 28 <= min(len(data), 65536):
        if data[pos:pos+4] == b'OggS':
            n_segments = data[pos+26]
            header_size = 27 + n_segments
            if pos + header_size <= len(data):
                body = data[pos+header_size:pos+header_size+64]
                if b'\x01vorbis' in body:
                    v_idx = body.find(b'\x01vorbis')
                    if v_idx + 16 <= len(body):
                        sample_rate = struct.unpack('<I', body[v_idx+12:v_idx+16])[0]
                elif b'OpusHead' in body:
                    sample_rate = 48000
            if sample_rate:
                break
            pos += 1
        else:
            pos += 1

    if not sample_rate or sample_rate <= 0:
        sample_rate = 44100

    scan_start = max(0, len(data) - 65536)
    last_granule = None
    p = len(data) - 14
    while p >= scan_start:
        if data[p:p+4] == b'OggS':
            granule = struct.unpack('<Q', data[p+6:p+14])[0]
            if granule > 0 and granule != 0xFFFFFFFFFFFFFFFF:
                last_granule = granule
                break
        p -= 1

    if last_granule is not None and last_granule > 0:
        return int((last_granule / sample_rate) * 1000)

    return None

def _parse_m4a_duration(data):
    if not data or len(data) < 8:
        return None

    def find_atom(buf, atom_type, start=0, end=None):
        if end is None:
            end = len(buf)
        p = start
        while p + 8 <= end:
            size = struct.unpack('>I', buf[p:p+4])[0]
            name = buf[p+4:p+8]
            if size == 1 and p + 16 <= end:
                size = struct.unpack('>Q', buf[p+8:p+16])[0]
            elif size == 0:
                size = end - p
            if size < 8:
                break
            if name == atom_type:
                return p, size
            p += size
        return None, 0

    try:
        moov_offset, moov_size = find_atom(data, b'moov')
        if moov_offset is not None:
            mvhd_offset, mvhd_size = find_atom(data, b'mvhd', start=moov_offset+8, end=moov_offset+moov_size)
            if mvhd_offset is not None and mvhd_size >= 24:
                content_offset = mvhd_offset + 8
                version = data[content_offset]
                if version == 0 and mvhd_size >= 28:
                    timescale = struct.unpack('>I', data[content_offset+12:content_offset+16])[0]
                    duration = struct.unpack('>I', data[content_offset+16:content_offset+20])[0]
                    if timescale > 0 and duration > 0:
                        return int((duration / timescale) * 1000)
                elif version == 1 and mvhd_size >= 40:
                    timescale = struct.unpack('>I', data[content_offset+20:content_offset+24])[0]
                    duration = struct.unpack('>Q', data[content_offset+24:content_offset+32])[0]
                    if timescale > 0 and duration > 0:
                        return int((duration / timescale) * 1000)
    except Exception:
        pass

    return None

def extract_audio_duration_ms(audio_bytes, filename="audio.mp3"):
    """
    Extracts duration in milliseconds from audio bytes using multiple strategies:
    1. mutagen (if installed)
    2. tinytag (if installed)
    3. ffprobe (if available on system)
    4. pure-python binary parsers (WAV, FLAC, MP3, OGG, M4A)
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

    # 3. FFprobe
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
                if dur_sec > 0:
                    return int(dur_sec * 1000)
        finally:
            if os.path.exists(tf_path):
                os.remove(tf_path)
    except Exception:
        pass

    # 4. Pure Python binary parsers
    # WAV
    wav_dur = _parse_wav_duration(audio_bytes)
    if wav_dur is not None:
        return wav_dur

    # FLAC
    flac_dur = _parse_flac_duration(audio_bytes)
    if flac_dur is not None:
        return flac_dur

    # MP3
    mp3_dur = _parse_mp3_duration(audio_bytes)
    if mp3_dur is not None:
        return mp3_dur

    # OGG
    ogg_dur = _parse_ogg_duration(audio_bytes)
    if ogg_dur is not None:
        return ogg_dur

    # M4A
    m4a_dur = _parse_m4a_duration(audio_bytes)
    if m4a_dur is not None:
        return m4a_dur

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

def _extract_scene_tracks_count(s, pack_tracks=None, total_scenes=1):
    if not isinstance(s, dict):
        return 0

    explicit_count = s.get("tracks_count")
    if explicit_count is None:
        explicit_count = s.get("tracksCount")
    if isinstance(explicit_count, int) and explicit_count > 0:
        return explicit_count

    direct_tracks = s.get("tracks")
    if isinstance(direct_tracks, list) and len(direct_tracks) > 0:
        return len(direct_tracks)

    scene_track_ids = set()

    music_id = s.get("music_track_id") or s.get("musicTrackId")
    if music_id and isinstance(music_id, str) and music_id.strip():
        scene_track_ids.add(music_id.strip())

    amb = s.get("ambient_layer_volumes") or s.get("ambientLayerVolumes")
    if amb:
        if isinstance(amb, str):
            try:
                amb = json.loads(amb)
            except Exception:
                amb = {}
        if isinstance(amb, dict):
            for k in amb.keys():
                if k and str(k).strip():
                    scene_track_ids.add(str(k).strip())
        elif isinstance(amb, (list, set, tuple)):
            for k in amb:
                if k and str(k).strip():
                    scene_track_ids.add(str(k).strip())

    sfx = s.get("soundboard_sfx_ids") or s.get("soundboardSfxIds")
    if sfx:
        if isinstance(sfx, str):
            try:
                sfx = json.loads(sfx)
            except Exception:
                sfx = []
        if isinstance(sfx, (list, set, tuple)):
            for k in sfx:
                if k and str(k).strip():
                    scene_track_ids.add(str(k).strip())
        elif isinstance(sfx, dict):
            for k in sfx.keys():
                if k and str(k).strip():
                    scene_track_ids.add(str(k).strip())

    extra_ids = s.get("track_ids") or s.get("trackIds")
    if extra_ids:
        if isinstance(extra_ids, str):
            try:
                extra_ids = json.loads(extra_ids)
            except Exception:
                extra_ids = []
        if isinstance(extra_ids, (list, set, tuple)):
            for k in extra_ids:
                if k and str(k).strip():
                    scene_track_ids.add(str(k).strip())

    if len(scene_track_ids) > 0:
        return len(scene_track_ids)

    if total_scenes == 1 and pack_tracks and len(pack_tracks) > 0:
        return len(pack_tracks)

    if isinstance(explicit_count, int):
        return explicit_count

    return 0

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
                        tracks_cnt = _extract_scene_tracks_count(s, tracks_data, len(scenes_data))
                        scene_name = s.get("name") or s.get("title") or "Untitled Scene"
                        scenes_summary.append({
                            "name": scene_name,
                            "tracks_count": tracks_cnt
                        })

                    total_tracks = manifest_data.get("tracks_count") or manifest_data.get("tracksCount")
                    if total_tracks is None:
                        total_tracks = len(tracks_data)
                    if total_tracks == 0 and scenes_summary:
                        total_tracks = sum(sc.get("tracks_count", 0) for sc in scenes_summary)

                    items.append({
                        "id": pack_id,
                        "name": name,
                        "description": description,
                        "download_url": rel_zip_path,
                        "cover_url": cover_url,
                        "color_hex": color_hex,
                        "scenes_count": len(scenes_summary),
                        "tracks_count": total_tracks,
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
        "description": existing_data.get("description", "Catalog of scenes, media sets, and packs"),
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
