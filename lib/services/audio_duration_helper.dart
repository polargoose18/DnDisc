import 'dart:io';
import 'dart:typed_data';

/// Utility to extract audio duration (in milliseconds) directly from audio file bytes in pure Dart.
/// Supports WAV, FLAC, OGG (Vorbis/Opus), MP3 (CBR/VBR/Xing/VBRI), and M4A/AAC.
class AudioDurationHelper {
  AudioDurationHelper._();

  /// Number of leading bytes read from a file. Every parser only needs the
  /// header; the file size itself comes from [File.length].
  static const int headerReadLimit = 256 * 1024;

  /// Reads audio duration in milliseconds from a local file. Returns 0 if cannot be determined.
  static Future<int> getDurationMs(String filePath) async {
    RandomAccessFile? raf;
    try {
      if (filePath.isEmpty) return 0;
      final file = File(filePath);
      if (!file.existsSync()) return 0;
      raf = await file.open();
      final length = await raf.length();
      var bytes = await raf.read(_prefixLength(length, await _peekId3(raf)));
      if (bytes.length < length && _needsWholeFile(bytes)) {
        await raf.setPosition(0);
        bytes = await raf.read(length);
      }
      var dur = extractDurationMs(bytes, filename: filePath, totalLength: length);
      if (dur == 0 && bytes.length < length) {
        // Header data not at the start (e.g. M4A with moov after mdat).
        await raf.setPosition(0);
        bytes = await raf.read(length);
        dur = extractDurationMs(bytes, filename: filePath);
      }
      return dur;
    } catch (_) {
      return 0;
    } finally {
      try {
        await raf?.close();
      } catch (_) {}
    }
  }

  /// Synchronous extraction if bytes or file are already loaded.
  static int getDurationMsSync(String filePath) {
    RandomAccessFile? raf;
    try {
      final file = File(filePath);
      if (!file.existsSync()) return 0;
      raf = file.openSync();
      final length = raf.lengthSync();
      var bytes = raf.readSync(_prefixLength(length, _peekId3Sync(raf)));
      if (bytes.length < length && _needsWholeFile(bytes)) {
        raf.setPositionSync(0);
        bytes = raf.readSync(length);
      }
      var dur = extractDurationMs(bytes, filename: filePath, totalLength: length);
      if (dur == 0 && bytes.length < length) {
        raf.setPositionSync(0);
        bytes = raf.readSync(length);
        dur = extractDurationMs(bytes, filename: filePath);
      }
      return dur;
    } catch (_) {
      return 0;
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
  }

  /// Size of the ID3v2 tag at the start of the file (0 if none); rewinds.
  static Future<int> _peekId3(RandomAccessFile raf) async {
    final head = await raf.read(10);
    await raf.setPosition(0);
    return _id3Size(head);
  }

  static int _peekId3Sync(RandomAccessFile raf) {
    final head = raf.readSync(10);
    raf.setPositionSync(0);
    return _id3Size(head);
  }

  static int _id3Size(Uint8List head) {
    if (head.length < 10 || !_matchesAscii(head, 0, 'ID3')) return 0;
    return 10 +
        (((head[6] & 0x7F) << 21) |
            ((head[7] & 0x7F) << 14) |
            ((head[8] & 0x7F) << 7) |
            (head[9] & 0x7F));
  }

  /// A large ID3 tag (cover art) pushes the first MP3 frame past the limit.
  static int _prefixLength(int fileLength, int id3Size) {
    final want = id3Size + headerReadLimit;
    final n = want > headerReadLimit ? want : headerReadLimit;
    return n < fileLength ? n : fileLength;
  }

  /// OGG duration comes from the last page's granule position, at the file end.
  static bool _needsWholeFile(Uint8List prefix) => _matchesAscii(prefix, 0, 'OggS');

  /// Extracts duration in milliseconds from audio bytes.
  ///
  /// [totalLength] is the real file size when [bytes] is only a leading part of
  /// the file; MP3 without a Xing/VBRI header is then extrapolated to it.
  static int extractDurationMs(Uint8List bytes, {String filename = 'audio.mp3', int? totalLength}) {
    if (bytes.length < 16) return 0;

    final ext = filename.toLowerCase();

    // 1. WAV
    if (bytes.length >= 44 && _matchesAscii(bytes, 0, 'RIFF') && _matchesAscii(bytes, 8, 'WAVE')) {
      final dur = _parseWav(bytes);
      if (dur > 0) return dur;
    }

    // 2. FLAC
    if (bytes.length >= 42 && _matchesAscii(bytes, 0, 'fLaC')) {
      final dur = _parseFlac(bytes);
      if (dur > 0) return dur;
    }

    // 3. M4A / MP4
    if (bytes.length >= 32 && (_matchesAscii(bytes, 4, 'ftyp') || ext.endsWith('.m4a') || ext.endsWith('.aac') || ext.endsWith('.mp4'))) {
      final dur = _parseM4a(bytes);
      if (dur > 0) return dur;
    }

    // 4. OGG
    if (bytes.length >= 28 && _matchesAscii(bytes, 0, 'OggS')) {
      final dur = _parseOgg(bytes);
      if (dur > 0) return dur;
    }

    // 5. MP3
    final mp3Dur = _parseMp3(bytes, totalLength: totalLength);
    if (mp3Dur > 0) return mp3Dur;

    return 0;
  }

  static bool _matchesAscii(Uint8List bytes, int offset, String ascii) {
    if (offset + ascii.length > bytes.length) return false;
    for (int i = 0; i < ascii.length; i++) {
      if (bytes[offset + i] != ascii.codeUnitAt(i)) return false;
    }
    return true;
  }

  static int _parseWav(Uint8List data) {
    try {
      int pos = 12;
      int byteRate = 0;
      int dataLen = 0;

      while (pos + 8 <= data.length) {
        final chunkId = String.fromCharCodes(data.sublist(pos, pos + 4));
        final chunkLen = ByteData.sublistView(data, pos + 4, pos + 8).getUint32(0, Endian.little);

        if (chunkId == 'fmt ' && chunkLen >= 16 && pos + 8 + 16 <= data.length) {
          byteRate = ByteData.sublistView(data, pos + 8 + 8, pos + 8 + 12).getUint32(0, Endian.little);
        } else if (chunkId == 'data') {
          dataLen = chunkLen;
          break;
        }

        pos += 8 + chunkLen;
        if (chunkLen % 2 == 1) pos += 1;
      }

      if (byteRate > 0 && dataLen > 0) {
        return ((dataLen / byteRate) * 1000).round();
      }
    } catch (_) {}
    return 0;
  }

  static int _parseFlac(Uint8List data) {
    try {
      if ((data[4] & 0x7F) == 0 && data.length >= 42) {
        final si = data.sublist(8, 42);
        final sr = (si[10] << 12) | (si[11] << 4) | (si[12] >> 4);
        final totalSamples = ((si[13] & 0x0F) * 0x100000000) +
            (si[14] << 24) +
            (si[15] << 16) +
            (si[16] << 8) +
            si[17];
        if (sr > 0 && totalSamples > 0) {
          return ((totalSamples / sr) * 1000).round();
        }
      }
    } catch (_) {}
    return 0;
  }

  static int _parseM4a(Uint8List data) {
    try {
      int pos = 0;
      while (pos + 8 <= data.length) {
        final size = ByteData.sublistView(data, pos, pos + 4).getUint32(0, Endian.big);
        final type = String.fromCharCodes(data.sublist(pos + 4, pos + 8));

        if (type == 'moov') {
          return _searchMvhd(data.sublist(pos + 8, pos + size <= data.length ? pos + size : data.length));
        }

        if (size <= 0) break;
        pos += size;
      }
    } catch (_) {}
    return 0;
  }

  static int _searchMvhd(Uint8List moovData) {
    int pos = 0;
    while (pos + 8 <= moovData.length) {
      final size = ByteData.sublistView(moovData, pos, pos + 4).getUint32(0, Endian.big);
      final type = String.fromCharCodes(moovData.sublist(pos + 4, pos + 8));

      if (type == 'mvhd' && pos + 8 + 24 <= moovData.length) {
        final version = moovData[pos + 8];
        final bd = ByteData.sublistView(moovData);
        if (version == 0 && pos + 8 + 20 <= moovData.length) {
          final timescale = bd.getUint32(pos + 8 + 12, Endian.big);
          final duration = bd.getUint32(pos + 8 + 16, Endian.big);
          if (timescale > 0 && duration > 0) {
            return ((duration / timescale) * 1000).round();
          }
        } else if (version == 1 && pos + 8 + 32 <= moovData.length) {
          final timescale = bd.getUint32(pos + 8 + 20, Endian.big);
          final duration = bd.getUint64(pos + 8 + 24, Endian.big);
          if (timescale > 0 && duration > 0) {
            return ((duration / timescale) * 1000).round();
          }
        }
      }

      if (type == 'trak' || type == 'mdia' || type == 'minf') {
        final res = _searchMvhd(moovData.sublist(pos + 8, pos + size <= moovData.length ? pos + size : moovData.length));
        if (res > 0) return res;
      }

      if (size <= 0) break;
      pos += size;
    }
    return 0;
  }

  static int _parseOgg(Uint8List data) {
    try {
      int sampleRate = 0;
      int lastGranule = 0;
      int pos = 0;

      while (pos + 27 <= data.length) {
        if (!_matchesAscii(data, pos, 'OggS')) {
          pos++;
          continue;
        }

        final granule = ByteData.sublistView(data, pos + 6, pos + 14).getInt64(0, Endian.little);
        if (granule > 0) lastGranule = granule;

        final numSegments = data[pos + 26];
        if (pos + 27 + numSegments > data.length) break;

        int bodyLen = 0;
        for (int s = 0; s < numSegments; s++) {
          bodyLen += data[pos + 27 + s];
        }

        final bodyStart = pos + 27 + numSegments;
        final bodyEnd = bodyStart + bodyLen;
        if (bodyEnd > data.length) break;

        if (sampleRate == 0) {
          final body = data.sublist(bodyStart, bodyEnd);
          for (int i = 0; i + 16 <= body.length; i++) {
            if (_matchesAscii(body, i, 'vorbis') && i + 16 <= body.length) {
              sampleRate = ByteData.sublistView(body, i + 12, i + 16).getUint32(0, Endian.little);
              break;
            }
            if (_matchesAscii(body, i, 'OpusHead')) {
              sampleRate = 48000;
              break;
            }
          }
        }

        pos = bodyEnd;
      }

      if (sampleRate > 0 && lastGranule > 0) {
        return ((lastGranule / sampleRate) * 1000).round();
      }
    } catch (_) {}
    return 0;
  }

  static int _parseMp3(Uint8List data, {int? totalLength}) {
    try {
      int pos = 0;
      if (data.length >= 10 && _matchesAscii(data, 0, 'ID3')) {
        final tagSize = ((data[6] & 0x7F) << 21) |
            ((data[7] & 0x7F) << 14) |
            ((data[8] & 0x7F) << 7) |
            (data[9] & 0x7F);
        pos = 10 + tagSize;
      }
      final audioStart = pos;

      const v1L3Bitrates = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0];
      const v2L3Bitrates = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0];
      const v1SampleRates = [44100, 48000, 32000, 0];
      const v2SampleRates = [22050, 24000, 16000, 0];
      const v25SampleRates = [11025, 12000, 8000, 0];

      double totalDurationSec = 0;
      int framesCounted = 0;
      int scanLimit = 0;

      while (pos + 4 <= data.length && scanLimit < 500000) {
        scanLimit++;
        if (data[pos] == 0xFF && (data[pos + 1] & 0xE0) == 0xE0) {
          final header = (data[pos] << 24) | (data[pos + 1] << 16) | (data[pos + 2] << 8) | data[pos + 3];
          final versionId = (header >> 19) & 0x3;
          final layer = (header >> 17) & 0x3;
          final hasCrc = ((header >> 16) & 1) == 0;
          final bitrateIdx = (header >> 12) & 0xF;
          final srIdx = (header >> 10) & 0x3;
          final padding = (header >> 9) & 1;
          final channelMode = (header >> 6) & 0x3;

          if (layer == 1 && bitrateIdx != 0 && bitrateIdx != 0xF && srIdx != 3) {
            int sr = 0;
            int br = 0;
            int samplesPerFrame = 1152;

            if (versionId == 3) {
              sr = v1SampleRates[srIdx];
              br = v1L3Bitrates[bitrateIdx] * 1000;
              samplesPerFrame = 1152;
            } else if (versionId == 0 || versionId == 2) {
              sr = versionId == 2 ? v2SampleRates[srIdx] : v25SampleRates[srIdx];
              br = v2L3Bitrates[bitrateIdx] * 1000;
              samplesPerFrame = 576;
            }

            if (sr > 0 && br > 0) {
              final frameLen = ((samplesPerFrame / 8 * br / sr) + padding).floor();
              if (frameLen <= 0) {
                pos++;
                continue;
              }

              // On the first frame, check for Xing / Info / VBRI header
              if (framesCounted == 0) {
                final headerLen = hasCrc ? 6 : 4;
                final sideInfo = (versionId == 3)
                    ? (channelMode == 3 ? 17 : 32)
                    : (channelMode == 3 ? 9 : 17);

                final candidateOffsets = [
                  pos + headerLen + sideInfo,
                  pos + 4 + sideInfo,
                  pos + 36,
                  pos + 21,
                ];

                for (final off in candidateOffsets) {
                  if (off + 12 <= data.length) {
                    if (_matchesAscii(data, off, 'Xing') || _matchesAscii(data, off, 'Info')) {
                      final flags = ByteData.sublistView(data, off + 4, off + 8).getUint32(0, Endian.big);
                      if ((flags & 1) != 0 && off + 12 <= data.length) {
                        final frames = ByteData.sublistView(data, off + 8, off + 12).getUint32(0, Endian.big);
                        if (frames > 0) {
                          return ((frames * samplesPerFrame / sr) * 1000).round();
                        }
                      }
                    } else if (_matchesAscii(data, off, 'VBRI') && off + 18 <= data.length) {
                      final frames = ByteData.sublistView(data, off + 14, off + 18).getUint32(0, Endian.big);
                      if (frames > 0) {
                        return ((frames * samplesPerFrame / sr) * 1000).round();
                      }
                    }
                  }
                }
              }

              totalDurationSec += (samplesPerFrame / sr);
              framesCounted++;
              pos += frameLen;
              continue;
            }
          }
        }
        pos++;
      }

      if (totalDurationSec > 0) {
        if (totalLength != null && totalLength > data.length && pos > audioStart) {
          // Only a prefix was read: scale the counted frames to the whole file.
          totalDurationSec *= (totalLength - audioStart) / (pos - audioStart);
        }
        return (totalDurationSec * 1000).round();
      }
    } catch (_) {}
    return 0;
  }
}
