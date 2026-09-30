enum CatalogItemType {
  scene,
  media,
  pack;

  String get displayName {
    switch (this) {
      case CatalogItemType.scene:
        return 'Scene';
      case CatalogItemType.media:
        return 'Media';
      case CatalogItemType.pack:
        return 'Pack';
    }
  }

  String getLocalizedName([dynamic l10n]) {
    switch (this) {
      case CatalogItemType.scene:
        return l10n?.sceneTitle ?? 'Scene';
      case CatalogItemType.media:
        return l10n?.mediaTitle ?? 'Media';
      case CatalogItemType.pack:
        return l10n?.packTitle ?? 'Pack';
    }
  }

  String getLocalizedAccusativeName([dynamic l10n]) {
    switch (this) {
      case CatalogItemType.scene:
        return l10n?.catalogTypeScene ?? 'scene';
      case CatalogItemType.media:
        return l10n?.catalogTypeMedia ?? 'media package';
      case CatalogItemType.pack:
        return l10n?.catalogTypePack ?? 'pack';
    }
  }

  String get badgeLabel {
    switch (this) {
      case CatalogItemType.scene:
        return '🎭 Scene';
      case CatalogItemType.media:
        return '🎵 Media';
      case CatalogItemType.pack:
        return '📦 Pack';
    }
  }

  String getLocalizedBadge([dynamic l10n]) {
    switch (this) {
      case CatalogItemType.scene:
        return l10n?.catalogSceneBadge ?? '🎭 Scene';
      case CatalogItemType.media:
        return l10n?.catalogMediaBadge ?? '🎵 Media';
      case CatalogItemType.pack:
        return l10n?.catalogPackBadge ?? '📦 Pack';
    }
  }
}

enum CatalogCategoryFilter {
  all,
  scenes,
  media,
  packs;

  String get label {
    switch (this) {
      case CatalogCategoryFilter.all:
        return 'All';
      case CatalogCategoryFilter.scenes:
        return '🎭 Scenes';
      case CatalogCategoryFilter.media:
        return '🎵 Media';
      case CatalogCategoryFilter.packs:
        return '📦 Packs';
    }
  }

  String getLocalizedLabel([dynamic l10n]) {
    switch (this) {
      case CatalogCategoryFilter.all:
        return l10n?.filterAll ?? 'All';
      case CatalogCategoryFilter.scenes:
        return l10n?.filterScenes ?? '🎭 Scenes';
      case CatalogCategoryFilter.media:
        return l10n?.filterMedia ?? '🎵 Media';
      case CatalogCategoryFilter.packs:
        return l10n?.filterPacks ?? '📦 Packs';
    }
  }
}

class SceneRepositoryModel {
  final String id;
  final String name;
  final String url;
  final String? description;
  final DateTime createdAt;
  final DateTime? lastSyncedAt;

  const SceneRepositoryModel({
    required this.id,
    required this.name,
    required this.url,
    this.description,
    required this.createdAt,
    this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  factory SceneRepositoryModel.fromMap(Map<String, dynamic> map) {
    return SceneRepositoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.parse(map['last_synced_at'] as String)
          : null,
    );
  }

  SceneRepositoryModel copyWith({
    String? id,
    String? name,
    String? url,
    String? description,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
  }) {
    return SceneRepositoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneRepositoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          url == other.url &&
          description == other.description &&
          createdAt == other.createdAt &&
          lastSyncedAt == other.lastSyncedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      url.hashCode ^
      description.hashCode ^
      createdAt.hashCode ^
      lastSyncedAt.hashCode;
}

class SceneRepositoryManifest {
  final String name;
  final String? description;
  final String? version;
  final String? author;
  final List<RepositorySceneItem> scenes;
  final List<RepositoryMediaItem> media;
  final List<RepositoryPackItem> packs;

  const SceneRepositoryManifest({
    required this.name,
    this.description,
    this.version,
    this.author,
    this.scenes = const [],
    this.media = const [],
    this.packs = const [],
  });

  factory SceneRepositoryManifest.fromJson(Map<String, dynamic> json) {
    final rawScenes = json['scenes'] as List<dynamic>? ?? [];
    final rawMedia = json['media'] as List<dynamic>? ?? [];
    final rawPacks = json['packs'] as List<dynamic>? ?? [];

    return SceneRepositoryManifest(
      name: json['name'] as String? ?? 'Unnamed Repository',
      description: json['description'] as String?,
      version: json['version'] as String?,
      author: json['author'] as String?,
      scenes: rawScenes
          .map((item) => RepositorySceneItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      media: rawMedia
          .map((item) => RepositoryMediaItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      packs: rawPacks
          .map((item) => RepositoryPackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'version': version,
      'author': author,
      'scenes': scenes.map((s) => s.toJson()).toList(),
      'media': media.map((m) => m.toJson()).toList(),
      'packs': packs.map((p) => p.toJson()).toList(),
    };
  }
}

class RepositorySceneItem {
  final String id;
  final String name;
  final String? description;
  final String downloadUrl;
  final String? coverUrl;
  final int? colorHex;
  final int? tracksCount;
  final int? sizeBytes;
  final List<RepositorySceneTrack> tracks;

  const RepositorySceneItem({
    required this.id,
    required this.name,
    this.description,
    required this.downloadUrl,
    this.coverUrl,
    this.colorHex,
    this.tracksCount,
    this.sizeBytes,
    this.tracks = const [],
  });

  factory RepositorySceneItem.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'] as List<dynamic>? ?? [];
    final idVal = json['id'] as String? ?? '';
    final downloadUrlVal = json['download_url'] as String? ?? json['downloadUrl'] as String? ?? '';
    final rawColor = json['color_hex'] ?? json['colorHex'];

    return RepositorySceneItem(
      id: idVal.isNotEmpty ? idVal : downloadUrlVal,
      name: json['name'] as String? ?? 'Unnamed Scene',
      description: json['description'] as String?,
      downloadUrl: downloadUrlVal,
      coverUrl: json['cover_url'] as String? ?? json['coverUrl'] as String?,
      colorHex: parseColorHex(rawColor),
      tracksCount: json['tracks_count'] as int? ?? json['tracksCount'] as int?,
      sizeBytes: json['size_bytes'] as int? ?? json['sizeBytes'] as int?,
      tracks: rawTracks
          .map((t) => RepositorySceneTrack.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  static int? parseColorHex(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      if (raw <= 0xFFFFFF) return 0xFF000000 | raw;
      return raw;
    }
    if (raw is String) {
      var str = raw.trim().replaceAll('#', '');
      if (str.startsWith('0x') || str.startsWith('0X')) {
        str = str.substring(2);
      }
      final val = int.tryParse(str, radix: 16);
      if (val != null) {
        if (val <= 0xFFFFFF && str.length <= 6) {
          return 0xFF000000 | val;
        }
        return val;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'download_url': downloadUrl,
      'cover_url': coverUrl,
      'color_hex': colorHex,
      'tracks_count': tracksCount ?? tracks.length,
      'size_bytes': sizeBytes,
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }
}

class RepositoryMediaItem {
  final String id;
  final String name;
  final String? description;
  final String downloadUrl;
  final String? coverUrl;
  final int? colorHex;
  final int? tracksCount;
  final int? sizeBytes;
  final List<RepositorySceneTrack> tracks;

  const RepositoryMediaItem({
    required this.id,
    required this.name,
    this.description,
    required this.downloadUrl,
    this.coverUrl,
    this.colorHex,
    this.tracksCount,
    this.sizeBytes,
    this.tracks = const [],
  });

  factory RepositoryMediaItem.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'] as List<dynamic>? ?? [];
    final idVal = json['id'] as String? ?? '';
    final downloadUrlVal = json['download_url'] as String? ?? json['downloadUrl'] as String? ?? '';
    final rawColor = json['color_hex'] ?? json['colorHex'];

    return RepositoryMediaItem(
      id: idVal.isNotEmpty ? idVal : downloadUrlVal,
      name: json['name'] as String? ?? 'Unnamed Media Set',
      description: json['description'] as String?,
      downloadUrl: downloadUrlVal,
      coverUrl: json['cover_url'] as String? ?? json['coverUrl'] as String?,
      colorHex: RepositorySceneItem.parseColorHex(rawColor),
      tracksCount: json['tracks_count'] as int? ?? json['tracksCount'] as int?,
      sizeBytes: json['size_bytes'] as int? ?? json['sizeBytes'] as int?,
      tracks: rawTracks
          .map((t) => RepositorySceneTrack.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'download_url': downloadUrl,
      'cover_url': coverUrl,
      'color_hex': colorHex,
      'tracks_count': tracksCount ?? tracks.length,
      'size_bytes': sizeBytes,
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }
}

class RepositoryPackSceneSummary {
  final String name;
  final int? tracksCount;

  const RepositoryPackSceneSummary({
    required this.name,
    this.tracksCount,
  });

  factory RepositoryPackSceneSummary.fromJson(Map<String, dynamic> json) {
    return RepositoryPackSceneSummary(
      name: json['name'] as String? ?? 'Untitled Scene',
      tracksCount: json['tracks_count'] as int? ?? json['tracksCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tracks_count': tracksCount,
    };
  }
}

class RepositoryPackItem {
  final String id;
  final String name;
  final String? description;
  final String downloadUrl;
  final String? coverUrl;
  final int? colorHex;
  final int? scenesCount;
  final int? tracksCount;
  final int? sizeBytes;
  final List<RepositoryPackSceneSummary> scenes;

  const RepositoryPackItem({
    required this.id,
    required this.name,
    this.description,
    required this.downloadUrl,
    this.coverUrl,
    this.colorHex,
    this.scenesCount,
    this.tracksCount,
    this.sizeBytes,
    this.scenes = const [],
  });

  factory RepositoryPackItem.fromJson(Map<String, dynamic> json) {
    final rawScenes = json['scenes'] as List<dynamic>? ?? [];
    final idVal = json['id'] as String? ?? '';
    final downloadUrlVal = json['download_url'] as String? ?? json['downloadUrl'] as String? ?? '';
    final rawColor = json['color_hex'] ?? json['colorHex'];

    return RepositoryPackItem(
      id: idVal.isNotEmpty ? idVal : downloadUrlVal,
      name: json['name'] as String? ?? 'Unnamed Pack',
      description: json['description'] as String?,
      downloadUrl: downloadUrlVal,
      coverUrl: json['cover_url'] as String? ?? json['coverUrl'] as String?,
      colorHex: RepositorySceneItem.parseColorHex(rawColor),
      scenesCount: json['scenes_count'] as int? ?? json['scenesCount'] as int? ?? rawScenes.length,
      tracksCount: json['tracks_count'] as int? ?? json['tracksCount'] as int?,
      sizeBytes: json['size_bytes'] as int? ?? json['sizeBytes'] as int?,
      scenes: rawScenes
          .map((s) => RepositoryPackSceneSummary.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'download_url': downloadUrl,
      'cover_url': coverUrl,
      'color_hex': colorHex,
      'scenes_count': scenesCount ?? scenes.length,
      'tracks_count': tracksCount,
      'size_bytes': sizeBytes,
      'scenes': scenes.map((s) => s.toJson()).toList(),
    };
  }
}

class RepositorySceneTrack {
  final String title;
  final String busType;
  final int? durationMs;

  const RepositorySceneTrack({
    required this.title,
    required this.busType,
    this.durationMs,
  });

  factory RepositorySceneTrack.fromJson(Map<String, dynamic> json) {
    return RepositorySceneTrack(
      title: json['title'] as String? ?? 'Untitled Track',
      busType: json['bus_type'] as String? ?? json['busType'] as String? ?? 'music',
      durationMs: json['duration_ms'] as int? ?? json['durationMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'bus_type': busType,
      'duration_ms': durationMs,
    };
  }
}

class CatalogItem {
  final String id;
  final String name;
  final String? description;
  final String downloadUrl;
  final String? coverUrl;
  final int? colorHex;
  final int? sizeBytes;
  final CatalogItemType type;
  final RepositorySceneItem? sceneItem;
  final RepositoryMediaItem? mediaItem;
  final RepositoryPackItem? packItem;

  const CatalogItem._({
    required this.id,
    required this.name,
    this.description,
    required this.downloadUrl,
    this.coverUrl,
    this.colorHex,
    this.sizeBytes,
    required this.type,
    this.sceneItem,
    this.mediaItem,
    this.packItem,
  });

  factory CatalogItem.fromScene(RepositorySceneItem item) {
    return CatalogItem._(
      id: item.id,
      name: item.name,
      description: item.description,
      downloadUrl: item.downloadUrl,
      coverUrl: item.coverUrl,
      colorHex: item.colorHex,
      sizeBytes: item.sizeBytes,
      type: CatalogItemType.scene,
      sceneItem: item,
    );
  }

  factory CatalogItem.fromMedia(RepositoryMediaItem item) {
    return CatalogItem._(
      id: item.id,
      name: item.name,
      description: item.description,
      downloadUrl: item.downloadUrl,
      coverUrl: item.coverUrl,
      colorHex: item.colorHex,
      sizeBytes: item.sizeBytes,
      type: CatalogItemType.media,
      mediaItem: item,
    );
  }

  factory CatalogItem.fromPack(RepositoryPackItem item) {
    return CatalogItem._(
      id: item.id,
      name: item.name,
      description: item.description,
      downloadUrl: item.downloadUrl,
      coverUrl: item.coverUrl,
      colorHex: item.colorHex,
      sizeBytes: item.sizeBytes,
      type: CatalogItemType.pack,
      packItem: item,
    );
  }

  int get tracksCount {
    if (type == CatalogItemType.scene) return sceneItem?.tracks.length ?? sceneItem?.tracksCount ?? 0;
    if (type == CatalogItemType.media) return mediaItem?.tracks.length ?? mediaItem?.tracksCount ?? 0;
    if (type == CatalogItemType.pack) return packItem?.tracksCount ?? 0;
    return 0;
  }
}
