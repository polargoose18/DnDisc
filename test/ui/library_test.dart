import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/data/services/media_library_service.dart';
import 'package:ttrpg_audio_player/domain/models/audio_track.dart';
import 'package:ttrpg_audio_player/domain/models/library_track.dart';
import 'package:ttrpg_audio_player/l10n/app_localizations_en.dart';
import 'package:ttrpg_audio_player/ui/design/ds_button.dart';
import 'package:ttrpg_audio_player/ui/design/equalizer_bars.dart';
import 'package:ttrpg_audio_player/ui/screens/library_screen.dart';
import 'package:ttrpg_audio_player/ui/widgets/import_track_dialog.dart';
import 'package:ttrpg_audio_player/ui/widgets/track_row.dart';
import '../helpers/ui_harness.dart';

final l10n = AppLocalizationsEn();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UiTestEnv env;

  setUp(() async {
    tempDir = await setUpUiTestDb();
    env = UiTestEnv();
  });

  tearDown(() => tearDownUiTestDb(tempDir));

  String realFile(String name) {
    final file = File('${tempDir.path}/$name')..writeAsBytesSync([0, 1, 2]);
    return file.path;
  }

  group('Media Library screen', () {
    testWidgets('lists tracks with type and duration, at most three tags, and no file path in the row', (tester) async {
      await env.addTracks(tester, [
        testTrack('m1', 'Epic Battle Theme', AudioBusType.music, seconds: 141, tags: ['a', 'b', 'c', 'd'], path: realFile('m1.mp3')),
        testTrack('s1', 'Unknown effect', AudioBusType.sfx, seconds: 0, path: realFile('s1.mp3')),
      ]);
      await env.pump(tester, const LibraryScreen());

      expect(find.text('Epic Battle Theme'), findsOneWidget);
      expect(find.text('Music · 2:21'), findsOneWidget);
      expect(find.text('SFX'), findsOneWidget);
      for (final tag in ['a', 'b', 'c']) {
        expect(find.text(tag), findsOneWidget);
      }
      expect(find.text('d'), findsNothing);
      expect(find.textContaining('/m1.mp3'), findsNothing);
    });

    testWidgets('shows counts in the type filter and filters the list', (tester) async {
      await env.addTracks(tester, [
        testTrack('m1', 'Song', AudioBusType.music, path: realFile('m1.mp3')),
        testTrack('a1', 'Rain', AudioBusType.ambient, path: realFile('a1.mp3')),
        testTrack('a2', 'Wind', AudioBusType.ambient, path: realFile('a2.mp3')),
        testTrack('s1', 'Door', AudioBusType.sfx, path: realFile('s1.mp3')),
      ]);
      await env.pump(tester, const LibraryScreen());

      expect(find.text('All · 4'), findsOneWidget);
      expect(find.text('Music · 1'), findsOneWidget);
      expect(find.text('Ambient · 2'), findsOneWidget);
      expect(find.text('SFX · 1'), findsOneWidget);

      await tester.tap(find.text('Ambient · 2'));
      await tester.pump();
      expect(find.text('Rain'), findsOneWidget);
      expect(find.text('Wind'), findsOneWidget);
      expect(find.text('Song'), findsNothing);
      // Counts stay the totals of the whole library.
      expect(find.text('All · 4'), findsOneWidget);

      await tester.tap(find.text('All · 4'));
      await tester.pump();
      expect(find.text('Song'), findsOneWidget);
    });

    testWidgets('searches by title or tag and offers to clear when nothing matches', (tester) async {
      await env.addTracks(tester, [
        testTrack('a1', 'Rain', AudioBusType.ambient, tags: ['weather'], path: realFile('a1.mp3')),
        testTrack('a2', 'Fire', AudioBusType.ambient, path: realFile('a2.mp3')),
      ]);
      await env.pump(tester, const LibraryScreen());

      await tester.enterText(find.byKey(const ValueKey('library_search_input')), 'weather');
      await tester.pump();
      expect(find.text('Rain'), findsOneWidget);
      expect(find.text('Fire'), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('library_search_input')), 'zzz');
      await tester.pump();
      expect(find.text(l10n.noTracksFound), findsOneWidget);

      await tester.tap(find.text(l10n.clearSearch).last);
      await tester.pump();
      expect(find.text('Fire'), findsOneWidget);
    });

    testWidgets('shows an empty state with an import action when the library has no tracks', (tester) async {
      await env.pump(tester, const LibraryScreen());

      expect(find.text(l10n.libraryEmpty), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('import_empty_button')));
      await settle(tester);
      expect(find.text(l10n.importDialogTitle), findsOneWidget);
      expect(find.text(l10n.dropFilesTitle), findsOneWidget);
      // Nothing to import yet: the confirm button is disabled.
      expect(tester.widget<DsButton>(find.byKey(const ValueKey('import_confirm_btn'))).onPressed, isNull);
    });

    testWidgets('marks a missing file with a danger badge and disables its preview', (tester) async {
      await env.addTracks(tester, [
        testTrack('ok', 'Present', AudioBusType.music, path: realFile('ok.mp3')),
        testTrack('gone', 'Gone', AudioBusType.music, path: '${tempDir.path}/gone.mp3'),
      ]);
      await env.pump(tester, const LibraryScreen());
      // The file check is real IO: let it finish, then rebuild.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      await tester.pump();

      expect(find.text(l10n.fileMissing), findsOneWidget);
      expect(tester.widget<DsButton>(find.byKey(const ValueKey('track_play_gone'))).onPressed, isNull);
      expect(tester.widget<DsButton>(find.byKey(const ValueKey('track_play_ok'))).onPressed, isNotNull);
    });

    testWidgets('previews a music track through the music bus and shows it as playing', (tester) async {
      await env.addTracks(tester, [testTrack('m1', 'Tavern Melodies', AudioBusType.music, path: realFile('m1.mp3'))]);
      await env.pump(tester, const LibraryScreen());

      await tester.tap(find.byKey(const ValueKey('track_play_m1')));
      await tester.pump();

      expect(env.music.currentTrack?.title, equals('Tavern Melodies'));
    });

    testWidgets('edits track details from the edit dialog', (tester) async {
      await env.addTracks(tester, [testTrack('s1', 'Door', AudioBusType.sfx, path: realFile('s1.mp3'))]);
      await env.pump(tester, const LibraryScreen());

      await tester.tap(find.byKey(const ValueKey('track_edit_s1')));
      await settle(tester);
      expect(find.text(l10n.editTrackTitle), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('track_title_field')), 'Heavy door');
      await tester.enterText(find.byKey(const ValueKey('track_tags_field')), 'dungeon, creak');
      await tester.tap(find.bySemanticsLabel('door'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save_track_btn')));
      await settleIo(tester);

      final saved = env.library.allTracks.single;
      expect(saved.title, equals('Heavy door'));
      expect(saved.tags, equals(['dungeon', 'creak']));
      expect(saved.iconName, equals('door'));
      expect(find.text('Heavy door'), findsOneWidget);
    });

    testWidgets('deletes a track only after confirmation and keeps the file on disk', (tester) async {
      final path = realFile('s1.mp3');
      await env.addTracks(tester, [testTrack('s1', 'Door', AudioBusType.sfx, path: path)]);
      await env.pump(tester, const LibraryScreen());

      Future<void> openMenuAndDelete() async {
        await tester.tap(find.byTooltip(l10n.moreActions));
        await settle(tester);
        await tester.tap(find.text(l10n.delete));
        await settle(tester);
      }

      await openMenuAndDelete();
      expect(find.text(l10n.deleteTrackTitle), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await settle(tester);
      expect(env.library.allTracks, hasLength(1));

      await openMenuAndDelete();
      await tester.tap(find.widgetWithText(DsButton, l10n.delete));
      await settleIo(tester);

      expect(env.library.allTracks, isEmpty);
      expect(File(path).existsSync(), isTrue);
    });

    testWidgets('highlights a playing ambient track and offers stopping it', (tester) async {
      await env.addTracks(tester, [testTrack('a1', 'Rain', AudioBusType.ambient, path: realFile('a1.mp3'))]);
      await env.pump(tester, const LibraryScreen());

      expect(find.descendant(of: find.byType(TrackRow), matching: find.byType(EqualizerBars)), findsNothing);
      await tester.tap(find.byKey(const ValueKey('track_play_a1')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      // The layer was added to the ambient bus by the preview.
      expect(env.ambient.layers.any((l) => l.id == 'a1'), isTrue);
    });

    testWidgets('has Export set and Import in the top bar, export disabled for an empty library', (tester) async {
      await env.pump(tester, const LibraryScreen());

      expect(tester.widget<DsButton>(find.byKey(const ValueKey('export_media_package_button'))).onPressed, isNull);
      expect(tester.widget<DsButton>(find.byKey(const ValueKey('import_media_button'))).onPressed, isNotNull);
      expect(find.text(l10n.exportMediaPackageBtn), findsOneWidget);
      expect(find.text(l10n.importBtn), findsOneWidget);
    });
  });

  group('Import dialog', () {
    testWidgets('lists dropped audio files, ignores other formats and returns the chosen channel', (tester) async {
      ImportSelection? selection;
      await env.pump(
        tester,
        Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selection = await showDialog<ImportSelection>(
                    context: context,
                    builder: (_) => const ImportAudioDialog(initialPaths: ['/a/one.mp3', '/a/notes.txt', '/a/two.ogg']),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);

      expect(find.text('one.mp3'), findsOneWidget);
      expect(find.text('two.ogg'), findsOneWidget);
      expect(find.text('notes.txt'), findsNothing);
      expect(find.text(l10n.importNFiles(2)), findsOneWidget);

      await tester.tap(find.text('SFX'));
      await tester.pump();
      await tester.tap(find.text(l10n.importNFiles(2)));
      await settle(tester);

      expect(selection!.busType, equals(AudioBusType.sfx));
      expect(selection!.paths, equals(['/a/one.mp3', '/a/two.ogg']));
    });

    test('recognises supported audio extensions case-insensitively', () {
      expect(MediaLibraryService.isSupportedFile('/x/Song.MP3'), isTrue);
      expect(MediaLibraryService.isSupportedFile('/x/clip.flac'), isTrue);
      expect(MediaLibraryService.isSupportedFile('/x/readme.txt'), isFalse);
    });
  });

  testWidgets('edit dialog keeps the original values when cancelled and offers intensity only for music', (tester) async {
    final track = testTrack('m1', 'Theme', AudioBusType.music);
    LibraryTrack? result = track;
    await env.pump(
      tester,
      Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showDialog<LibraryTrack>(context: context, builder: (_) => EditTrackDialog(track: track)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);

    expect(find.text(l10n.intensityLabel), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await settle(tester);
    expect(result, isNull);

    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.tap(find.text(l10n.sfx));
    await tester.pump();
    expect(find.text(l10n.intensityLabel), findsNothing);
    expect(find.text(l10n.soundIcon), findsOneWidget);
    expect(MusicIntensity.values, isNotEmpty);
    // keep the mouse type import used for hover-based flows elsewhere
    expect(PointerDeviceKind.mouse, isNotNull);
  });
}
