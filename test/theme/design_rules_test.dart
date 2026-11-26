import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// The design system forbids raw colours, numbers in padding and radii, fonts
/// other than IBM Plex and decorative glow. These checks keep the UI code on
/// the theme and the constants.
void main() {
  final files = Directory('lib/ui')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  Map<String, List<int>> find(RegExp pattern, {bool Function(String line)? skip}) {
    final hits = <String, List<int>>{};
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (skip != null && skip(line)) continue;
        if (pattern.hasMatch(line)) hits.putIfAbsent(file.path, () => []).add(i + 1);
      }
    }
    return hits;
  }

  test('the UI does not use the Colors palette', () {
    expect(find(RegExp(r'\bColors\.')), isEmpty);
  });

  test('the UI has no hard-coded Color(...) values', () {
    // The logo recolours the two colours of its SVG source (flutter_svg ColorMapper).
    expect(find(RegExp(r'\bColor\(0x'), skip: (l) => l.contains('substitute') || l.contains('color == const Color')), isEmpty);
  });

  test('the UI does not use withValues or withOpacity', () {
    expect(find(RegExp(r'\.withValues\(|\.withOpacity\(')), isEmpty);
  });

  test('padding and radii come from the tokens, not from numbers', () {
    final padding = RegExp(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*(?<![\w.])[1-9]\d*(\.\d+)?(?![\w.])');
    final radius = RegExp(r'(BorderRadius|Radius)\.(circular|all)\(\s*\d');
    expect(find(padding), isEmpty);
    expect(find(radius), isEmpty);
  });

  test('there is one font family and no Google Fonts', () {
    expect(find(RegExp(r'GoogleFonts|fontFamilyFallback')), isEmpty);
  });

  test('cards and tiles have no glow or shadow of their own', () {
    // Only menus, dialogs and toasts have a shadow, and it is Shadows.overlay.
    expect(find(RegExp(r'\bBoxShadow\(|boxShadow:'), skip: (l) => l.contains('Shadows.overlay')), isEmpty);
  });

  test('curves and durations come from Easings and Durations', () {
    expect(find(RegExp(r'Duration\((milliseconds|seconds|minutes): *\d')), isEmpty);
  });
}
