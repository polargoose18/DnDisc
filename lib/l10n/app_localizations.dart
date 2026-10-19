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
  /// **'Media library'**
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

  /// No description provided for @muteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteTooltip;

  /// No description provided for @unmuteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteTooltip;

  /// No description provided for @logConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Log console'**
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
  /// **'Interface language'**
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

  /// No description provided for @musicFadeTitle.
  ///
  /// In en, this message translates to:
  /// **'Music crossfade'**
  String get musicFadeTitle;

  /// No description provided for @ambientFadeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ambient crossfade'**
  String get ambientFadeTitle;

  /// No description provided for @duckingTitle.
  ///
  /// In en, this message translates to:
  /// **'Ducking'**
  String get duckingTitle;

  /// No description provided for @duckAttackTitle.
  ///
  /// In en, this message translates to:
  /// **'Duck attack'**
  String get duckAttackTitle;

  /// No description provided for @duckAttackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How fast the music fades down when an effect starts'**
  String get duckAttackSubtitle;

  /// No description provided for @duckReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Duck release'**
  String get duckReleaseTitle;

  /// No description provided for @duckReleaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How fast the music returns to full volume'**
  String get duckReleaseSubtitle;

  /// No description provided for @duckMultiplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Ducking depth'**
  String get duckMultiplierTitle;

  /// No description provided for @duckMultiplierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share of the music volume that stays while an effect plays'**
  String get duckMultiplierSubtitle;

  /// No description provided for @resetDefaultsBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetDefaultsBtn;

  /// No description provided for @customThemes.
  ///
  /// In en, this message translates to:
  /// **'Custom themes'**
  String get customThemes;

  /// No description provided for @createThemeBtn.
  ///
  /// In en, this message translates to:
  /// **'Create theme'**
  String get createThemeBtn;

  /// No description provided for @hotkeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get hotkeysTitle;

  /// No description provided for @hotkeysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Work while the app window is focused'**
  String get hotkeysSubtitle;

  /// No description provided for @scenesTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get scenesTitle;

  /// No description provided for @createSceneBtn.
  ///
  /// In en, this message translates to:
  /// **'Create scene'**
  String get createSceneBtn;

  /// No description provided for @noScenesHint.
  ///
  /// In en, this message translates to:
  /// **'Create a scene to combine music, ambient layers and sound effects'**
  String get noScenesHint;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Import audio files to use them in scenes'**
  String get libraryEmptyHint;

  /// No description provided for @importFilesBtn.
  ///
  /// In en, this message translates to:
  /// **'Import files'**
  String get importFilesBtn;

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
  /// **'Search by title or tag'**
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

  /// No description provided for @musicTrack.
  ///
  /// In en, this message translates to:
  /// **'Music track'**
  String get musicTrack;

  /// No description provided for @stopMusic.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopMusic;

  /// No description provided for @noAmbientTracksInLibrary.
  ///
  /// In en, this message translates to:
  /// **'No ambient tracks in the library'**
  String get noAmbientTracksInLibrary;

  /// No description provided for @noSfxTracksInLibrary.
  ///
  /// In en, this message translates to:
  /// **'No sound effects in the library'**
  String get noSfxTracksInLibrary;

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

  /// No description provided for @ambientLayers.
  ///
  /// In en, this message translates to:
  /// **'Ambient layers'**
  String get ambientLayers;

  /// No description provided for @addAmbientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add layer'**
  String get addAmbientTooltip;

  /// No description provided for @stopAll.
  ///
  /// In en, this message translates to:
  /// **'Stop all'**
  String get stopAll;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @addAmbientDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add ambient layer'**
  String get addAmbientDialogTitle;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @persistentLayerCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Pin to every scene'**
  String get persistentLayerCheckbox;

  /// No description provided for @addLayerBtn.
  ///
  /// In en, this message translates to:
  /// **'Add layer'**
  String get addLayerBtn;

  /// No description provided for @soundboardTitle.
  ///
  /// In en, this message translates to:
  /// **'SFX'**
  String get soundboardTitle;

  /// No description provided for @unpinSfx.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinSfx;

  /// No description provided for @pinSfx.
  ///
  /// In en, this message translates to:
  /// **'Pin to every scene'**
  String get pinSfx;

  /// No description provided for @deleteSfxButton.
  ///
  /// In en, this message translates to:
  /// **'Remove from soundboard'**
  String get deleteSfxButton;

  /// No description provided for @addSfxDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add sound effect'**
  String get addSfxDialogTitle;

  /// No description provided for @persistentSfxCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Pin to every scene'**
  String get persistentSfxCheckbox;

  /// No description provided for @loopModeCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get loopModeCheckbox;

  /// No description provided for @addSfxBtn.
  ///
  /// In en, this message translates to:
  /// **'Add effect'**
  String get addSfxBtn;

  /// No description provided for @searchScenesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search scenes'**
  String get searchScenesPlaceholder;

  /// No description provided for @noScenesMatching.
  ///
  /// In en, this message translates to:
  /// **'Try a different name'**
  String get noScenesMatching;

  /// No description provided for @saveSceneAs.
  ///
  /// In en, this message translates to:
  /// **'Save scene as'**
  String get saveSceneAs;

  /// No description provided for @exportScenePackTitle.
  ///
  /// In en, this message translates to:
  /// **'Export bundle'**
  String get exportScenePackTitle;

  /// No description provided for @packTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Bundle name'**
  String get packTitleLabel;

  /// No description provided for @packDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get packDescLabel;

  /// No description provided for @defaultPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Adventure bundle'**
  String get defaultPackTitle;

  /// No description provided for @defaultPackDesc.
  ///
  /// In en, this message translates to:
  /// **'Atmospheric scenes collection'**
  String get defaultPackDesc;

  /// No description provided for @savePackAs.
  ///
  /// In en, this message translates to:
  /// **'Save bundle as'**
  String get savePackAs;

  /// No description provided for @selectScenePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a scene to set up the table'**
  String get selectScenePrompt;

  /// No description provided for @musicIntensityLabel.
  ///
  /// In en, this message translates to:
  /// **'Music intensity'**
  String get musicIntensityLabel;

  /// No description provided for @createSceneTitle.
  ///
  /// In en, this message translates to:
  /// **'Create scene'**
  String get createSceneTitle;

  /// No description provided for @editSceneTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit scene'**
  String get editSceneTitle;

  /// No description provided for @sceneNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Scene name'**
  String get sceneNameLabel;

  /// No description provided for @sceneNameHint.
  ///
  /// In en, this message translates to:
  /// **'Harbor at dusk'**
  String get sceneNameHint;

  /// No description provided for @specifySceneName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the scene'**
  String get specifySceneName;

  /// No description provided for @createCustomThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create theme'**
  String get createCustomThemeTitle;

  /// No description provided for @editCustomThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit theme'**
  String get editCustomThemeTitle;

  /// No description provided for @themeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme name'**
  String get themeNameLabel;

  /// No description provided for @themeNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a theme name'**
  String get themeNameRequired;

  /// No description provided for @baseOnPreset.
  ///
  /// In en, this message translates to:
  /// **'Start from a preset'**
  String get baseOnPreset;

  /// No description provided for @colorPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose color: {title}'**
  String colorPickTitle(String title);

  /// No description provided for @saveThemeBtn.
  ///
  /// In en, this message translates to:
  /// **'Save theme'**
  String get saveThemeBtn;

  /// No description provided for @newThemeDefaultName.
  ///
  /// In en, this message translates to:
  /// **'New theme'**
  String get newThemeDefaultName;

  /// No description provided for @editTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editTrackTitle;

  /// No description provided for @trackTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get trackTitleLabel;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, for example tavern, battle'**
  String get tagsHint;

  /// No description provided for @exportMediaPackageBtn.
  ///
  /// In en, this message translates to:
  /// **'Export set'**
  String get exportMediaPackageBtn;

  /// No description provided for @exportMediaPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Export set'**
  String get exportMediaPackageTitle;

  /// No description provided for @mediaPackageNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Set name'**
  String get mediaPackageNameLabel;

  /// No description provided for @mediaPackageDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get mediaPackageDescLabel;

  /// No description provided for @defaultMediaPackageName.
  ///
  /// In en, this message translates to:
  /// **'My media set'**
  String get defaultMediaPackageName;

  /// No description provided for @defaultMediaPackageDesc.
  ///
  /// In en, this message translates to:
  /// **'Audio tracks collection'**
  String get defaultMediaPackageDesc;

  /// No description provided for @saveMediaPackageAs.
  ///
  /// In en, this message translates to:
  /// **'Save set as'**
  String get saveMediaPackageAs;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogTitle;

  /// No description provided for @refreshCatalogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshCatalogTooltip;

  /// No description provided for @searchCatalogPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search the catalog'**
  String get searchCatalogPlaceholder;

  /// No description provided for @sourcesBtn.
  ///
  /// In en, this message translates to:
  /// **'Sources · {count}'**
  String sourcesBtn(int count);

  /// No description provided for @urlHttpPrefixValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a full https:// address'**
  String get urlHttpPrefixValidation;

  /// No description provided for @noCatalogItemsFound.
  ///
  /// In en, this message translates to:
  /// **'Try another name or switch the filter'**
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
  /// **'{count, plural, =1{1 scene} other{{count} scenes}}'**
  String scenesCount(int count);

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
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
  /// **'Source: {name}'**
  String repositoryLabel(String name);

  /// No description provided for @scenesInPack.
  ///
  /// In en, this message translates to:
  /// **'Scenes in the bundle'**
  String get scenesInPack;

  /// No description provided for @mediaSetContent.
  ///
  /// In en, this message translates to:
  /// **'Media pack contents'**
  String get mediaSetContent;

  /// No description provided for @sceneContent.
  ///
  /// In en, this message translates to:
  /// **'Scene contents'**
  String get sceneContent;

  /// No description provided for @tracksMissingInManifest.
  ///
  /// In en, this message translates to:
  /// **'The manifest has no track list'**
  String get tracksMissingInManifest;

  /// No description provided for @scenesMissingInManifest.
  ///
  /// In en, this message translates to:
  /// **'The manifest has no scene list'**
  String get scenesMissingInManifest;

  /// No description provided for @removeFromApp.
  ///
  /// In en, this message translates to:
  /// **'Remove from app'**
  String get removeFromApp;

  /// No description provided for @installItem.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installItem;

  /// No description provided for @catalogStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'Folder for audio files downloaded from the catalog'**
  String get catalogStorageDesc;

  /// No description provided for @customDirectory.
  ///
  /// In en, this message translates to:
  /// **'Custom folder'**
  String get customDirectory;

  /// No description provided for @defaultDirectory.
  ///
  /// In en, this message translates to:
  /// **'Default folder'**
  String get defaultDirectory;

  /// No description provided for @defaultStoragePath.
  ///
  /// In en, this message translates to:
  /// **'Documents/audio_library'**
  String get defaultStoragePath;

  /// No description provided for @resetDefaultDirTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetDefaultDirTooltip;

  /// No description provided for @chooseFolderBtn.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get chooseFolderBtn;

  /// No description provided for @chooseFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder for catalog audio'**
  String get chooseFolderDialogTitle;

  /// No description provided for @shortcutPlayPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Play / pause'**
  String get shortcutPlayPauseTitle;

  /// No description provided for @shortcutPlayPauseDesc.
  ///
  /// In en, this message translates to:
  /// **'Current music track'**
  String get shortcutPlayPauseDesc;

  /// No description provided for @shortcutIntensityCalmTitle.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get shortcutIntensityCalmTitle;

  /// No description provided for @shortcutIntensityCalmDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch music mode to Calm'**
  String get shortcutIntensityCalmDesc;

  /// No description provided for @shortcutIntensitySuspenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspense'**
  String get shortcutIntensitySuspenseTitle;

  /// No description provided for @shortcutIntensitySuspenseDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch music mode to Suspense'**
  String get shortcutIntensitySuspenseDesc;

  /// No description provided for @shortcutIntensityBattleTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle'**
  String get shortcutIntensityBattleTitle;

  /// No description provided for @shortcutIntensityBattleDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch music mode to Battle'**
  String get shortcutIntensityBattleDesc;

  /// No description provided for @shortcutIntensityBossTitle.
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get shortcutIntensityBossTitle;

  /// No description provided for @shortcutIntensityBossDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch music mode to Boss'**
  String get shortcutIntensityBossDesc;

  /// No description provided for @shortcutSfxTitle.
  ///
  /// In en, this message translates to:
  /// **'SFX slot {index}'**
  String shortcutSfxTitle(int index);

  /// No description provided for @shortcutSfxDesc.
  ///
  /// In en, this message translates to:
  /// **'Play sound effect {index}'**
  String shortcutSfxDesc(int index);

  /// No description provided for @shortcutMasterMuteTitle.
  ///
  /// In en, this message translates to:
  /// **'Mute master'**
  String get shortcutMasterMuteTitle;

  /// No description provided for @shortcutMasterMuteDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick mute or unmute'**
  String get shortcutMasterMuteDesc;

  /// No description provided for @shortcutFullscreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get shortcutFullscreenTitle;

  /// No description provided for @shortcutFullscreenDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle fullscreen mode'**
  String get shortcutFullscreenDesc;

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
  /// **'Scene'**
  String get catalogSceneBadge;

  /// No description provided for @catalogMediaBadge.
  ///
  /// In en, this message translates to:
  /// **'Media pack'**
  String get catalogMediaBadge;

  /// No description provided for @catalogPackBadge.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get catalogPackBadge;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterScenes.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get filterScenes;

  /// No description provided for @filterMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get filterMedia;

  /// No description provided for @filterPacks.
  ///
  /// In en, this message translates to:
  /// **'Bundles'**
  String get filterPacks;

  /// No description provided for @playTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playTooltip;

  /// No description provided for @pauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTooltip;

  /// No description provided for @colorNamePrimary.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get colorNamePrimary;

  /// No description provided for @colorNameBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get colorNameBackground;

  /// No description provided for @colorNameSurface.
  ///
  /// In en, this message translates to:
  /// **'Panels'**
  String get colorNameSurface;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get seconds;

  /// No description provided for @milliseconds.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get milliseconds;

  /// No description provided for @collapseSidebarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseSidebarTooltip;

  /// No description provided for @expandSidebarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebarTooltip;

  /// No description provided for @aboutDesc.
  ///
  /// In en, this message translates to:
  /// **'Audio engine for tabletop game masters'**
  String get aboutDesc;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @showScenes.
  ///
  /// In en, this message translates to:
  /// **'Show scenes'**
  String get showScenes;

  /// No description provided for @openNavigation.
  ///
  /// In en, this message translates to:
  /// **'Open navigation'**
  String get openNavigation;

  /// No description provided for @channelVolumes.
  ///
  /// In en, this message translates to:
  /// **'Channel volumes'**
  String get channelVolumes;

  /// No description provided for @noScenesTitle.
  ///
  /// In en, this message translates to:
  /// **'No scenes yet'**
  String get noScenesTitle;

  /// No description provided for @noScenesFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No scenes found'**
  String get noScenesFoundTitle;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @exportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportAction;

  /// No description provided for @ambientCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} ambient} other{{count} ambient}}'**
  String ambientCount(int count);

  /// No description provided for @sfxCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} SFX} other{{count} SFX}}'**
  String sfxCount(int count);

  /// No description provided for @sceneMeta.
  ///
  /// In en, this message translates to:
  /// **'{intensity} · {layers} · {sfx}'**
  String sceneMeta(String intensity, String layers, String sfx);

  /// No description provided for @deleteSceneTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete scene?'**
  String get deleteSceneTitle;

  /// No description provided for @deleteSceneMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} and its layout will be removed. Audio files stay in the library.'**
  String deleteSceneMessage(String name);

  /// No description provided for @exportBundleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export all scenes as a bundle'**
  String get exportBundleTooltip;

  /// No description provided for @toastSceneExported.
  ///
  /// In en, this message translates to:
  /// **'Scene exported'**
  String get toastSceneExported;

  /// No description provided for @toastBundleExported.
  ///
  /// In en, this message translates to:
  /// **'Bundle exported'**
  String get toastBundleExported;

  /// No description provided for @toastExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get toastExportFailed;

  /// No description provided for @ambientOnCount.
  ///
  /// In en, this message translates to:
  /// **'{on} of {total} on'**
  String ambientOnCount(int on, int total);

  /// No description provided for @stopAllLayers.
  ///
  /// In en, this message translates to:
  /// **'Stop all layers'**
  String get stopAllLayers;

  /// No description provided for @noAmbientTitle.
  ///
  /// In en, this message translates to:
  /// **'No ambient layers'**
  String get noAmbientTitle;

  /// No description provided for @noAmbientHint.
  ///
  /// In en, this message translates to:
  /// **'Add a layer to play rain, wind or a crowd under the music'**
  String get noAmbientHint;

  /// No description provided for @addAmbientLayer.
  ///
  /// In en, this message translates to:
  /// **'Add layer'**
  String get addAmbientLayer;

  /// No description provided for @pinEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Pin to every scene'**
  String get pinEverywhere;

  /// No description provided for @removeLayer.
  ///
  /// In en, this message translates to:
  /// **'Remove layer'**
  String get removeLayer;

  /// No description provided for @addAmbientDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a track from the library or a file'**
  String get addAmbientDialogDesc;

  /// No description provided for @fromLibrary.
  ///
  /// In en, this message translates to:
  /// **'From library'**
  String get fromLibrary;

  /// No description provided for @chooseLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get chooseLocalFile;

  /// No description provided for @soundIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get soundIcon;

  /// No description provided for @persistentLayerDesc.
  ///
  /// In en, this message translates to:
  /// **'The layer keeps playing when the scene changes'**
  String get persistentLayerDesc;

  /// No description provided for @filterLibrary.
  ///
  /// In en, this message translates to:
  /// **'Filter library'**
  String get filterLibrary;

  /// No description provided for @addSfxSlot.
  ///
  /// In en, this message translates to:
  /// **'Add sound effect'**
  String get addSfxSlot;

  /// No description provided for @addSfxDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a sound from the library or a file'**
  String get addSfxDialogDesc;

  /// No description provided for @persistentSfxDesc.
  ///
  /// In en, this message translates to:
  /// **'The tile stays on the soundboard when the scene changes'**
  String get persistentSfxDesc;

  /// No description provided for @loopModeDesc.
  ///
  /// In en, this message translates to:
  /// **'The sound repeats until you press the tile again'**
  String get loopModeDesc;

  /// No description provided for @createSceneDesc.
  ///
  /// In en, this message translates to:
  /// **'Name, cover, starting intensity and sounds'**
  String get createSceneDesc;

  /// No description provided for @coverLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get coverLabel;

  /// No description provided for @coverHint.
  ///
  /// In en, this message translates to:
  /// **'Picked at random if you skip it. Your own image replaces it.'**
  String get coverHint;

  /// No description provided for @uploadCover.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadCover;

  /// No description provided for @startingIntensity.
  ///
  /// In en, this message translates to:
  /// **'Starting intensity'**
  String get startingIntensity;

  /// No description provided for @soundsSelected.
  ///
  /// In en, this message translates to:
  /// **'Sounds · {count} selected'**
  String soundsSelected(int count);

  /// No description provided for @soundsHint.
  ///
  /// In en, this message translates to:
  /// **'Music, ambient layers and SFX tiles'**
  String get soundsHint;

  /// No description provided for @noSoundsFound.
  ///
  /// In en, this message translates to:
  /// **'No sounds found'**
  String get noSoundsFound;

  /// No description provided for @everythingEditableLater.
  ///
  /// In en, this message translates to:
  /// **'Everything can be changed later'**
  String get everythingEditableLater;

  /// No description provided for @saveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveBtn;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'This form has unsaved changes.'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @importBtn.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importBtn;

  /// No description provided for @noTracksFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get noTracksFound;

  /// No description provided for @noTracksFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try another title or tag'**
  String get noTracksFoundHint;

  /// No description provided for @previewTrack.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTrack;

  /// No description provided for @stopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopPreview;

  /// No description provided for @locateFile.
  ///
  /// In en, this message translates to:
  /// **'Locate file'**
  String get locateFile;

  /// No description provided for @fileMissing.
  ///
  /// In en, this message translates to:
  /// **'File missing'**
  String get fileMissing;

  /// No description provided for @deleteTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete track?'**
  String get deleteTrackTitle;

  /// No description provided for @deleteTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'{title} will be removed from the library. The audio file stays on disk.'**
  String deleteTrackMessage(String title);

  /// No description provided for @importDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import audio'**
  String get importDialogTitle;

  /// No description provided for @importDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the channel and add files'**
  String get importDialogDesc;

  /// No description provided for @importTarget.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get importTarget;

  /// No description provided for @dropFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop audio files here'**
  String get dropFilesTitle;

  /// No description provided for @dropFilesHint.
  ///
  /// In en, this message translates to:
  /// **'MP3, WAV, OGG, FLAC or M4A, or click to browse'**
  String get dropFilesHint;

  /// No description provided for @releaseToImport.
  ///
  /// In en, this message translates to:
  /// **'Release to import'**
  String get releaseToImport;

  /// No description provided for @importNFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Import} =1{Import 1 file} other{Import {count} files}}'**
  String importNFiles(int count);

  /// No description provided for @removeFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get removeFromList;

  /// No description provided for @toastImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 file} other{Imported {count} files}}'**
  String toastImported(int count);

  /// No description provided for @toastImportSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file was skipped: not an audio format} other{{count} files were skipped: not an audio format}}'**
  String toastImportSkipped(int count);

  /// No description provided for @trackTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get trackTypeLabel;

  /// No description provided for @intensityLabel.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get intensityLabel;

  /// No description provided for @filePathLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get filePathLabel;

  /// No description provided for @toastMediaPackageExported.
  ///
  /// In en, this message translates to:
  /// **'Set exported'**
  String get toastMediaPackageExported;

  /// No description provided for @addSourceBtn.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get addSourceBtn;

  /// No description provided for @downloadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadingLabel;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get viewDetails;

  /// No description provided for @removeItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeItemTitle(String name);

  /// No description provided for @removeItemMessage.
  ///
  /// In en, this message translates to:
  /// **'It and the files it installed will be removed from the app.'**
  String get removeItemMessage;

  /// No description provided for @toastInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get toastInstalled;

  /// No description provided for @toastInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed'**
  String get toastInstallFailed;

  /// No description provided for @toastInstallFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Check the connection and try again'**
  String get toastInstallFailedHint;

  /// No description provided for @toastRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get toastRemoved;

  /// No description provided for @toastRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove'**
  String get toastRemoveFailed;

  /// No description provided for @sourcesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sourcesDialogTitle;

  /// No description provided for @sourcesDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Repositories the catalog reads from'**
  String get sourcesDialogDesc;

  /// No description provided for @addSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get addSourceTitle;

  /// No description provided for @editSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit source'**
  String get editSourceTitle;

  /// No description provided for @sourceUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get sourceUrlLabel;

  /// No description provided for @sourceUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://gitlab.com/user/repo'**
  String get sourceUrlHint;

  /// No description provided for @sourceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sourceNameLabel;

  /// No description provided for @sourceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Taken from the manifest if empty'**
  String get sourceNameHint;

  /// No description provided for @sourceDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sourceDescLabel;

  /// No description provided for @enterSourceUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter the source address'**
  String get enterSourceUrl;

  /// No description provided for @enterSourceName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterSourceName;

  /// No description provided for @sourceStats.
  ///
  /// In en, this message translates to:
  /// **'Scenes {scenes} · Media {media} · Bundles {packs}'**
  String sourceStats(int scenes, int media, int packs);

  /// No description provided for @deleteSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove source?'**
  String get deleteSourceTitle;

  /// No description provided for @deleteSourceMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be listed in the catalog. Installed items stay.'**
  String deleteSourceMessage(String name);

  /// No description provided for @noSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'No sources connected'**
  String get noSourcesTitle;

  /// No description provided for @noSourcesHint.
  ///
  /// In en, this message translates to:
  /// **'Add a link to GitLab, Dropbox or a web server with a repository.json manifest'**
  String get noSourcesHint;

  /// No description provided for @sourceUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Source unavailable'**
  String get sourceUnavailableTitle;

  /// No description provided for @sourceUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Check the connection and try again'**
  String get sourceUnavailableHint;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noCatalogItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get noCatalogItemsTitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Theme applies to every screen. Custom themes are checked for contrast in the editor.'**
  String get appearanceDesc;

  /// No description provided for @customThemeTag.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customThemeTag;

  /// No description provided for @deleteThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete theme?'**
  String get deleteThemeTitle;

  /// No description provided for @deleteThemeMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed. If it is active, the app switches to Deep Dark.'**
  String deleteThemeMessage(String name);

  /// No description provided for @audioTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioTitle;

  /// No description provided for @duckingDesc.
  ///
  /// In en, this message translates to:
  /// **'Music drops while a sound effect plays'**
  String get duckingDesc;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// No description provided for @toastStoragePathUpdated.
  ///
  /// In en, this message translates to:
  /// **'Storage folder updated'**
  String get toastStoragePathUpdated;

  /// No description provided for @toastStoragePathReset.
  ///
  /// In en, this message translates to:
  /// **'Storage folder reset to default'**
  String get toastStoragePathReset;

  /// No description provided for @shortcutGroupPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get shortcutGroupPlayback;

  /// No description provided for @shortcutGroupIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get shortcutGroupIntensity;

  /// No description provided for @shortcutGroupSfx.
  ///
  /// In en, this message translates to:
  /// **'SFX slots'**
  String get shortcutGroupSfx;

  /// No description provided for @shortcutSfxSlotsDesc.
  ///
  /// In en, this message translates to:
  /// **'Slots 2–9 follow the same pattern'**
  String get shortcutSfxSlotsDesc;

  /// No description provided for @openLogs.
  ///
  /// In en, this message translates to:
  /// **'Open logs'**
  String get openLogs;

  /// No description provided for @toastSettingsReset.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get toastSettingsReset;

  /// No description provided for @themeEditorDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick eight colors, the rest is calculated'**
  String get themeEditorDesc;

  /// No description provided for @colorNameText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get colorNameText;

  /// No description provided for @hexLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex color'**
  String get hexLabel;

  /// No description provided for @hexInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a color like #D4A373'**
  String get hexInvalid;

  /// No description provided for @contrastChecksTitle.
  ///
  /// In en, this message translates to:
  /// **'Contrast checks'**
  String get contrastChecksTitle;

  /// No description provided for @contrastTextBg.
  ///
  /// In en, this message translates to:
  /// **'Text on background'**
  String get contrastTextBg;

  /// No description provided for @contrastTextSurface.
  ///
  /// In en, this message translates to:
  /// **'Text on panels'**
  String get contrastTextSurface;

  /// No description provided for @contrastPrimaryBg.
  ///
  /// In en, this message translates to:
  /// **'Accent on background'**
  String get contrastPrimaryBg;

  /// No description provided for @contrastPrimarySurface.
  ///
  /// In en, this message translates to:
  /// **'Accent on panels'**
  String get contrastPrimarySurface;

  /// No description provided for @contrastIntensityOnSurface.
  ///
  /// In en, this message translates to:
  /// **'{name} on panels'**
  String contrastIntensityOnSurface(String name);

  /// No description provided for @contrastFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get contrastFix;

  /// No description provided for @contrastWarning.
  ///
  /// In en, this message translates to:
  /// **'Some pairs are below the readable minimum. You can still save the theme.'**
  String get contrastWarning;

  /// No description provided for @contrastOk.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get contrastOk;

  /// No description provided for @orWord.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orWord;

  /// No description provided for @choosePreset.
  ///
  /// In en, this message translates to:
  /// **'Choose a preset'**
  String get choosePreset;

  /// No description provided for @outputDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Output device'**
  String get outputDeviceLabel;

  /// No description provided for @outputDeviceDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get outputDeviceDefault;

  /// No description provided for @outputDeviceMissing.
  ///
  /// In en, this message translates to:
  /// **'{name} is not connected, sound goes to the system default'**
  String outputDeviceMissing(String name);

  /// No description provided for @refreshDevices.
  ///
  /// In en, this message translates to:
  /// **'Refresh device list'**
  String get refreshDevices;

  /// No description provided for @toastOutputDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not switch the output device'**
  String get toastOutputDeviceFailed;

  /// No description provided for @toastCannotPlay.
  ///
  /// In en, this message translates to:
  /// **'Could not play {name}'**
  String toastCannotPlay(String name);

  /// No description provided for @toastCannotPlayHint.
  ///
  /// In en, this message translates to:
  /// **'The file is damaged or its format is not supported'**
  String get toastCannotPlayHint;

  /// No description provided for @toastM4aNeedsFfmpeg.
  ///
  /// In en, this message translates to:
  /// **'M4A on Linux needs the FFmpeg libraries (libavcodec, libavformat)'**
  String get toastM4aNeedsFfmpeg;

  /// No description provided for @toastOutputDeviceFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Sound is not reaching the output device. Pick another device in Settings or check the system sound settings'**
  String get toastOutputDeviceFailedHint;
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
