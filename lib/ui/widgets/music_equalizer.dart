import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../audio/analysis/music_spectrum_service.dart';
import '../../audio/music_bus_controller.dart';
import '../../audio/playback/soloud_bus_player.dart';
import '../design/equalizer_bars.dart';

/// [EqualizerBars] that follow the frequencies of the music track playing
/// now (never ambient or SFX). The levels come from the track's spectrum at
/// the playback position and follow the fade, so the bars sink with a pause
/// or stop. Without a spectrum (still analysing, M4A, tests) the motion is
/// simulated as before; with reduced motion the bars stay static.
class MusicEqualizer extends StatefulWidget {
  final int bars;
  final double height;
  final bool wide;

  const MusicEqualizer({super.key, this.bars = 4, required this.height, this.wide = false});

  @override
  State<MusicEqualizer> createState() => _MusicEqualizerState();
}

class _MusicEqualizerState extends State<MusicEqualizer> with SingleTickerProviderStateMixin {
  /// Time constant of the bars (Equalizer.md: smoothing 80ms).
  static const double smoothingSeconds = 0.08;

  /// Between two position reports of the player the position runs on, for
  /// at most two report intervals.
  static final Duration maxExtrapolation = SoLoudBusPlayer.positionInterval * 2;

  late final Ticker _ticker;
  final ValueNotifier<List<double>?> _levels = ValueNotifier(null);
  MusicBusController? _music;
  // Frame time while the bars move (the ticker restarts from zero, so the
  // elapsed times are summed up here).
  Duration _time = Duration.zero;
  Duration _last = Duration.zero;
  Duration _reported = Duration.zero;
  Duration _reportedAt = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final music = context.read<MusicBusController>();
    if (!identical(music, _music)) {
      _music?.position.removeListener(_onPosition);
      _music = music..position.addListener(_onPosition);
      _onPosition();
    }
  }

  void _onPosition() {
    _reported = _music!.position.value;
    _reportedAt = _time;
  }

  void _tick(Duration elapsed) {
    final step = elapsed - _last;
    _last = elapsed;
    _time += step;
    final now = _time;
    final dt = step.inMicroseconds / 1e6;
    final music = _music!;
    final spectrum = context.read<MusicSpectrumService?>()?.current;
    if (spectrum == null) return;

    final target = List<double>.filled(widget.bars, 0);
    if (music.isAudible) {
      final since = now - _reportedAt;
      final position = _reported + (since < maxExtrapolation ? since : maxExtrapolation);
      final frame = spectrum.levelsAt(position);
      final gain = music.fadeMultiplier * music.duckingMultiplier;
      for (var i = 0; i < widget.bars; i++) {
        // Bars share the bands evenly; each shows the loudest of its group.
        final from = i * frame.length ~/ widget.bars;
        final to = math.max(from + 1, (i + 1) * frame.length ~/ widget.bars);
        var peak = 0.0;
        for (var b = from; b < to; b++) {
          peak = math.max(peak, frame[b]);
        }
        target[i] = peak * gain;
      }
    }

    final previous = _levels.value;
    final k = 1 - math.exp(-dt / smoothingSeconds);
    final next = [
      for (var i = 0; i < widget.bars; i++)
        previous == null || previous.length != widget.bars ? target[i] : previous[i] + (target[i] - previous[i]) * k,
    ];
    _levels.value = next;
    // Nothing left to move: stop until playback resumes.
    if (!music.isAudible && next.every((l) => l < 0.01)) _ticker.stop();
  }

  @override
  void dispose() {
    _music?.position.removeListener(_onPosition);
    _ticker.dispose();
    _levels.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicBusController>();
    final spectrum = context.watch<MusicSpectrumService?>()?.current;
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final playing = music.isPlaying;

    if (spectrum == null || reducedMotion) {
      if (_ticker.isActive) _ticker.stop();
      _levels.value = null;
      return EqualizerBars(active: playing, bars: widget.bars, height: widget.height, wide: widget.wide);
    }

    if (music.isAudible && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
    return ValueListenableBuilder<List<double>?>(
      valueListenable: _levels,
      builder: (context, levels, _) => EqualizerBars(
        active: playing,
        bars: widget.bars,
        height: widget.height,
        wide: widget.wide,
        levels: levels ?? List<double>.filled(widget.bars, 0),
      ),
    );
  }
}
