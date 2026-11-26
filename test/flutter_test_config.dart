import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled IBM Plex fonts so text in widget tests has real widths
/// (the default test font is much wider and causes false overflows).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final family in ['IBMPlexSans', 'IBMPlexMono']) {
    final loader = FontLoader(family);
    for (final weight in ['Regular', 'Medium', 'SemiBold']) {
      final bytes = File('assets/fonts/$family-$weight.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    }
    await loader.load();
  }
  await testMain();
}
