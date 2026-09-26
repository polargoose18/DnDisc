import 'package:flutter_test/flutter_test.dart';
import 'package:ttrpg_audio_player/services/logger_service.dart';

void main() {
  group('LoggerService Unit Tests', () {
    late LoggerService logger;

    setUp(() {
      logger = LoggerService();
      logger.clear();
    });

    test('Что проверяем: Паттерн Singleton для LoggerService. '
        'Входные данные: Два вызова LoggerService(). '
        'Ожидаемый результат: Возвращается один и тот же объект в памяти.', () {
      final logger1 = LoggerService();
      final logger2 = LoggerService();

      expect(identical(logger1, logger2), isTrue);
    });

    test('Что проверяем: Запись лог-сообщений уровня info, warning, error. '
        'Входные данные: Вызовы info(), warning(), error() с кастомным сообщением и деталями. '
        'Ожидаемый результат: Список logs содержит 3 записи с правильными уровнями и отформатированным временем.', () {
      logger.info('Info log test', details: 'Details 1');
      logger.warning('Warning log test', details: 'Details 2');
      logger.error('Error log test', details: 'Details 3');

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

    test('Что проверяем: Уведомление слушателей (ChangeNotifier) при добавлении лога. '
        'Входные данные: Подписка на addListener и запись нового лога. '
        'Ожидаемый результат: Слушатель вызывается ровно один раз.', () {
      int callCount = 0;
      logger.addListener(() {
        callCount++;
      });

      logger.info('Test notification');

      expect(callCount, equals(1));
    });

    test('Что проверяем: Очистка списка логов через clear(). '
        'Входные данные: Список с 2 логами, вызов logger.clear(). '
        'Ожидаемый результат: Список logs становится пустым, генерируется уведомление.', () {
      logger.info('Log 1');
      logger.warning('Log 2');
      expect(logger.logs.length, equals(2));

      int notificationCount = 0;
      logger.addListener(() => notificationCount++);

      logger.clear();

      expect(logger.logs, isEmpty);
      expect(notificationCount, equals(1));
    });
  });
}
