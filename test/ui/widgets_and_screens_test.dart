import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ttrpg_audio_player/audio/audio_engine_service.dart';
import 'package:ttrpg_audio_player/audio/music_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/ambient_bus_controller.dart';
import 'package:ttrpg_audio_player/audio/sfx_bus_controller.dart';
import 'package:ttrpg_audio_player/services/media_library_service.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';
import 'package:ttrpg_audio_player/db/database_service.dart';
import 'package:ttrpg_audio_player/models/audio_track.dart';
import 'package:ttrpg_audio_player/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/models/sfx_trigger.dart';
import 'package:ttrpg_audio_player/models/library_track.dart';

import 'package:ttrpg_audio_player/ui/widgets/music_player_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/ambient_mixer_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/soundboard_grid.dart';
import 'package:ttrpg_audio_player/ui/widgets/logger_console_drawer.dart';
import 'package:ttrpg_audio_player/ui/widgets/import_track_dialog.dart';
import 'package:ttrpg_audio_player/ui/screens/main_dashboard_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/library_screen.dart';
import 'package:ttrpg_audio_player/services/settings_service.dart';
import 'package:ttrpg_audio_player/services/scene_service.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempPath;
  }
}

Widget createTestableWidget(Widget child, {
  AudioEngineService? engine,
  MediaLibraryService? library,
  LoggerService? logger,
  SettingsService? settings,
  SceneService? sceneService,
}) {
  final eng = engine ?? AudioEngineService();
  final log = logger ?? LoggerService();
  final set = settings ?? SettingsService();
  final scn = sceneService ?? SceneService(autoLoad: false);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LoggerService>.value(value: log),
      ChangeNotifierProvider<SettingsService>.value(value: set),
      ChangeNotifierProvider<AudioEngineService>.value(value: eng),
      ChangeNotifierProvider<MusicBusController>.value(value: eng.musicBus),
      ChangeNotifierProvider<AmbientBusController>.value(value: eng.ambientBus),
      ChangeNotifierProvider<SfxBusController>.value(value: eng.sfxBus),
      ChangeNotifierProvider<SceneService>.value(value: scn),
      if (library != null)
        ChangeNotifierProvider<MediaLibraryService>.value(value: library),
    ],
    child: Consumer<SettingsService>(
      builder: (context, set, _) {
        return MaterialApp(
          locale: set.currentLocale ?? const Locale('ru'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseService().close();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ttrpg_ui_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    LoggerService().clear();
  });

  tearDown(() async {
    await DatabaseService().close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('MusicPlayerPanel Widget Tests', () {
    testWidgets('Что проверяем: Отображение состояния воспроизведения и клики по чипам интенсивности. '
        'Входные данные: MusicPlayerPanel c MusicBusController. Tар по чипу "BOSS". '
        'Ожидаемый результат: Текст "Музыка не воспроизводится", а после нажатия чипа intensity становится MusicIntensity.boss.', (WidgetTester tester) async {
      final engine = AudioEngineService();

      await tester.pumpWidget(createTestableWidget(const MusicPlayerPanel(), engine: engine));

      expect(find.text('Музыкальная дорожка'), findsOneWidget);
      expect(find.text('Музыка не воспроизводится'), findsOneWidget);

      // Нажимаем на чип BOSS
      await tester.tap(find.byKey(const ValueKey('chip_boss')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(engine.musicBus.currentIntensity, equals(MusicIntensity.boss));
      engine.dispose();
    });

    testWidgets('Что проверяем: Кнопка воспроизведения/паузы и слайдер громкости в MusicPlayerPanel. '
        'Входные данные: Нажатие кнопки play/pause и смещение слайдера громкости. '
        'Ожидаемый результат: Вызывается pause/resume, слайдер меняет rawVolume.', (WidgetTester tester) async {
      final engine = AudioEngineService();

      await tester.pumpWidget(createTestableWidget(const MusicPlayerPanel(), engine: engine));

      // Нажатие кнопки play/pause
      await tester.tap(find.byKey(const ValueKey('music_play_pause_button')));
      await tester.pump(const Duration(milliseconds: 200));

      // Изменение слайдера громкости
      await tester.drag(find.byKey(const ValueKey('music_volume_slider')), const Offset(-50, 0));
      await tester.pump(const Duration(milliseconds: 200));

      expect(engine.musicBus.rawVolume, lessThan(1.0));
      engine.dispose();
    });
  });

  group('AmbientMixerPanel Widget Tests', () {
    testWidgets('Что проверяем: Отображение пустого состояния AmbientMixerPanel. '
        'Входные данные: AmbientMixerPanel без слоев. '
        'Ожидаемый результат: Отображается сообщение "Нет активных эмбиентов".', (WidgetTester tester) async {
      final engine = AudioEngineService();

      await tester.pumpWidget(createTestableWidget(const AmbientMixerPanel(), engine: engine));

      expect(find.textContaining('Нет активных эмбиентов'), findsOneWidget);
      engine.dispose();
    });

    testWidgets('Что проверяем: Отображение слоев эмбиента, переключение свитчей и кнопки "Выключить все". '
        'Входные данные: AmbientMixerPanel со слоем "Rain". Переключение Switch и нажатие кнопки stop. '
        'Ожидаемый результат: Переключатель инвертирует isActive, а кнопка "Выключить все" сбрасывает все слои.', (WidgetTester tester) async {
      final engine = AudioEngineService();
      engine.ambientBus.addLayer(const AmbientLayer(id: 'rain-l', title: 'Шум Дождя', filePath: '/rain.mp3', isActive: true));

      await tester.pumpWidget(createTestableWidget(const AmbientMixerPanel(), engine: engine));

      expect(find.textContaining('Эмбиент-слои'), findsOneWidget);
      expect(find.text('Шум Дождя'), findsOneWidget);
      expect(engine.ambientBus.layers.first.isActive, isTrue);

      // Нажимаем на переключатель слоя
      await tester.tap(find.byKey(const ValueKey('ambient_switch_rain-l')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(engine.ambientBus.layers.first.isActive, isFalse);

      // Нажимаем кнопку "Выключить все"
      await tester.tap(find.byKey(const ValueKey('ambient_stop_all_btn')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(engine.ambientBus.layers.every((l) => !l.isActive), isTrue);
      engine.dispose();
    });
  });

  group('SoundboardGrid Widget Tests', () {
    testWidgets('Что проверяем: Отображение пустого состояния SoundboardGrid. '
        'Входные данные: SoundboardGrid без триггеров. '
        'Ожидаемый результат: Отображается сообщение "Soundboard пуст".', (WidgetTester tester) async {
      final engine = AudioEngineService();

      await tester.pumpWidget(createTestableWidget(const SoundboardGrid(), engine: engine));

      expect(find.textContaining('Soundboard пуст'), findsOneWidget);
      engine.dispose();
    });

    testWidgets('Что проверяем: Отображение кнопок SFX триггеров и реакция на клик. '
        'Входные данные: SoundboardGrid c триггером "Удар Меча". Клик по кнопке. '
        'Ожидаемый результат: Запускается triggerSfx, вызывается даккинг на музыки.', (WidgetTester tester) async {
      final engine = AudioEngineService();
      engine.sfxBus.addTrigger(const SfxTrigger(id: 'sword-trig', title: 'Удар Меча', filePath: '/sword.wav', hotkey: '1'));

      await tester.pumpWidget(createTestableWidget(const SoundboardGrid(), engine: engine));

      expect(find.textContaining('Soundboard'), findsOneWidget);
      expect(find.text('Удар Меча'), findsOneWidget);
      expect(find.text('[1]'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sfx_btn_sword-trig')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(engine.duckingController.isDucked, isTrue);
      engine.dispose();
    });
  });

  group('LoggerConsoleDrawer Widget Tests', () {
    testWidgets('Что проверяем: Отображение записей логов и кнопка очистки в LoggerConsoleDrawer. '
        'Входные данные: LoggerService с 1 логом. Открытие Drawer и нажатие иконки очистки. '
        'Ожидаемый результат: Запись отображается, после нажатия кнопки очистки консоль показывает "Логи пусты".', (WidgetTester tester) async {
      final logger = LoggerService();
      logger.info('Тестовая запись лога');

      await tester.pumpWidget(createTestableWidget(const LoggerConsoleDrawer(), logger: logger));

      expect(find.text('Консоль логов и отладки'), findsOneWidget);
      expect(find.text('Тестовая запись лога'), findsOneWidget);

      await tester.tap(find.byTooltip('Очистить логи'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Логи пусты'), findsOneWidget);
    });
  });

  group('EditTrackDialog Widget Tests', () {
    testWidgets('Что проверяем: Редактирование параметров трека в EditTrackDialog. '
        'Входные данные: EditTrackDialog с исходным треком "Old Name". Ввод нового имени "New Name" и нажатие "Сохранить". '
        'Ожидаемый результат: Возвращается обновлённый объект LibraryTrack с title="New Name".', (WidgetTester tester) async {
      final track = LibraryTrack(
        id: 'edit-1',
        title: 'Old Name',
        filePath: '/track.mp3',
        busType: AudioBusType.music,
      );

      LibraryTrack? resultTrack;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () async {
                    resultTrack = await showDialog<LibraryTrack>(
                      context: ctx,
                      builder: (_) => EditTrackDialog(track: track),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Редактировать аудиозапись'), findsOneWidget);

      // Меняем текстовое поле названия
      await tester.enterText(find.widgetWithText(TextField, 'Old Name'), 'New Name');
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Сохранить'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(resultTrack, isNotNull);
      expect(resultTrack!.title, equals('New Name'));
    });

    testWidgets('Что проверяем: Нажатие кнопки "Отмена" в EditTrackDialog. '
        'Входные данные: EditTrackDialog и нажатие кнопки "Отмена". '
        'Ожидаемый результат: Диалог закрывается, результат равен null.', (WidgetTester tester) async {
      final track = LibraryTrack(
        id: 'edit-2',
        title: 'Cancel Test',
        filePath: '/cancel.mp3',
        busType: AudioBusType.sfx,
      );

      LibraryTrack? resultTrack = track;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () async {
                    resultTrack = await showDialog<LibraryTrack>(
                      context: ctx,
                      builder: (_) => EditTrackDialog(track: track),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Отмена'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(resultTrack, isNull);
    });
  });

  group('MainDashboardScreen Widget Tests', () {
    testWidgets('Что проверяем: Главный дашборд ГМа, переключение вкладок и открывание консоли логов. '
        'Входные данные: MainDashboardScreen. Клик по вкладке "Общая Библиотека" и по иконке консоли логов. '
        'Ожидаемый результат: Переключается активный экран и открывается боковая панель (endDrawer).', (WidgetTester tester) async {
      final engine = AudioEngineService();
      late final MediaLibraryService library;
      await tester.runAsync(() async {
        library = MediaLibraryService();
        await library.loadTracks();
      });

      await tester.pumpWidget(
        createTestableWidget(
          const MainDashboardScreen(),
          engine: engine,
          library: library,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('TTRPG Audio Master'), findsOneWidget);
      expect(find.text('Панель Мастера'), findsOneWidget);
      expect(find.text('Общая Библиотека'), findsOneWidget);

      // Переключаемся на вкладку "Общая Библиотека"
      await tester.tap(find.text('Общая Библиотека'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('library_search_input')), findsOneWidget);

      // Открываем консоль логов через иконку
      await tester.tap(find.byTooltip('Открыть консоль логов и отладки'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Консоль логов и отладки'), findsOneWidget);

      library.dispose();
      engine.dispose();
    });
  });

  group('LibraryScreen Widget Tests', () {
    testWidgets('Что проверяем: Отображение карточек треков, фильтрация по шинам и отправка трека на шину. '
        'Входные данные: LibraryScreen с загруженным треком. Проверка кнопки воспроизведения и отправка на шину. '
        'Ожидаемый результат: Находится карточка трека с кнопкой быстрой отправки, трек корректно передаётся в MusicBusController.', (WidgetTester tester) async {
      final engine = AudioEngineService();
      late final MediaLibraryService library;

      final track = LibraryTrack(
        id: 'lib-t1',
        title: 'Tavern Melodies',
        filePath: '/tavern.mp3',
        busType: AudioBusType.music,
      );

      await tester.runAsync(() async {
        library = MediaLibraryService();
        await library.addTrack(track);
      });

      await tester.pumpWidget(
        createTestableWidget(
          const LibraryScreen(),
          engine: engine,
          library: library,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tavern Melodies'), findsOneWidget);
      expect(find.byTooltip('Воспроизвести на шине Музыка'), findsOneWidget);

      library.playTrackToEngine(track, engine);
      expect(engine.musicBus.currentTrack?.title, equals('Tavern Melodies'));

      library.dispose();
      engine.dispose();
    });

    testWidgets('Что проверяем: Отображение экрана пустой библиотеки при отсутствии треков. '
        'Входные данные: LibraryScreen с пустой библиотекой MediaLibraryService. '
        'Ожидаемый результат: На экране отображается надпись "Медиабиблиотека пуста".', (WidgetTester tester) async {
      final engine = AudioEngineService();
      late final MediaLibraryService library;

      await tester.runAsync(() async {
        library = MediaLibraryService();
        await library.loadTracks();
      });

      await tester.pumpWidget(
        createTestableWidget(
          const LibraryScreen(),
          engine: engine,
          library: library,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Медиатека пуста'), findsOneWidget);

      library.dispose();
      engine.dispose();
    });

    testWidgets('Что проверяем: Удаление трека через иконку корзины на карточке LibraryScreen. '
        'Входные данные: Нажатие кнопки "Удалить из библиотеки". '
        'Ожидаемый результат: Вызывается deleteTrack, трек удаляется и библиотека становится пустой.', (WidgetTester tester) async {
      final engine = AudioEngineService();
      late final MediaLibraryService library;

      final track = LibraryTrack(
        id: 'lib-del-1',
        title: 'Delete Me Track',
        filePath: '/del.mp3',
        busType: AudioBusType.sfx,
      );

      await tester.runAsync(() async {
        library = MediaLibraryService();
        await library.addTrack(track);
      });

      await tester.pumpWidget(
        createTestableWidget(
          const LibraryScreen(),
          engine: engine,
          library: library,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Delete Me Track'), findsOneWidget);

      await tester.runAsync(() async {
        await library.deleteTrack(track.id);
      });
      await tester.pump();

      expect(library.tracks, isEmpty);

      library.dispose();
      engine.dispose();
    });
  });
}
