import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  Future<void> log(String message, {String level = 'INFO'}) async {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] [$level] $message\n';
    
    print(logLine.trim());
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/zion.log');
      await logFile.writeAsString(logLine, mode: FileMode.append);
    } catch (_) {}
  }

  Future<void> info(String message) => log(message, level: 'INFO');
  Future<void> warning(String message) => log(message, level: 'WARNING');
  Future<void> error(String message) => log(message, level: 'ERROR');
  Future<void> success(String message) => log(message, level: 'SUCCESS');
}
