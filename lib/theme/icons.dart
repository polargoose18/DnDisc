/// Registry of the 65 DnDisc icons: key -> asset path. The key of a sound or
/// layer icon is stored in the library (`icon` column).
abstract class DnDiscIcons {
  static const String defaultKey = 'bolt';
  static const String defaultSfx = 'bolt';
  static const String defaultAmbient = 'waves';

  static const List<String> service = [
    'play',
    'pause',
    'stop',
    'plus',
    'x',
    'check',
    'check-circle',
    'search',
    'volume',
    'mute',
    'more',
    'pin',
    'bolt',
    'music',
    'waves',
    'dashboard',
    'library',
    'catalog',
    'bundle',
    'settings',
    'scene',
    'panel-left',
    'refresh',
    'upload',
    'download',
    'archive',
    'edit',
    'trash',
    'keyboard',
    'palette',
    'terminal',
    'clock',
    'alert',
    'info',
    'chevron-down',
    'chevron-right',
    'loop',
  ];

  /// 16 icons a user can pick for an SFX tile.
  static const List<String> sfx = [
    'door',
    'chains',
    'skull',
    'growl',
    'stone',
    'flame',
    'coins',
    'sword',
    'dragon',
    'thunder',
    'steps',
    'whisper',
    'arrow',
    'shield',
    'spell',
    'potion',
  ];

  /// 12 icons a user can pick for an ambient layer.
  static const List<String> ambient = [
    'rain',
    'wind',
    'forest',
    'campfire',
    'sea',
    'cave',
    'tavern',
    'night',
    'crowd',
    'swamp',
    'birds',
    'snow',
  ];

  static final Map<String, String> paths = {
    for (final key in [...service, ...sfx, ...ambient]) key: 'assets/icons/$key.svg',
  };

  static bool contains(String? key) => key != null && paths.containsKey(key);

  /// Asset path of [key]; unknown or null keys show the default icon.
  static String pathOf(String? key) => paths[contains(key) ? key : defaultKey]!;
}
