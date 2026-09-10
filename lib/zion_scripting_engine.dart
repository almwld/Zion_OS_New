import 'dart:io';

import 'package:flutter/material.dart';

class ZionScript {
  final String name;
  final String description;
  final String code;
  final bool enabled;

  const ZionScript({
    required this.name,
    required this.description,
    required this.code,
    this.enabled = true,
  });
}

class ZionScriptingEngine extends ChangeNotifier {
  static const Set<String> _allowedCommands = {
    'pwd',
    'whoami',
    'hostname',
    'uname',
    'date',
    'id',
    'ls',
    'df',
    'du',
  };

  final List<ZionScript> _scripts = [
    const ZionScript(
      name: 'system_info.sh',
      description: 'جمع معلومات النظام المتاحة للتطبيق',
      code: 'whoami\nhostname\nuname -a\ndate',
    ),
    const ZionScript(
      name: 'storage_info.sh',
      description: 'قراءة حالة التخزين المتاحة للتطبيق',
      code: 'df -h',
    ),
    const ZionScript(
      name: 'workspace.sh',
      description: 'عرض مجلد العمل ومحتوياته',
      code: 'pwd\nls -la',
    ),
  ];

  String _output = '';
  bool _isRunning = false;

  List<ZionScript> get scripts => List.unmodifiable(_scripts);
  String get output => _output;
  bool get isRunning => _isRunning;

  Future<void> runScript(ZionScript script) async {
    if (_isRunning) return;
    _isRunning = true;
    _output = '';
    notifyListeners();

    var failed = false;
    for (final rawLine in script.code.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      _output += '> $line\n';
      notifyListeners();

      final parts = line.split(RegExp(r'\\s+'));
      final command = parts.first;
      if (!_allowedCommands.contains(command)) {
        _output += '  [BLOCKED] الأمر غير مسموح به في محرك السكربت الآمن.\n';
        failed = true;
        notifyListeners();
        continue;
      }

      try {
        final result = await Process.run(command, parts.skip(1).toList());
        final stdoutText = result.stdout.toString().trimRight();
        final stderrText = result.stderr.toString().trimRight();
        if (stdoutText.isNotEmpty) _output += '$stdoutText\n';
        if (stderrText.isNotEmpty) _output += '$stderrText\n';
        _output += result.exitCode == 0
            ? '  [OK] exitCode=0\n'
            : '  [ERROR] exitCode=${result.exitCode}\n';
        if (result.exitCode != 0) failed = true;
      } catch (e) {
        failed = true;
        _output += '  [ERROR] $e\n';
      }
      notifyListeners();
    }

    _output += failed
        ? '\n[ERROR] انتهى السكريبت مع أخطاء.\n'
        : '\n[OK] انتهى السكريبت بنتيجة فعلية.\n';
    _isRunning = false;
    notifyListeners();
  }

  void addScript(String name, String description, String code) {
    _scripts.add(ZionScript(
      name: name,
      description: description,
      code: code,
    ));
    notifyListeners();
  }

  void removeScript(String name) {
    _scripts.removeWhere((s) => s.name == name);
    notifyListeners();
  }
}
