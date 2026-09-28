import 'dart:async';
import 'dart:io';

import 'strategy.dart';

class ChrootStrategy extends RootStrategyBase {
  ChrootStrategy({this.distroPath = '/data/local/tmp/distros/ubuntu'});
  final String distroPath;

  @override
  String get name => 'chroot';
  @override
  String get displayName => 'Chroot (Root حقيقي)';
  @override
  String get description => 'بيئة chroot حقيقية عند توفر root وملفات النظام';
  @override
  int get priority => 75;
  @override
  bool get requiresRoot => true;

  Future<bool> isAvailable() async {
    try {
      final r = await Process.run('su', ['-c', 'id'], runInShell: false)
          .timeout(const Duration(seconds: 5));
      return r.exitCode == 0 &&
          r.stdout.toString().contains('uid=0') &&
          await Directory(distroPath).exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<StrategyStatus> getStatus() async {
    if (!await Directory(distroPath).exists()) {
      return StrategyStatus.notConfigured;
    }
    return await isAvailable()
        ? StrategyStatus.available
        : StrategyStatus.permissionRequired;
  }

  bool _blocked(String c) => RegExp(
        r'(^|[;&|])\s*(rm\s+-rf|mkfs|dd\s+if=|reboot|poweroff|shutdown)',
        caseSensitive: false,
      ).hasMatch(c);

  @override
  Future<ExecutionResult> execute(
    String command, {
    Duration? timeout,
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (_blocked(command)) {
      return ExecutionResult.failure(
        'تم حظر الأمر عالي الخطورة بواسطة سياسة Zion.',
        'chroot',
      );
    }
    if (!await isAvailable()) {
      return ExecutionResult.failure('Chroot غير متاح.', 'chroot');
    }
    final t = DateTime.now();
    try {
      final r = await Process.run(
        'su',
        ['-c', 'chroot "$distroPath" /bin/bash -lc "$command"'],
        runInShell: false,
      ).timeout(timeout ?? const Duration(seconds: 60));
      return ExecutionResult(
        success: r.exitCode == 0,
        exitCode: r.exitCode,
        stdout: r.stdout.toString(),
        stderr: r.stderr.toString(),
        duration: DateTime.now().difference(t),
        strategy: name,
      );
    } on TimeoutException {
      return ExecutionResult.failure('انتهت المهلة', 'chroot');
    } catch (e) {
      return ExecutionResult.failure('خطأ: $e', name);
    }
  }

  @override
  Future<Process> startInteractiveShell({
    String? shell,
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (!await isAvailable()) {
      throw StateError('Chroot غير متاح.');
    }
    final selected = shell ?? '/bin/bash';
    if (!selected.startsWith('/bin/') || selected.contains('"')) {
      throw ArgumentError('مسار shell غير موثوق.');
    }
    return Process.start(
      'su',
      ['-c', 'chroot "$distroPath" $selected --login -i'],
      runInShell: false,
    );
  }

  @override
  Future<void> dispose() async {}
}
