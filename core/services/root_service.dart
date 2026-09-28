import 'dart:io';
import 'package:flutter/services.dart';

class RootService {
  static final RootService _instance = RootService._internal();
  factory RootService() => _instance;
  RootService._internal();

  bool _hasRoot = false;
  bool _rootAccessGranted = false;
  List<String> _rootPaths = [
    '/system/bin/su',
    '/system/xbin/su',
    '/system/bin/.ext/.su',
    '/sbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
    '/su/bin/su',
  ];

  /// التحقق من وجود ملف su (جذر)
  Future<bool> checkRootAvailability() async {
    for (final path in _rootPaths) {
      final file = File(path);
      if (await file.exists()) {
        _hasRoot = true;
        return true;
      }
    }
    // محاولة تنفيذ الأمر 'which su'
    try {
      final result = await Process.run('which', ['su'], runInShell: true);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        _hasRoot = true;
        return true;
      }
    } catch (_) {}
    _hasRoot = false;
    return false;
  }

  /// طلب صلاحيات الجذر (محاولة تنفيذ أمر بسيط مع su)
  Future<bool> requestRootAccess() async {
    if (!_hasRoot) {
      await checkRootAvailability();
      if (!_hasRoot) return false;
    }
    
    try {
      // محاولة تنفيذ الأمر 'id' مع su
      final result = await Process.run('su', ['-c', 'id'], runInShell: true);
      if (result.exitCode == 0 && result.stdout.toString().contains('uid=0')) {
        _rootAccessGranted = true;
        return true;
      }
    } catch (_) {
      _rootAccessGranted = false;
    }
    return false;
  }

  /// تنفيذ أمر بصلاحيات الجذر
  Future<ProcessResult> runAsRoot(String command, {List<String>? arguments}) async {
    if (!_rootAccessGranted) {
      final granted = await requestRootAccess();
      if (!granted) {
        return ProcessResult(0, 1, 'Root access denied', '');
      }
    }
    
    try {
      final fullCommand = arguments != null && arguments.isNotEmpty
          ? 'su -c "$command ${arguments.join(' ')}"'
          : 'su -c "$command"';
      final result = await Process.run('sh', ['-c', fullCommand], runInShell: true);
      return result;
    } catch (e) {
      return ProcessResult(0, 1, 'Error: $e', '');
    }
  }

  /// تنفيذ أمر عادي (بدون su) مع إمكانية التحول إلى root لاحقاً
  Future<ProcessResult> runCommand(String command, {bool asRoot = false}) async {
    if (asRoot) {
      return runAsRoot(command);
    } else {
      try {
        return await Process.run('sh', ['-c', command], runInShell: true);
      } catch (e) {
        return ProcessResult(0, 1, 'Error: $e', '');
      }
    }
  }

  /// الحصول على حالة الجذر (وصف نصي)
  Future<Map<String, dynamic>> getRootStatus() async {
    final available = await checkRootAvailability();
    final granted = await requestRootAccess();
    return {
      'available': available,
      'granted': granted,
      'message': _getStatusMessage(available, granted),
    };
  }

  String _getStatusMessage(bool available, bool granted) {
    if (!available) return '❌ الجهاز غير مجذّر (Root غير متوفر)';
    if (!granted) return '⚠️ صلاحيات الجذر متوفرة لكن لم يتم منحها للتطبيق';
    return '✅ صلاحيات الجذر مفعلة وموجودة';
  }

  /// اختبار صلاحيات الجذر بتنفيذ أمر بسيط
  Future<String> testRootAccess() async {
    final result = await runAsRoot('echo "Root test successful"');
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    } else {
      return 'Root test failed: ${result.stderr}';
    }
  }

  /// الحصول على معلومات الجهاز (تتطلب صلاحيات root في بعض الأحيان)
  Future<Map<String, String>> getDeviceInfoWithRoot() async {
    final info = <String, String>{};
    
    // معلومات أساسية لا تحتاج root
    try {
      final buildResult = await Process.run('getprop', ['ro.build.version.release'], runInShell: true);
      info['android_version'] = buildResult.stdout.toString().trim();
    } catch (_) {}
    
    // معلومات قد تحتاج root
    final kernelResult = await runAsRoot('uname -a');
    if (kernelResult.exitCode == 0) {
      info['kernel'] = kernelResult.stdout.toString().trim();
    }
    
    final cpuResult = await runAsRoot('cat /proc/cpuinfo | grep "Processor"');
    if (cpuResult.exitCode == 0) {
      info['cpu'] = cpuResult.stdout.toString().trim();
    }
    
    return info;
  }
}
