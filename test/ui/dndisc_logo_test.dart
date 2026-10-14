import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/ui/widgets/dndisc_logo.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  group('DnDiscLogo Widget Tests', () {
    testWidgets('should render DnDiscLogo with default symbol when instantiated', (tester) async {
      // Arrange
      const widget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: DnDiscLogo(size: 32),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);

      // Assert
      expect(find.byType(DnDiscLogo), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('should render full badge logo when useSymbol is false', (tester) async {
      // Arrange
      const widget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: DnDiscLogo(size: 48, useSymbol: false),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);

      // Assert
      expect(find.byType(DnDiscLogo), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('should apply custom color when color parameter is provided', (tester) async {
      // Arrange
      const customColor = Colors.amber;
      const widget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: DnDiscLogo(size: 32, color: customColor),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);

      // Assert
      final logoFinder = find.byType(DnDiscLogo);
      expect(logoFinder, findsOneWidget);
      final logoWidget = tester.widget<DnDiscLogo>(logoFinder);
      expect(logoWidget.color, customColor);
      expect(logoWidget.size, 32.0);
    });
  });
}
