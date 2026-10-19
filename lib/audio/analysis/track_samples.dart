import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

typedef _ReadNative = UnsignedInt Function(Pointer<Utf8>, Float, Float, UnsignedLong, Bool, Pointer<Float>);
typedef _Read = int Function(Pointer<Utf8>, double, double, int, bool, Pointer<Float>);

/// Decoded mono samples of a file and their real rate.
typedef TrackSamples = ({Float32List samples, double sampleRate});

/// Reads a file's samples through the decoder inside flutter_soloud's native
/// library (miniaudio: MP3, WAV, OGG, FLAC).
///
/// The plugin's own `readSamplesFromFile` never frees its buffer (about
/// 16 bytes per sample leak) and its native loop can write past the
/// requested count when the frame count does not divide evenly, so this
/// calls the native function directly with a buffer of twice the size,
/// marked so the samples actually written can be counted, and frees it.
class TrackSampleReader {
  /// Target rate: enough for a music visualizer (up to about 4 kHz), and
  /// low enough that every common file rate gives at least one frame per
  /// sample, which the native loop needs.
  static const int targetRate = 8000;

  /// Longest stretch read in one native call (the decoder seeks again for
  /// each call, which is slow for MP3).
  static const int chunkSeconds = 300;

  final _Read _read;

  TrackSampleReader._(this._read);

  /// Opens the plugin library; null where it is not available (tests, web).
  static TrackSampleReader? open() {
    try {
      final lib = Platform.isWindows
          ? DynamicLibrary.open('flutter_soloud_plugin.dll')
          : (Platform.isLinux || Platform.isAndroid)
              ? DynamicLibrary.open('libflutter_soloud_plugin.so')
              : DynamicLibrary.process();
      return TrackSampleReader._(lib.lookupFunction<_ReadNative, _Read>('readSamplesFromFile'));
    } catch (_) {
      return null;
    }
  }

  /// First channel of [path] over [length]; null when it cannot be decoded.
  TrackSamples? read(String path, Duration length) {
    final seconds = length.inMicroseconds / 1e6;
    if (seconds < 0.1) return null;
    final parts = <Float32List>[];
    var rate = 0.0;
    for (var start = 0.0; start < seconds; start += chunkSeconds) {
      final end = (start + chunkSeconds) < seconds ? start + chunkSeconds : seconds;
      final chunk = _readChunk(path, start, end);
      if (chunk == null) return null;
      parts.add(chunk.samples);
      rate = chunk.sampleRate;
    }
    final total = parts.fold<int>(0, (n, p) => n + p.length);
    final samples = Float32List(total);
    var offset = 0;
    for (final p in parts) {
      samples.setAll(offset, p);
      offset += p.length;
    }
    return (samples: samples, sampleRate: rate);
  }

  TrackSamples? _readChunk(String path, double start, double end) {
    final needed = ((end - start) * targetRate).floor();
    if (needed < 1) return null;
    // The native loop writes ceil(frames / floor(frames / needed)) values,
    // which is between needed and 2 * needed.
    final capacity = needed * 2 + 1;
    final buffer = calloc<Float>(capacity);
    final name = path.toNativeUtf8();
    try {
      final view = buffer.asTypedList(capacity);
      view.fillRange(needed, capacity, double.nan);
      final error = _read(name, start, end, needed, false, buffer);
      if (error != 0) return null;
      var written = needed;
      while (written < capacity && !view[written].isNaN) {
        written++;
      }
      return (samples: Float32List.fromList(view.sublist(0, written)), sampleRate: written / (end - start));
    } finally {
      calloc.free(buffer);
      malloc.free(name);
    }
  }
}
