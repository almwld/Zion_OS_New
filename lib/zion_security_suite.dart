import 'package:flutter/material.dart';
import 'dart:async';

class SecurityScanResult {
  final String name;
  final String status; // safe, warning, danger, scanning
  final String details;

  SecurityScanResult({required this.name, required this.status, required this.details});
}

class ZionSecuritySuite extends ChangeNotifier {
  final List<SecurityScanResult> _results = [];
  bool _isScanning = false;
  int _scanProgress = 0;
  bool _antivirusEnabled = true;
  bool _intrusionDetection = true;
  bool _ransomwareProtection = true;
  bool _keyloggerProtection = true;

  List<SecurityScanResult> get results => _results;
  bool get isScanning => _isScanning;
  int get scanProgress => _scanProgress;
  bool get antivirusEnabled => _antivirusEnabled;
  bool get intrusionDetection => _intrusionDetection;
  bool get ransomwareProtection => _ransomwareProtection;
  bool get keyloggerProtection => _keyloggerProtection;

  void toggleAntivirus() { _antivirusEnabled = !_antivirusEnabled; notifyListeners(); }
  void toggleIDS() { _intrusionDetection = !_intrusionDetection; notifyListeners(); }
  void toggleRansomware() { _ransomwareProtection = !_ransomwareProtection; notifyListeners(); }
  void toggleKeylogger() { _keyloggerProtection = !_keyloggerProtection; notifyListeners(); }

  Future<void> runFullScan() async {
    _isScanning = true;
    _scanProgress = 0;
    _results.clear();
    notifyListeners();

    final scanItems = [
      'فحص الفيروسات',
      'فحص البرمجيات الخبيثة',
      'فحص الجذور الخفية',
      'فحص الثغرات الأمنية',
      'فحص التطبيقات',
      'فحص الشبكة',
      'فحص الملفات الحساسة',
      'فحص كلمات المرور الضعيفة',
    ];

    for (int i = 0; i < scanItems.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      _results.add(SecurityScanResult(
        name: scanItems[i],
        status: ['safe', 'safe', 'safe', 'warning', 'safe', 'safe', 'danger', 'warning'][i],
        details: ['لا توجد تهديدات', 'لا توجد برمجيات خبيثة', 'لا توجد جذور خفية', 'تم اكتشاف ثغرة قديمة', 'جميع التطبيقات آمنة', 'الشبكة آمنة', 'تم اكتشاف ملفات حساسة مكشوفة', 'تم اكتشاف كلمة مرور ضعيفة'][i],
      ));
      _scanProgress = ((i + 1) / scanItems.length * 100).round();
      notifyListeners();
    }

    _isScanning = false;
    notifyListeners();
  }
}
