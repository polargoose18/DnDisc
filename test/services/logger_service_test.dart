import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';

void main() {
  group('LoggerService Unit Tests', () {
    late LoggerService logger;

    setUp(() {
      logger = LoggerService();
      logger.clear();
    });

    test('should maintain singleton instance across multiple instantiations', () {
      // Arrange & Act
      final logger1 = LoggerService();
      final logger2 = LoggerService();

      // Assert
      expect(identical(logger1, logger2), isTrue);
    });

    test('should record log entries with appropriate levels and timestamp formatting', () {
      // Arrange & Act
      logger.info('Info log test', details: 'Details 1');
      logger.warning('Warning log test', details: 'Details 2');
      logger.error('Error log test', details: 'Details 3');

      // Assert
      expect(logger.logs.length, equals(3));

      expect(logger.logs[0].level, equals(LogLevel.info));
      expect(logger.logs[0].message, equals('Info log test'));
      expect(logger.logs[0].details, equals('Details 1'));
      expect(logger.logs[0].formattedTime, matches(r'^\d{2}:\d{2}:\d{2}\.\d{3}$'));

      expect(logger.logs[1].level, equals(LogLevel.warning));
      expect(logger.logs[1].message, equals('Warning log test'));

      expect(logger.logs[2].level, equals(LogLevel.error));
      expect(logger.logs[2].message, equals('Error log test'));
    });

    test('should notify listeners when a new log entry is added', () {
      // Arrange
      int callCount = 0;
      logger.addListener(() {
        callCount++;
      });

      // Act
      logger.info('Test notification');

      // Assert
      expect(callCount, equals(1));
    });

    test('should clear all log entries and notify listeners when clear is called', () {
      // Arrange
      logger.info('Log 1');
      logger.warning('Log 2');
      expect(logger.logs.length, equals(2));

      int notificationCount = 0;
      logger.addListener(() => notificationCount++);

      // Act
      logger.clear();

      // Assert
      expect(logger.logs, isEmpty);
      expect(notificationCount, equals(1));
    });
  });
}
