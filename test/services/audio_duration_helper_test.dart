import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/services/audio_duration_helper.dart';

void main() {
  group('AudioDurationHelper Unit Tests', () {
    test('should extract duration in milliseconds from synthetic WAV header', () {
      // Arrange
      final wavData = ByteData(44);
      // "RIFF"
      wavData.setUint8(0, 0x52);
      wavData.setUint8(1, 0x49);
      wavData.setUint8(2, 0x46);
      wavData.setUint8(3, 0x46);
      // "WAVE"
      wavData.setUint8(8, 0x57);
      wavData.setUint8(9, 0x41);
      wavData.setUint8(10, 0x56);
      wavData.setUint8(11, 0x45);
      // "fmt "
      wavData.setUint8(12, 0x66);
      wavData.setUint8(13, 0x6D);
      wavData.setUint8(14, 0x74);
      wavData.setUint8(15, 0x20);
      // fmt chunk size = 16
      wavData.setUint32(16, 16, Endian.little);
      // audio format = 1 (PCM), channels = 2
      wavData.setUint16(20, 1, Endian.little);
      wavData.setUint16(22, 2, Endian.little);
      // sample rate = 44100
      wavData.setUint32(24, 44100, Endian.little);
      // byte rate = 176400
      wavData.setUint32(28, 176400, Endian.little);
      // "data"
      wavData.setUint8(36, 0x64);
      wavData.setUint8(37, 0x61);
      wavData.setUint8(38, 0x74);
      wavData.setUint8(39, 0x61);
      // data size = 352800 (2.0s)
      wavData.setUint32(40, 352800, Endian.little);

      // Act
      final dur = AudioDurationHelper.extractDurationMs(wavData.buffer.asUint8List(), filename: 'test.wav');

      // Assert
      expect(dur, 2000);
    });

    test('should extract duration in milliseconds from synthetic FLAC STREAMINFO header', () {
      // Arrange
      final flacBytes = Uint8List(42);
      // "fLaC"
      flacBytes[0] = 0x66;
      flacBytes[1] = 0x4C;
      flacBytes[2] = 0x61;
      flacBytes[3] = 0x43;
      // STREAMINFO block header (0x00)
      flacBytes[4] = 0x00;
      // sample rate 44100 (0x0AC44) and 3 channels, 16-bit
      flacBytes[18] = 0x0A;
      flacBytes[19] = 0xC4;
      flacBytes[20] = 0x40;
      // total samples 132300 (0x000204CC)
      flacBytes[21] = 0x00;
      flacBytes[22] = 0x00;
      flacBytes[23] = 0x02;
      flacBytes[24] = 0x04;
      flacBytes[25] = 0xCC;

      // Act
      final dur = AudioDurationHelper.extractDurationMs(flacBytes, filename: 'test.flac');

      // Assert
      expect(dur, 3000);
    });

    test('should extract duration in milliseconds from synthetic M4A mvhd atom header', () {
      // Arrange
      final buffer = ByteData(48);
      // moov atom (size = 48)
      buffer.setUint32(0, 48, Endian.big);
      buffer.setUint8(4, 0x6D); // 'm'
      buffer.setUint8(5, 0x6F); // 'o'
      buffer.setUint8(6, 0x6F); // 'o'
      buffer.setUint8(7, 0x76); // 'v'

      // mvhd atom (size = 40, offset 8)
      buffer.setUint32(8, 40, Endian.big);
      buffer.setUint8(12, 0x6D); // 'm'
      buffer.setUint8(13, 0x76); // 'v'
      buffer.setUint8(14, 0x68); // 'h'
      buffer.setUint8(15, 0x64); // 'd'
      buffer.setUint8(16, 0); // version 0

      // timescale at offset 28 = 1000
      buffer.setUint32(28, 1000, Endian.big);
      // duration at offset 32 = 5500
      buffer.setUint32(32, 5500, Endian.big);

      // Act
      final dur = AudioDurationHelper.extractDurationMs(buffer.buffer.asUint8List(), filename: 'test.m4a');

      // Assert
      expect(dur, 5500);
    });

    group('large files (bounded header read)', () {
      late Directory dir;
      setUp(() => dir = Directory.systemTemp.createTempSync('dur_test'));
      tearDown(() => dir.deleteSync(recursive: true));

      Uint8List wav(int dataLen, int totalLen) {
        final b = Uint8List(totalLen);
        final d = ByteData.sublistView(b);
        b.setRange(0, 4, 'RIFF'.codeUnits);
        b.setRange(8, 12, 'WAVE'.codeUnits);
        b.setRange(12, 16, 'fmt '.codeUnits);
        d.setUint32(16, 16, Endian.little);
        d.setUint16(20, 1, Endian.little);
        d.setUint16(22, 2, Endian.little);
        d.setUint32(24, 44100, Endian.little);
        d.setUint32(28, 176400, Endian.little);
        b.setRange(36, 40, 'data'.codeUnits);
        d.setUint32(40, dataLen, Endian.little);
        return b;
      }

      // 128 kbps, 44.1 kHz MPEG1 Layer III frames without Xing/VBRI header.
      Uint8List cbrMp3(int frames, {int id3Size = 0}) {
        final out = BytesBuilder();
        if (id3Size > 0) {
          out.add([0x49, 0x44, 0x33, 4, 0, 0, (id3Size >> 21) & 0x7F, (id3Size >> 14) & 0x7F, (id3Size >> 7) & 0x7F, id3Size & 0x7F]);
          out.add(Uint8List(id3Size));
        }
        var carry = 0.0;
        for (var i = 0; i < frames; i++) {
          carry += 417.96;
          final len = carry.floor();
          carry -= len;
          final f = Uint8List(len);
          f[0] = 0xFF;
          f[1] = 0xFB;
          f[2] = 0x90 | (len == 418 ? 0x02 : 0);
          f[3] = 0x44;
          out.add(f);
        }
        return out.toBytes();
      }

      test('WAV of several MB gives the same result as full parse', () async {
        const total = 5 * 1024 * 1024;
        final bytes = wav(total - 44, total);
        final f = File('${dir.path}/big.wav')..writeAsBytesSync(bytes);
        final expected = AudioDurationHelper.extractDurationMs(bytes, filename: f.path);
        expect(await AudioDurationHelper.getDurationMs(f.path), expected);
        expect(AudioDurationHelper.getDurationMsSync(f.path), expected);
      });

      test('MP3 without Xing is scaled by the real file size', () async {
        final bytes = cbrMp3(8000); // ~209 s, > 3 MB
        expect(bytes.length, greaterThan(AudioDurationHelper.headerReadLimit * 4));
        final f = File('${dir.path}/big.mp3')..writeAsBytesSync(bytes);
        final expected = AudioDurationHelper.extractDurationMs(bytes, filename: f.path);
        expect(expected, closeTo(8000 * 1152 / 44100 * 1000, 50));
        expect(await AudioDurationHelper.getDurationMs(f.path), closeTo(expected, expected * 0.002));
        expect(AudioDurationHelper.getDurationMsSync(f.path), closeTo(expected, expected * 0.002));
      });

      test('MP3 with an ID3 tag larger than the read limit still works', () async {
        final bytes = cbrMp3(3000, id3Size: 400 * 1024);
        final f = File('${dir.path}/tag.mp3')..writeAsBytesSync(bytes);
        final expected = AudioDurationHelper.extractDurationMs(bytes, filename: f.path);
        expect(expected, greaterThan(0));
        expect(await AudioDurationHelper.getDurationMs(f.path), closeTo(expected, expected * 0.005));
      });

      test('M4A with moov after a large mdat falls back to full read', () async {
        const mdat = 1024 * 1024;
        final b = BytesBuilder();
        void box(String type, List<int> payload) {
          final h = ByteData(4)..setUint32(0, 8 + payload.length);
          b.add(h.buffer.asUint8List());
          b.add(type.codeUnits);
          b.add(payload);
        }
        box('ftyp', 'M4A \x00\x00\x00\x00M4A '.codeUnits);
        box('mdat', Uint8List(mdat));
        final mvhd = ByteData(100)
          ..setUint32(12, 1000)
          ..setUint32(16, 7000);
        final mvhdBox = BytesBuilder();
        final h = ByteData(4)..setUint32(0, 108);
        mvhdBox.add(h.buffer.asUint8List());
        mvhdBox.add('mvhd'.codeUnits);
        mvhdBox.add(mvhd.buffer.asUint8List());
        box('moov', mvhdBox.toBytes());
        final f = File('${dir.path}/tail.m4a')..writeAsBytesSync(b.toBytes());
        expect(await AudioDurationHelper.getDurationMs(f.path), 7000);
        expect(AudioDurationHelper.getDurationMsSync(f.path), 7000);
      });
    });
  });
}
