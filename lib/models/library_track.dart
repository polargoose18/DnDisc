import 'audio_track.dart';

enum AudioBusType {
  music,
  ambient,
  sfx,
}

extension AudioBusTypeExtension on AudioBusType {
  String get displayName {
    switch (this) {
      case AudioBusType.music:
        return 'Музыка';
      case AudioBusType.ambient:
        return 'Эмбиент';
      case AudioBusType.sfx:
        return 'SFX Эффект';
    }
  }

  String get codeName => name;

  static AudioBusType fromCode(String code) {
    return AudioBusType.values.firstWhere(
      (e) => e.name == code,
      orElse: () => AudioBusType.music,
    );
  }
}

class LibraryTrack {
  final String id;
  final String title;
  final String filePath;
  final AudioBusType busType;
  final MusicIntensity intensity;
  final List<String> tags;
  final int colorHex;
  final String? iconName;
  final String? coverImagePath;
  final int durationMs;
  final int? loopStartMs;
  final int? loopEndMs;
  final DateTime createdAt;

  LibraryTrack({
    required this.id,
    required this.title,
    required this.filePath,
    required this.busType,
    this.intensity = MusicIntensity.calm,
    this.tags = const [],
    this.colorHex = 0xFF4A90E2,
    this.iconName,
    this.coverImagePath,
    this.durationMs = 0,
    this.loopStartMs,
    this.loopEndMs,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  LibraryTrack copyWith({
    String? id,
    String? title,
    String? filePath,
    AudioBusType? busType,
    MusicIntensity? intensity,
    List<String>? tags,
    int? colorHex,
    String? iconName,
    String? coverImagePath,
    int? durationMs,
    int? loopStartMs,
    int? loopEndMs,
    DateTime? createdAt,
  }) {
    return LibraryTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      busType: busType ?? this.busType,
      intensity: intensity ?? this.intensity,
      tags: tags ?? this.tags,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      durationMs: durationMs ?? this.durationMs,
      loopStartMs: loopStartMs ?? this.loopStartMs,
      loopEndMs: loopEndMs ?? this.loopEndMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'bus_type': busType.name,
      'intensity': intensity.name,
      'tags': tags.join(','),
      'color_hex': colorHex,
      'icon_name': iconName,
      'cover_image_path': coverImagePath,
      'duration_ms': durationMs,
      'loop_start_ms': loopStartMs,
      'loop_end_ms': loopEndMs,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LibraryTrack.fromMap(Map<String, dynamic> map) {
    final tagsString = map['tags'] as String? ?? '';
    return LibraryTrack(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      busType: AudioBusTypeExtension.fromCode(map['bus_type'] as String? ?? 'music'),
      intensity: MusicIntensity.values.firstWhere(
        (e) => e.name == (map['intensity'] as String? ?? 'calm'),
        orElse: () => MusicIntensity.calm,
      ),
      tags: tagsString.isNotEmpty ? tagsString.split(',') : [],
      colorHex: map['color_hex'] as int? ?? 0xFF4A90E2,
      iconName: map['icon_name'] as String?,
      coverImagePath: map['cover_image_path'] as String?,
      durationMs: map['duration_ms'] as int? ?? 0,
      loopStartMs: map['loop_start_ms'] as int?,
      loopEndMs: map['loop_end_ms'] as int?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
