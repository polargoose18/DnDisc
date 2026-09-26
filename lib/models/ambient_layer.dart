class AmbientLayer {
  final String id;
  final String title;
  final String filePath;
  final double volume; // 0.0 to 1.0
  final bool isActive;
  final String? iconName;

  const AmbientLayer({
    required this.id,
    required this.title,
    required this.filePath,
    this.volume = 0.8,
    this.isActive = false,
    this.iconName,
  });

  AmbientLayer copyWith({
    String? id,
    String? title,
    String? filePath,
    double? volume,
    bool? isActive,
    String? iconName,
  }) {
    return AmbientLayer(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      volume: volume ?? this.volume,
      isActive: isActive ?? this.isActive,
      iconName: iconName ?? this.iconName,
    );
  }
}
