import 'package:flutter/material.dart';

enum LogLevel { info, warning, error, critical, debug, success }

class LogEntry {
  final String id;
  final String message;
  final LogLevel level;
  final String source;
  final DateTime timestamp;

  LogEntry({
    required this.id,
    required this.message,
    required this.level,
    required this.source,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedTime => '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}

class ZionLogSystem extends ChangeNotifier {
  final List<LogEntry> _logs = [];
  final int _maxLogs = 500;

  List<LogEntry> get logs => _logs.reversed.toList();
  List<LogEntry> get errors => _logs.where((l) => l.level == LogLevel.error || l.level == LogLevel.critical).toList();
  List<LogEntry> get warnings => _logs.where((l) => l.level == LogLevel.warning).toList();

  void log(String message, {LogLevel level = LogLevel.info, String source = 'system'}) {
    _logs.add(LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      level: level,
      source: source,
    ));

    if (_logs.length > _maxLogs) _logs.removeRange(0, _logs.length - _maxLogs);

    notifyListeners();
  }

  void clear() { _logs.clear(); notifyListeners(); }
  void clearByLevel(LogLevel level) { _logs.removeWhere((l) => l.level == level); notifyListeners(); }
}
