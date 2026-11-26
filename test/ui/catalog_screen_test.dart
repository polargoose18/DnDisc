import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';
import 'package:ttrpg_audio_player/ui/screens/repository_catalog_screen.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/repository_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/widgets/scene_repository_details_dialog.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_en.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/ui/design/ds_button.dart';
import '../helpers/fakes.dart';

Widget createCatalogTestableWidget({
  required Widget child,
  required RepositoryViewModel repositoryViewModel,
  required SceneViewModel sceneViewModel,
  required MediaLibraryViewModel mediaLibraryViewModel,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<RepositoryViewModel>.value(value: repositoryViewModel),
      ChangeNotifierProvider<SceneViewModel>.value(value: sceneViewModel),
      ChangeNotifierProvider<MediaLibraryViewModel>.value(value: mediaLibraryViewModel),
    ],
    child: MaterialApp(
      theme: AppThemes.deepDark.toThemeData(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('RepositoryCatalogScreen Widget & Filter Tests', () {
    testWidgets('should render catalog screen and filter items by category chips', (WidgetTester tester) async {
      // Arrange
      final mockRepo = SceneRepositoryModel(
        id: 'repo_1',
        name: 'Central Audio Repo',
        url: 'https://example.com/repo.json',
        createdAt: DateTime.now(),
      );

      const mockManifest = SceneRepositoryManifest(
        name: 'Central Audio Repo',
        scenes: [
          RepositorySceneItem(
            id: 'sc_1',
            name: 'Dragon Lair Scene',
            downloadUrl: 'scenes/dragon.scene.zip',
          ),
        ],
        media: [
          RepositoryMediaItem(
            id: 'med_1',
            name: 'Roar Effects Media',
            downloadUrl: 'media/roars.media.zip',
          ),
        ],
        packs: [
          RepositoryPackItem(
            id: 'pk_1',
            name: 'Strahd Campaign Pack',
            downloadUrl: 'packs/strahd.pack.zip',
          ),
        ],
      );

      final repoVm = RepositoryViewModel(
        sourceRepository: FakeSourceRepo([mockRepo]),
        networkService: FakeNetworkService(mockManifest),
      );
      final sceneService = SceneService(repository: FakeSceneRepo(), autoLoad: false);
      final sceneVm = SceneViewModel(service: sceneService, autoLoad: false);

      final mediaService = MediaLibraryService(repository: FakeMediaLibraryRepo(), autoLoad: false);
      final mediaVm = MediaLibraryViewModel(service: mediaService, autoLoad: false);

      // Act
      await tester.pumpWidget(createCatalogTestableWidget(
        child: const RepositoryCatalogScreen(),
        repositoryViewModel: repoVm,
        sceneViewModel: sceneVm,
        mediaLibraryViewModel: mediaVm,
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();

      // Assert - Header and Chips
      expect(find.text(l10n.catalogTitle), findsOneWidget);
      expect(find.text('${l10n.filterAll} · 3'), findsOneWidget);
      expect(find.text('${l10n.filterScenes} · 1'), findsOneWidget);
      expect(find.text('${l10n.filterMedia} · 1'), findsOneWidget);
      expect(find.text('${l10n.filterPacks} · 1'), findsOneWidget);

      // Assert - All category items visible
      expect(find.text('Dragon Lair Scene'), findsOneWidget);
      expect(find.text('Roar Effects Media'), findsOneWidget);
      expect(find.text('Strahd Campaign Pack'), findsOneWidget);

      // Act & Assert - Filter Scenes
      await tester.tap(find.text('${l10n.filterScenes} · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Dragon Lair Scene'), findsOneWidget);
      expect(find.text('Roar Effects Media'), findsNothing);
      expect(find.text('Strahd Campaign Pack'), findsNothing);

      // Act & Assert - Filter Media
      await tester.tap(find.text('${l10n.filterMedia} · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Dragon Lair Scene'), findsNothing);
      expect(find.text('Roar Effects Media'), findsOneWidget);
      expect(find.text('Strahd Campaign Pack'), findsNothing);

      // Act & Assert - Filter Packs
      await tester.tap(find.text('${l10n.filterPacks} · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Dragon Lair Scene'), findsNothing);
      expect(find.text('Roar Effects Media'), findsNothing);
      expect(find.text('Strahd Campaign Pack'), findsOneWidget);
    });

    testWidgets('should display installed status badge on cards when items exist in local library', (WidgetTester tester) async {
      // Arrange
      final mockRepo = SceneRepositoryModel(
        id: 'repo_installed_test',
        name: 'Central Audio Repo',
        url: 'https://example.com/repo.json',
        createdAt: DateTime.now(),
      );

      const mockManifest = SceneRepositoryManifest(
        name: 'Central Audio Repo',
        media: [
          RepositoryMediaItem(
            id: 'med_sword',
            name: 'Sword Sounds',
            downloadUrl: 'media/sword.media.zip',
            tracks: [
              RepositorySceneTrack(title: 'Slash SFX', busType: 'sfx'),
            ],
          ),
        ],
      );

      final repoVm = RepositoryViewModel(
        sourceRepository: FakeSourceRepo([mockRepo]),
        networkService: FakeNetworkService(mockManifest),
      );
      final sceneService = SceneService(repository: FakeSceneRepo(), autoLoad: false);
      final sceneVm = SceneViewModel(service: sceneService, autoLoad: false);

      final mediaService = MediaLibraryService(repository: FakeMediaLibraryRepo(), autoLoad: false);
      final mediaVm = MediaLibraryViewModel(service: mediaService, autoLoad: false);

      await tester.pumpWidget(createCatalogTestableWidget(
        child: const RepositoryCatalogScreen(),
        repositoryViewModel: repoVm,
        sceneViewModel: sceneVm,
        mediaLibraryViewModel: mediaVm,
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();

      expect(find.text(l10n.installedBadge), findsNothing);

      // Act
      await mediaVm.addTrack(
        LibraryTrack(
          id: 'trk_slash_1',
          title: 'Slash SFX',
          filePath: '/audio/slash.mp3',
          busType: AudioBusType.sfx,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(l10n.installedBadge), findsOneWidget);
    });

    testWidgets('should open edit repository dialog and persist changes through UI', (WidgetTester tester) async {
      // Arrange
      final mockRepo = SceneRepositoryModel(
        id: 'repo_edit_ui',
        name: 'Original Repo Name',
        url: 'https://example.com/original.json',
        description: 'Original Description',
        createdAt: DateTime.now(),
      );

      const updatedManifest = SceneRepositoryManifest(
        name: 'Edited Repo Name',
        description: 'New Description',
      );

      final repoVm = RepositoryViewModel(
        sourceRepository: FakeSourceRepo([mockRepo]),
        networkService: FakeNetworkService(updatedManifest),
      );
      final sceneService = SceneService(repository: FakeSceneRepo(), autoLoad: false);
      final sceneVm = SceneViewModel(service: sceneService, autoLoad: false);

      final mediaService = MediaLibraryService(repository: FakeMediaLibraryRepo(), autoLoad: false);
      final mediaVm = MediaLibraryViewModel(service: mediaService, autoLoad: false);

      await tester.pumpWidget(createCatalogTestableWidget(
        child: const RepositoryCatalogScreen(),
        repositoryViewModel: repoVm,
        sceneViewModel: sceneVm,
        mediaLibraryViewModel: mediaVm,
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();

      // Act & Assert - open manage modal
      await tester.tap(find.text(l10n.sourcesBtn(1)));
      await tester.pumpAndSettle();

      expect(find.text(l10n.sourcesDialogTitle), findsOneWidget);
      expect(find.text('Original Repo Name'), findsOneWidget);

      // Act & Assert - edit
      final editButton = find.byTooltip(l10n.editDetails);
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.editSourceTitle), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('source_name_field')), 'Edited Repo Name');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('save_source_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Edited Repo Name'), findsOneWidget);
    });

    testWidgets('should remove pack and associated tracks when delete is confirmed in details dialog', (WidgetTester tester) async {
      // Arrange
      final mockRepo = SceneRepositoryModel(
        id: 'repo_pack_del',
        name: 'Pack Repo',
        url: 'https://example.com/repo.json',
        createdAt: DateTime.now(),
      );

      const packItem = RepositoryPackItem(
        id: 'pk_strahd',
        name: 'Strahd Pack',
        downloadUrl: 'packs/strahd.pack.zip',
        scenes: [
          RepositoryPackSceneSummary(name: 'Castle Ravenloft', tracksCount: 1),
        ],
      );

      final catalogItem = CatalogItem.fromPack(packItem);

      const mockManifest = SceneRepositoryManifest(
        name: 'Pack Repo',
        packs: [packItem],
      );

      final repoVm = RepositoryViewModel(
        sourceRepository: FakeSourceRepo([mockRepo]),
        networkService: FakeNetworkService(mockManifest),
      );
      final sceneService = SceneService(repository: FakeSceneRepo(), autoLoad: false);
      final sceneVm = SceneViewModel(service: sceneService, autoLoad: false);

      final mediaService = MediaLibraryService(repository: FakeMediaLibraryRepo(), autoLoad: false);
      final mediaVm = MediaLibraryViewModel(service: mediaService, autoLoad: false);

      final track = LibraryTrack(
        id: 'trk_organ',
        title: 'Organ Music',
        filePath: '/audio/organ.mp3',
        busType: AudioBusType.music,
      );
      await mediaVm.addTrack(track);

      final scene = SceneModel(
        id: 'sc_ravenloft',
        name: 'Castle Ravenloft',
        musicTrackId: 'trk_organ',
      );
      await sceneVm.createScene(scene);

      await tester.pumpWidget(createCatalogTestableWidget(
        child: SceneRepositoryDetailsDialog(
          item: catalogItem,
          repo: mockRepo,
        ),
        repositoryViewModel: repoVm,
        sceneViewModel: sceneVm,
        mediaLibraryViewModel: mediaVm,
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();

      expect(find.text(l10n.installedBadge), findsOneWidget);
      expect(find.text(l10n.removeFromApp), findsOneWidget);

      // Act
      await tester.tap(find.text(l10n.removeFromApp));
      await tester.pumpAndSettle();

      expect(find.text(l10n.removeItemTitle('Strahd Pack')), findsOneWidget);
      expect(find.textContaining(l10n.removeItemMessage), findsOneWidget);

      await tester.tap(find.widgetWithText(DsButton, l10n.delete));
      await tester.pumpAndSettle();

      // Assert
      expect(sceneVm.scenes, isEmpty);
      expect(mediaVm.tracks, isEmpty);
      expect(find.text(l10n.installItem), findsOneWidget);
    });

    testWidgets('should cancel pack deletion when Cancel button is tapped in confirmation dialog', (WidgetTester tester) async {
      // Arrange
      final mockRepo = SceneRepositoryModel(
        id: 'repo_cancel_del',
        name: 'Cancel Repo',
        url: 'https://example.com/repo.json',
        createdAt: DateTime.now(),
      );

      const packItem = RepositoryPackItem(
        id: 'pk_cancel',
        name: 'Cancel Pack',
        downloadUrl: 'packs/cancel.pack.zip',
        scenes: [
          RepositoryPackSceneSummary(name: 'Safe Scene', tracksCount: 0),
        ],
      );

      final catalogItem = CatalogItem.fromPack(packItem);

      const mockManifest = SceneRepositoryManifest(
        name: 'Cancel Repo',
        packs: [packItem],
      );

      final repoVm = RepositoryViewModel(
        sourceRepository: FakeSourceRepo([mockRepo]),
        networkService: FakeNetworkService(mockManifest),
      );
      final sceneService = SceneService(repository: FakeSceneRepo(), autoLoad: false);
      final sceneVm = SceneViewModel(service: sceneService, autoLoad: false);

      final mediaService = MediaLibraryService(repository: FakeMediaLibraryRepo(), autoLoad: false);
      final mediaVm = MediaLibraryViewModel(service: mediaService, autoLoad: false);

      await sceneVm.createScene(
        SceneModel(id: 'sc_safe', name: 'Safe Scene'),
      );

      await tester.pumpWidget(createCatalogTestableWidget(
        child: SceneRepositoryDetailsDialog(
          item: catalogItem,
          repo: mockRepo,
        ),
        repositoryViewModel: repoVm,
        sceneViewModel: sceneVm,
        mediaLibraryViewModel: mediaVm,
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();

      expect(find.text(l10n.removeFromApp), findsOneWidget);

      // Act
      await tester.tap(find.text(l10n.removeFromApp));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DsButton, l10n.cancel));
      await tester.pumpAndSettle();

      // Assert
      expect(sceneVm.scenes.length, 1);
      expect(find.text(l10n.removeFromApp), findsOneWidget);
      expect(find.text(l10n.installItem), findsNothing);
    });

    testWidgets('should remove media package and related tracks when delete action is confirmed', (WidgetTester tester) async {
      // Arrange
      final mockRepo = SceneRepositoryModel(
        id: 'repo_media_del',
        name: 'Media Repo',
        url: 'https://example.com/repo.json',
        createdAt: DateTime.now(),
      );

      const mediaItem = RepositoryMediaItem(
        id: 'med_swords',
        name: 'Swords Collection',
        downloadUrl: 'media/swords.media.zip',
        tracks: [
          RepositorySceneTrack(title: 'Iron Sword Strike', busType: 'sfx'),
        ],
      );

      final catalogItem = CatalogItem.fromMedia(mediaItem);

      const mockManifest = SceneRepositoryManifest(
        name: 'Media Repo',
        media: [mediaItem],
      );

      final repoVm = RepositoryViewModel(
        sourceRepository: FakeSourceRepo([mockRepo]),
        networkService: FakeNetworkService(mockManifest),
      );
      final sceneService = SceneService(repository: FakeSceneRepo(), autoLoad: false);
      final sceneVm = SceneViewModel(service: sceneService, autoLoad: false);

      final mediaService = MediaLibraryService(repository: FakeMediaLibraryRepo(), autoLoad: false);
      final mediaVm = MediaLibraryViewModel(service: mediaService, autoLoad: false);

      await mediaVm.addTrack(
        LibraryTrack(
          id: 'trk_iron',
          title: 'Iron Sword Strike',
          filePath: '/audio/iron.mp3',
          busType: AudioBusType.sfx,
        ),
      );

      await tester.pumpWidget(createCatalogTestableWidget(
        child: SceneRepositoryDetailsDialog(
          item: catalogItem,
          repo: mockRepo,
        ),
        repositoryViewModel: repoVm,
        sceneViewModel: sceneVm,
        mediaLibraryViewModel: mediaVm,
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();

      expect(find.text(l10n.removeFromApp), findsOneWidget);

      // Act
      await tester.tap(find.text(l10n.removeFromApp));
      await tester.pumpAndSettle();

      expect(find.text(l10n.removeItemTitle('Swords Collection')), findsOneWidget);
      await tester.tap(find.widgetWithText(DsButton, l10n.delete));
      await tester.pumpAndSettle();

      // Assert
      expect(mediaVm.tracks, isEmpty);
      expect(find.text(l10n.installItem), findsOneWidget);
    });

    testWidgets('should remove single scene and associated audio when delete is confirmed', (WidgetTester tester) async {
      // Arrange
      final mockRepo = SceneRepositoryModel(
        id: 'repo_scene_del',
        name: 'Scene Repo',
        url: 'https://example.com/repo.json',
        createdAt: DateTime.now(),
      );

      const sceneItem = RepositorySceneItem(
        id: 'sc_tavern',
        name: 'Tavern Scene',
        downloadUrl: 'scenes/tavern.scene.zip',
        tracks: [
          RepositorySceneTrack(title: 'Tavern Music', busType: 'music'),
        ],
      );

      final catalogItem = CatalogItem.fromScene(sceneItem);

      const mockManifest = SceneRepositoryManifest(
        name: 'Scene Repo',
        scenes: [sceneItem],
      );

      final repoVm = RepositoryViewModel(
        sourceRepository: FakeSourceRepo([mockRepo]),
        networkService: FakeNetworkService(mockManifest),
      );
      final sceneService = SceneService(repository: FakeSceneRepo(), autoLoad: false);
      final sceneVm = SceneViewModel(service: sceneService, autoLoad: false);

      final mediaService = MediaLibraryService(repository: FakeMediaLibraryRepo(), autoLoad: false);
      final mediaVm = MediaLibraryViewModel(service: mediaService, autoLoad: false);

      await mediaVm.addTrack(
        LibraryTrack(
          id: 'trk_tavern',
          title: 'Tavern Music',
          filePath: '/audio/tavern.mp3',
          busType: AudioBusType.music,
        ),
      );

      await sceneVm.createScene(
        SceneModel(
          id: 'sc_tavern',
          name: 'Tavern Scene',
          musicTrackId: 'trk_tavern',
        ),
      );

      await tester.pumpWidget(createCatalogTestableWidget(
        child: SceneRepositoryDetailsDialog(
          item: catalogItem,
          repo: mockRepo,
        ),
        repositoryViewModel: repoVm,
        sceneViewModel: sceneVm,
        mediaLibraryViewModel: mediaVm,
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();

      expect(find.text(l10n.removeFromApp), findsOneWidget);

      // Act
      await tester.tap(find.text(l10n.removeFromApp));
      await tester.pumpAndSettle();

      expect(find.text(l10n.removeItemTitle('Tavern Scene')), findsOneWidget);
      await tester.tap(find.widgetWithText(DsButton, l10n.delete));
      await tester.pumpAndSettle();

      // Assert
      expect(sceneVm.scenes, isEmpty);
      expect(mediaVm.tracks, isEmpty);
      expect(find.text(l10n.installItem), findsOneWidget);
    });

    testWidgets('should preserve shared tracks in library when deleting pack if another scene uses them', (WidgetTester tester) async {
      // Arrange
      final mockRepo = SceneRepositoryModel(
        id: 'repo_shared_test',
        name: 'Shared Repo',
        url: 'https://example.com/repo.json',
        createdAt: DateTime.now(),
      );

      const packItem = RepositoryPackItem(
        id: 'pk_dungeon',
        name: 'Dungeon Pack',
        downloadUrl: 'packs/dungeon.pack.zip',
        scenes: [
          RepositoryPackSceneSummary(name: 'Dungeon Room 1', tracksCount: 1),
        ],
      );

      final catalogItem = CatalogItem.fromPack(packItem);

      const mockManifest = SceneRepositoryManifest(
        name: 'Shared Repo',
        packs: [packItem],
      );

      final repoVm = RepositoryViewModel(
        sourceRepository: FakeSourceRepo([mockRepo]),
        networkService: FakeNetworkService(mockManifest),
      );
      final sceneService = SceneService(repository: FakeSceneRepo(), autoLoad: false);
      final sceneVm = SceneViewModel(service: sceneService, autoLoad: false);

      final mediaService = MediaLibraryService(repository: FakeMediaLibraryRepo(), autoLoad: false);
      final mediaVm = MediaLibraryViewModel(service: mediaService, autoLoad: false);

      final sharedTrack = LibraryTrack(
        id: 'trk_shared',
        title: 'Ambient Drip',
        filePath: '/audio/drip.mp3',
        busType: AudioBusType.music,
      );
      await mediaVm.addTrack(sharedTrack);

      await sceneVm.createScene(
        SceneModel(
          id: 'sc_dungeon_1',
          name: 'Dungeon Room 1',
          musicTrackId: 'trk_shared',
        ),
      );

      await sceneVm.createScene(
        SceneModel(
          id: 'sc_custom',
          name: 'My Custom Scene',
          musicTrackId: 'trk_shared',
        ),
      );

      await tester.pumpWidget(createCatalogTestableWidget(
        child: SceneRepositoryDetailsDialog(
          item: catalogItem,
          repo: mockRepo,
        ),
        repositoryViewModel: repoVm,
        sceneViewModel: sceneVm,
        mediaLibraryViewModel: mediaVm,
      ));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();

      // Act
      await tester.tap(find.text(l10n.removeFromApp));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DsButton, l10n.delete));
      await tester.pumpAndSettle();

      // Assert
      expect(sceneVm.scenes.length, 1);
      expect(sceneVm.scenes.first.id, 'sc_custom');
      expect(mediaVm.tracks.length, 1);
      expect(mediaVm.tracks.first.id, 'trk_shared');
    });
  });

  group('RepositoryCatalogScreen states and source dialogs', () {
    Future<(RepositoryViewModel, SceneViewModel, MediaLibraryViewModel)> pumpCatalog(
      WidgetTester tester, {
      List<SceneRepositoryModel> repos = const [],
      SceneRepositoryManifest manifest = const SceneRepositoryManifest(name: 'm'),
    }) async {
      final repoVm = RepositoryViewModel(sourceRepository: FakeSourceRepo([...repos]), networkService: FakeNetworkService(manifest));
      final sceneVm = SceneViewModel(service: SceneService(repository: FakeSceneRepo(), autoLoad: false), autoLoad: false);
      final mediaVm = MediaLibraryViewModel(service: MediaLibraryService(repository: FakeMediaLibraryRepo(), autoLoad: false), autoLoad: false);
      await tester.pumpWidget(createCatalogTestableWidget(
        child: const RepositoryCatalogScreen(),
        repositoryViewModel: repoVm,
        sceneViewModel: sceneVm,
        mediaLibraryViewModel: mediaVm,
      ));
      await tester.pumpAndSettle();
      return (repoVm, sceneVm, mediaVm);
    }

    final repo = SceneRepositoryModel(id: 'r1', name: 'DnDisc', url: 'https://example.com/repo.json', createdAt: DateTime(2025));

    testWidgets('shows an empty state with an add-source action when no source is connected', (tester) async {
      await pumpCatalog(tester);
      final l10n = AppLocalizationsEn();

      expect(find.text(l10n.noSourcesTitle), findsOneWidget);
      expect(find.text(l10n.sourcesBtn(0)), findsOneWidget);
      // Top bar action and the empty-state action.
      expect(find.text(l10n.addSourceBtn), findsNWidgets(2));
    });

    testWidgets('shows a calm card per kind with size and an Install button, and a cover instead of a coloured header', (tester) async {
      await pumpCatalog(
        tester,
        repos: [repo],
        manifest: const SceneRepositoryManifest(
          name: 'DnDisc',
          scenes: [RepositorySceneItem(id: 's1', name: 'Test scene', description: 'A quiet tavern', downloadUrl: 'a.zip', sizeBytes: 14 * 1024 * 1024)],
          media: [RepositoryMediaItem(id: 'm1', name: 'Pack', downloadUrl: 'b.zip')],
        ),
      );
      final l10n = AppLocalizationsEn();

      expect(find.text('Test scene'), findsOneWidget);
      expect(find.text('A quiet tavern'), findsOneWidget);
      expect(find.text('14.0 MB'), findsOneWidget);
      expect(find.text(l10n.sizeUnknown), findsOneWidget);
      expect(find.text(l10n.installItem), findsNWidgets(2));
      expect(find.textContaining('${l10n.catalogSceneBadge} ·'), findsOneWidget);
      expect(find.textContaining('${l10n.catalogMediaBadge} ·'), findsOneWidget);
      // No emoji in kind labels.
      expect(find.textContaining('🎭'), findsNothing);
      expect(find.textContaining('🎵'), findsNothing);
    });

    testWidgets('opens details from a card and shows the contents of the item', (tester) async {
      await pumpCatalog(
        tester,
        repos: [repo],
        manifest: const SceneRepositoryManifest(
          name: 'DnDisc',
          scenes: [
            RepositorySceneItem(
              id: 's1',
              name: 'Test scene',
              description: 'A quiet tavern',
              downloadUrl: 'a.zip',
              tracks: [RepositorySceneTrack(title: 'Rain loop', busType: 'ambient', durationMs: 65000)],
            ),
          ],
        ),
      );
      final l10n = AppLocalizationsEn();

      await tester.tap(find.text('Test scene'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.repositoryLabel('DnDisc')), findsOneWidget);
      expect(find.text(l10n.sceneContent), findsOneWidget);
      expect(find.text('Rain loop'), findsOneWidget);
      expect(find.text('Ambient · 1:05'), findsOneWidget);
      expect(find.byKey(const ValueKey('details_install_btn')), findsOneWidget);
    });

    testWidgets('validates the address when adding a source and explains how to fix it', (tester) async {
      await pumpCatalog(tester);
      final l10n = AppLocalizationsEn();

      await tester.tap(find.byKey(const ValueKey('catalog_add_source_button')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.addSourceTitle), findsWidgets);
      expect(find.byKey(const ValueKey('source_url_field')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save_source_btn')));
      await tester.pump();
      expect(find.text(l10n.enterSourceUrl), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('source_url_field')), 'example.com/repo');
      await tester.pump();
      expect(find.text(l10n.urlHttpPrefixValidation), findsOneWidget);
    });

    testWidgets('adds a source and removes it again only after confirmation', (tester) async {
      final (repoVm, _, _) = await pumpCatalog(tester);
      final l10n = AppLocalizationsEn();

      await tester.tap(find.byKey(const ValueKey('catalog_add_source_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('source_url_field')), 'https://example.com/repo.json');
      await tester.enterText(find.byKey(const ValueKey('source_name_field')), 'Fresh source');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save_source_btn')));
      await tester.pumpAndSettle();
      expect(repoVm.repositories.map((r) => r.name), contains('Fresh source'));

      await tester.tap(find.byKey(const ValueKey('catalog_sources_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.delete));
      await tester.pumpAndSettle();
      expect(find.text(l10n.deleteSourceTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(DsButton, l10n.cancel));
      await tester.pumpAndSettle();
      expect(repoVm.repositories, isNotEmpty);

      await tester.tap(find.byTooltip(l10n.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DsButton, l10n.delete));
      await tester.pumpAndSettle();
      expect(repoVm.repositories, isEmpty);
    });
  });
}
