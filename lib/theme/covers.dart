/// The seven default scene covers (`assets/covers/<key>.svg`, 1600x400).
abstract class SceneCovers {
  static const List<String> keys = ['peaks', 'tower', 'forest', 'sea', 'gate', 'dunes', 'village'];

  static bool contains(String? key) => key != null && keys.contains(key);

  static String pathOf(String key) => 'assets/covers/$key.svg';

  /// Cover for a seed (scene id, title): the same seed always gives the same cover.
  static String forSeed(String seed) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return keys[hash % keys.length];
  }
}
