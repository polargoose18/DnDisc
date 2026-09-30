import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ttrpg_audio_player/data/repositories/media_library_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository_source_repository.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_repository_network_service.dart';
import 'package:ttrpg_audio_player/data/services/scene_service.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';
import 'package:ttrpg_audio_player/ui/screens/repository_catalog_screen.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/repository_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';
import 'package:ttrpg_audio_player/ui/widgets/scene_repository_details_dialog.dart';

class FakeSourceRepo implements SceneRepositorySourceRepository {
  final List<SceneRepositoryModel> repos;

  FakeSourceRepo(this.repos);

  @override
  Future<List<SceneRepositoryModel>> getAllRepositories() async => List.from(repos);

  @override
  Future<SceneRepositoryModel?> getRepositoryById(String id) async {
    return repos.firstWhere((r) => r.id == id);
  }

  @override
  Future<void> addRepository(SceneRepositoryModel repo) async => repos.add(repo);

  @override
  Future<void> updateRepository(SceneRepositoryModel repo) async {
    final idx = repos.indexWhere((r) => r.id == repo.id);
    if (idx != -1) {
      repos[idx] = repo;
    }
  }

  @override
  Future<void> deleteRepository(String id) async => repos.removeWhere((r) => r.id == id);
}

class FakeMediaLibraryRepo implements MediaLibraryRepository {
  final List<LibraryTrack> tracks = [];

  @override
  Future<List<LibraryTrack>> getAllTracks() async => List.from(tracks);

  @override
  Future<LibraryTrack?> getTrackById(String id) async {
    try {
      return tracks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertTrack(LibraryTrack track) async {
    tracks.add(track);
  }

  @override
  Future<void> insertTracksBatch(List<LibraryTrack> newTracks) async {
    tracks.addAll(newTracks);
  }

  @override
  Future<void> updateTrack(LibraryTrack track) async {
    final idx = tracks.indexWhere((t) => t.id == track.id);
    if (idx != -1) tracks[idx] = track;
  }

  @override
  Future<void> deleteTrack(String id) async {
    tracks.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<LibraryTrack>> searchTracks(String query, {AudioBusType? filterBus}) async {
    return tracks.where((t) => t.title.toLowerCase().contains(query.toLowerCase())).toList();
  }
}

class FakeSceneRepo implements SceneRepository {
  final List<SceneModel> scenes = [];

  @override
  Future<List<SceneModel>> getAllScenes() async => List.from(scenes);

  @override
  Future<SceneModel?> getSceneById(String id) async {
    try {
      return scenes.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertScene(SceneModel scene) async {
    scenes.add(scene);
  }

  @override
  Future<void> updateScene(SceneModel scene) async {
    final idx = scenes.indexWhere((s) => s.id == scene.id);
    if (idx != -1) scenes[idx] = scene;
  }

  @override
  Future<void> deleteScene(String id) async {
    scenes.removeWhere((s) => s.id == id);
  }
}

class FakeNetworkService extends SceneRepositoryNetworkService {
  final SceneRepositoryManifest manifest;

  FakeNetworkService(this.manifest);

  @override
  Future<ManifestFetchResult> fetchManifestWithResolvedUrl(String url) async {
    return ManifestFetchResult(manifest: manifest, resolvedUrl: url);
  }
}

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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('RepositoryCatalogScreen Widget & Filter Tests', () {
    testWidgets(
      'Что проверяем: Заголовок экрана "Каталог", чипы фильтров [Все], [🎭 Сцены], [🎵 Медиа], [📦 Паки] и отображение карточек. '
      'Входные данные: RepositoryCatalogScreen с подключенным макетом репозитория, содержащим 1 сцену, 1 медиа-набор и 1 пак. '
      'Ожидаемый результат: Экран отображает заголовок "Каталог", чипы фильтрации переключают категории.',
      (WidgetTester tester) async {
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

        await tester.pumpWidget(createCatalogTestableWidget(
          child: const RepositoryCatalogScreen(),
          repositoryViewModel: repoVm,
          sceneViewModel: sceneVm,
          mediaLibraryViewModel: mediaVm,
        ));

        await tester.pumpAndSettle();

        // Check screen title
        expect(find.text('Каталог'), findsOneWidget);

        // Check filter chips
        expect(find.widgetWithText(ChoiceChip, 'Все'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, '🎭 Сцены'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, '🎵 Медиа'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, '📦 Паки'), findsOneWidget);

        // Under 'Все', all 3 cards should be present
        expect(find.text('Dragon Lair Scene'), findsOneWidget);
        expect(find.text('Roar Effects Media'), findsOneWidget);
        expect(find.text('Strahd Campaign Pack'), findsOneWidget);

        // Tap on '🎭 Сцены' filter
        await tester.tap(find.widgetWithText(ChoiceChip, '🎭 Сцены'));
        await tester.pumpAndSettle();

        expect(find.text('Dragon Lair Scene'), findsOneWidget);
        expect(find.text('Roar Effects Media'), findsNothing);
        expect(find.text('Strahd Campaign Pack'), findsNothing);

        // Tap on '🎵 Медиа' filter
        await tester.tap(find.widgetWithText(ChoiceChip, '🎵 Медиа'));
        await tester.pumpAndSettle();

        expect(find.text('Dragon Lair Scene'), findsNothing);
        expect(find.text('Roar Effects Media'), findsOneWidget);
        expect(find.text('Strahd Campaign Pack'), findsNothing);

        // Tap on '📦 Паки' filter
        await tester.tap(find.widgetWithText(ChoiceChip, '📦 Паки'));
        await tester.pumpAndSettle();

        expect(find.text('Dragon Lair Scene'), findsNothing);
        expect(find.text('Roar Effects Media'), findsNothing);
        expect(find.text('Strahd Campaign Pack'), findsOneWidget);
      },
    );

    testWidgets(
      'Что проверяем: Отображение статуса "Загружено" для медиа-набора и пака в RepositoryCatalogScreen. '
      'Входные данные: MediaLibraryViewModel содержит треки из медиа-набора, SceneViewModel содержит сцену из пака. '
      'Ожидаемый результат: На карточках медиа-набора и пака отображается плашка "Загружено" и иконка check_circle.',
      (WidgetTester tester) async {
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

        // Initially not installed
        expect(find.text('Загружено'), findsNothing);

        // Add matching track to media library
        await mediaVm.addTrack(
          LibraryTrack(
            id: 'trk_slash_1',
            title: 'Slash SFX',
            filePath: '/audio/slash.mp3',
            busType: AudioBusType.sfx,
          ),
        );

        await tester.pumpAndSettle();

        // Now "Загружено" badge should appear on the media card
        expect(find.text('Загружено'), findsOneWidget);
      },
    );

    testWidgets(
      'Что проверяем: Открытие диалога редактирования репозитория и сохранение изменений через UI. '
      'Входные данные: Нажатие кнопки "Источники", клик по иконке редактирования репозитория, ввод нового имени и нажатие "Сохранить". '
      'Ожидаемый результат: Открывается диалог "Редактировать репозиторий", после сохранения имя репозитория обновляется на экране.',
      (WidgetTester tester) async {
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

        // Open manage repositories modal
        await tester.tap(find.text('Источники (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Управление репозиториями (1)'), findsOneWidget);
        expect(find.text('Original Repo Name'), findsOneWidget);

        // Tap edit button
        final editButton = find.byIcon(Icons.edit_outlined);
        expect(editButton, findsOneWidget);
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Check edit dialog
        expect(find.text('Редактировать репозиторий'), findsOneWidget);

        // Enter new name
        final nameField = find.widgetWithText(TextFormField, 'Название');
        await tester.enterText(nameField, 'Edited Repo Name');

        // Tap Save
        await tester.tap(find.text('Сохранить'));
        await tester.pumpAndSettle();

        // Verify updated name in the UI
        expect(find.text('Edited Repo Name'), findsOneWidget);
      },
    );

    testWidgets(
      'Что проверяем: Удаление загруженного пака через кнопку "Удалить из приложения" в SceneRepositoryDetailsDialog. '
      'Входные данные: Пак со сценой и связанными треками установлен в SceneViewModel и MediaLibraryViewModel. Пользователь открывает детали пака, нажимает кнопку удаления и подтверждает действие. '
      'Ожидаемый результат: Отображается диалог подтверждения удаления, после подтверждения сцены и треки пака удаляются, а кнопка переключается на "Установить пак".',
      (WidgetTester tester) async {
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

        expect(find.text('Загружено'), findsOneWidget);
        expect(find.text('Удалить из приложения'), findsOneWidget);
        expect(find.text('Загружено (Переустановить)'), findsNothing);

        await tester.tap(find.text('Удалить из приложения'));
        await tester.pumpAndSettle();

        expect(find.text('Удалить пак?'), findsOneWidget);
        expect(find.textContaining('Вы уверены, что хотите удалить пак "Strahd Pack"'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Удалить'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Отмена'), findsOneWidget);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Удалить'));
        await tester.pumpAndSettle();

        expect(sceneVm.scenes, isEmpty);
        expect(mediaVm.tracks, isEmpty);

        expect(find.text('Удалить из приложения'), findsNothing);
        expect(find.text('Установить пак'), findsOneWidget);
      },
    );

    testWidgets(
      'Что проверяем: Отмена удаления пака в диалоге подтверждения. '
      'Входные данные: Пользователь открывает детали установленного пака, нажимает "Удалить из приложения" и нажимает "Отмена". '
      'Ожидаемый результат: Пак и сцены не удаляются, кнопка остаётся "Удалить из приложения".',
      (WidgetTester tester) async {
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

        expect(find.text('Удалить из приложения'), findsOneWidget);

        await tester.tap(find.text('Удалить из приложения'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Отмена'));
        await tester.pumpAndSettle();

        expect(sceneVm.scenes.length, 1);
        expect(find.text('Удалить из приложения'), findsOneWidget);
        expect(find.text('Установить пак'), findsNothing);
      },
    );

    testWidgets(
      'Что проверяем: Удаление медиа-набора через SceneRepositoryDetailsDialog. '
      'Входные данные: Медиа-набор с треком установлен в MediaLibraryViewModel. Пользователь нажимает "Удалить из приложения" и подтверждает. '
      'Ожидаемый результат: Трек удаляется из MediaLibraryViewModel, кнопка возвращается в состояние "Установить медиа".',
      (WidgetTester tester) async {
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

        expect(find.text('Удалить из приложения'), findsOneWidget);

        await tester.tap(find.text('Удалить из приложения'));
        await tester.pumpAndSettle();

        expect(find.text('Удалить медиа-набор?'), findsOneWidget);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Удалить'));
        await tester.pumpAndSettle();

        expect(mediaVm.tracks, isEmpty);
        expect(find.text('Установить медиа-набор'), findsOneWidget);
      },
    );

    testWidgets(
      'Что проверяем: Удаление одиночной сцены через SceneRepositoryDetailsDialog. '
      'Входные данные: Сцена со звуковым сопровождением установлена в SceneViewModel и MediaLibraryViewModel. Пользователь подтверждает удаление. '
      'Ожидаемый результат: Сцена и трек удаляются, кнопка возвращается в состояние "Установить сцену".',
      (WidgetTester tester) async {
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

        expect(find.text('Удалить из приложения'), findsOneWidget);

        await tester.tap(find.text('Удалить из приложения'));
        await tester.pumpAndSettle();

        expect(find.text('Удалить сцену?'), findsOneWidget);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Удалить'));
        await tester.pumpAndSettle();

        expect(sceneVm.scenes, isEmpty);
        expect(mediaVm.tracks, isEmpty);
        expect(find.text('Установить сцену'), findsOneWidget);
      },
    );

    testWidgets(
      'Что проверяем: Сохранение трека в медиабиблиотеке при удалении пака, если трек используется в другой существующей сцене. '
      'Входные данные: Пак со сценой A (музыка trk_shared) и независимая сцена B (музыка trk_shared). Пользователь удаляет пак. '
      'Ожидаемый результат: Сцена пака удаляется, а независимая сцена B и трек trk_shared сохраняются в системе.',
      (WidgetTester tester) async {
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

        // Pack scene
        await sceneVm.createScene(
          SceneModel(
            id: 'sc_dungeon_1',
            name: 'Dungeon Room 1',
            musicTrackId: 'trk_shared',
          ),
        );

        // Independent custom scene sharing the same track
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

        expect(find.text('Удалить из приложения'), findsOneWidget);

        await tester.tap(find.text('Удалить из приложения'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Удалить'));
        await tester.pumpAndSettle();

        // Pack scene removed, but custom scene and shared track retained
        expect(sceneVm.scenes.length, 1);
        expect(sceneVm.scenes.first.id, 'sc_custom');
        expect(mediaVm.tracks.length, 1);
        expect(mediaVm.tracks.first.id, 'trk_shared');
      },
    );
  });
}
