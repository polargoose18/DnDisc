import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/audio/audio_output_service.dart';
import 'package:ttrpg_audio_player/audio/playback/bus_player.dart';
import 'package:ttrpg_audio_player/audio/playback/soloud_bus_player.dart';
import 'package:ttrpg_audio_player/data/services/database_service.dart';
import '../helpers/fakes.dart';
import '../helpers/ui_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const speakers = OutputDevice('alsa_output.speakers', label: 'Speakers', isDefault: true);
  const headset = OutputDevice('bluez_output.headset', label: 'Headset');

  group('AudioOutputService', () {
    late Directory tempDir;

    setUp(() async => tempDir = await setUpUiTestDb());
    tearDown(() => tearDownUiTestDb(tempDir));

    test('starts on the system default and lists the devices', () async {
      final backend = FakeOutputBackend([speakers, headset]);
      final output = AudioOutputService(backend: backend, supported: true);
      await output.init();

      expect(backend.started, isTrue);
      expect(backend.startedOn, isNull);
      expect(output.selectedDevice, isNull);
      expect(output.devices, [speakers, headset]);
    });

    test('moves the sound to the chosen device, remembers it and starts on it next time', () async {
      final db = DatabaseService();
      final backend = FakeOutputBackend([speakers, headset]);
      final output = AudioOutputService(backend: backend, db: db, supported: true);
      await output.init();

      await output.select(headset.id);
      expect(backend.changes, [headset.id]);
      expect(output.selectedDevice, headset.id);
      expect(output.selectedLabel, 'Headset');
      expect(await db.getSetting(AudioOutputService.settingKey), headset.id);

      final nextRun = FakeOutputBackend([speakers, headset]);
      await AudioOutputService(backend: nextRun, db: db, supported: true).init();
      expect(nextRun.startedOn, headset.id);

      await output.select(null);
      expect(await db.getSetting(AudioOutputService.settingKey), '');
    });

    test('reports a saved device that is not connected', () async {
      final backend = FakeOutputBackend([speakers, headset]);
      final output = AudioOutputService(backend: backend, supported: true);
      await output.init();
      await output.select(headset.id);

      backend.devices = [speakers];
      await output.refresh();
      expect(output.selectedIsMissing, isTrue);
      expect(output.selectedLabel, headset.id);
    });

    test('keeps the previous device when switching fails', () async {
      final backend = FakeOutputBackend([speakers, headset])..failChange = true;
      final output = AudioOutputService(backend: backend, supported: true);
      await output.init();

      await expectLater(output.select(headset.id), throwsStateError);
      expect(output.selectedDevice, isNull);
    });

    test('does not offer a choice where it is not supported (Android)', () async {
      final backend = FakeOutputBackend([speakers, headset]);
      final output = AudioOutputService(backend: backend, supported: false);
      await output.init();

      expect(backend.started, isTrue);
      expect(output.devices, isEmpty);
      await output.select(headset.id);
      expect(backend.changes, isEmpty);
    });
  });

  group('Stream volume on the sound server (Linux)', () {
    late Directory tempDir;

    setUp(() async => tempDir = await setUpUiTestDb());
    tearDown(() => tearDownUiTestDb(tempDir));

    AudioOutputService service(FakeStreamVolume volume, {DatabaseService? db}) =>
        AudioOutputService(backend: FakeOutputBackend([speakers]), supported: true, db: db, streamVolume: volume);

    test('the first start resets a stream left at 0 % by older builds and remembers it did', () async {
      final db = DatabaseService();
      final volume = FakeStreamVolume([(index: 7, silent: true)]);
      final events = <void>[];
      final output = service(volume, db: db);
      output.systemSilenced.listen(events.add);

      await output.init();
      await Future<void>.delayed(Duration.zero);
      expect(volume.restored, [7]);
      expect(events, isEmpty);
      expect(await db.getSetting(AudioOutputService.streamVolumeResetKey), '1');
    });

    test('later a silenced stream is the user\'s choice: it is reported, not changed', () async {
      final db = DatabaseService();
      await db.setSetting(AudioOutputService.streamVolumeResetKey, '1');
      final volume = FakeStreamVolume([(index: 7, silent: true)]);
      final events = <void>[];
      final output = service(volume, db: db);
      output.systemSilenced.listen(events.add);

      await output.init();
      await Future<void>.delayed(Duration.zero);
      expect(volume.restored, isEmpty);
      expect(events, hasLength(1));
    });

    test('an audible stream is left alone', () async {
      final volume = FakeStreamVolume([(index: 3, silent: false)]);
      final events = <void>[];
      final output = service(volume);
      output.systemSilenced.listen(events.add);

      await output.init();
      expect(volume.restored, isEmpty);
      expect(events, isEmpty);
    });

    test('waits for the engine\'s stream to appear on the server', () async {
      final volume = FakeStreamVolume([(index: 9, silent: true)], appearsAfter: 3);
      await service(volume).init();
      expect(volume.lookups, 4);
      expect(volume.restored, [9]);
    });
  });

  group('BusPlayer', () {
    test('plays every format, M4A included, on SoLoud', () {
      for (final path in ['/a/x.mp3', '/a/x.WAV', '/a/x.ogg', '/a/x.flac', '/a/x.m4a']) {
        expect(BusPlayer.forFile(path), isA<SoLoudBusPlayer>(), reason: path);
      }
      expect((BusPlayer.forFile('/a/x.m4a', bus: 'music') as SoLoudBusPlayer).bus, 'music');
    });
  });
}

class FakeStreamVolume implements StreamVolume {
  final List<({int index, bool silent})> streams;
  final int appearsAfter;
  final List<int> restored = [];
  int lookups = 0;

  FakeStreamVolume(this.streams, {this.appearsAfter = 0});

  @override
  Future<List<({int index, bool silent})>> ownStreams() async => lookups++ < appearsAfter ? const [] : streams;

  @override
  Future<bool> restore(int index) async {
    restored.add(index);
    return true;
  }
}
