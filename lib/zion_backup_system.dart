import 'package:flutter/material.dart';
import 'dart:async';

class BackupEntry {
  final String id;
  final String name;
  final DateTime createdAt;
  final int size;
  final String type; // full, incremental, settings

  BackupEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
    required this.type,
  });
}

class ZionBackupSystem extends ChangeNotifier {
  final List<BackupEntry> _backups = [];
  bool _isBackingUp = false;
  int _progress = 0;

  List<BackupEntry> get backups => _backups.reversed.toList();
  bool get isBackingUp => _isBackingUp;
  int get progress => _progress;

  void addBackup(BackupEntry entry) {
    _backups.add(entry);
    notifyListeners();
  }

  Future<void> createBackup({String type = 'full'}) async {
    _isBackingUp = true;
    _progress = 0;
    notifyListeners();

    // محاكاة عملية النسخ الاحتياطي
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 150));
      _progress = i;
      notifyListeners();
    }

    final backup = BackupEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Backup_${DateTime.now().toString().substring(0, 19)}',
      createdAt: DateTime.now(),
      size: 150000000 + DateTime.now().millisecond * 1000,
      type: type,
    );

    _backups.add(backup);
    _isBackingUp = false;
    notifyListeners();
  }

  Future<void> restoreBackup(BackupEntry backup) async {
    _isBackingUp = true;
    _progress = 0;
    notifyListeners();

    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      _progress = i;
      notifyListeners();
    }

    _isBackingUp = false;
    notifyListeners();
  }

  void deleteBackup(String id) {
    _backups.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
