class SfxTrigger {
  final String id;
  final String title;
  final String filePath;
  final double volume;
  final int colorHex;
  final String? hotkey;
  final bool isLoop;
  final bool isPersistent;

  const SfxTrigger({
    required this.id,
    required this.title,
    required this.filePath,
    this.volume = 1.0,
    this.colorHex = 0xFF4A90E2, // Default Blue Accent
    this.hotkey,
    this.isLoop = false,
    this.isPersistent = false,
  });

  SfxTrigger copyWith({
    String? id,
    String? title,
    String? filePath,
    double? volume,
    int? colorHex,
    String? hotkey,
    bool? isLoop,
    bool? isPersistent,
  }) {
    return SfxTrigger(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      volume: volume ?? this.volume,
      colorHex: colorHex ?? this.colorHex,
      hotkey: hotkey ?? this.hotkey,
      isLoop: isLoop ?? this.isLoop,
      isPersistent: isPersistent ?? this.isPersistent,
    );
  }
}
