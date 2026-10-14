enum MusicIntensity {
  calm,
  suspense,
  battle,
  boss,
}

extension MusicIntensityExtension on MusicIntensity {
  String get englishName {
    switch (this) {
      case MusicIntensity.calm:
        return 'Calm';
      case MusicIntensity.suspense:
        return 'Suspense';
      case MusicIntensity.battle:
        return 'Battle';
      case MusicIntensity.boss:
        return 'Boss';
    }
  }

  String getLocalizedName([dynamic l10n]) {
    switch (this) {
      case MusicIntensity.calm:
        return l10n?.intensityCalm ?? 'Calm';
      case MusicIntensity.suspense:
        return l10n?.intensitySuspense ?? 'Suspense';
      case MusicIntensity.battle:
        return l10n?.intensityBattle ?? 'Battle';
      case MusicIntensity.boss:
        return l10n?.intensityBoss ?? 'Boss';
    }
  }
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
