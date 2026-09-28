// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TTRPG Audio Master';

  @override
  String get tabGmDashboard => 'GM Dashboard';

  @override
  String get tabLibrary => 'Media Library';

  @override
  String get tabSettings => 'Settings';

  @override
  String get manualDuckingTooltip => 'Manual Ducking [D]';

  @override
  String get muteTooltip => 'Mute [M]';

  @override
  String get unmuteTooltip => 'Unmute [M]';

  @override
  String get fullscreenTooltip => 'Fullscreen [F11]';

  @override
  String get logConsoleTooltip => 'Open log and debug console';

  @override
  String get logConsoleTitle => 'Log Console';

  @override
  String get clearLogs => 'Clear logs';

  @override
  String get noLogs => 'No logs';

  @override
  String get language => 'Interface Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTitle => 'Audio Engine Settings';

  @override
  String get settingsSubtitle =>
      'Themes, shortcuts, audio engine and preset management';

  @override
  String get fadeEngineTitle => 'Fade Engine';

  @override
  String get musicFadeTitle => 'Music fade in/out duration';

  @override
  String get ambientFadeTitle => 'Ambient fade in/out duration';

  @override
  String get duckingTitle => 'Auto-ducking music during SFX (Ducking)';

  @override
  String get duckAttackTitle => 'Duck Attack Time';

  @override
  String get duckAttackSubtitle => 'music fade-down speed when SFX triggers';

  @override
  String get duckReleaseTitle => 'Duck Release Time';

  @override
  String get duckReleaseSubtitle => 'music fade-up speed to full volume';

  @override
  String get duckMultiplierTitle => 'Ducking Depth';

  @override
  String get duckMultiplierSubtitle => 'of original music volume';

  @override
  String get presetPacksTitle => 'Preset Packs (ZIP Archives)';

  @override
  String get presetPacksSubtitle =>
      'Export your scenes and tracks into a single archive to share with other GMs or import ready-made adventure packs.';

  @override
  String get importPresetBtn => 'Import Preset (ZIP)';

  @override
  String get exportPresetBtn => 'Export Preset to ZIP';

  @override
  String get interfaceTitle => 'Interface & Control Panel';

  @override
  String get showLogConsoleTitle => 'Show log console icon';

  @override
  String get showLogConsoleSubtitle =>
      'Show quick toggle button for log console in top header';

  @override
  String get resetDefaultsBtn => 'Reset all settings to defaults';

  @override
  String get settingsResetToast => 'Audio engine settings reset.';

  @override
  String get themesTitle => 'App Themes';

  @override
  String get builtinThemes => 'Built-in Presets (5 variants)';

  @override
  String get customThemes => 'Custom Themes';

  @override
  String get noCustomThemes =>
      'You don\'t have custom themes yet. Create your own theme with a custom palette!';

  @override
  String get createThemeBtn => '+ Create new theme';

  @override
  String get hotkeysTitle => 'Centralized Shortcuts';

  @override
  String get hotkeysSubtitle =>
      'Control soundscape during game session without distraction:';

  @override
  String get actionCol => 'Action';

  @override
  String get descriptionCol => 'Description';

  @override
  String get keyCol => 'Key';

  @override
  String get scenesTitle => 'Atmospheric Scenes';

  @override
  String get createSceneBtn => 'Create Scene';

  @override
  String get noScenesHint =>
      'No scenes created yet. Click \"Create Scene\" to combine music and ambients.';

  @override
  String get activeBadge => 'ACTIVE';

  @override
  String get enableSceneBtn => 'Enable';

  @override
  String get libraryTitle => 'Media Library';

  @override
  String get libraryEmpty => 'Media library is empty';

  @override
  String get libraryEmptyHint =>
      'Click \"Import Files\" to add music, ambient or SFX.';

  @override
  String get importFilesBtn => 'Import Files';

  @override
  String get allSounds => 'All Sounds';

  @override
  String get music => 'Music';

  @override
  String get ambient => 'Ambient';

  @override
  String get sfx => 'SFX Effect';

  @override
  String get searchPlaceholder =>
      'Search by title or tags (e.g., Tavern, Battle)...';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get export => 'Export';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get musicNotPlaying => 'Music is not playing';

  @override
  String get musicTrack => 'Music Track';

  @override
  String get intensityLevel => 'Intensity Level';

  @override
  String get stopMusic => 'Stop music';

  @override
  String get pausedSuffix => '(Paused)';

  @override
  String get noAmbientTracksInLibrary => 'No ambient tracks in the library.';

  @override
  String get noSfxTracksInLibrary => 'No SFX tracks in the library.';
}
