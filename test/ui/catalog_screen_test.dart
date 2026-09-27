import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttrpg_audio_player/data/repositories/scene_repository_source_repository.dart';
import 'package:ttrpg_audio_player/domain/models/scene_repository_model.dart';
import 'package:ttrpg_audio_player/services/scene_repository_network_service.dart';
import 'package:ttrpg_audio_player/ui/screens/repository_catalog_screen.dart';
import 'package:ttrpg_audio_player/ui/view_models/media_library_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/repository_view_model.dart';
import 'package:ttrpg_audio_player/ui/view_models/scene_view_model.dart';

class MockSourceRepo implements SceneRepositorySourceRepository {
  final List<SceneRepositoryModel> repos;

  MockSourceRepo(this.repos);

  @override
  Future<List<SceneRepositoryModel>> getAllRepositories() async => repos;

  @override
  Future<SceneRepositoryModel?> getRepositoryById(String id) async {
    return repos.firstWhere((r) => r.id == id);
  }

  @override
  Future<void> addRepository(SceneRepositoryModel repo) async => repos.add(repo);

  @override
  Future<void> updateRepository(SceneRepositoryModel repo) async {}

  @override
  Future<void> deleteRepository(String id) async => repos.removeWhere((r) => r.id == id);
}

class MockNetworkService extends SceneRepositoryNetworkService {
  final SceneRepositoryManifest manifest;

  MockNetworkService(this.manifest);

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
      home: child,
    ),
  );
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

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
          sourceRepository: MockSourceRepo([mockRepo]),
          networkService: MockNetworkService(mockManifest),
        );
        final sceneVm = SceneViewModel(autoLoad: false);
        final mediaVm = MediaLibraryViewModel(autoLoad: false);

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
  });
}
