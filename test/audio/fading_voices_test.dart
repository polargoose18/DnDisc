import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/audio/fading_voices.dart';
import '../helpers/fakes.dart';

void main() {
  const fade = Duration(milliseconds: 300);

  testWidgets('a voice fades out and is freed at the end', (tester) async {
    final voices = FadingVoices('Test');
    final player = FakeBusPlayer('a');
    voices.fadeOutAndRelease(player, from: 1, duration: fade);

    await tester.pump(fade ~/ 2);
    expect(player.volume, inExclusiveRange(0.0, 1.0));
    expect(player.disposed, isFalse);

    await tester.pump(fade);
    expect(player.volume, 0);
    expect(player.disposed, isTrue);
  });

  testWidgets('voices fade side by side unless one replaces the others', (tester) async {
    final voices = FadingVoices('Test');
    final first = FakeBusPlayer('a');
    final second = FakeBusPlayer('b');
    final third = FakeBusPlayer('c');
    voices.fadeOutAndRelease(first, from: 1, duration: fade);
    voices.fadeOutAndRelease(second, from: 1, duration: fade);
    await tester.pump(fade ~/ 3);
    expect(first.disposed, isFalse);
    expect(second.disposed, isFalse);

    voices.fadeOutAndRelease(third, from: 1, duration: fade, replaceOthers: true);
    await tester.pump();
    expect(first.disposed, isTrue);
    expect(second.disposed, isTrue);
    expect(third.disposed, isFalse);

    await tester.pump(fade * 2);
    expect(third.disposed, isTrue);
  });

  testWidgets('releaseAll cuts off every fading voice', (tester) async {
    final voices = FadingVoices('Test');
    final player = FakeBusPlayer('a');
    voices.fadeOutAndRelease(player, from: 1, duration: fade);
    await voices.releaseAll();
    expect(player.disposed, isTrue);
    expect(player.stopped, isTrue);
  });
}
