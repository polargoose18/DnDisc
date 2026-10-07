import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DnDisc'**
  String get appTitle;

  /// No description provided for @tabGmDashboard.
  ///
  /// In en, this message translates to:
  /// **'GM Dashboard'**
  String get tabGmDashboard;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Media Library'**
  String get tabLibrary;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @tabCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get tabCatalog;

  /// No description provided for @manualDuckingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manual Ducking [D]'**
  String get manualDuckingTooltip;

  /// No description provided for @muteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mute [M]'**
  String get muteTooltip;

  /// No description provided for @unmuteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unmute [M]'**
  String get unmuteTooltip;

  /// No description provided for @fullscreenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen [F11]'**
  String get fullscreenTooltip;

  /// No description provided for @logConsoleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open log and debug console'**
  String get logConsoleTooltip;

  /// No description provided for @logConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Console'**
  String get logConsoleTitle;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogs;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs'**
  String get noLogs;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Interface Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Engine Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Themes, shortcuts, audio engine and preset management'**
  String get settingsSubtitle;

  /// No description provided for @fadeEngineTitle.
  ///
  /// In en, this message translates to:
  /// **'Fade Engine'**
  String get fadeEngineTitle;

  /// No description provided for @musicFadeTitle.
  ///
  /// In en, this message translates to:
  /// **'Music fade in/out duration'**
  String get musicFadeTitle;

  /// No description provided for @ambientFadeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ambient fade in/out duration'**
  String get ambientFadeTitle;

  /// No description provided for @duckingTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-ducking music during SFX (Ducking)'**
  String get duckingTitle;

  /// No description provided for @duckAttackTitle.
  ///
  /// In en, this message translates to:
  /// **'Duck Attack Time'**
  String get duckAttackTitle;

  /// No description provided for @duckAttackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'music fade-down speed when SFX triggers'**
  String get duckAttackSubtitle;

  /// No description provided for @duckReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Duck Release Time'**
  String get duckReleaseTitle;

  /// No description provided for @duckReleaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'music fade-up speed to full volume'**
  String get duckReleaseSubtitle;

  /// No description provided for @duckMultiplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Ducking Depth'**
  String get duckMultiplierTitle;

  /// No description provided for @duckMultiplierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'of original music volume'**
  String get duckMultiplierSubtitle;

  /// No description provided for @presetPacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Preset Bundles (ZIP)'**
  String get presetPacksTitle;

  /// No description provided for @presetPacksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export your scenes and tracks into a single archive to share with other GMs or import ready-made adventure bundles.'**
  String get presetPacksSubtitle;

  /// No description provided for @importPresetBtn.
  ///
  /// In en, this message translates to:
  /// **'Import Preset (ZIP)'**
  String get importPresetBtn;

  /// No description provided for @exportPresetBtn.
  ///
  /// In en, this message translates to:
  /// **'Export Preset to (ZIP)'**
  String get exportPresetBtn;

  /// No description provided for @interfaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Interface & Control Panel'**
  String get interfaceTitle;

  /// No description provided for @showLogConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Show log console icon'**
  String get showLogConsoleTitle;

  /// No description provided for @showLogConsoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show quick toggle button for log console in top header'**
  String get showLogConsoleSubtitle;

  /// No description provided for @resetDefaultsBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings to defaults'**
  String get resetDefaultsBtn;

  /// No description provided for @settingsResetToast.
  ///
  /// In en, this message translates to:
  /// **'Audio engine settings reset.'**
  String get settingsResetToast;

  /// No description provided for @themesTitle.
  ///
  /// In en, this message translates to:
  /// **'App Themes'**
  String get themesTitle;

  /// No description provided for @builtinThemes.
  ///
  /// In en, this message translates to:
  /// **'Built-in Presets (5 variants)'**
  String get builtinThemes;

  /// No description provided for @customThemes.
  ///
  /// In en, this message translates to:
  /// **'Custom Themes'**
  String get customThemes;

  /// No description provided for @noCustomThemes.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have custom themes yet. Create your own theme with a custom palette!'**
  String get noCustomThemes;

  /// No description provided for @createThemeBtn.
  ///
  /// In en, this message translates to:
  /// **'Create new theme'**
  String get createThemeBtn;

  /// No description provided for @hotkeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Centralized Shortcuts'**
  String get hotkeysTitle;

  /// No description provided for @hotkeysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control soundscape during game session without distraction:'**
  String get hotkeysSubtitle;

  /// No description provided for @actionCol.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get actionCol;

  /// No description provided for @descriptionCol.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionCol;

  /// No description provided for @keyCol.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get keyCol;

  /// No description provided for @scenesTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get scenesTitle;

  /// No description provided for @createSceneBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Scene'**
  String get createSceneBtn;

  /// No description provided for @noScenesHint.
  ///
  /// In en, this message translates to:
  /// **'No scenes created yet. Click \"Create Scene\" to combine music and ambients.'**
  String get noScenesHint;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeBadge;

  /// No description provided for @enableSceneBtn.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableSceneBtn;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Media Library'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Media library is empty'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Click \"Import Files\" to add music, ambient or SFX.'**
  String get libraryEmptyHint;

  /// No description provided for @importFilesBtn.
  ///
  /// In en, this message translates to:
  /// **'Import Files'**
  String get importFilesBtn;

  /// No description provided for @allSounds.
  ///
  /// In en, this message translates to:
  /// **'All Sounds'**
  String get allSounds;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @ambient.
  ///
  /// In en, this message translates to:
  /// **'Ambient'**
  String get ambient;

  /// No description provided for @sfx.
  ///
  /// In en, this message translates to:
  /// **'SFX'**
  String get sfx;

  /// No description provided for @scenes.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get scenes;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by title or tags (e.g., Tavern, Battle)...'**
  String get searchPlaceholder;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @musicNotPlaying.
  ///
  /// In en, this message translates to:
  /// **'Music is not playing'**
  String get musicNotPlaying;

  /// No description provided for @musicTrack.
  ///
  /// In en, this message translates to:
  /// **'Music Track'**
  String get musicTrack;

  /// No description provided for @intensityLevel.
  ///
  /// In en, this message translates to:
  /// **'Intensity Level'**
  String get intensityLevel;

  /// No description provided for @stopMusic.
  ///
  /// In en, this message translates to:
  /// **'Stop music'**
  String get stopMusic;

  /// No description provided for @pausedSuffix.
  ///
  /// In en, this message translates to:
  /// **'(Paused)'**
  String get pausedSuffix;

  /// No description provided for @noAmbientTracksInLibrary.
  ///
  /// In en, this message translates to:
  /// **'No ambient tracks in the library.'**
  String get noAmbientTracksInLibrary;

  /// No description provided for @noSfxTracksInLibrary.
  ///
  /// In en, this message translates to:
  /// **'No SFX tracks in the library.'**
  String get noSfxTracksInLibrary;

  /// No description provided for @playPause.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause'**
  String get playPause;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @noMusic.
  ///
  /// In en, this message translates to:
  /// **'No music'**
  String get noMusic;

  /// No description provided for @noMusicSilence.
  ///
  /// In en, this message translates to:
  /// **'No music (silence)'**
  String get noMusicSilence;

  /// No description provided for @noMusicDesc.
  ///
  /// In en, this message translates to:
  /// **'When activating the scene, background music smoothly fades out'**
  String get noMusicDesc;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @ambientLayers.
  ///
  /// In en, this message translates to:
  /// **'Ambient Layers (Background Sounds)'**
  String get ambientLayers;

  /// No description provided for @addAmbientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Layer / Persistent Ambient'**
  String get addAmbientTooltip;

  /// No description provided for @stopAll.
  ///
  /// In en, this message translates to:
  /// **'Stop All'**
  String get stopAll;

  /// No description provided for @noActiveAmbients.
  ///
  /// In en, this message translates to:
  /// **'No active ambients. Click \"+\" to add a persistent background sound.'**
  String get noActiveAmbients;

  /// No description provided for @addPersistentAmbient.
  ///
  /// In en, this message translates to:
  /// **'Add Persistent Ambient'**
  String get addPersistentAmbient;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @persistentLayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Persistent layer (not reset when switching scenes)'**
  String get persistentLayerTooltip;

  /// No description provided for @makePersistentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Make persistent layer'**
  String get makePersistentTooltip;

  /// No description provided for @muteLayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mute layer'**
  String get muteLayerTooltip;

  /// No description provided for @unmuteLayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unmute layer'**
  String get unmuteLayerTooltip;

  /// No description provided for @removeLayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove layer'**
  String get removeLayerTooltip;

  /// No description provided for @addAmbientDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Ambient Layer'**
  String get addAmbientDialogTitle;

  /// No description provided for @selectTrackFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select a track from the media library:'**
  String get selectTrackFromLibrary;

  /// No description provided for @selectLocalAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Choose local audio file...'**
  String get selectLocalAudioFile;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected: '**
  String get selected;

  /// No description provided for @persistentLayerCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Persistent layer (do not reset on scene change)'**
  String get persistentLayerCheckbox;

  /// No description provided for @addLayerBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Layer'**
  String get addLayerBtn;

  /// No description provided for @soundboardTitle.
  ///
  /// In en, this message translates to:
  /// **'SFX Quick-Trigger'**
  String get soundboardTitle;

  /// No description provided for @addSfxTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add SFX / Persistent Button'**
  String get addSfxTooltip;

  /// No description provided for @panicStopBtn.
  ///
  /// In en, this message translates to:
  /// **'Panic Stop [Esc]'**
  String get panicStopBtn;

  /// No description provided for @sfxVolume.
  ///
  /// In en, this message translates to:
  /// **'SFX Volume: '**
  String get sfxVolume;

  /// No description provided for @soundboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Soundboard is empty. Add SFX or persistent quick buttons.'**
  String get soundboardEmpty;

  /// No description provided for @addPersistentSfx.
  ///
  /// In en, this message translates to:
  /// **'Add Persistent SFX'**
  String get addPersistentSfx;

  /// No description provided for @unpinSfx.
  ///
  /// In en, this message translates to:
  /// **'Unpin (make temporary)'**
  String get unpinSfx;

  /// No description provided for @pinSfx.
  ///
  /// In en, this message translates to:
  /// **'Pin as persistent SFX'**
  String get pinSfx;

  /// No description provided for @deleteSfxButton.
  ///
  /// In en, this message translates to:
  /// **'Delete SFX button'**
  String get deleteSfxButton;

  /// No description provided for @addSfxDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add SFX Button'**
  String get addSfxDialogTitle;

  /// No description provided for @selectSoundFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select a sound from library:'**
  String get selectSoundFromLibrary;

  /// No description provided for @persistentSfxCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Persistent SFX (do not reset on scene change)'**
  String get persistentSfxCheckbox;

  /// No description provided for @loopModeCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Loop Mode'**
  String get loopModeCheckbox;

  /// No description provided for @addSfxBtn.
  ///
  /// In en, this message translates to:
  /// **'Add SFX'**
  String get addSfxBtn;

  /// No description provided for @exportScenePackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export Scene Bundles (.pack.zip)'**
  String get exportScenePackTooltip;

  /// No description provided for @searchScenesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search scenes...'**
  String get searchScenesPlaceholder;

  /// No description provided for @noScenesMatching.
  ///
  /// In en, this message translates to:
  /// **'No scenes found matching your search.'**
  String get noScenesMatching;

  /// No description provided for @saveSceneAs.
  ///
  /// In en, this message translates to:
  /// **'Save scene as...'**
  String get saveSceneAs;

  /// No description provided for @sceneExported.
  ///
  /// In en, this message translates to:
  /// **'Scene \"{name}\" exported!'**
  String sceneExported(String name);

  /// No description provided for @sceneExportError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting scene: {error}'**
  String sceneExportError(String error);

  /// No description provided for @exportScenePackTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Bundle (.pack.zip)'**
  String get exportScenePackTitle;

  /// No description provided for @packTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Bundle Name'**
  String get packTitleLabel;

  /// No description provided for @packDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Bundle Description'**
  String get packDescLabel;

  /// No description provided for @defaultPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Adventure Bundle'**
  String get defaultPackTitle;

  /// No description provided for @defaultPackDesc.
  ///
  /// In en, this message translates to:
  /// **'Atmospheric scenes collection'**
  String get defaultPackDesc;

  /// No description provided for @savePackAs.
  ///
  /// In en, this message translates to:
  /// **'Save Bundle as...'**
  String get savePackAs;

  /// No description provided for @packExported.
  ///
  /// In en, this message translates to:
  /// **'Bundle \"{name}\" successfully exported!'**
  String packExported(String name);

  /// No description provided for @packExportError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting bundle: {error}'**
  String packExportError(String error);

  /// No description provided for @exportSceneMenu.
  ///
  /// In en, this message translates to:
  /// **'Export (.scene.zip)'**
  String get exportSceneMenu;

  /// No description provided for @currentSceneBadge.
  ///
  /// In en, this message translates to:
  /// **'CURRENT SCENE'**
  String get currentSceneBadge;

  /// No description provided for @selectScenePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a scene to set up the game environment'**
  String get selectScenePrompt;

  /// No description provided for @musicIntensityLabel.
  ///
  /// In en, this message translates to:
  /// **'Music Intensity'**
  String get musicIntensityLabel;

  /// No description provided for @createSceneTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Scene'**
  String get createSceneTitle;

  /// No description provided for @editSceneTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Scene'**
  String get editSceneTitle;

  /// No description provided for @sceneNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Scene Name *'**
  String get sceneNameLabel;

  /// No description provided for @sceneNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tavern \"The Drunken Dragon\"'**
  String get sceneNameHint;

  /// No description provided for @sceneDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Atmosphere Description / GM Notes'**
  String get sceneDescLabel;

  /// No description provided for @sceneDescHint.
  ///
  /// In en, this message translates to:
  /// **'Warm fireplace, clinking mugs, quiet lute...'**
  String get sceneDescHint;

  /// No description provided for @sceneCoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Image / Cover Art Path'**
  String get sceneCoverLabel;

  /// No description provided for @browseBtn.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseBtn;

  /// No description provided for @colorAccent.
  ///
  /// In en, this message translates to:
  /// **'Color Accent:'**
  String get colorAccent;

  /// No description provided for @musicChannel.
  ///
  /// In en, this message translates to:
  /// **'Music Channel'**
  String get musicChannel;

  /// No description provided for @ambientChannel.
  ///
  /// In en, this message translates to:
  /// **'Ambient Channel'**
  String get ambientChannel;

  /// No description provided for @sfxChannel.
  ///
  /// In en, this message translates to:
  /// **'SFX Channel (Soundboard)'**
  String get sfxChannel;

  /// No description provided for @searchMusicHint.
  ///
  /// In en, this message translates to:
  /// **'Search music by title or tags...'**
  String get searchMusicHint;

  /// No description provided for @searchAmbientHint.
  ///
  /// In en, this message translates to:
  /// **'Search ambient by title or tags...'**
  String get searchAmbientHint;

  /// No description provided for @searchSfxHint.
  ///
  /// In en, this message translates to:
  /// **'Search SFX by title or tags...'**
  String get searchSfxHint;

  /// No description provided for @layersSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} layers selected'**
  String layersSelected(int count);

  /// No description provided for @sfxSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} SFX selected'**
  String sfxSelected(int count);

  /// No description provided for @specifySceneName.
  ///
  /// In en, this message translates to:
  /// **'Please specify scene name'**
  String get specifySceneName;

  /// No description provided for @createCustomThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Theme'**
  String get createCustomThemeTitle;

  /// No description provided for @editCustomThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Theme'**
  String get editCustomThemeTitle;

  /// No description provided for @themeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme Name'**
  String get themeNameLabel;

  /// No description provided for @themeNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please specify theme name'**
  String get themeNameRequired;

  /// No description provided for @baseOnPreset.
  ///
  /// In en, this message translates to:
  /// **'Base on Preset'**
  String get baseOnPreset;

  /// No description provided for @baseOnPresetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Use preset as template'**
  String get baseOnPresetTooltip;

  /// No description provided for @themePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Preview'**
  String get themePreviewTitle;

  /// No description provided for @duckingActive.
  ///
  /// In en, this message translates to:
  /// **'Ducking Active'**
  String get duckingActive;

  /// No description provided for @cardExampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample Card'**
  String get cardExampleTitle;

  /// No description provided for @cardExampleDesc.
  ///
  /// In en, this message translates to:
  /// **'Scene or track description in the selected color palette.'**
  String get cardExampleDesc;

  /// No description provided for @colorPaletteConfig.
  ///
  /// In en, this message translates to:
  /// **'Color Palette Settings'**
  String get colorPaletteConfig;

  /// No description provided for @colorPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Choice: {title}'**
  String colorPickTitle(String title);

  /// No description provided for @saveThemeBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Theme'**
  String get saveThemeBtn;

  /// No description provided for @newThemeDefaultName.
  ///
  /// In en, this message translates to:
  /// **'New Theme'**
  String get newThemeDefaultName;

  /// No description provided for @editTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Audio Track'**
  String get editTrackTitle;

  /// No description provided for @trackTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Track Title'**
  String get trackTitleLabel;

  /// No description provided for @targetAudioBus.
  ///
  /// In en, this message translates to:
  /// **'Target Audio Bus:'**
  String get targetAudioBus;

  /// No description provided for @musicIntensitySetting.
  ///
  /// In en, this message translates to:
  /// **'Music Intensity Level:'**
  String get musicIntensitySetting;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get tagsLabel;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Tavern, Battle, Forest, Magic'**
  String get tagsHint;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color Badge:'**
  String get colorLabel;

  /// No description provided for @exportMediaPackageBtn.
  ///
  /// In en, this message translates to:
  /// **'Export Set'**
  String get exportMediaPackageBtn;

  /// No description provided for @selectBusForImport.
  ///
  /// In en, this message translates to:
  /// **'Select target audio bus for imported files'**
  String get selectBusForImport;

  /// No description provided for @exportMediaPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Media Package (.media.zip)'**
  String get exportMediaPackageTitle;

  /// No description provided for @mediaPackageNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Package Name'**
  String get mediaPackageNameLabel;

  /// No description provided for @mediaPackageDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Package Description'**
  String get mediaPackageDescLabel;

  /// No description provided for @defaultMediaPackageName.
  ///
  /// In en, this message translates to:
  /// **'My Media Package'**
  String get defaultMediaPackageName;

  /// No description provided for @defaultMediaPackageDesc.
  ///
  /// In en, this message translates to:
  /// **'Audio tracks collection'**
  String get defaultMediaPackageDesc;

  /// No description provided for @saveMediaPackageAs.
  ///
  /// In en, this message translates to:
  /// **'Save media package as...'**
  String get saveMediaPackageAs;

  /// No description provided for @mediaPackageExported.
  ///
  /// In en, this message translates to:
  /// **'Media package \"{name}\" successfully exported!'**
  String mediaPackageExported(String name);

  /// No description provided for @mediaPackageExportError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting media package: {error}'**
  String mediaPackageExportError(String error);

  /// No description provided for @dispatchToBus.
  ///
  /// In en, this message translates to:
  /// **'Play on {bus} bus'**
  String dispatchToBus(String bus);

  /// No description provided for @dispatchedToBus.
  ///
  /// In en, this message translates to:
  /// **'Sent to {bus} bus: \"{title}\"'**
  String dispatchedToBus(String bus, String title);

  /// No description provided for @deleteFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Delete from library'**
  String get deleteFromLibrary;

  /// No description provided for @busInfo.
  ///
  /// In en, this message translates to:
  /// **'Bus: {bus} | Duration: {duration} | Path: {path}'**
  String busInfo(String bus, String duration, String path);

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogTitle;

  /// No description provided for @refreshCatalogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh catalog'**
  String get refreshCatalogTooltip;

  /// No description provided for @manageRepositoriesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage repositories'**
  String get manageRepositoriesTooltip;

  /// No description provided for @addRepositoryBtn.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addRepositoryBtn;

  /// No description provided for @searchCatalogPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search items in catalog...'**
  String get searchCatalogPlaceholder;

  /// No description provided for @sourcesBtn.
  ///
  /// In en, this message translates to:
  /// **'Sources ({count})'**
  String sourcesBtn(int count);

  /// No description provided for @noRepositoriesConnected.
  ///
  /// In en, this message translates to:
  /// **'No connected repositories'**
  String get noRepositoriesConnected;

  /// No description provided for @addRepositoryUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Add a link to GitLab, Dropbox or Webserver with repository.json manifest'**
  String get addRepositoryUrlHint;

  /// No description provided for @addRepositoryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Repository'**
  String get addRepositoryDialogTitle;

  /// No description provided for @editRepositoryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Repository'**
  String get editRepositoryDialogTitle;

  /// No description provided for @manageRepositoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Repositories ({count})'**
  String manageRepositoriesTitle(int count);

  /// No description provided for @repositoryUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Repository URL (GitLab / Dropbox / HTTP)'**
  String get repositoryUrlLabel;

  /// No description provided for @repositoryNameOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get repositoryNameOptionalLabel;

  /// No description provided for @repositoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Will be extracted from manifest if empty'**
  String get repositoryNameHint;

  /// No description provided for @repositoryDescOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get repositoryDescOptionalLabel;

  /// No description provided for @enterRepositoryUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter repository URL'**
  String get enterRepositoryUrl;

  /// No description provided for @urlHttpPrefixValidation.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get urlHttpPrefixValidation;

  /// No description provided for @enterRepositoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter repository name'**
  String get enterRepositoryName;

  /// No description provided for @repositoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Repository updated successfully'**
  String get repositoryUpdated;

  /// No description provided for @noConnectedRepositories.
  ///
  /// In en, this message translates to:
  /// **'No connected repositories.'**
  String get noConnectedRepositories;

  /// No description provided for @noCatalogItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found matching your query.'**
  String get noCatalogItemsFound;

  /// No description provided for @installedBadge.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installedBadge;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @scenesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} scenes'**
  String scenesCount(int count);

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String tracksCount(int count);

  /// No description provided for @sizeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Size unknown'**
  String get sizeUnknown;

  /// No description provided for @sizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String sizeMb(String size);

  /// No description provided for @repositoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Repository: {name}'**
  String repositoryLabel(String name);

  /// No description provided for @scenesInPack.
  ///
  /// In en, this message translates to:
  /// **'Scenes in Bundle'**
  String get scenesInPack;

  /// No description provided for @mediaSetContent.
  ///
  /// In en, this message translates to:
  /// **'Media Set Content'**
  String get mediaSetContent;

  /// No description provided for @sceneContent.
  ///
  /// In en, this message translates to:
  /// **'Scene Content'**
  String get sceneContent;

  /// No description provided for @tracksMissingInManifest.
  ///
  /// In en, this message translates to:
  /// **'Track list is missing in manifest.'**
  String get tracksMissingInManifest;

  /// No description provided for @scenesMissingInManifest.
  ///
  /// In en, this message translates to:
  /// **'Scene list is missing in manifest.'**
  String get scenesMissingInManifest;

  /// No description provided for @channelLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel: {channel}'**
  String channelLabel(String channel);

  /// No description provided for @downloadingAndImporting.
  ///
  /// In en, this message translates to:
  /// **'Downloading and importing... {percent}%'**
  String downloadingAndImporting(String percent);

  /// No description provided for @removeFromApp.
  ///
  /// In en, this message translates to:
  /// **'Remove {type}'**
  String removeFromApp(String type);

  /// No description provided for @installing.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get installing;

  /// No description provided for @installItem.
  ///
  /// In en, this message translates to:
  /// **'Install {type}'**
  String installItem(String type);

  /// No description provided for @deleteItemConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteItemConfirmTitle(String name);

  /// No description provided for @deleteItemConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {type} \"{name}\" and associated files from the application?'**
  String deleteItemConfirmMessage(String type, String name);

  /// No description provided for @itemUninstalled.
  ///
  /// In en, this message translates to:
  /// **'{type} \"{name}\" successfully removed.'**
  String itemUninstalled(String type, String name);

  /// No description provided for @itemUninstallError.
  ///
  /// In en, this message translates to:
  /// **'Error removing {type}.'**
  String itemUninstallError(String type);

  /// No description provided for @itemInstalled.
  ///
  /// In en, this message translates to:
  /// **'{type} \"{name}\" successfully installed!'**
  String itemInstalled(String type, String name);

  /// No description provided for @itemInstallError.
  ///
  /// In en, this message translates to:
  /// **'Error downloading {type}.'**
  String itemInstallError(String type);

  /// No description provided for @catalogStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog & Audio File Storage'**
  String get catalogStorageTitle;

  /// No description provided for @catalogStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'Folder for downloading and extracting audio files from online repository catalog:'**
  String get catalogStorageDesc;

  /// No description provided for @customDirectory.
  ///
  /// In en, this message translates to:
  /// **'Custom Directory'**
  String get customDirectory;

  /// No description provided for @defaultDirectory.
  ///
  /// In en, this message translates to:
  /// **'Default Directory'**
  String get defaultDirectory;

  /// No description provided for @defaultStoragePath.
  ///
  /// In en, this message translates to:
  /// **'Default: Documents/audio_library'**
  String get defaultStoragePath;

  /// No description provided for @resetDefaultDirTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset to default value'**
  String get resetDefaultDirTooltip;

  /// No description provided for @chooseFolderBtn.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get chooseFolderBtn;

  /// No description provided for @chooseFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose folder for catalog audio storage'**
  String get chooseFolderDialogTitle;

  /// No description provided for @storagePathReset.
  ///
  /// In en, this message translates to:
  /// **'Storage path reset to default.'**
  String get storagePathReset;

  /// No description provided for @storagePathUpdated.
  ///
  /// In en, this message translates to:
  /// **'Catalog storage folder updated: {path}'**
  String storagePathUpdated(String path);

  /// No description provided for @shortcutPlayPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause'**
  String get shortcutPlayPauseTitle;

  /// No description provided for @shortcutPlayPauseDesc.
  ///
  /// In en, this message translates to:
  /// **'Start or pause current music track'**
  String get shortcutPlayPauseDesc;

  /// No description provided for @shortcutIntensityCalmTitle.
  ///
  /// In en, this message translates to:
  /// **'Intensity: Calm'**
  String get shortcutIntensityCalmTitle;

  /// No description provided for @shortcutIntensityCalmDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch music mode to Calm'**
  String get shortcutIntensityCalmDesc;

  /// No description provided for @shortcutIntensitySuspenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Intensity: Suspense'**
  String get shortcutIntensitySuspenseTitle;

  /// No description provided for @shortcutIntensitySuspenseDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch music mode to Suspense'**
  String get shortcutIntensitySuspenseDesc;

  /// No description provided for @shortcutIntensityBattleTitle.
  ///
  /// In en, this message translates to:
  /// **'Intensity: Battle'**
  String get shortcutIntensityBattleTitle;

  /// No description provided for @shortcutIntensityBattleDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch music mode to Battle'**
  String get shortcutIntensityBattleDesc;

  /// No description provided for @shortcutIntensityBossTitle.
  ///
  /// In en, this message translates to:
  /// **'Intensity: Boss'**
  String get shortcutIntensityBossTitle;

  /// No description provided for @shortcutIntensityBossDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch music mode to Boss'**
  String get shortcutIntensityBossDesc;

  /// No description provided for @shortcutSfxTitle.
  ///
  /// In en, this message translates to:
  /// **'SFX Slot {index}'**
  String shortcutSfxTitle(int index);

  /// No description provided for @shortcutSfxDesc.
  ///
  /// In en, this message translates to:
  /// **'Trigger sound effect {index}'**
  String shortcutSfxDesc(int index);

  /// No description provided for @shortcutMasterMuteTitle.
  ///
  /// In en, this message translates to:
  /// **'Mute Audio'**
  String get shortcutMasterMuteTitle;

  /// No description provided for @shortcutMasterMuteDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick mute or unmute master audio'**
  String get shortcutMasterMuteDesc;

  /// No description provided for @shortcutManualDuckingTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Ducking'**
  String get shortcutManualDuckingTitle;

  /// No description provided for @shortcutManualDuckingDesc.
  ///
  /// In en, this message translates to:
  /// **'Duck music during speech'**
  String get shortcutManualDuckingDesc;

  /// No description provided for @shortcutPanicStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Panic Stop SFX'**
  String get shortcutPanicStopTitle;

  /// No description provided for @shortcutPanicStopDesc.
  ///
  /// In en, this message translates to:
  /// **'Instantly stop all playing SFX sounds'**
  String get shortcutPanicStopDesc;

  /// No description provided for @shortcutFullscreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen Mode'**
  String get shortcutFullscreenTitle;

  /// No description provided for @shortcutFullscreenDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle fullscreen display'**
  String get shortcutFullscreenDesc;

  /// No description provided for @deleteFromApp.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteFromApp;

  /// No description provided for @repositoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get repositoryNameLabel;

  /// No description provided for @intensityCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get intensityCalm;

  /// No description provided for @intensitySuspense.
  ///
  /// In en, this message translates to:
  /// **'Suspense'**
  String get intensitySuspense;

  /// No description provided for @intensityBattle.
  ///
  /// In en, this message translates to:
  /// **'Battle'**
  String get intensityBattle;

  /// No description provided for @intensityBoss.
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get intensityBoss;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @catalogTypeScene.
  ///
  /// In en, this message translates to:
  /// **'scene'**
  String get catalogTypeScene;

  /// No description provided for @catalogTypeMedia.
  ///
  /// In en, this message translates to:
  /// **'media package'**
  String get catalogTypeMedia;

  /// No description provided for @catalogTypePack.
  ///
  /// In en, this message translates to:
  /// **'bundle'**
  String get catalogTypePack;

  /// No description provided for @sceneTitle.
  ///
  /// In en, this message translates to:
  /// **'Scene'**
  String get sceneTitle;

  /// No description provided for @mediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaTitle;

  /// No description provided for @packTitle.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get packTitle;

  /// No description provided for @catalogSceneBadge.
  ///
  /// In en, this message translates to:
  /// **'🎭 Scene'**
  String get catalogSceneBadge;

  /// No description provided for @catalogMediaBadge.
  ///
  /// In en, this message translates to:
  /// **'🎵 Media'**
  String get catalogMediaBadge;

  /// No description provided for @catalogPackBadge.
  ///
  /// In en, this message translates to:
  /// **'📦 Bundle'**
  String get catalogPackBadge;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterScenes.
  ///
  /// In en, this message translates to:
  /// **'🎭 Scenes'**
  String get filterScenes;

  /// No description provided for @filterMedia.
  ///
  /// In en, this message translates to:
  /// **'🎵 Media'**
  String get filterMedia;

  /// No description provided for @filterPacks.
  ///
  /// In en, this message translates to:
  /// **'📦 Bundles'**
  String get filterPacks;

  /// No description provided for @repoStats.
  ///
  /// In en, this message translates to:
  /// **'Scenes: {scenes} | Media: {media} | Bundles: {packs}'**
  String repoStats(int scenes, int media, int packs);

  /// No description provided for @addRepositoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add repository'**
  String get addRepositoryTooltip;

  /// No description provided for @repositoryUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://gitlab.com/user/repo'**
  String get repositoryUrlHint;

  /// No description provided for @playTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play [Space]'**
  String get playTooltip;

  /// No description provided for @pauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause [Space]'**
  String get pauseTooltip;

  /// No description provided for @panicStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Panic Stop SFX [Esc]'**
  String get panicStopTooltip;

  /// No description provided for @loopingBadge.
  ///
  /// In en, this message translates to:
  /// **'LOOPING'**
  String get loopingBadge;

  /// No description provided for @tagsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Tags: '**
  String get tagsPrefix;

  /// No description provided for @colorNamePrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get colorNamePrimary;

  /// No description provided for @colorNameSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get colorNameSecondary;

  /// No description provided for @colorNameBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get colorNameBackground;

  /// No description provided for @colorNameSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get colorNameSurface;

  /// No description provided for @colorNameCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get colorNameCard;

  /// No description provided for @colorNameAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get colorNameAccent;

  /// No description provided for @colorNameTextPrimary.
  ///
  /// In en, this message translates to:
  /// **'Text Primary'**
  String get colorNameTextPrimary;

  /// No description provided for @colorNameTextSecondary.
  ///
  /// In en, this message translates to:
  /// **'Text Secondary'**
  String get colorNameTextSecondary;

  /// No description provided for @colorNameDuckingBadge.
  ///
  /// In en, this message translates to:
  /// **'Ducking Badge'**
  String get colorNameDuckingBadge;

  /// No description provided for @colorNameBattleIntensity.
  ///
  /// In en, this message translates to:
  /// **'Battle Intensity'**
  String get colorNameBattleIntensity;

  /// No description provided for @colorNameBossIntensity.
  ///
  /// In en, this message translates to:
  /// **'Boss Intensity'**
  String get colorNameBossIntensity;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get seconds;

  /// No description provided for @milliseconds.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get milliseconds;

  /// No description provided for @sfxQuickTrigger.
  ///
  /// In en, this message translates to:
  /// **'SFX Quick-Trigger'**
  String get sfxQuickTrigger;

  /// No description provided for @activeMusicMode.
  ///
  /// In en, this message translates to:
  /// **'Active music mode'**
  String get activeMusicMode;

  /// No description provided for @musicModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get musicModeOff;

  /// No description provided for @musicModeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get musicModeExplore;

  /// No description provided for @musicModeCombat.
  ///
  /// In en, this message translates to:
  /// **'Combat'**
  String get musicModeCombat;

  /// No description provided for @musicModeVictory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get musicModeVictory;

  /// No description provided for @intensityStepped1.
  ///
  /// In en, this message translates to:
  /// **'I'**
  String get intensityStepped1;

  /// No description provided for @intensityStepped2.
  ///
  /// In en, this message translates to:
  /// **'II'**
  String get intensityStepped2;

  /// No description provided for @intensityStepped3.
  ///
  /// In en, this message translates to:
  /// **'III'**
  String get intensityStepped3;

  /// No description provided for @optionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsTooltip;

  /// No description provided for @scenesQuickPicker.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get scenesQuickPicker;

  /// No description provided for @sessionAudioDeck.
  ///
  /// In en, this message translates to:
  /// **'Session Audio Deck'**
  String get sessionAudioDeck;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
