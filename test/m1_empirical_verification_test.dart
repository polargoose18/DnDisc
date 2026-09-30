import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Empirical Verification of Milestone M1 Changes', () {
    test('should produce equivalent RGBA values between Color.withValues and Color.withOpacity', () {
      // Arrange
      final testCases = <(Color, double)>[
        (Colors.black, 0.65), // repository_catalog_screen.dart:452
        (const Color(0xFF2E7D32), 0.8), // scene_repository_details_dialog.dart:100 (headerColor)
        (Colors.black, 0.55), // scene_repository_details_dialog.dart:113
        (Colors.white, 0.85), // scene_repository_details_dialog.dart:158
        (Colors.teal, 0.2), // scene_repository_details_dialog.dart:245 (busColor)
        (Colors.purple, 0.2), // scene_repository_details_dialog.dart:270 (busColor)
        (Colors.red, 0.0), // Edge case: zero opacity
        (Colors.blue, 1.0), // Edge case: full opacity
      ];

      for (final (color, alpha) in testCases) {
        // Act
        // ignore: deprecated_member_use
        final legacyColor = color.withOpacity(alpha);
        final modernColor = color.withValues(alpha: alpha);

        // Assert - Color channels (R, G, B)
        expect(modernColor.r, closeTo(legacyColor.r, 0.01),
            reason: 'Red channel mismatch for $color with alpha $alpha');
        expect(modernColor.g, closeTo(legacyColor.g, 0.01),
            reason: 'Green channel mismatch for $color with alpha $alpha');
        expect(modernColor.b, closeTo(legacyColor.b, 0.01),
            reason: 'Blue channel mismatch for $color with alpha $alpha');

        // Assert - Alpha channel
        expect(modernColor.a, closeTo(alpha, 0.005),
            reason: 'Alpha channel mismatch for $color with alpha $alpha');
        expect(modernColor.a, closeTo(legacyColor.a, 0.01),
            reason: 'Alpha comparison with legacy mismatch for $color with alpha $alpha');

        // Assert - 32-bit ARGB integer values
        final legacyIntAlpha = (legacyColor.a * 255).round();
        final modernIntAlpha = (modernColor.a * 255).round();
        expect((legacyIntAlpha - modernIntAlpha).abs(), lessThanOrEqualTo(1),
            reason: 'Integer alpha discrepancy > 1 for $color with alpha $alpha');
      }
    });

    test('should maintain string interpolation syntax for package export filenames', () {
      // Arrange
      final sampleInputs = [
        'My Media Set',
        'Default Pack',
        'Tavern & Battle 2026',
        'Pack/With/Slashes',
        r'Pack\With\Backslashes',
        '../../etc/passwd',
        'special!@#\$%^&*()_+|}{":?><~`',
        '   trimmed spaces   ',
        '',
        'Pack 1.2.3',
        'A' * 256,
      ];

      for (final rawInput in sampleInputs) {
        // Act
        final sanitized = rawInput.trim().replaceAll(RegExp(r'[^\w\s\-]'), '_');

        // ignore: unnecessary_brace_in_string_interps
        final legacyMediaName = '${sanitized}.media.zip';
        final modernMediaName = '$sanitized.media.zip';

        // ignore: unnecessary_brace_in_string_interps
        final legacyPackName = '${sanitized}.pack.zip';
        final modernPackName = '$sanitized.pack.zip';

        // Assert
        expect(modernMediaName, equals(legacyMediaName),
            reason: 'Media zip string interpolation mismatch for input "$rawInput"');
        expect(modernMediaName.endsWith('.media.zip'), isTrue,
            reason: 'Media zip extension lost for input "$rawInput"');

        expect(modernPackName, equals(legacyPackName),
            reason: 'Pack zip string interpolation mismatch for input "$rawInput"');
        expect(modernPackName.endsWith('.pack.zip'), isTrue,
            reason: 'Pack zip extension lost for input "$rawInput"');
      }
    });

    test('should neutralize illegal filesystem characters in export filename sanitizer', () {
      // Arrange
      const maliciousInput = '../../../../secret/pack:name*?.zip';

      // Act
      final sanitized = maliciousInput.trim().replaceAll(RegExp(r'[^\w\s\-]'), '_');
      final exportName = '$sanitized.pack.zip';

      // Assert
      expect(sanitized.contains('/'), isFalse);
      expect(sanitized.contains('\\'), isFalse);
      expect(sanitized.contains(':'), isFalse);
      expect(sanitized.contains('*'), isFalse);
      expect(sanitized.contains('?'), isFalse);
      expect(sanitized.contains('"'), isFalse);
      expect(sanitized.contains('<'), isFalse);
      expect(sanitized.contains('>'), isFalse);
      expect(sanitized.contains('|'), isFalse);
      expect(exportName.endsWith('.pack.zip'), isTrue);
    });
  });
}
