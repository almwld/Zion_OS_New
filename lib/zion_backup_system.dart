import 'package:flutter/material.dart';

import 'core/services/backup_service.dart';

class BackupEntry {
  final String id;
  final String name;
  final DateTime createdAt;
  final int size;
  final String type;
  final String path;

  BackupEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
    required this.type,
    required this.path,
  });
}

/// Persistent backup facade backed by real application storage.
/// No simulated progress, size, timestamps, or restore success are generated.
class ZionBackupSystem extends ChangeNotifier {
  ZionBackupSystem({BackupService? service}) : _service = service ?? BackupService();

  final BackupService _service;
  final List<BackupEntry> _backups = [];
  bool _isBackingUp = false;
  int _progress = 0;

  List<BackupEntry> get backups => List.unmodifiable(_backups.reversed.toList());
  bool get isBackingUp => _isBackingUp;
  int get progress => _progress;

  Future<void> init() async {
    await _service.init();
    await _reloadHistory();
    notifyListeners();
  }

  Future<BackupEntry?> createBackup({String type = 'full'}) async {
    if (_isBackingUp) return null;
    _isBackingUp = true;
    _progress = 0;
    notifyListeners();

    try {
      await _service.init();
      _progress = 50;
      notifyListeners();

      final result = await _service.createBackup(
        'Zion_${type}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result['success'] != true || result['path'] is! String) return null;

      final timestamp = DateTime.tryParse(result['timestamp'] as String? ?? '') ?? DateTime.now();
      final entry = BackupEntry(
        id: result['path'] as String,
        name: result['name'] as String? ?? 'Zion Backup',
        createdAt: timestamp,
        size: (result['size'] as num?)?.toInt() ?? 0,
        type: type,
        path: result['path'] as String,
      );

      await _reloadHistory();
      _progress = 100;
      notifyListeners();
      return entry;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  Future<int> restoreBackup(BackupEntry backup) async {
    if (_isBackingUp) return 0;
    _isBackingUp = true;
    _progress = 0;
    notifyListeners();

    try {
      final result = await _service.restoreBackup(backup.path);
      if (result['success'] != true) return 0;
      _progress = 100;
      notifyListeners();
      return (result['restored_items'] as num?)?.toInt() ?? 0;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  Future<void> deleteBackup(String id) async {
    final index = _backups.indexWhere((b) => b.id == id || b.path == id);
    if (index < 0) return;
    await _service.deleteBackup(_backups[index].path);
    _backups.removeAt(index);
    notifyListeners();
  }

  /// Compatibility hook: only accepts an already-created real backup record.
  void addBackup(BackupEntry entry) {
    if (!_backups.any((b) => b.path == entry.path)) {
      _backups.add(entry);
      notifyListeners();
    }
  }

  Future<void> _reloadHistory() async {
    final history = await _service.getBackupHistory();
    _backups
      ..clear()
      ..addAll(history.where((b) => b['path'] is String).map((b) {
        final timestamp = DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final path = b['path'] as String;
        return BackupEntry(
          id: path,
          name: b['name'] as String? ?? 'Zion Backup',
          createdAt: timestamp,
          size: (b['size'] as num?)?.toInt() ?? 0,
          type: 'full',
          path: path,
        );
      }));
  }
}
