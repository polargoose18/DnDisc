import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/domain/models/ambient_layer.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/domain/models/scene_model.dart';
import 'package:ttrpg_audio_player/domain/models/sfx_trigger.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_en.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_ru.dart';
import 'package:ttrpg_audio_player/ui/design/ds_button.dart';
import 'package:ttrpg_audio_player/ui/design/ds_dialog.dart';
import 'package:ttrpg_audio_player/ui/design/equalizer_bars.dart';
import 'package:ttrpg_audio_player/ui/screens/main_dashboard_screen.dart';
import 'package:ttrpg_audio_player/ui/screens/responsive_gm_dashboard.dart';
import 'package:ttrpg_audio_player/ui/shell/mixer_bar.dart';
import 'package:ttrpg_audio_player/ui/widgets/ambient_mixer_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/create_edit_scene_dialog.dart';
import 'package:ttrpg_audio_player/ui/widgets/music_player_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/scene_backdrop_header.dart';
import 'package:ttrpg_audio_player/ui/widgets/scene_selector_panel.dart';
import 'package:ttrpg_audio_player/ui/widgets/soundboard_grid.dart';
import '../helpers/ui_harness.dart';

final l10n = AppLocalizationsEn();

Widget panel(Widget child) => Scaffold(body: SizedBox(width: 640, height: 800, child: Padding(padding: const EdgeInsets.all(16), child: child)));

/// Moves a mouse pointer over [finder] so hover-only controls appear.
Future<TestGesture> hover(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pump(const Duration(milliseconds: 200));
  return gesture;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UiTestEnv env;

  setUp(() async {
    tempDir = await setUpUiTestDb();
    env = UiTestEnv();
  });

  tearDown(() => tearDownUiTestDb(tempDir));

  group('Scene list', () {
    testWidgets('shows an empty state with a create action when there are no scenes', (tester) async {
      await env.pump(tester, panel(const SceneSelectorPanel()));

      expect(find.text(l10n.noScenesTitle), findsOneWidget);
      expect(find.text(l10n.noScenesHint), findsOneWidget);
      expect(find.text(l10n.createSceneBtn), findsOneWidget);
    });

    testWidgets('lists scenes with one metadata line and activates a scene on tap', (tester) async {
      await env.addScenes(tester, [
        SceneModel(id: 'a', name: 'Tavern at night', musicIntensity: MusicIntensity.calm, ambientLayerVolumes: const {'x': 1}, soundboardSfxIds: const ['s1', 's2']),
        SceneModel(id: 'b', name: 'Catacombs', musicIntensity: MusicIntensity.suspense),
      ]);
      await env.pump(tester, panel(const SceneSelectorPanel()));

      expect(find.text('Tavern at night'), findsOneWidget);
      expect(find.text('Calm · 1 ambient · 2 SFX'), findsOneWidget);
      expect(find.text('Suspense · 0 ambient · 0 SFX'), findsOneWidget);
      expect(find.byType(EqualizerBars), findsNothing);

      await tester.tap(find.text('Catacombs'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(env.scenes.activeSceneId, equals('b'));
      // The active scene is marked by its background only: no equalizer next
      // to the more button.
      expect(find.descendant(of: find.byKey(const ValueKey('scene_card_b')), matching: find.byType(EqualizerBars)), findsNothing);
    });

    testWidgets('filters scenes by search and offers to clear the search when nothing matches', (tester) async {
      await env.addScenes(tester, [SceneModel(id: 'a', name: 'Tavern'), SceneModel(id: 'b', name: 'Catacombs')]);
      await env.pump(tester, panel(const SceneSelectorPanel()));

      await tester.enterText(find.byType(TextField), 'cata');
      await tester.pump();
      expect(find.text('Tavern'), findsNothing);
      expect(find.text('Catacombs'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text(l10n.noScenesFoundTitle), findsOneWidget);

      await tester.tap(find.text(l10n.clearSearch).last);
      await tester.pump();
      expect(find.text('Tavern'), findsOneWidget);
    });

    testWidgets('deletes a scene only after the confirmation dialog', (tester) async {
      await env.addScenes(tester, [SceneModel(id: 'a', name: 'Tavern')]);
      await env.pump(tester, panel(const SceneSelectorPanel()));

      final gesture = await hover(tester, find.text('Tavern'));
      await tester.tap(find.byTooltip(l10n.moreActions));
      await settle(tester);
      await tester.tap(find.text(l10n.delete));
      await settle(tester);

      expect(find.text(l10n.deleteSceneTitle), findsOneWidget);
      // Cancel keeps the scene.
      await tester.tap(find.text(l10n.cancel));
      await settle(tester);
      expect(find.text('Tavern'), findsWidgets);

      await tester.tap(find.byTooltip(l10n.moreActions));
      await settle(tester);
      await tester.tap(find.text(l10n.delete));
      await settle(tester);
      await tester.tap(find.widgetWithText(DsButton, l10n.delete));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await settle(tester);

      expect(env.scenes.scenes, isEmpty);
      await gesture.removePointer();
    });
  });

  group('Create and edit scene dialog', () {
    Future<void Function()> openDialog(WidgetTester tester, {SceneModel? scene, required void Function(SceneModel?) onResult}) async {
      await env.pump(
        tester,
        Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () async => onResult(await showDsDialog<SceneModel>(context: context, builder: (_) => CreateEditSceneDialog(scene: scene))),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      return () {};
    }

    testWidgets('requires a name and returns the scene with the chosen cover, intensity and sounds', (tester) async {
      await env.addTracks(tester, [
        testTrack('m1', 'Wyrdness', AudioBusType.music),
        testTrack('a1', 'Rain', AudioBusType.ambient),
        testTrack('s1', 'Door creaks', AudioBusType.sfx),
      ]);
      SceneModel? result;
      await openDialog(tester, onResult: (s) => result = s);

      expect(find.text(l10n.createSceneTitle), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('save_scene_btn')));
      await tester.pump();
      expect(find.text(l10n.specifySceneName), findsOneWidget);
      expect(result, isNull);

      await tester.enterText(find.byKey(const ValueKey('scene_name_field')), 'Harbor at dusk');
      await tester.tap(find.byKey(const ValueKey('cover_sea')));
      await tester.tap(find.text(l10n.intensityBattle));
      await tester.tap(find.byKey(const ValueKey('scene_sound_m1')));
      await tester.tap(find.byKey(const ValueKey('scene_sound_a1')));
      await tester.tap(find.byKey(const ValueKey('scene_sound_s1')));
      await tester.pump();
      expect(find.text(l10n.soundsSelected(3)), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save_scene_btn')));
      await settle(tester);

      expect(result, isNotNull);
      expect(result!.name, equals('Harbor at dusk'));
      expect(result!.cover, equals('sea'));
      expect(result!.musicIntensity, equals(MusicIntensity.battle));
      expect(result!.musicTrackId, equals('m1'));
      expect(result!.ambientLayerVolumes.keys, equals(['a1']));
      expect(result!.soundboardSfxIds, equals(['s1']));
    });

    testWidgets('keeps one music track at a time and lets a checked row be unchecked', (tester) async {
      await env.addTracks(tester, [testTrack('m1', 'One', AudioBusType.music), testTrack('m2', 'Two', AudioBusType.music)]);
      SceneModel? result;
      await openDialog(tester, onResult: (s) => result = s);

      await tester.enterText(find.byKey(const ValueKey('scene_name_field')), 'Scene');
      await tester.tap(find.byKey(const ValueKey('scene_sound_m1')));
      await tester.tap(find.byKey(const ValueKey('scene_sound_m2')));
      await tester.pump();
      expect(find.text(l10n.soundsSelected(1)), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scene_sound_m2')));
      await tester.pump();
      expect(find.text(l10n.soundsSelected(0)), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save_scene_btn')));
      await settle(tester);
      expect(result!.musicTrackId, isNull);
    });

    testWidgets('filters the sound list by title or tag', (tester) async {
      await env.addTracks(tester, [testTrack('a1', 'Rain', AudioBusType.ambient), testTrack('a2', 'Wind', AudioBusType.ambient, tags: ['storm'])]);
      await openDialog(tester, onResult: (_) {});

      await tester.enterText(find.byKey(const ValueKey('scene_sound_filter')), 'storm');
      await tester.pump();
      expect(find.byKey(const ValueKey('scene_sound_a1')), findsNothing);
      expect(find.byKey(const ValueKey('scene_sound_a2')), findsOneWidget);
    });

    testWidgets('asks before discarding a changed form and keeps it when editing continues', (tester) async {
      SceneModel? result;
      var closed = false;
      await openDialog(tester, onResult: (s) {
        result = s;
        closed = true;
      });

      await tester.enterText(find.byKey(const ValueKey('scene_name_field')), 'Half done');
      await tester.pump();
      await tester.tap(find.byTooltip(l10n.close));
      await settle(tester);

      expect(find.text(l10n.discardChangesTitle), findsOneWidget);
      await tester.tap(find.text(l10n.keepEditing));
      await settle(tester);
      expect(closed, isFalse);
      expect(find.text(l10n.createSceneTitle), findsWidgets);

      await tester.tap(find.byTooltip(l10n.close).last);
      await settle(tester);
      await tester.tap(find.text(l10n.discard));
      await settle(tester);
      expect(closed, isTrue);
      expect(result, isNull);
    });

    testWidgets('closes an untouched form without asking and keeps old description and colour when editing', (tester) async {
      final scene = SceneModel(id: 'e', name: 'Old', description: 'GM notes', colorHex: 0xFF123456, cover: 'peaks');
      SceneModel? result;
      var closed = false;
      await openDialog(tester, scene: scene, onResult: (s) {
        result = s;
        closed = true;
      });

      expect(find.text(l10n.editSceneTitle), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.close));
      await settle(tester);
      expect(closed, isTrue);
      expect(find.text(l10n.discardChangesTitle), findsNothing);
      expect(result, isNull);

      closed = false;
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('save_scene_btn')));
      await settle(tester);
      expect(result!.description, equals('GM notes'));
      expect(result!.colorHex, equals(0xFF123456));
      expect(result!.cover, equals('peaks'));
    });
  });

  group('Scene header', () {
    testWidgets('shows the active scene and the only intensity switch of the app', (tester) async {
      await env.addScenes(tester, [SceneModel(id: 'a', name: 'Catacombs', musicIntensity: MusicIntensity.suspense, ambientLayerVolumes: const {'x': 1, 'y': 1, 'z': 1}, soundboardSfxIds: List.generate(12, (i) => 's$i'))]);
      await env.scenes.activateScene(env.scenes.scenes.first);
      await env.pump(tester, panel(const SceneBackdropHeader()));

      expect(find.text('Catacombs'), findsOneWidget);
      expect(find.text('Suspense · 3 ambient · 12 SFX'), findsOneWidget);
      for (final name in ['Calm', 'Suspense', 'Battle', 'Boss']) {
        expect(find.text(name), findsOneWidget);
      }
      for (final key in ['1', '2', '3', '4']) {
        expect(find.text(key), findsOneWidget);
      }
    });

    testWidgets('switches the music intensity without starting playback', (tester) async {
      await env.addScenes(tester, [SceneModel(id: 'a', name: 'Catacombs')]);
      await env.scenes.activateScene(env.scenes.scenes.first);
      await env.pump(tester, panel(const SceneBackdropHeader()));

      expect(env.music.currentIntensity, equals(MusicIntensity.calm));
      await tester.tap(find.text('Battle'));
      await tester.pump();

      expect(env.music.currentIntensity, equals(MusicIntensity.battle));
      expect(env.music.isPlaying, isFalse);
    });

    testWidgets('asks to pick a scene when none is active and localises the levels in Russian', (tester) async {
      await env.pump(tester, panel(const SceneBackdropHeader()), locale: const Locale('ru'));
      expect(find.text(AppLocalizationsRu().selectScenePrompt), findsOneWidget);

      await env.addScenes(tester, [SceneModel(id: 'a', name: 'Склеп')]);
      await env.scenes.activateScene(env.scenes.scenes.first);
      await tester.pump();
      final ru = AppLocalizationsRu();
      expect(find.text(ru.intensityBattle), findsOneWidget);
      expect(find.text(ru.intensityCalm), findsOneWidget);
    });
  });

  group('Music card', () {
    testWidgets('shows an idle state without intensity or volume controls', (tester) async {
      await env.pump(tester, panel(const MusicPlayerPanel()));

      expect(find.text(l10n.noMusic), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
      expect(find.text(l10n.intensityBattle), findsNothing);
      expect(tester.widget<DsButton>(find.byKey(const ValueKey('music_play_pause_button'))).onPressed, isNull);
    });

    testWidgets('shows the track, the paused badge and the duration of the prepared track', (tester) async {
      await tester.runAsync(() => env.music.prepareTrack(const AudioTrack(id: 'm1', title: '11 — Wyrdness', filePath: '/missing/m1.mp3')));
      await env.pump(tester, panel(const MusicPlayerPanel()));

      expect(find.text('11 — Wyrdness'), findsOneWidget);
      expect(find.text(l10n.paused), findsOneWidget);
      expect(find.text(l10n.playing), findsNothing);
      expect(find.text('0:00'), findsNWidgets(2));
      expect(formatDuration(const Duration(minutes: 3, seconds: 4)), equals('3:04'));
    });
  });

  group('Ambient layers', () {
    testWidgets('shows an empty state with an add action', (tester) async {
      await env.pump(tester, panel(const AmbientMixerPanel()));

      expect(find.text(l10n.noAmbientTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('add_ambient_layer_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('ambient_stop_all_btn')), findsNothing);
    });

    testWidgets('renders a row per layer with its counter and lets the volume change while the layer is off', (tester) async {
      env.ambient.addLayer(const AmbientLayer(id: 'a', title: 'Dripping water', filePath: '/missing/a.mp3', volume: 0.8, isActive: true, isPersistent: true, iconName: 'cave'));
      env.ambient.addLayer(const AmbientLayer(id: 'b', title: 'Torch crackle', filePath: '/missing/b.mp3', volume: 0.3));
      await env.pump(tester, panel(const AmbientMixerPanel()));

      expect(find.text('Dripping water'), findsOneWidget);
      expect(find.text('Torch crackle'), findsOneWidget);
      expect(find.text(l10n.ambientOnCount(1, 2)), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      // An active layer shows an equalizer, the muted one does not.
      expect(find.descendant(of: find.byKey(const ValueKey('ambient_row_a')), matching: find.byType(EqualizerBars)), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('ambient_row_b')), matching: find.byType(EqualizerBars)), findsNothing);

      final slider = find.descendant(of: find.byKey(const ValueKey('ambient_slider_b')), matching: find.byType(Slider));
      await tester.drag(slider, const Offset(60, 0));
      await tester.pump();
      expect(env.ambient.layers.firstWhere((l) => l.id == 'b').volume, greaterThan(0.3));
    });

    testWidgets('pins and removes a layer from its menu', (tester) async {
      env.ambient.addLayer(const AmbientLayer(id: 'a', title: 'Wind', filePath: '/missing/a.mp3'));
      await env.pump(tester, panel(const AmbientMixerPanel()));

      await tester.tap(find.byTooltip(l10n.moreActions));
      await settle(tester);
      await tester.tap(find.text(l10n.pinEverywhere));
      await settle(tester);
      expect(env.ambient.layers.single.isPersistent, isTrue);

      await tester.tap(find.byTooltip(l10n.moreActions));
      await settle(tester);
      await tester.tap(find.text(l10n.removeLayer));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await settle(tester);
      expect(env.ambient.layers, isEmpty);
    });

    testWidgets('adds a layer from the library with the chosen icon', (tester) async {
      await env.addTracks(tester, [testTrack('a1', 'Rain on the roof', AudioBusType.ambient)]);
      await env.pump(tester, panel(const AmbientMixerPanel()));

      await tester.tap(find.byKey(const ValueKey('add_ambient_layer_btn')));
      await settle(tester);
      expect(find.text(l10n.addAmbientDialogTitle), findsOneWidget);
      expect(tester.widget<DsButton>(find.byKey(const ValueKey('add_ambient_confirm_btn'))).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('pick_a1')));
      await tester.tap(find.bySemanticsLabel('rain'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('add_ambient_confirm_btn')));
      await settle(tester);

      final layer = env.ambient.layers.single;
      expect(layer.id, equals('a1'));
      expect(layer.iconName, equals('rain'));
      expect(layer.isPersistent, isTrue);
    });
  });

  group('SFX soundboard', () {
    testWidgets('shows only the empty slot when there are no sounds', (tester) async {
      await env.pump(tester, panel(const SoundboardGrid()));

      expect(find.byKey(const ValueKey('add_sfx_trigger_btn')), findsOneWidget);
      expect(find.text('1–9'), findsOneWidget);
    });

    testWidgets('renders square tiles with their number and the empty slot last', (tester) async {
      for (var i = 1; i <= 3; i++) {
        env.sfx.addTrigger(SfxTrigger(id: 's$i', title: 'Sound $i', filePath: '/missing/s$i.mp3', iconName: 'door'));
      }
      await env.pump(tester, panel(const SoundboardGrid()));

      for (var i = 1; i <= 3; i++) {
        expect(find.text('Sound $i'), findsOneWidget);
        expect(find.text('$i'), findsOneWidget);
      }
      final tile = tester.getSize(find.byKey(const ValueKey('sfx_btn_s1')));
      expect(tile.width, closeTo(tile.height, 0.5));
      expect(tile.width, greaterThanOrEqualTo(96));
      final emptySlot = tester.getTopLeft(find.byKey(const ValueKey('add_sfx_trigger_btn')));
      final lastTile = tester.getTopLeft(find.byKey(const ValueKey('sfx_btn_s3')));
      expect(emptySlot.dx > lastTile.dx || emptySlot.dy > lastTile.dy, isTrue);
    });

    testWidgets('highlights a tile that was pressed and shows its equalizer in place of the key', (tester) async {
      env.sfx.addTrigger(const SfxTrigger(id: 's1', title: 'Door', filePath: '/missing/s1.mp3'));
      await env.pump(tester, panel(const SoundboardGrid()));

      expect(find.descendant(of: find.byKey(const ValueKey('sfx_btn_s1')), matching: find.byType(EqualizerBars)), findsNothing);
      await tester.tap(find.byKey(const ValueKey('sfx_btn_s1')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.descendant(of: find.byKey(const ValueKey('sfx_btn_s1')), matching: find.byType(EqualizerBars)), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('sfx_btn_s1')), matching: find.text('1')), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.descendant(of: find.byKey(const ValueKey('sfx_btn_s1')), matching: find.byType(EqualizerBars)), findsNothing);
    });

    testWidgets('draws the progress as a ring along the tile border that grows while the sound plays', (tester) async {
      env.sfx.addTrigger(const SfxTrigger(id: 's1', title: 'Door', filePath: '/missing/s1.mp3'));
      await env.pump(tester, panel(const SoundboardGrid()));

      Finder ring() => find.descendant(
            of: find.byKey(const ValueKey('sfx_btn_s1')),
            matching: find.byWidgetPredicate((w) => w is CustomPaint && w.foregroundPainter is SfxProgressRingPainter),
          );
      double progress() => (tester.widget<CustomPaint>(ring()).foregroundPainter! as SfxProgressRingPainter).progress;

      expect(ring(), findsNothing);
      await tester.tap(find.byKey(const ValueKey('sfx_btn_s1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final early = progress();
      await tester.pump(const Duration(milliseconds: 150));
      expect(progress(), greaterThan(early));

      await tester.pump(const Duration(seconds: 2));
      expect(ring(), findsNothing);
      expect(find.descendant(of: find.byKey(const ValueKey('sfx_btn_s1')), matching: find.byType(EqualizerBars)), findsNothing);
    });

    testWidgets('pins, loops and removes a tile through its menu (long press)', (tester) async {
      env.sfx.addTrigger(const SfxTrigger(id: 's1', title: 'Door', filePath: '/missing/s1.mp3'));
      await env.pump(tester, panel(const SoundboardGrid()));

      Future<void> choose(String label) async {
        await tester.longPress(find.byKey(const ValueKey('sfx_btn_s1')));
        await settle(tester);
        await tester.tap(find.text(label));
        await settle(tester);
      }

      await choose(l10n.pinSfx);
      expect(env.sfx.triggers.single.isPersistent, isTrue);
      await choose(l10n.loopModeCheckbox);
      expect(env.sfx.triggers.single.isLoop, isTrue);
      await choose(l10n.deleteSfxButton);
      expect(env.sfx.triggers, isEmpty);
    });

    testWidgets('adds a sound from the library with its icon', (tester) async {
      await env.addTracks(tester, [testTrack('s9', 'Dragon roar', AudioBusType.sfx)]);
      await env.pump(tester, panel(const SoundboardGrid()));

      await tester.tap(find.byKey(const ValueKey('add_sfx_trigger_btn')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('pick_s9')));
      await tester.tap(find.bySemanticsLabel('dragon'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('add_sfx_confirm_btn')));
      await settle(tester);

      final trigger = env.sfx.triggers.single;
      expect(trigger.title, equals('Dragon roar'));
      expect(trigger.iconName, equals('dragon'));
    });
  });

  group('Dashboard layouts', () {
    testWidgets('wide window: scenes panel, header, two columns and the mixer', (tester) async {
      await env.pump(tester, const MainDashboardScreen(), size: const Size(1440, 900));

      expect(find.byType(SceneSelectorPanel), findsOneWidget);
      expect(find.byType(SceneBackdropHeader), findsOneWidget);
      expect(find.byType(MusicPlayerPanel), findsOneWidget);
      expect(find.byType(AmbientMixerPanel), findsOneWidget);
      expect(find.byType(SoundboardGrid), findsOneWidget);
      expect(find.byType(MixerBar), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
      // Music is left of SFX (1.2 : 1 columns).
      expect(tester.getTopLeft(find.byType(MusicPlayerPanel)).dx, lessThan(tester.getTopLeft(find.byType(SoundboardGrid)).dx));
    });

    testWidgets('medium window: one column, scenes in a slide-out panel', (tester) async {
      await env.addScenes(tester, [SceneModel(id: 'a', name: 'Tavern')]);
      await env.pump(tester, const MainDashboardScreen(), size: const Size(900, 1000));

      expect(find.byType(SceneSelectorPanel), findsNothing);
      // Order: header (intensity), Music, SFX, Ambient.
      final music = tester.getTopLeft(find.byType(MusicPlayerPanel)).dy;
      final sfx = tester.getTopLeft(find.byType(SoundboardGrid)).dy;
      final header = tester.getTopLeft(find.byType(SceneBackdropHeader)).dy;
      expect(header, lessThan(music));
      expect(music, lessThan(sfx));

      await tester.tap(find.byKey(const ValueKey('show_scenes_btn')));
      await settle(tester);
      expect(find.byType(SceneSelectorPanel), findsOneWidget);
      expect(find.text('Tavern'), findsOneWidget);
    });

    testWidgets('compact window: header once and four bottom tabs', (tester) async {
      await env.pump(tester, const MainDashboardScreen(), size: const Size(600, 900));

      expect(find.byType(SceneBackdropHeader), findsOneWidget);
      for (final tab in ['scenes', 'music', 'ambient', 'sfx']) {
        expect(find.byKey(ValueKey('compact_tab_$tab')), findsOneWidget);
      }
      expect(find.byType(SceneSelectorPanel), findsOneWidget);
      expect(find.byType(MusicPlayerPanel), findsNothing);

      await tester.tap(find.byKey(const ValueKey('compact_tab_music')));
      await tester.pump();
      expect(find.byType(MusicPlayerPanel), findsOneWidget);
      expect(find.byType(SceneBackdropHeader), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('compact_tab_sfx')));
      await tester.pump();
      expect(find.byType(SoundboardGrid), findsOneWidget);
      expect(find.byType(MusicPlayerPanel), findsNothing);
    });

    testWidgets('dashboard content alone adapts to the window width without the shell', (tester) async {
      await env.pump(tester, const ResponsiveGmDashboard(), size: const Size(1200, 900));
      expect(find.byType(SceneSelectorPanel), findsOneWidget);
    });
  });

  group('Mixer', () {
    testWidgets('has Music, Ambient, SFX and Master sliders that drive the buses', (tester) async {
      await env.pump(tester, const MainDashboardScreen(), size: const Size(1440, 900));

      for (final key in ['mixer_music_slider', 'mixer_ambient_slider', 'mixer_sfx_slider', 'mixer_master_slider']) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      final before = env.music.rawVolume;
      await tester.drag(find.descendant(of: find.byKey(const ValueKey('mixer_music_slider')), matching: find.byType(Slider)), const Offset(-30, 0));
      await tester.pump();
      expect(env.music.rawVolume, lessThan(before));

      final ambientBefore = env.ambient.channelVolume;
      await tester.drag(find.descendant(of: find.byKey(const ValueKey('mixer_ambient_slider')), matching: find.byType(Slider)), const Offset(-30, 0));
      await tester.pump();
      expect(env.ambient.channelVolume, lessThan(ambientBefore));

      final masterBefore = env.engine.masterVolume;
      await tester.drag(find.descendant(of: find.byKey(const ValueKey('mixer_master_slider')), matching: find.byType(Slider)), const Offset(-30, 0));
      await tester.pump();
      expect(env.engine.masterVolume, lessThan(masterBefore));
    });

    testWidgets('mutes and unmutes from the master channel icon', (tester) async {
      await env.pump(tester, const MainDashboardScreen(), size: const Size(1440, 900));

      await tester.tap(find.byKey(const ValueKey('mixer_mute_button')));
      await tester.pump();
      expect(env.engine.isMuted, isTrue);
      await tester.tap(find.byKey(const ValueKey('mixer_mute_button')));
      await tester.pump();
      expect(env.engine.isMuted, isFalse);
    });

    testWidgets('shows the current track with its state and keeps only Master on narrow windows', (tester) async {
      await tester.runAsync(() => env.music.prepareTrack(const AudioTrack(id: 'm1', title: 'Wyrdness', filePath: '/missing/m1.mp3')));
      await env.pump(tester, const MainDashboardScreen(), size: const Size(900, 900));

      expect(find.descendant(of: find.byType(MixerBar), matching: find.text('Wyrdness')), findsOneWidget);
      expect(find.descendant(of: find.byType(MixerBar), matching: find.text(l10n.paused)), findsOneWidget);
      expect(find.byKey(const ValueKey('mixer_music_slider')), findsNothing);
      expect(find.byKey(const ValueKey('mixer_master_slider')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mixer_channels_button')));
      await settle(tester);
      expect(find.byType(Slider), findsWidgets);
      expect(find.bySemanticsLabel(l10n.music), findsWidgets);
    });

    testWidgets('is present on every screen so the music keeps playing between screens', (tester) async {
      await env.pump(tester, const MainDashboardScreen(), size: const Size(1440, 900));
      for (final tooltip in [l10n.tabLibrary, l10n.tabCatalog, l10n.tabSettings, l10n.tabGmDashboard]) {
        await tester.tap(find.byTooltip(tooltip).first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(MixerBar), findsOneWidget, reason: tooltip);
      }
    });
  });

  test('library track type is exposed for the icon defaults', () {
    expect(AudioBusType.values.length, equals(3));
    expect(const AmbientLayer(id: 'x', title: 't', filePath: 'p').iconName, isNull);
    expect(LibraryTrack(id: 'x', title: 't', filePath: 'p', busType: AudioBusType.sfx).iconName, isNull);
  });
}
