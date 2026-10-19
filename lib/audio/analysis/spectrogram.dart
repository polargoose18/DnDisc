import 'dart:math' as math;
import 'dart:typed_data';

/// Precomputed spectrum of a track: [bands] levels (0..1) per frame, frames
/// [framesPerSecond] apart. Small enough to keep in memory (a 5-minute track
/// at 48 bands and 30 fps is about 430 KB).
class Spectrogram {
  final int bands;
  final double framesPerSecond;
  final Uint8List data;

  const Spectrogram({required this.bands, required this.framesPerSecond, required this.data});

  int get frameCount => data.length ~/ bands;

  Duration get length => Duration(microseconds: (frameCount / framesPerSecond * 1e6).round());

  /// Levels at [position], interpolated between the two nearest frames;
  /// silence outside the track.
  List<double> levelsAt(Duration position) {
    final levels = List<double>.filled(bands, 0);
    if (frameCount == 0) return levels;
    final f = position.inMicroseconds / 1e6 * framesPerSecond;
    if (f < 0 || f > frameCount - 1) return levels;
    final i = f.floor();
    final t = f - i;
    final next = math.min(i + 1, frameCount - 1);
    for (var b = 0; b < bands; b++) {
      final a = data[i * bands + b];
      final c = data[next * bands + b];
      levels[b] = (a + (c - a) * t) / 255;
    }
    return levels;
  }
}

/// Builds a [Spectrogram] from mono [samples] at [sampleRate]: Hann-windowed
/// FFT frames, log-spaced bands, a +3 dB/octave tilt (music loses energy
/// towards the highs) and levels relative to the loud parts of the track.
Spectrogram computeSpectrogram(
  Float32List samples,
  double sampleRate, {
  int bands = 48,
  double framesPerSecond = 30,
  int fftSize = 512,
  double minHz = 50,
  double rangeDb = 48,
}) {
  final hop = sampleRate / framesPerSecond;
  final frames = samples.length < fftSize ? 0 : ((samples.length - fftSize) / hop).floor() + 1;
  final maxHz = math.min(sampleRate / 2 * 0.95, 16000.0);

  // FFT bin range of each band (at least one bin, edges on a log scale).
  final binHz = sampleRate / fftSize;
  final lo = Int32List(bands);
  final hi = Int32List(bands);
  for (var b = 0; b < bands; b++) {
    final f0 = minHz * math.pow(maxHz / minHz, b / bands);
    final f1 = minHz * math.pow(maxHz / minHz, (b + 1) / bands);
    lo[b] = (f0 / binHz).floor().clamp(1, fftSize ~/ 2 - 1);
    hi[b] = math.max(lo[b] + 1, (f1 / binHz).ceil()).clamp(lo[b] + 1, fftSize ~/ 2);
  }
  final tilt = Float64List(bands);
  for (var b = 0; b < bands; b++) {
    final centre = binHz * (lo[b] + hi[b]) / 2;
    tilt[b] = 3 * math.log(centre / 1000) / math.ln2;
  }

  final window = Float64List(fftSize);
  for (var i = 0; i < fftSize; i++) {
    window[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (fftSize - 1));
  }

  final db = Float64List(frames * bands);
  final re = Float64List(fftSize);
  final im = Float64List(fftSize);
  for (var f = 0; f < frames; f++) {
    final start = (f * hop).round();
    for (var i = 0; i < fftSize; i++) {
      re[i] = samples[start + i] * window[i];
      im[i] = 0;
    }
    _fft(re, im);
    for (var b = 0; b < bands; b++) {
      var power = 0.0;
      for (var k = lo[b]; k < hi[b]; k++) {
        power += re[k] * re[k] + im[k] * im[k];
      }
      power /= hi[b] - lo[b];
      db[f * bands + b] = 10 * math.log(power + 1e-12) / math.ln10 + tilt[b];
    }
  }

  // The top of the scale is a high percentile, so a few peaks do not
  // squash the rest of the track.
  final data = Uint8List(frames * bands);
  if (frames > 0) {
    final sorted = Float64List.fromList(db)..sort();
    final top = sorted[((sorted.length - 1) * 0.995).round()];
    final floor = top - rangeDb;
    for (var i = 0; i < db.length; i++) {
      data[i] = (((db[i] - floor) / rangeDb).clamp(0.0, 1.0) * 255).round();
    }
  }
  return Spectrogram(bands: bands, framesPerSecond: framesPerSecond, data: data);
}

/// In-place iterative radix-2 FFT; the length must be a power of two.
void _fft(Float64List re, Float64List im) {
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
    for (var i = 0; i < n; i += len) {
      var curRe = 1.0;
      var curIm = 0.0;
      for (var k = 0; k < len ~/ 2; k++) {
        final aRe = re[i + k];
        final aIm = im[i + k];
        final bRe = re[i + k + len ~/ 2] * curRe - im[i + k + len ~/ 2] * curIm;
        final bIm = re[i + k + len ~/ 2] * curIm + im[i + k + len ~/ 2] * curRe;
        re[i + k] = aRe + bRe;
        im[i + k] = aIm + bIm;
        re[i + k + len ~/ 2] = aRe - bRe;
        im[i + k + len ~/ 2] = aIm - bIm;
        final nextRe = curRe * wRe - curIm * wIm;
        curIm = curRe * wIm + curIm * wRe;
        curRe = nextRe;
      }
    }
  }
}
