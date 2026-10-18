import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ttrpg_audio_player/theme/app_themes.dart';
import 'package:ttrpg_audio_player/ui/widgets/dndisc_logo.dart';

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? AppThemes.deepDark.toThemeData(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('DnDiscLogo Widget Tests', () {
    testWidgets('should render the logo mark of the requested size', (tester) async {
      await tester.pumpWidget(_app(const DnDiscLogo(size: 32)));

      expect(find.byType(DnDiscLogo), findsOneWidget);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.width, equals(32));
      expect(svg.height, equals(32));
      expect(find.text('DnDisc'), findsNothing);
    });

    testWidgets('should add the wordmark in IBM Plex Sans when requested', (tester) async {
      await tester.pumpWidget(_app(const DnDiscLogo(size: 40, wordmark: true)));

      final text = tester.widget<Text>(find.text('DnDisc'));
      expect(text.style?.fontFamily, equals('IBMPlexSans'));
      expect(text.style?.fontWeight, equals(FontWeight.w600));
      expect(text.style?.fontSize, closeTo(40 * 0.8, 0.001));
    });

    testWidgets('should take outline and spindle colours from the active theme', (tester) async {
      await tester.pumpWidget(_app(
        const DnDiscLogo(),
        theme: AppThemes.cleanLight.toThemeData(),
      ));

      expect(find.byType(SvgPicture), findsOneWidget);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final loader = svg.bytesLoader as SvgAssetLoader;
      expect(loader.assetName, equals('assets/logo/logo-mark.svg'));
      expect(loader.colorMapper, isNotNull);
    });
  });
}
