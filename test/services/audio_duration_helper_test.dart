import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/services/audio_duration_helper.dart';

void main() {
  group('AudioDurationHelper Unit Tests', () {
    test(
      'Что проверяем: Извлечение длительности из синтетического WAV (RIFF) аудиопотока. '
      'Входные данные: 44-байтовый заголовок WAV с byteRate=176400 (44100Hz 16-bit stereo) и dataLen=352800 (2 секунды). '
      'Ожидаемый результат: Возвращается durationMs = 2000.',
      () {
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

        final dur = AudioDurationHelper.extractDurationMs(wavData.buffer.asUint8List(), filename: 'test.wav');
        expect(dur, 2000);
      },
    );

    test(
      'Что проверяем: Извлечение длительности из FLAC STREAMINFO заголовка. '
      'Входные данные: Заголовок FLAC с sample_rate=44100 и total_samples=132300 (3 секунды). '
      'Ожидаемый результат: Возвращается durationMs = 3000.',
      () {
        final flacBytes = Uint8List(42);
        // "fLaC"
        flacBytes[0] = 0x66;
        flacBytes[1] = 0x4C;
        flacBytes[2] = 0x61;
        flacBytes[3] = 0x43;
        // STREAMINFO block header (0x00)
        flacBytes[4] = 0x00;
        // sample rate 44100 (0x0AC44) and 3 channels, 16-bit
        // offset 18: sample_rate upper 12 bits = 0x0AC
        flacBytes[18] = 0x0A;
        flacBytes[19] = 0xC4;
        flacBytes[20] = 0x40; // lower 4 bits of SR (4) | 3 bits channels (0) | 1 bit bps
        // total samples 132300 (0x000204CC) across offsets 21..25
        flacBytes[21] = 0x00;
        flacBytes[22] = 0x00;
        flacBytes[23] = 0x02;
        flacBytes[24] = 0x04;
        flacBytes[25] = 0xCC;

        final dur = AudioDurationHelper.extractDurationMs(flacBytes, filename: 'test.flac');
        expect(dur, 3000);
      },
    );

    test(
      'Что проверяем: Извлечение длительности из M4A mvhd атома. '
      'Входные данные: Контейнер MP4/M4A с timescale=1000 и duration=5500. '
      'Ожидаемый результат: Возвращается durationMs = 5500.',
      () {
        // Build minimal moov -> mvhd atom
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

        // timescale at offset 8 + 8 + 12 = 28
        buffer.setUint32(28, 1000, Endian.big);
        // duration at offset 8 + 8 + 16 = 32
        buffer.setUint32(32, 5500, Endian.big);

        final dur = AudioDurationHelper.extractDurationMs(buffer.buffer.asUint8List(), filename: 'test.m4a');
        expect(dur, 5500);
      },
    );
  });
}
