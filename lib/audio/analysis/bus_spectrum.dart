import 'dart:ffi' as ffi;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../playback/soloud_engine.dart';

const String _soloudAsset = 'package:flutter_soloud/src/bindings.cpp';

// Exported by flutter_soloud's native library but not wrapped in its Dart
// API (5.2.1): visualization data of a single mixing bus.
@ffi.Native<ffi.Void Function(ffi.UnsignedInt, ffi.Bool)>(symbol: 'busSetVisualizationEnable', assetId: _soloudAsset)
external void _busSetVisualizationEnable(int busId, bool enable);

@ffi.Native<ffi.Pointer<ffi.Float> Function(ffi.UnsignedInt)>(symbol: 'busGetWave', assetId: _soloudAsset)
external ffi.Pointer<ffi.Float> _busGetWave(int busId);

abstract class BusSpectrumNative {
  static void enable(int busId) => _busSetVisualizationEnable(busId, true);
}

/// Live spectrum of a mixing bus: what plays through it right now, after
/// the volume of each voice, so fades and ducking show.
///
/// SoLoud keeps the first 256 samples of each mixed block of a bus (the
/// channels summed). Its own `busCalcFFT` transforms them without a window,
/// which smears a tone over the whole spectrum; here they get a Hann window
/// and are zero-padded to [fftSize], so a tone stays in its bands. 256
/// samples at 44.1 kHz are 5.8 ms, which limits the resolution in the bass
/// to roughly 170 Hz: enough for a visualizer.
abstract class BusSpectrum {
  static const int waveSize = 256;
  static const int fftSize = 1024;

  /// Engine sample rate (SoLoud.init default).
  static const double sampleRate = 44100;

  /// Replaces the native reader in tests: returns the bus's 256 samples.
  @visibleForTesting
  static Float32List? Function(String bus)? debugReader;

  /// Sum of squared magnitudes of a padded Hann-windowed tone relative to
  /// its peak (1024 / 256 padding x 1.5 for the Hann window).
  static const double _toneBins = fftSize / waveSize * 1.5;

  static final Float64List _window = Float64List.fromList([
    for (var i = 0; i < waveSize; i++) 0.5 - 0.5 * math.cos(2 * math.pi * i / (waveSize - 1)),
  ]);

  /// [bands] levels (0..1) of the bus [key]; null while nothing has played
  /// through it or there is no audio engine (tests).
  static List<double>? read(String key, int bands) {
    final wave = (debugReader ?? _readNative)(key);
    if (wave == null) return null;
    return bandsFromWave(wave, sampleRate: sampleRate, bands: bands);
  }

  static Float32List? _readNative(String key) {
    final id = SoLoudEngine.instance.busId(key);
    if (id == null) return null;
    final data = _busGetWave(id);
    if (data == ffi.nullptr) return null;
    return Float32List.fromList(data.asTypedList(waveSize));
  }

  /// Hann-windowed spectrum of [wave] folded into [bands] log-spaced bands
  /// from [minHz] to [maxHz]: a band narrower than a bin reads the
  /// magnitude at its centre (interpolated), a wider one sums the energy of
  /// its bins, so noise that spreads over many bins shows like a tone of the
  /// same power and pink noise (and music on average) comes out level.
  /// Levels are in dB over [rangeDb] below a full-scale sine.
  static List<double> bandsFromWave(
    Float32List wave, {
    required double sampleRate,
    required int bands,
    double minHz = 80,
    double maxHz = 14000,
    double rangeDb = 60,
  }) {
    final re = Float64List(fftSize);
    final im = Float64List(fftSize);
    final n = math.min(wave.length, waveSize);
    for (var i = 0; i < n; i++) {
      re[i] = wave[i] * _window[i];
    }
    _fft(re, im);
    const half = fftSize ~/ 2;
    final magnitudes = Float64List(half);
    for (var k = 0; k < half; k++) {
      magnitudes[k] = math.sqrt(re[k] * re[k] + im[k] * im[k]);
    }

    final binHz = sampleRate / fftSize;
    final top = math.min(maxHz, binHz * (half - 1));
    // A Hann-windowed full-scale sine of 256 samples peaks at 256 / 4.
    const fullScale = waveSize / 4;

    double magnitudeAt(double hz) {
      final x = (hz / binHz).clamp(0.0, half - 1.0);
      final i = x.floor();
      final j = math.min(i + 1, half - 1);
      return magnitudes[i] + (magnitudes[j] - magnitudes[i]) * (x - i);
    }

    final levels = List<double>.filled(bands, 0);
    for (var b = 0; b < bands; b++) {
      final f0 = minHz * math.pow(top / minHz, b / bands);
      final f1 = minHz * math.pow(top / minHz, (b + 1) / bands);
      final lo = (f0 / binHz).ceil();
      final hi = (f1 / binHz).floor();
      double magnitude;
      if (hi - lo < 1) {
        magnitude = magnitudeAt(math.sqrt(f0 * f1));
      } else {
        var power = 0.0;
        for (var k = lo; k <= hi; k++) {
          power += magnitudes[k] * magnitudes[k];
        }
        // A Hann main lobe spreads a tone over ~4 padded bins; dividing by
        // that keeps a tone at the same level as in a narrow band.
        magnitude = math.sqrt(power / _toneBins);
      }
      final db = 20 * math.log(magnitude / fullScale + 1e-9) / math.ln10;
      levels[b] = ((db + rangeDb) / rangeDb).clamp(0.0, 1.0);
    }
    return levels;
  }

  /// In-place iterative radix-2 FFT; the length must be a power of two.
  static void _fft(Float64List re, Float64List im) {
    final n = re.length;
    for (var i = 1, j = 0; i < n; i++) {
      var bit = n >> 1;
      for (; j & bit != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    for (var len = 2; len <= n; len <<= 1) {
      final angle = -2 * math.pi / len;
      final wRe = math.cos(angle);
      final wIm = math.sin(angle);
      final halfLen = len ~/ 2;
      for (var i = 0; i < n; i += len) {
        var curRe = 1.0;
        var curIm = 0.0;
        for (var k = 0; k < halfLen; k++) {
          final bRe = re[i + k + halfLen] * curRe - im[i + k + halfLen] * curIm;
          final bIm = re[i + k + halfLen] * curIm + im[i + k + halfLen] * curRe;
          re[i + k + halfLen] = re[i + k] - bRe;
          im[i + k + halfLen] = im[i + k] - bIm;
          re[i + k] += bRe;
          im[i + k] += bIm;
          final nextRe = curRe * wRe - curIm * wIm;
          curIm = curRe * wIm + curIm * wRe;
          curRe = nextRe;
        }
      }
    }
  }
}
