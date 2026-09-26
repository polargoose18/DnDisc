import 'dart:io';
import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;
  final String? details;

  LogEntry({
    required this.message,
    this.level = LogLevel.info,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

class LoggerService extends ChangeNotifier {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final List<LogEntry> _logs = [];

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void info(String message, {String? details}) {
    _add(LogEntry(message: message, level: LogLevel.info, details: details));
  }

  void warning(String message, {String? details}) {
    _add(LogEntry(message: message, level: LogLevel.warning, details: details));
  }

  void error(String message, {String? details}) {
    _add(LogEntry(message: message, level: LogLevel.error, details: details));
  }

  void _add(LogEntry entry) {
    _logs.add(entry);

    // Direct terminal output via stdout / stderr so logs appear in `flutter run` terminal immediately
    final logLine = '[${entry.formattedTime}] [${entry.level.name.toUpperCase()}] ${entry.message}${entry.details != null ? '\n -> ${entry.details}' : ''}';
    
    if (entry.level == LogLevel.error) {
      stderr.writeln(logLine);
    } else {
      stdout.writeln(logLine);
    }

    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }
}
