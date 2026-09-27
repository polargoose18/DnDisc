enum MusicIntensity {
  calm,
  suspense,
  battle,
  boss,
}

class AudioTrack {
  final String id;
  final String title;
  final String filePath;
  final MusicIntensity intensity;
  final Duration duration;
  final int? loopStartMs;
  final int? loopEndMs;
  final String? coverImagePath;

  const AudioTrack({
    required this.id,
    required this.title,
    required this.filePath,
    this.intensity = MusicIntensity.calm,
    this.duration = Duration.zero,
    this.loopStartMs,
    this.loopEndMs,
    this.coverImagePath,
  });

  AudioTrack copyWith({
    String? id,
    String? title,
    String? filePath,
    MusicIntensity? intensity,
    Duration? duration,
    int? loopStartMs,
    int? loopEndMs,
    String? coverImagePath,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      intensity: intensity ?? this.intensity,
      duration: duration ?? this.duration,
      loopStartMs: loopStartMs ?? this.loopStartMs,
      loopEndMs: loopEndMs ?? this.loopEndMs,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }
}
