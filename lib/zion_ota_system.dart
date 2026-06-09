import 'package:flutter/material.dart';
import 'dart:async';

class OTAUpdate {
  final String version;
  final int buildNumber;
  final String description;
  final int size;
  final bool isCritical;

  OTAUpdate({
    required this.version,
    required this.buildNumber,
    required this.description,
    required this.size,
    this.isCritical = false,
  });
}

class ZionOTASystem extends ChangeNotifier {
  OTAUpdate? _availableUpdate;
  bool _isChecking = false;
  bool _isDownloading = false;
  bool _isInstalling = false;
  int _downloadProgress = 0;
  int _installProgress = 0;

  OTAUpdate? get availableUpdate => _availableUpdate;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  bool get isInstalling => _isInstalling;
  int get downloadProgress => _downloadProgress;
  int get installProgress => _installProgress;

  Future<OTAUpdate?> checkForUpdates() async {
    _isChecking = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    // محاكاة وجود تحديث جديد
    _availableUpdate = OTAUpdate(
      version: '1.5.0',
      buildNumber: 150,
      description: '- إضافة دعم كامل لـ 600+ أداة Kali\n- تحسين أداء النظام\n- إصلاحات أمنية هامة\n- دعم الوضع الليلي المحسن',
      size: 25000000,
      isCritical: false,
    );

    _isChecking = false;
    notifyListeners();
    return _availableUpdate;
  }

  Future<void> downloadUpdate() async {
    if (_availableUpdate == null) return;

    _isDownloading = true;
    _downloadProgress = 0;
    notifyListeners();

    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 100));
      _downloadProgress = i;
      notifyListeners();
    }

    _isDownloading = false;
    notifyListeners();
  }

  Future<void> installUpdate() async {
    _isInstalling = true;
    _installProgress = 0;
    notifyListeners();

    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 200));
      _installProgress = i;
      notifyListeners();
    }

    _availableUpdate = null;
    _isInstalling = false;
    notifyListeners();
  }
}
