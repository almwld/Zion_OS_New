import 'package:flutter/material.dart';
import 'dart:async';

enum RecoveryMode { safeMode, networkRecovery, diskRepair, factoryReset, bootRepair }

class ZionRecoverySystem extends ChangeNotifier {
  bool _inRecovery = false;
  RecoveryMode _currentMode = RecoveryMode.safeMode;
  bool _isRunning = false;
  int _progress = 0;
  final List<String> _output = [];

  bool get inRecovery => _inRecovery;
  RecoveryMode get currentMode => _currentMode;
  bool get isRunning => _isRunning;
  int get progress => _progress;
  List<String> get output => _output;

  void enterRecovery(RecoveryMode mode) {
    _inRecovery = true;
    _currentMode = mode;
    notifyListeners();
  }

  void exitRecovery() {
    _inRecovery = false;
    _output.clear();
    notifyListeners();
  }

  Future<void> runRecovery() async {
    _isRunning = true;
    _progress = 0;
    _output.clear();
    notifyListeners();

    switch (_currentMode) {
      case RecoveryMode.safeMode:
        await _runSafeMode();
        break;
      case RecoveryMode.networkRecovery:
        await _runNetworkRecovery();
        break;
      case RecoveryMode.diskRepair:
        await _runDiskRepair();
        break;
      case RecoveryMode.factoryReset:
        await _runFactoryReset();
        break;
      case RecoveryMode.bootRepair:
        await _runBootRepair();
        break;
    }

    _isRunning = false;
    notifyListeners();
  }

  Future<void> _runSafeMode() async {
    _output.add('[+] جاري التشغيل في الوضع الآمن...');
    await _simulateProgress('تحميل برامج التشغيل الأساسية');
    _output.add('[✓] تم التشغيل في الوضع الآمن بنجاح');
  }

  Future<void> _runNetworkRecovery() async {
    _output.add('[+] جاري إصلاح الشبكة...');
    await _simulateProgress('إعادة تعيين إعدادات الشبكة');
    _output.add('[✓] تم إصلاح الشبكة بنجاح');
  }

  Future<void> _runDiskRepair() async {
    _output.add('[+] جاري فحص وإصلاح القرص...');
    await _simulateProgress('فحص نظام الملفات');
    _output.add('[✓] تم إصلاح القرص بنجاح');
  }

  Future<void> _runFactoryReset() async {
    _output.add('[!] تحذير: سيتم حذف جميع البيانات!');
    await _simulateProgress('حذف البيانات واستعادة إعدادات المصنع');
    _output.add('[✓] تمت استعادة إعدادات المصنع بنجاح');
  }

  Future<void> _runBootRepair() async {
    _output.add('[+] جاري إصلاح محمل الإقلاع...');
    await _simulateProgress('إعادة بناء محمل الإقلاع');
    _output.add('[✓] تم إصلاح محمل الإقلاع بنجاح');
  }

  Future<void> _simulateProgress(String step) async {
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      _progress = i;
      notifyListeners();
    }
    _output.add('  └─ $step ... 100%');
  }
}
