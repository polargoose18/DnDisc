import 'dart:math';
import '../../theme/covers.dart';

/// Chooses default covers for scenes. The choice is made once, when a scene
/// is created, and stored in the scene's `cover` column.
class SceneCoverService {
  final Random _random;

  SceneCoverService({Random? random}) : _random = random ?? Random();

  String pickRandom() => SceneCovers.keys[_random.nextInt(SceneCovers.keys.length)];

  /// Stable choice for scenes that were created before covers existed.
  String pickForSeed(String seed) => SceneCovers.forSeed(seed);
}
