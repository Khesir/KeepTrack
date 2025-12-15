/// In-app logging system for production debugging
///
/// This logger captures all log messages and makes them visible
/// in the app UI, even in production builds where print() is hidden.
library;

import 'dart:collection';

/// Log level
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// A single log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.stackTrace,
  });

  @override
  String toString() {
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    final levelStr = level.name.toUpperCase().padRight(7);
    return '[$time] $levelStr $message';
  }
}

/// Global app logger
///
/// Usage:
/// ```dart
/// AppLogger.info('User logged in');
/// AppLogger.error('Failed to connect', error, stackTrace);
/// ```
class AppLogger {
  static final _instance = AppLogger._();
  factory AppLogger() => _instance;
  AppLogger._();

  /// Maximum number of log entries to keep in memory
  static const int _maxLogEntries = 500;

  /// Log entries (newest last)
  final _logs = Queue<LogEntry>();

  /// Listeners for new log entries
  final _listeners = <void Function(LogEntry)>[];

  /// Add a log entry
  void log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: error != null ? '$message: $error' : message,
      stackTrace: stackTrace,
    );

    // Add to queue
    _logs.add(entry);

    // Remove old entries if queue is too large
    while (_logs.length > _maxLogEntries) {
      _logs.removeFirst();
    }

    // Print to console (for debugging)
    print(entry.toString());
    if (stackTrace != null) {
      print(stackTrace);
    }

    // Notify listeners
    for (final listener in _listeners) {
      listener(entry);
    }
  }

  /// Get all log entries
  List<LogEntry> get logs => _logs.toList();

  /// Get recent log entries
  List<LogEntry> getRecent(int count) {
    final logs = _logs.toList();
    return logs.length <= count
        ? logs
        : logs.sublist(logs.length - count);
  }

  /// Clear all logs
  void clear() {
    _logs.clear();
    _notifyListeners();
  }

  /// Add a listener for new log entries
  void addListener(void Function(LogEntry) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(void Function(LogEntry) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    // Notify with a null entry to indicate logs were cleared
    for (final listener in _listeners) {
      listener(LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'Logs cleared',
      ));
    }
  }

  // Convenience methods
  static void debug(String message) => _instance.log(LogLevel.debug, message);
  static void info(String message) => _instance.log(LogLevel.info, message);
  static void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _instance.log(LogLevel.warning, message, error, stackTrace);
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _instance.log(LogLevel.error, message, error, stackTrace);

  // Get logs
  static List<LogEntry> getLogs() => _instance.logs;
  static List<LogEntry> getRecentLogs(int count) => _instance.getRecent(count);
}
