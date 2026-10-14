// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DnDisc';

  @override
  String get tabGmDashboard => 'GM Dashboard';

  @override
  String get tabLibrary => 'Media Library';

  @override
  String get tabSettings => 'Settings';

  @override
  String get tabCatalog => 'Catalog';

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
  String get languageRussian => 'Russian';

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
  String get presetPacksTitle => 'Preset Bundles (ZIP)';

  @override
  String get presetPacksSubtitle =>
      'Export your scenes and tracks into a single archive to share with other GMs or import ready-made adventure bundles.';

  @override
  String get importPresetBtn => 'Import Preset (ZIP)';

  @override
  String get exportPresetBtn => 'Export Preset to (ZIP)';

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
  String get createThemeBtn => 'Create new theme';

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
  String get scenesTitle => 'Scenes';

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
  String get sfx => 'SFX';

  @override
  String get scenes => 'Scenes';

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

  @override
  String get playPause => 'Play / Pause';

  @override
  String get playing => 'Playing';

  @override
  String get paused => 'Paused';

  @override
  String get noMusic => 'No music';

  @override
  String get noMusicSilence => 'No music (silence)';

  @override
  String get noMusicDesc =>
      'When activating the scene, background music smoothly fades out';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get ambientLayers => 'Ambient Layers (Background Sounds)';

  @override
  String get addAmbientTooltip => 'Add Layer / Persistent Ambient';

  @override
  String get stopAll => 'Stop All';

  @override
  String get noActiveAmbients =>
      'No active ambients. Click \"+\" to add a persistent background sound.';

  @override
  String get addPersistentAmbient => 'Add Persistent Ambient';

  @override
  String get volume => 'Volume';

  @override
  String get persistentLayerTooltip =>
      'Persistent layer (not reset when switching scenes)';

  @override
  String get makePersistentTooltip => 'Make persistent layer';

  @override
  String get muteLayerTooltip => 'Mute layer';

  @override
  String get unmuteLayerTooltip => 'Unmute layer';

  @override
  String get removeLayerTooltip => 'Remove layer';

  @override
  String get addAmbientDialogTitle => 'Add Ambient Layer';

  @override
  String get selectTrackFromLibrary => 'Select a track from the media library:';

  @override
  String get selectLocalAudioFile => 'Choose local audio file...';

  @override
  String get selected => 'Selected: ';

  @override
  String get persistentLayerCheckbox =>
      'Persistent layer (do not reset on scene change)';

  @override
  String get addLayerBtn => 'Add Layer';

  @override
  String get soundboardTitle => 'SFX Quick-Trigger';

  @override
  String get addSfxTooltip => 'Add SFX / Persistent Button';

  @override
  String get sfxVolume => 'SFX Volume: ';

  @override
  String get soundboardEmpty =>
      'Soundboard is empty. Add SFX or persistent quick buttons.';

  @override
  String get addPersistentSfx => 'Add Persistent SFX';

  @override
  String get unpinSfx => 'Unpin (make temporary)';

  @override
  String get pinSfx => 'Pin as persistent SFX';

  @override
  String get deleteSfxButton => 'Delete SFX button';

  @override
  String get addSfxDialogTitle => 'Add SFX Button';

  @override
  String get selectSoundFromLibrary => 'Select a sound from library:';

  @override
  String get persistentSfxCheckbox =>
      'Persistent SFX (do not reset on scene change)';

  @override
  String get loopModeCheckbox => 'Loop Mode';

  @override
  String get addSfxBtn => 'Add SFX';

  @override
  String get exportScenePackTooltip => 'Export Scene Bundles (.pack.zip)';

  @override
  String get searchScenesPlaceholder => 'Search scenes...';

  @override
  String get noScenesMatching => 'No scenes found matching your search.';

  @override
  String get saveSceneAs => 'Save scene as...';

  @override
  String sceneExported(String name) {
    return 'Scene \"$name\" exported!';
  }

  @override
  String sceneExportError(String error) {
    return 'Error exporting scene: $error';
  }

  @override
  String get exportScenePackTitle => 'Export Bundle (.pack.zip)';

  @override
  String get packTitleLabel => 'Bundle Name';

  @override
  String get packDescLabel => 'Bundle Description';

  @override
  String get defaultPackTitle => 'Adventure Bundle';

  @override
  String get defaultPackDesc => 'Atmospheric scenes collection';

  @override
  String get savePackAs => 'Save Bundle as...';

  @override
  String packExported(String name) {
    return 'Bundle \"$name\" successfully exported!';
  }

  @override
  String packExportError(String error) {
    return 'Error exporting bundle: $error';
  }

  @override
  String get exportSceneMenu => 'Export (.scene.zip)';

  @override
  String get currentSceneBadge => 'CURRENT SCENE';

  @override
  String get selectScenePrompt =>
      'Select a scene to set up the game environment';

  @override
  String get musicIntensityLabel => 'Music Intensity';

  @override
  String get createSceneTitle => 'Create New Scene';

  @override
  String get editSceneTitle => 'Edit Scene';

  @override
  String get sceneNameLabel => 'Scene Name *';

  @override
  String get sceneNameHint => 'e.g. Tavern \"The Drunken Dragon\"';

  @override
  String get sceneDescLabel => 'Atmosphere Description / GM Notes';

  @override
  String get sceneDescHint => 'Warm fireplace, clinking mugs, quiet lute...';

  @override
  String get sceneCoverLabel => 'Image / Cover Art Path';

  @override
  String get browseBtn => 'Browse';

  @override
  String get colorAccent => 'Color Accent:';

  @override
  String get musicChannel => 'Music Channel';

  @override
  String get ambientChannel => 'Ambient Channel';

  @override
  String get sfxChannel => 'SFX Channel (Soundboard)';

  @override
  String get searchMusicHint => 'Search music by title or tags...';

  @override
  String get searchAmbientHint => 'Search ambient by title or tags...';

  @override
  String get searchSfxHint => 'Search SFX by title or tags...';

  @override
  String layersSelected(int count) {
    return '$count layers selected';
  }

  @override
  String sfxSelected(int count) {
    return '$count SFX selected';
  }

  @override
  String get specifySceneName => 'Please specify scene name';

  @override
  String get createCustomThemeTitle => 'Create Custom Theme';

  @override
  String get editCustomThemeTitle => 'Edit Theme';

  @override
  String get themeNameLabel => 'Theme Name';

  @override
  String get themeNameRequired => 'Please specify theme name';

  @override
  String get baseOnPreset => 'Base on Preset';

  @override
  String get baseOnPresetTooltip => 'Use preset as template';

  @override
  String get themePreviewTitle => 'Theme Preview';

  @override
  String get duckingActive => 'Ducking Active';

  @override
  String get cardExampleTitle => 'Sample Card';

  @override
  String get cardExampleDesc =>
      'Scene or track description in the selected color palette.';

  @override
  String get colorPaletteConfig => 'Color Palette Settings';

  @override
  String colorPickTitle(String title) {
    return 'Color Choice: $title';
  }

  @override
  String get saveThemeBtn => 'Save Theme';

  @override
  String get newThemeDefaultName => 'New Theme';

  @override
  String get editTrackTitle => 'Edit Audio Track';

  @override
  String get trackTitleLabel => 'Track Title';

  @override
  String get targetAudioBus => 'Target Audio Bus:';

  @override
  String get musicIntensitySetting => 'Music Intensity Level:';

  @override
  String get tagsLabel => 'Tags (comma separated)';

  @override
  String get tagsHint => 'Tavern, Battle, Forest, Magic';

  @override
  String get colorLabel => 'Color Badge:';

  @override
  String get exportMediaPackageBtn => 'Export Set';

  @override
  String get selectBusForImport => 'Select target audio bus for imported files';

  @override
  String get exportMediaPackageTitle => 'Export Media Package (.media.zip)';

  @override
  String get mediaPackageNameLabel => 'Package Name';

  @override
  String get mediaPackageDescLabel => 'Package Description';

  @override
  String get defaultMediaPackageName => 'My Media Package';

  @override
  String get defaultMediaPackageDesc => 'Audio tracks collection';

  @override
  String get saveMediaPackageAs => 'Save media package as...';

  @override
  String mediaPackageExported(String name) {
    return 'Media package \"$name\" successfully exported!';
  }

  @override
  String mediaPackageExportError(String error) {
    return 'Error exporting media package: $error';
  }

  @override
  String dispatchToBus(String bus) {
    return 'Play on $bus bus';
  }

  @override
  String dispatchedToBus(String bus, String title) {
    return 'Sent to $bus bus: \"$title\"';
  }

  @override
  String get deleteFromLibrary => 'Delete from library';

  @override
  String busInfo(String bus, String duration, String path) {
    return 'Bus: $bus | Duration: $duration | Path: $path';
  }

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get refreshCatalogTooltip => 'Refresh catalog';

  @override
  String get manageRepositoriesTooltip => 'Manage repositories';

  @override
  String get addRepositoryBtn => 'Add';

  @override
  String get searchCatalogPlaceholder => 'Search items in catalog...';

  @override
  String sourcesBtn(int count) {
    return 'Sources ($count)';
  }

  @override
  String get noRepositoriesConnected => 'No connected repositories';

  @override
  String get addRepositoryUrlHint =>
      'Add a link to GitLab, Dropbox or Webserver with repository.json manifest';

  @override
  String get addRepositoryDialogTitle => 'Add Repository';

  @override
  String get editRepositoryDialogTitle => 'Edit Repository';

  @override
  String manageRepositoriesTitle(int count) {
    return 'Manage Repositories ($count)';
  }

  @override
  String get repositoryUrlLabel => 'Repository URL (GitLab / Dropbox / HTTP)';

  @override
  String get repositoryNameOptionalLabel => 'Name (optional)';

  @override
  String get repositoryNameHint => 'Will be extracted from manifest if empty';

  @override
  String get repositoryDescOptionalLabel => 'Description (optional)';

  @override
  String get enterRepositoryUrl => 'Please enter repository URL';

  @override
  String get urlHttpPrefixValidation =>
      'URL must start with http:// or https://';

  @override
  String get enterRepositoryName => 'Please enter repository name';

  @override
  String get repositoryUpdated => 'Repository updated successfully';

  @override
  String get noConnectedRepositories => 'No connected repositories.';

  @override
  String get noCatalogItemsFound => 'No items found matching your query.';

  @override
  String get installedBadge => 'Installed';

  @override
  String get noDescription => 'No description';

  @override
  String scenesCount(int count) {
    return '$count scenes';
  }

  @override
  String tracksCount(int count) {
    return '$count tracks';
  }

  @override
  String get sizeUnknown => 'Size unknown';

  @override
  String sizeMb(String size) {
    return '$size MB';
  }

  @override
  String repositoryLabel(String name) {
    return 'Repository: $name';
  }

  @override
  String get scenesInPack => 'Scenes in Bundle';

  @override
  String get mediaSetContent => 'Media Set Content';

  @override
  String get sceneContent => 'Scene Content';

  @override
  String get tracksMissingInManifest => 'Track list is missing in manifest.';

  @override
  String get scenesMissingInManifest => 'Scene list is missing in manifest.';

  @override
  String channelLabel(String channel) {
    return 'Channel: $channel';
  }

  @override
  String downloadingAndImporting(String percent) {
    return 'Downloading and importing... $percent%';
  }

  @override
  String removeFromApp(String type) {
    return 'Remove $type';
  }

  @override
  String get installing => 'Installing...';

  @override
  String installItem(String type) {
    return 'Install $type';
  }

  @override
  String deleteItemConfirmTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String deleteItemConfirmMessage(String type, String name) {
    return 'Are you sure you want to delete $type \"$name\" and associated files from the application?';
  }

  @override
  String itemUninstalled(String type, String name) {
    return '$type \"$name\" successfully removed.';
  }

  @override
  String itemUninstallError(String type) {
    return 'Error removing $type.';
  }

  @override
  String itemInstalled(String type, String name) {
    return '$type \"$name\" successfully installed!';
  }

  @override
  String itemInstallError(String type) {
    return 'Error downloading $type.';
  }

  @override
  String get catalogStorageTitle => 'Catalog & Audio File Storage';

  @override
  String get catalogStorageDesc =>
      'Folder for downloading and extracting audio files from online repository catalog:';

  @override
  String get customDirectory => 'Custom Directory';

  @override
  String get defaultDirectory => 'Default Directory';

  @override
  String get defaultStoragePath => 'Default: Documents/audio_library';

  @override
  String get resetDefaultDirTooltip => 'Reset to default value';

  @override
  String get chooseFolderBtn => 'Choose folder';

  @override
  String get chooseFolderDialogTitle =>
      'Choose folder for catalog audio storage';

  @override
  String get storagePathReset => 'Storage path reset to default.';

  @override
  String storagePathUpdated(String path) {
    return 'Catalog storage folder updated: $path';
  }

  @override
  String get shortcutPlayPauseTitle => 'Play / Pause';

  @override
  String get shortcutPlayPauseDesc => 'Start or pause current music track';

  @override
  String get shortcutIntensityCalmTitle => 'Intensity: Calm';

  @override
  String get shortcutIntensityCalmDesc => 'Switch music mode to Calm';

  @override
  String get shortcutIntensitySuspenseTitle => 'Intensity: Suspense';

  @override
  String get shortcutIntensitySuspenseDesc => 'Switch music mode to Suspense';

  @override
  String get shortcutIntensityBattleTitle => 'Intensity: Battle';

  @override
  String get shortcutIntensityBattleDesc => 'Switch music mode to Battle';

  @override
  String get shortcutIntensityBossTitle => 'Intensity: Boss';

  @override
  String get shortcutIntensityBossDesc => 'Switch music mode to Boss';

  @override
  String shortcutSfxTitle(int index) {
    return 'SFX Slot $index';
  }

  @override
  String shortcutSfxDesc(int index) {
    return 'Trigger sound effect $index';
  }

  @override
  String get shortcutMasterMuteTitle => 'Mute Audio';

  @override
  String get shortcutMasterMuteDesc => 'Quick mute or unmute master audio';

  @override
  String get shortcutManualDuckingTitle => 'Manual Ducking';

  @override
  String get shortcutManualDuckingDesc => 'Duck music during speech';

  @override
  String get shortcutFullscreenTitle => 'Fullscreen Mode';

  @override
  String get shortcutFullscreenDesc => 'Toggle fullscreen display';

  @override
  String get deleteFromApp => 'Delete';

  @override
  String get repositoryNameLabel => 'Name';

  @override
  String get intensityCalm => 'Calm';

  @override
  String get intensitySuspense => 'Suspense';

  @override
  String get intensityBattle => 'Battle';

  @override
  String get intensityBoss => 'Boss';

  @override
  String get play => 'Play';

  @override
  String get catalogTypeScene => 'scene';

  @override
  String get catalogTypeMedia => 'media package';

  @override
  String get catalogTypePack => 'bundle';

  @override
  String get sceneTitle => 'Scene';

  @override
  String get mediaTitle => 'Media';

  @override
  String get packTitle => 'Bundle';

  @override
  String get catalogSceneBadge => '🎭 Scene';

  @override
  String get catalogMediaBadge => '🎵 Media';

  @override
  String get catalogPackBadge => '📦 Bundle';

  @override
  String get filterAll => 'All';

  @override
  String get filterScenes => '🎭 Scenes';

  @override
  String get filterMedia => '🎵 Media';

  @override
  String get filterPacks => '📦 Bundles';

  @override
  String repoStats(int scenes, int media, int packs) {
    return 'Scenes: $scenes | Media: $media | Bundles: $packs';
  }

  @override
  String get addRepositoryTooltip => 'Add repository';

  @override
  String get repositoryUrlHint => 'https://gitlab.com/user/repo';

  @override
  String get playTooltip => 'Play [Space]';

  @override
  String get pauseTooltip => 'Pause [Space]';

  @override
  String get loopingBadge => 'LOOPING';

  @override
  String get tagsPrefix => 'Tags: ';

  @override
  String get colorNamePrimary => 'Primary';

  @override
  String get colorNameSecondary => 'Secondary';

  @override
  String get colorNameBackground => 'Background';

  @override
  String get colorNameSurface => 'Surface';

  @override
  String get colorNameCard => 'Card';

  @override
  String get colorNameAccent => 'Accent';

  @override
  String get colorNameTextPrimary => 'Text Primary';

  @override
  String get colorNameTextSecondary => 'Text Secondary';

  @override
  String get colorNameDuckingBadge => 'Ducking Badge';

  @override
  String get colorNameBattleIntensity => 'Battle Intensity';

  @override
  String get colorNameBossIntensity => 'Boss Intensity';

  @override
  String get seconds => 'sec';

  @override
  String get milliseconds => 'ms';

  @override
  String get sfxQuickTrigger => 'SFX Quick-Trigger';

  @override
  String get activeMusicMode => 'Active music mode';

  @override
  String get musicModeOff => 'Off';

  @override
  String get musicModeExplore => 'Explore';

  @override
  String get musicModeCombat => 'Combat';

  @override
  String get musicModeVictory => 'Victory';

  @override
  String get optionsTooltip => 'Options';

  @override
  String get scenesQuickPicker => 'Scenes';

  @override
  String get sessionAudioDeck => 'Session Audio Deck';

  @override
  String get collapseSidebarTooltip => 'Collapse sidebar';

  @override
  String get expandSidebarTooltip => 'Expand sidebar';

  @override
  String get aboutTitle => 'About DnDisc';

  @override
  String get aboutDesc =>
      'Atmospheric audio engine, scene mixer, and soundboard player for TTRPG Game Masters.';

  @override
  String get appVersion => 'Version 1.0.0';
}
