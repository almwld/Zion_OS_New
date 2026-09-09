import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent backup service for Zion OS application data.
///
/// Backups contain SharedPreferences data only. This is not a device/OS image
/// backup; Android system partitions and data belonging to other applications
/// are outside the permissions of a normal Flutter application.
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  String? _backupPath;

  Future<void> init() async {
    if (_backupPath != null) {
      final directory = Directory(_backupPath!);
      if (await directory.exists()) return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${appDir.path}/backups');
    await directory.create(recursive: true);
    _backupPath = directory.path;
  }

  Future<Directory> _backupDirectory() async {
    await init();
    return Directory(_backupPath!);
  }

  String _safeBackupName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^\.+'), '');
    return sanitized.isEmpty ? 'Zion_Backup' : sanitized;
  }

  Future<Map<String, dynamic>> createBackup(String backupName) async {
    final result = <String, dynamic>{
      'success': false,
      'path': null,
      'size': 0,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final directory = await _backupDirectory();
      final prefs = await SharedPreferences.getInstance();
      final backupData = <String, dynamic>{};

      for (final key in prefs.getKeys()) {
        final value = prefs.get(key);
        if (value is bool ||
            value is String ||
            value is int ||
            value is double ||
            value is List<String>) {
          backupData[key] = value;
        }
      }

      final safeName = _safeBackupName(backupName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${directory.path}/${safeName}_$timestamp.zionbackup');
      await backupFile.writeAsString(
        jsonEncode(<String, dynamic>{
          'format': 1,
          'created_at': DateTime.now().toIso8601String(),
          'data': backupData,
        }),
        flush: true,
      );

      final stats = await backupFile.stat();
      result
        ..['success'] = true
        ..['path'] = backupFile.path
        ..['size'] = stats.size
        ..['name'] = safeName;

      await _addToBackupHistory(safeName, backupFile.path, stats.size);
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  Future<Map<String, dynamic>> restoreBackup(String backupPath) async {
    final result = <String, dynamic>{
      'success': false,
      'restored_items': 0,
    };

    try {
      final directory = await _backupDirectory();
      final backupFile = File(backupPath);
      final expectedRoot = directory.absolute.path;
      final actualPath = backupFile.absolute.path;

      if (!actualPath.startsWith('$expectedRoot${Platform.pathSeparator}') ||
          !actualPath.endsWith('.zionbackup')) {
        result['error'] = 'Backup must be an application-owned .zionbackup file.';
        return result;
      }
      if (!await backupFile.exists()) {
        result['error'] = 'Backup file not found';
        return result;
      }

      final decoded = jsonDecode(await backupFile.readAsString());
      if (decoded is! Map<String, dynamic> || decoded['format'] != 1) {
        result['error'] = 'Unsupported or invalid backup format';
        return result;
      }

      final rawData = decoded['data'];
      if (rawData is! Map<String, dynamic>) {
        result['error'] = 'Backup data is invalid';
        return result;
      }

      final prefs = await SharedPreferences.getInstance();
      int restored = 0;
      for (final entry in rawData.entries) {
        final value = entry.value;
        bool written = false;
        if (value is bool) {
          written = await prefs.setBool(entry.key, value);
        } else if (value is String) {
          written = await prefs.setString(entry.key, value);
        } else if (value is int) {
          written = await prefs.setInt(entry.key, value);
        } else if (value is double) {
          written = await prefs.setDouble(entry.key, value);
        } else if (value is List && value.every((item) => item is String)) {
          written = await prefs.setStringList(entry.key, value.cast<String>());
        }
        if (written) restored++;
      }

      result
        ..['success'] = true
        ..['restored_items'] = restored;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    final directory = await _backupDirectory();
    final historyFile = File('${directory.path}/backup_history.json');
    if (!await historyFile.exists()) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(await historyFile.readAsString());
      if (decoded is! List) return <Map<String, dynamic>>[];

      final valid = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic> && item['path'] is String) {
          valid.add(item);
        }
      }
      return valid.reversed.toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _addToBackupHistory(String name, String path, int size) async {
    final directory = await _backupDirectory();
    final historyFile = File('${directory.path}/backup_history.json');
    List<Map<String, dynamic>> history = <Map<String, dynamic>>[];

    if (await historyFile.exists()) {
      try {
        final decoded = jsonDecode(await historyFile.readAsString());
        if (decoded is List) {
          history = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      } catch (_) {}
    }

    history.add(<String, dynamic>{
      'name': name,
      'path': path,
      'size': size,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (history.length > 20) {
      history = history.sublist(history.length - 20);
    }
    await historyFile.writeAsString(jsonEncode(history), flush: true);
  }

  Future<void> deleteBackup(String path) async {
    try {
      final directory = await _backupDirectory();
      final file = File(path);
      final root = directory.absolute.path;
      final actualPath = file.absolute.path;
      if (!actualPath.startsWith('$root${Platform.pathSeparator}') ||
          !actualPath.endsWith('.zionbackup')) {
        return;
      }
      if (await file.exists()) await file.delete();

      final historyFile = File('${directory.path}/backup_history.json');
      if (await historyFile.exists()) {
        final decoded = jsonDecode(await historyFile.readAsString());
        if (decoded is List) {
          final history = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) => item['path'] != path)
              .toList();
          await historyFile.writeAsString(jsonEncode(history), flush: true);
        }
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getBackupStats() async {
    final history = await getBackupHistory();
    int totalSize = 0;
    for (final backup in history) {
      final size = backup['size'];
      if (size is num) totalSize += size.toInt();
    }

    return <String, dynamic>{
      'total_backups': history.length,
      'total_size': totalSize,
      'last_backup': history.isNotEmpty ? history.first['timestamp'] : null,
    };
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
