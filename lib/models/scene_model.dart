import 'dart:convert';
import 'audio_track.dart';

class SceneModel {
  final String id;
  final String name;
  final String description;
  final int colorHex;
  final String? iconName;
  final String? musicTrackId;
  final MusicIntensity? musicIntensity;
  final Map<String, double> ambientLayerVolumes; // Map of trackId -> volume (0.0 - 1.0)
  final List<String> soundboardSfxIds;
  final String? imagePath;
  final DateTime createdAt;

  SceneModel({
    required this.id,
    required this.name,
    this.description = '',
    this.colorHex = 0xFF673AB7, // Default Deep Purple Accent
    this.iconName,
    this.musicTrackId,
    this.musicIntensity = MusicIntensity.calm,
    this.ambientLayerVolumes = const {},
    this.soundboardSfxIds = const [],
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SceneModel copyWith({
    String? id,
    String? name,
    String? description,
    int? colorHex,
    String? iconName,
    String? musicTrackId,
    MusicIntensity? musicIntensity,
    Map<String, double>? ambientLayerVolumes,
    List<String>? soundboardSfxIds,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return SceneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      musicTrackId: musicTrackId ?? this.musicTrackId,
      musicIntensity: musicIntensity ?? this.musicIntensity,
      ambientLayerVolumes: ambientLayerVolumes ?? Map.from(this.ambientLayerVolumes),
      soundboardSfxIds: soundboardSfxIds ?? List.from(this.soundboardSfxIds),
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_hex': colorHex,
      'icon_name': iconName,
      'music_track_id': musicTrackId,
      'music_intensity': musicIntensity?.name,
      'ambient_layer_volumes': jsonEncode(ambientLayerVolumes),
      'soundboard_sfx_ids': jsonEncode(soundboardSfxIds),
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SceneModel.fromMap(Map<String, dynamic> map) {
    Map<String, double> parsedAmbients = {};
    if (map['ambient_layer_volumes'] != null) {
      try {
        final raw = map['ambient_layer_volumes'];
        final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
        if (decoded is Map) {
          decoded.forEach((k, v) {
            parsedAmbients[k.toString()] = (v as num).toDouble();
          });
        }
      } catch (_) {}
    }

    List<String> parsedSfx = [];
    if (map['soundboard_sfx_ids'] != null) {
      try {
        final raw = map['soundboard_sfx_ids'];
        final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
        if (decoded is List) {
          parsedSfx = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    MusicIntensity? parsedIntensity;
    if (map['music_intensity'] != null) {
      parsedIntensity = MusicIntensity.values.firstWhere(
        (e) => e.name == map['music_intensity'],
        orElse: () => MusicIntensity.calm,
      );
    }

    return SceneModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      colorHex: map['color_hex'] as int? ?? 0xFF673AB7,
      iconName: map['icon_name'] as String?,
      musicTrackId: map['music_track_id'] as String?,
      musicIntensity: parsedIntensity,
      ambientLayerVolumes: parsedAmbients,
      soundboardSfxIds: parsedSfx,
      imagePath: map['image_path'] as String? ?? map['imagePath'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory SceneModel.fromJson(Map<String, dynamic> json) => SceneModel.fromMap(json);
}
