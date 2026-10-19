import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../audio/ambient_bus_controller.dart';
import '../../audio/analysis/bus_spectrum.dart';
import '../../audio/music_bus_controller.dart';
import '../../audio/playback/soloud_engine.dart';
import '../design/equalizer_bars.dart';

/// [EqualizerBars] that show the live spectrum of one mixing bus: what
/// plays through it now, after fades and ducking. While the bus has no data
/// (nothing has played through it yet, no audio engine in tests) the
/// motion is simulated as before; with reduced motion the bars are static.
class BusEqualizer extends StatefulWidget {
  /// Bus key, see [SoLoudEngine.musicBus] and [SoLoudEngine.ambientBus].
  final String bus;

  /// The source is on (colour and the simulated motion).
  final bool playing;

  /// Sound may come out now (a pause still fading out counts); the bars
  /// keep reading until they have sunk.
  final bool audible;

  final int bars;
  final double height;
  final bool wide;

  const BusEqualizer({
    super.key,
    required this.bus,
    required this.playing,
    required this.audible,
    this.bars = 4,
    required this.height,
    this.wide = false,
  });

  @override
  State<BusEqualizer> createState() => _BusEqualizerState();
}

class _BusEqualizerState extends State<BusEqualizer> with SingleTickerProviderStateMixin {
  /// Equalizer.md: with real levels the bars follow with 80ms smoothing.
  static const double smoothingSeconds = 0.08;

  /// Bands read from the bus before they are grouped into bars.
  static const int bands = 48;

  late final Ticker _ticker;
  final ValueNotifier<List<double>> _levels = ValueNotifier(const []);
  Duration _last = Duration.zero;

  /// The bus has data. The bus appears only once its first voice starts,
  /// after the play/pause state has changed, so every frame checks again.
  late bool _live = BusSpectrum.read(widget.bus, 1) != null;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _levels.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final spectrum = BusSpectrum.read(widget.bus, bands);
    if ((spectrum != null) != _live) setState(() => _live = spectrum != null);
    final target = List<double>.filled(widget.bars, 0);
    if (spectrum != null && widget.audible) {
      for (var i = 0; i < widget.bars; i++) {
        // Bars share the bands evenly; each shows the loudest of its group.
        final from = i * bands ~/ widget.bars;
        final to = math.max(from + 1, (i + 1) * bands ~/ widget.bars);
        for (var b = from; b < to; b++) {
          target[i] = math.max(target[i], spectrum[b]);
        }
      }
    }
    final previous = _levels.value;
    final k = 1 - math.exp(-dt / smoothingSeconds);
    final next = [
      for (var i = 0; i < widget.bars; i++)
        previous.length != widget.bars ? target[i] : previous[i] + (target[i] - previous[i]) * k,
    ];
    _levels.value = next;
    if (!widget.audible && next.every((l) => l < 0.01)) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reducedMotion) {
      if (_ticker.isActive) _ticker.stop();
      return EqualizerBars(active: widget.playing, bars: widget.bars, height: widget.height, wide: widget.wide);
    }
    if (widget.audible && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
    if (!_live) {
      return EqualizerBars(active: widget.playing, bars: widget.bars, height: widget.height, wide: widget.wide);
    }
    return ValueListenableBuilder<List<double>>(
      valueListenable: _levels,
      builder: (context, levels, _) => EqualizerBars(
        active: widget.playing,
        bars: widget.bars,
        height: widget.height,
        wide: widget.wide,
        levels: levels.length == widget.bars ? levels : List<double>.filled(widget.bars, 0),
      ),
    );
  }
}

/// Spectrum of the music bus (the music card, the mixer, the library row of
/// the playing track).
class MusicEqualizer extends StatelessWidget {
  final int bars;
  final double height;
  final bool wide;

  const MusicEqualizer({super.key, this.bars = 4, required this.height, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicBusController>();
    return BusEqualizer(
      bus: SoLoudEngine.musicBus,
      playing: music.isPlaying,
      audible: music.isAudible,
      bars: bars,
      height: height,
      wide: wide,
    );
  }
}

/// Small spectrum of one ambient layer, next to its name.
class AmbientEqualizer extends StatelessWidget {
  final String layerId;
  final int bars;
  final double height;

  const AmbientEqualizer({super.key, required this.layerId, this.bars = 3, required this.height});

  @override
  Widget build(BuildContext context) {
    final ambient = context.watch<AmbientBusController>();
    final active = ambient.layers.any((l) => l.id == layerId && l.isActive);
    return BusEqualizer(
      bus: SoLoudEngine.ambientBus(layerId),
      playing: active,
      audible: active,
      bars: bars,
      height: height,
    );
  }
}
