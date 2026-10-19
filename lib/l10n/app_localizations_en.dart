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
  String get tabLibrary => 'Media library';

  @override
  String get tabSettings => 'Settings';

  @override
  String get tabCatalog => 'Catalog';

  @override
  String get muteTooltip => 'Mute';

  @override
  String get unmuteTooltip => 'Unmute';

  @override
  String get logConsoleTitle => 'Log console';

  @override
  String get clearLogs => 'Clear logs';

  @override
  String get noLogs => 'No logs';

  @override
  String get language => 'Interface language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageRussian => 'Russian';

  @override
  String get languageEnglish => 'English';

  @override
  String get musicFadeTitle => 'Music crossfade';

  @override
  String get ambientFadeTitle => 'Ambient crossfade';

  @override
  String get duckingTitle => 'Ducking';

  @override
  String get duckAttackTitle => 'Duck attack';

  @override
  String get duckAttackSubtitle =>
      'How fast the music fades down when an effect starts';

  @override
  String get duckReleaseTitle => 'Duck release';

  @override
  String get duckReleaseSubtitle => 'How fast the music returns to full volume';

  @override
  String get duckMultiplierTitle => 'Ducking depth';

  @override
  String get duckMultiplierSubtitle =>
      'Share of the music volume that stays while an effect plays';

  @override
  String get resetDefaultsBtn => 'Reset to defaults';

  @override
  String get customThemes => 'Custom themes';

  @override
  String get createThemeBtn => 'Create theme';

  @override
  String get hotkeysTitle => 'Shortcuts';

  @override
  String get hotkeysSubtitle => 'Work while the app window is focused';

  @override
  String get scenesTitle => 'Scenes';

  @override
  String get createSceneBtn => 'Create scene';

  @override
  String get noScenesHint =>
      'Create a scene to combine music, ambient layers and sound effects';

  @override
  String get libraryEmpty => 'Your library is empty';

  @override
  String get libraryEmptyHint => 'Import audio files to use them in scenes';

  @override
  String get importFilesBtn => 'Import files';

  @override
  String get music => 'Music';

  @override
  String get ambient => 'Ambient';

  @override
  String get sfx => 'SFX';

  @override
  String get scenes => 'Scenes';

  @override
  String get searchPlaceholder => 'Search by title or tag';

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
  String get musicTrack => 'Music track';

  @override
  String get stopMusic => 'Stop';

  @override
  String get noAmbientTracksInLibrary => 'No ambient tracks in the library';

  @override
  String get noSfxTracksInLibrary => 'No sound effects in the library';

  @override
  String get playing => 'Playing';

  @override
  String get paused => 'Paused';

  @override
  String get noMusic => 'No music';

  @override
  String get ambientLayers => 'Ambient layers';

  @override
  String get addAmbientTooltip => 'Add layer';

  @override
  String get stopAll => 'Stop all';

  @override
  String get volume => 'Volume';

  @override
  String get addAmbientDialogTitle => 'Add ambient layer';

  @override
  String get selected => 'Selected';

  @override
  String get persistentLayerCheckbox => 'Pin to every scene';

  @override
  String get addLayerBtn => 'Add layer';

  @override
  String get soundboardTitle => 'SFX';

  @override
  String get unpinSfx => 'Unpin';

  @override
  String get pinSfx => 'Pin to every scene';

  @override
  String get deleteSfxButton => 'Remove from soundboard';

  @override
  String get addSfxDialogTitle => 'Add sound effect';

  @override
  String get persistentSfxCheckbox => 'Pin to every scene';

  @override
  String get loopModeCheckbox => 'Loop';

  @override
  String get addSfxBtn => 'Add effect';

  @override
  String get searchScenesPlaceholder => 'Search scenes';

  @override
  String get noScenesMatching => 'Try a different name';

  @override
  String get saveSceneAs => 'Save scene as';

  @override
  String get exportScenePackTitle => 'Export bundle';

  @override
  String get packTitleLabel => 'Bundle name';

  @override
  String get packDescLabel => 'Description';

  @override
  String get defaultPackTitle => 'Adventure bundle';

  @override
  String get defaultPackDesc => 'Atmospheric scenes collection';

  @override
  String get savePackAs => 'Save bundle as';

  @override
  String get selectScenePrompt => 'Select a scene to set up the table';

  @override
  String get musicIntensityLabel => 'Music intensity';

  @override
  String get createSceneTitle => 'Create scene';

  @override
  String get editSceneTitle => 'Edit scene';

  @override
  String get sceneNameLabel => 'Scene name';

  @override
  String get sceneNameHint => 'Harbor at dusk';

  @override
  String get specifySceneName => 'Enter a name for the scene';

  @override
  String get createCustomThemeTitle => 'Create theme';

  @override
  String get editCustomThemeTitle => 'Edit theme';

  @override
  String get themeNameLabel => 'Theme name';

  @override
  String get themeNameRequired => 'Enter a theme name';

  @override
  String get baseOnPreset => 'Start from a preset';

  @override
  String colorPickTitle(String title) {
    return 'Choose color: $title';
  }

  @override
  String get saveThemeBtn => 'Save theme';

  @override
  String get newThemeDefaultName => 'New theme';

  @override
  String get editTrackTitle => 'Edit details';

  @override
  String get trackTitleLabel => 'Title';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get tagsHint => 'Comma separated, for example tavern, battle';

  @override
  String get exportMediaPackageBtn => 'Export set';

  @override
  String get exportMediaPackageTitle => 'Export set';

  @override
  String get mediaPackageNameLabel => 'Set name';

  @override
  String get mediaPackageDescLabel => 'Description';

  @override
  String get defaultMediaPackageName => 'My media set';

  @override
  String get defaultMediaPackageDesc => 'Audio tracks collection';

  @override
  String get saveMediaPackageAs => 'Save set as';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get refreshCatalogTooltip => 'Refresh';

  @override
  String get searchCatalogPlaceholder => 'Search the catalog';

  @override
  String sourcesBtn(int count) {
    return 'Sources · $count';
  }

  @override
  String get urlHttpPrefixValidation => 'Enter a full https:// address';

  @override
  String get noCatalogItemsFound => 'Try another name or switch the filter';

  @override
  String get installedBadge => 'Installed';

  @override
  String get noDescription => 'No description';

  @override
  String scenesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scenes',
      one: '1 scene',
    );
    return '$_temp0';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get sizeUnknown => 'Size unknown';

  @override
  String sizeMb(String size) {
    return '$size MB';
  }

  @override
  String repositoryLabel(String name) {
    return 'Source: $name';
  }

  @override
  String get scenesInPack => 'Scenes in the bundle';

  @override
  String get mediaSetContent => 'Media pack contents';

  @override
  String get sceneContent => 'Scene contents';

  @override
  String get tracksMissingInManifest => 'The manifest has no track list';

  @override
  String get scenesMissingInManifest => 'The manifest has no scene list';

  @override
  String get removeFromApp => 'Remove from app';

  @override
  String get installItem => 'Install';

  @override
  String get catalogStorageDesc =>
      'Folder for audio files downloaded from the catalog';

  @override
  String get customDirectory => 'Custom folder';

  @override
  String get defaultDirectory => 'Default folder';

  @override
  String get defaultStoragePath => 'Documents/audio_library';

  @override
  String get resetDefaultDirTooltip => 'Reset to default';

  @override
  String get chooseFolderBtn => 'Choose folder';

  @override
  String get chooseFolderDialogTitle => 'Choose a folder for catalog audio';

  @override
  String get shortcutPlayPauseTitle => 'Play / pause';

  @override
  String get shortcutPlayPauseDesc => 'Current music track';

  @override
  String get shortcutIntensityCalmTitle => 'Calm';

  @override
  String get shortcutIntensityCalmDesc => 'Switch music mode to Calm';

  @override
  String get shortcutIntensitySuspenseTitle => 'Suspense';

  @override
  String get shortcutIntensitySuspenseDesc => 'Switch music mode to Suspense';

  @override
  String get shortcutIntensityBattleTitle => 'Battle';

  @override
  String get shortcutIntensityBattleDesc => 'Switch music mode to Battle';

  @override
  String get shortcutIntensityBossTitle => 'Boss';

  @override
  String get shortcutIntensityBossDesc => 'Switch music mode to Boss';

  @override
  String shortcutSfxTitle(int index) {
    return 'SFX slot $index';
  }

  @override
  String shortcutSfxDesc(int index) {
    return 'Play sound effect $index';
  }

  @override
  String get shortcutMasterMuteTitle => 'Mute master';

  @override
  String get shortcutMasterMuteDesc => 'Quick mute or unmute';

  @override
  String get shortcutFullscreenTitle => 'Fullscreen';

  @override
  String get shortcutFullscreenDesc => 'Toggle fullscreen mode';

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
  String get catalogSceneBadge => 'Scene';

  @override
  String get catalogMediaBadge => 'Media pack';

  @override
  String get catalogPackBadge => 'Bundle';

  @override
  String get filterAll => 'All';

  @override
  String get filterScenes => 'Scenes';

  @override
  String get filterMedia => 'Media';

  @override
  String get filterPacks => 'Bundles';

  @override
  String get playTooltip => 'Play';

  @override
  String get pauseTooltip => 'Pause';

  @override
  String get colorNamePrimary => 'Accent';

  @override
  String get colorNameBackground => 'Background';

  @override
  String get colorNameSurface => 'Panels';

  @override
  String get seconds => 's';

  @override
  String get milliseconds => 'ms';

  @override
  String get collapseSidebarTooltip => 'Collapse sidebar';

  @override
  String get expandSidebarTooltip => 'Expand sidebar';

  @override
  String get aboutDesc => 'Audio engine for tabletop game masters';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get master => 'Master';

  @override
  String get close => 'Close';

  @override
  String get moreActions => 'More actions';

  @override
  String get showScenes => 'Show scenes';

  @override
  String get openNavigation => 'Open navigation';

  @override
  String get channelVolumes => 'Channel volumes';

  @override
  String get noScenesTitle => 'No scenes yet';

  @override
  String get noScenesFoundTitle => 'No scenes found';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get editDetails => 'Edit details';

  @override
  String get exportAction => 'Export';

  @override
  String ambientCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ambient',
      one: '$count ambient',
    );
    return '$_temp0';
  }

  @override
  String sfxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SFX',
      one: '$count SFX',
    );
    return '$_temp0';
  }

  @override
  String sceneMeta(String intensity, String layers, String sfx) {
    return '$intensity · $layers · $sfx';
  }

  @override
  String get deleteSceneTitle => 'Delete scene?';

  @override
  String deleteSceneMessage(String name) {
    return '$name and its layout will be removed. Audio files stay in the library.';
  }

  @override
  String get exportBundleTooltip => 'Export all scenes as a bundle';

  @override
  String get toastSceneExported => 'Scene exported';

  @override
  String get toastBundleExported => 'Bundle exported';

  @override
  String get toastExportFailed => 'Export failed';

  @override
  String ambientOnCount(int on, int total) {
    return '$on of $total on';
  }

  @override
  String get stopAllLayers => 'Stop all layers';

  @override
  String get noAmbientTitle => 'No ambient layers';

  @override
  String get noAmbientHint =>
      'Add a layer to play rain, wind or a crowd under the music';

  @override
  String get addAmbientLayer => 'Add layer';

  @override
  String get pinEverywhere => 'Pin to every scene';

  @override
  String get removeLayer => 'Remove layer';

  @override
  String get addAmbientDialogDesc => 'Pick a track from the library or a file';

  @override
  String get fromLibrary => 'From library';

  @override
  String get chooseLocalFile => 'Choose a file';

  @override
  String get soundIcon => 'Icon';

  @override
  String get persistentLayerDesc =>
      'The layer keeps playing when the scene changes';

  @override
  String get filterLibrary => 'Filter library';

  @override
  String get addSfxSlot => 'Add sound effect';

  @override
  String get addSfxDialogDesc => 'Pick a sound from the library or a file';

  @override
  String get persistentSfxDesc =>
      'The tile stays on the soundboard when the scene changes';

  @override
  String get loopModeDesc => 'The sound repeats until you press the tile again';

  @override
  String get createSceneDesc => 'Name, cover, starting intensity and sounds';

  @override
  String get coverLabel => 'Cover';

  @override
  String get coverHint =>
      'Picked at random if you skip it. Your own image replaces it.';

  @override
  String get uploadCover => 'Upload';

  @override
  String get startingIntensity => 'Starting intensity';

  @override
  String soundsSelected(int count) {
    return 'Sounds · $count selected';
  }

  @override
  String get soundsHint => 'Music, ambient layers and SFX tiles';

  @override
  String get noSoundsFound => 'No sounds found';

  @override
  String get everythingEditableLater => 'Everything can be changed later';

  @override
  String get saveBtn => 'Save';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMessage => 'This form has unsaved changes.';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get importBtn => 'Import';

  @override
  String get noTracksFound => 'Nothing found';

  @override
  String get noTracksFoundHint => 'Try another title or tag';

  @override
  String get previewTrack => 'Preview';

  @override
  String get stopPreview => 'Stop';

  @override
  String get locateFile => 'Locate file';

  @override
  String get fileMissing => 'File missing';

  @override
  String get deleteTrackTitle => 'Delete track?';

  @override
  String deleteTrackMessage(String title) {
    return '$title will be removed from the library. The audio file stays on disk.';
  }

  @override
  String get importDialogTitle => 'Import audio';

  @override
  String get importDialogDesc => 'Choose the channel and add files';

  @override
  String get importTarget => 'Channel';

  @override
  String get dropFilesTitle => 'Drop audio files here';

  @override
  String get dropFilesHint => 'MP3, WAV, OGG, FLAC or M4A, or click to browse';

  @override
  String get releaseToImport => 'Release to import';

  @override
  String importNFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count files',
      one: 'Import 1 file',
      zero: 'Import',
    );
    return '$_temp0';
  }

  @override
  String get removeFromList => 'Remove from list';

  @override
  String toastImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count files',
      one: 'Imported 1 file',
    );
    return '$_temp0';
  }

  @override
  String toastImportSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files were skipped: not an audio format',
      one: '1 file was skipped: not an audio format',
    );
    return '$_temp0';
  }

  @override
  String get trackTypeLabel => 'Type';

  @override
  String get intensityLabel => 'Intensity';

  @override
  String get filePathLabel => 'File';

  @override
  String get toastMediaPackageExported => 'Set exported';

  @override
  String get addSourceBtn => 'Add source';

  @override
  String get downloadingLabel => 'Downloading';

  @override
  String get viewDetails => 'Details';

  @override
  String removeItemTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeItemMessage =>
      'It and the files it installed will be removed from the app.';

  @override
  String get toastInstalled => 'Installed';

  @override
  String get toastInstallFailed => 'Install failed';

  @override
  String get toastInstallFailedHint => 'Check the connection and try again';

  @override
  String get toastRemoved => 'Removed';

  @override
  String get toastRemoveFailed => 'Could not remove';

  @override
  String get sourcesDialogTitle => 'Sources';

  @override
  String get sourcesDialogDesc => 'Repositories the catalog reads from';

  @override
  String get addSourceTitle => 'Add source';

  @override
  String get editSourceTitle => 'Edit source';

  @override
  String get sourceUrlLabel => 'Address';

  @override
  String get sourceUrlHint => 'https://gitlab.com/user/repo';

  @override
  String get sourceNameLabel => 'Name';

  @override
  String get sourceNameHint => 'Taken from the manifest if empty';

  @override
  String get sourceDescLabel => 'Description';

  @override
  String get enterSourceUrl => 'Enter the source address';

  @override
  String get enterSourceName => 'Enter a name';

  @override
  String sourceStats(int scenes, int media, int packs) {
    return 'Scenes $scenes · Media $media · Bundles $packs';
  }

  @override
  String get deleteSourceTitle => 'Remove source?';

  @override
  String deleteSourceMessage(String name) {
    return '$name will no longer be listed in the catalog. Installed items stay.';
  }

  @override
  String get noSourcesTitle => 'No sources connected';

  @override
  String get noSourcesHint =>
      'Add a link to GitLab, Dropbox or a web server with a repository.json manifest';

  @override
  String get sourceUnavailableTitle => 'Source unavailable';

  @override
  String get sourceUnavailableHint => 'Check the connection and try again';

  @override
  String get retry => 'Retry';

  @override
  String get noCatalogItemsTitle => 'Nothing found';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceDesc =>
      'Theme applies to every screen. Custom themes are checked for contrast in the editor.';

  @override
  String get customThemeTag => 'Custom';

  @override
  String get deleteThemeTitle => 'Delete theme?';

  @override
  String deleteThemeMessage(String name) {
    return '$name will be removed. If it is active, the app switches to Deep Dark.';
  }

  @override
  String get audioTitle => 'Audio';

  @override
  String get duckingDesc => 'Music drops while a sound effect plays';

  @override
  String get storageTitle => 'Storage';

  @override
  String get toastStoragePathUpdated => 'Storage folder updated';

  @override
  String get toastStoragePathReset => 'Storage folder reset to default';

  @override
  String get shortcutGroupPlayback => 'Playback';

  @override
  String get shortcutGroupIntensity => 'Intensity';

  @override
  String get shortcutGroupSfx => 'SFX slots';

  @override
  String get shortcutSfxSlotsDesc => 'Slots 2–9 follow the same pattern';

  @override
  String get openLogs => 'Open logs';

  @override
  String get toastSettingsReset => 'Settings reset to defaults';

  @override
  String get themeEditorDesc => 'Pick eight colors, the rest is calculated';

  @override
  String get colorNameText => 'Text';

  @override
  String get hexLabel => 'Hex color';

  @override
  String get hexInvalid => 'Enter a color like #D4A373';

  @override
  String get contrastChecksTitle => 'Contrast checks';

  @override
  String get contrastTextBg => 'Text on background';

  @override
  String get contrastTextSurface => 'Text on panels';

  @override
  String get contrastPrimaryBg => 'Accent on background';

  @override
  String get contrastPrimarySurface => 'Accent on panels';

  @override
  String contrastIntensityOnSurface(String name) {
    return '$name on panels';
  }

  @override
  String get contrastFix => 'Fix';

  @override
  String get contrastWarning =>
      'Some pairs are below the readable minimum. You can still save the theme.';

  @override
  String get contrastOk => 'Ok';

  @override
  String get orWord => 'or';

  @override
  String get choosePreset => 'Choose a preset';

  @override
  String get outputDeviceLabel => 'Output device';

  @override
  String get outputDeviceDefault => 'System default';

  @override
  String outputDeviceMissing(String name) {
    return '$name is not connected, sound goes to the system default';
  }

  @override
  String get refreshDevices => 'Refresh device list';

  @override
  String get toastOutputDeviceFailed => 'Could not switch the output device';

  @override
  String toastCannotPlay(String name) {
    return 'Could not play $name';
  }

  @override
  String get toastCannotPlayHint =>
      'The file is damaged or its format is not supported';

  @override
  String get toastM4aNeedsFfmpeg =>
      'M4A on Linux needs the FFmpeg libraries (libavcodec, libavformat)';

  @override
  String get toastOutputDeviceFailedHint =>
      'Sound is not reaching the output device. Pick another device in Settings or check the system sound settings';
}
