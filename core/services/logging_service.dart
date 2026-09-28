import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

enum LogLevel {
  info,
  warning,
  error,
  success,
  debug,
  security,
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();
  
  List<Map<String, dynamic>> _logs = [];
  String? _logPath;
  
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _logPath = '${appDir.path}/logs';
    await Directory(_logPath!).create(recursive: true);
    await _loadLogs();
  }
  
  Future<void> _loadLogs() async {
    final logFile = File('$_logPath/system_logs.json');
    if (await logFile.exists()) {
      try {
        final content = await logFile.readAsString();
        final logs = jsonDecode(content) as List;
        _logs = logs.map((l) => l as Map<String, dynamic>).toList();
      } catch (_) {}
    }
  }
  
  Future<void> addLog({
    required String message,
    required LogLevel level,
    String? source,
    Map<String, dynamic>? data,
  }) async {
    final logEntry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'message': message,
      'level': level.toString().split('.').last,
      'source': source ?? 'system',
      'data': data ?? {},
    };
    
    _logs.insert(0, logEntry);
    
    if (_logs.length > 1000) {
      _logs = _logs.sublist(0, 1000);
    }
    
    await _saveLogs();
  }
  
  Future<void> _saveLogs() async {
    try {
      final logFile = File('$_logPath/system_logs.json');
      await logFile.writeAsString(jsonEncode(_logs));
    } catch (_) {}
  }
  
  List<Map<String, dynamic>> getLogs({LogLevel? level, int? limit}) {
    var filtered = _logs;
    if (level != null) {
      filtered = filtered.where((l) => l['level'] == level.toString().split('.').last).toList();
    }
    if (limit != null && limit > 0) {
      filtered = filtered.take(limit).toList();
    }
    return filtered;
  }
  
  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogs();
  }
  
  Future<void> exportLogs() async {
    final exportFile = File('$_logPath/export_${DateTime.now().millisecondsSinceEpoch}.json');
    await exportFile.writeAsString(jsonEncode(_logs));
  }
  
  Map<String, dynamic> getLogStatistics() {
    final total = _logs.length;
    final info = _logs.where((l) => l['level'] == 'info').length;
    final warning = _logs.where((l) => l['level'] == 'warning').length;
    final error = _logs.where((l) => l['level'] == 'error').length;
    final success = _logs.where((l) => l['level'] == 'success').length;
    final security = _logs.where((l) => l['level'] == 'security').length;
    
    return {
      'total': total,
      'info': info,
      'warning': warning,
      'error': error,
      'success': success,
      'security': security,
    };
  }
  
  String getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return '#00BCD4';
      case LogLevel.warning:
        return '#FF9800';
      case LogLevel.error:
        return '#F44336';
      case LogLevel.success:
        return '#4CAF50';
      case LogLevel.debug:
        return '#9C27B0';
      case LogLevel.security:
        return '#FF5722';
    }
  }
}

extension LogLevelExtension on LogLevel {
  String get icon {
    switch (this) {
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.success:
        return '✅';
      case LogLevel.debug:
        return '🐛';
      case LogLevel.security:
        return '🔒';
    }
  }
}
