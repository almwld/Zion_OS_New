import 'dart:async';
import 'dart:io';

import '../core/agent_models.dart';
import '../core/cancellation_token.dart';
import 'tool.dart';

class ShellTool extends AgentTool {
  static const String _prefix = '/data/data/com.zion.os/files/usr';
  static const String _home = '/data/data/com.zion.os/files/home';
  static const String _fallbackShell = '/system/bin/sh';

  @override
  String get name => 'shell';

  // The central AgentPolicy decides which command is safe for automatic
  // execution. Unknown commands are reviewed; destructive commands are blocked.
  @override
  Set<AgentPermission> get permissions => const {AgentPermission.readOnly};

  @override
  String get description => 'تشغيل أوامر محلية عبر Zion Userland Bash عند توفره، مع سياسة أمان مركزية.';

  @override
  Map<String, dynamic> get parameters => const {'command': 'string', 'timeout': 'int'};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) =>
      _execute(params, null);

  @override
  Future<StepResult> executeCancellable(
    Map<String, dynamic> params,
    CancellationToken? cancellationToken,
  ) => _execute(params, cancellationToken);

  Future<StepResult> _execute(
    Map<String, dynamic> params,
    CancellationToken? cancellationToken,
  ) async {
    final command = params['command']?.toString().trim();
    if (cancellationToken?.isCancelled == true) {
      return StepResult.failure('تم إلغاء الأمر قبل التشغيل.');
    }
    if (command == null || command.isEmpty) {
      return StepResult.failure('command مطلوب.');
    }

    final timeoutSeconds = ((params['timeout'] as num?)?.toInt() ?? 20).clamp(1, 120);
    final bash = File('$_prefix/bin/bash');
    final home = Directory(_home);
    final useUserland = await bash.exists();
    final shell = useUserland ? bash.path : _fallbackShell;
    final workingDirectory = await home.exists() ? home.path : Directory.current.path;
    final environment = <String, String>{
      'HOME': await home.exists() ? _home : Directory.current.path,
      'PREFIX': _prefix,
      'TMPDIR': '$_prefix/tmp',
      'PATH': '$_prefix/bin:$_prefix/sbin:/system/bin:/system/xbin:/vendor/bin',
      'TERM': 'xterm-256color',
      'LANG': 'C.UTF-8',
      'LC_ALL': 'C.UTF-8',
      if (useUserland) 'LD_LIBRARY_PATH': '$_prefix/lib:$_prefix/lib64',
    };

    try {
      late final Process runningProcess;
      try {
        runningProcess = await Process.start(
          shell,
          ['-c', command],
          environment: environment,
          workingDirectory: workingDirectory,
          runInShell: false,
        );
      } on ProcessException {
        // Keep diagnostics available even if the local Bash binary or one of
        // its linked libraries is not usable yet.
        if (!useUserland) rethrow;
        runningProcess = await Process.start(
          _fallbackShell,
          ['-c', command],
          environment: environment,
          workingDirectory: workingDirectory,
          runInShell: false,
        );
      }

      final cancellationSubscription = cancellationToken?.onCancel.listen((_) {
        runningProcess.kill(ProcessSignal.sigterm);
      });
      if (cancellationToken?.isCancelled == true) {
        runningProcess.kill(ProcessSignal.sigterm);
      }

      final stdout = StringBuffer();
      final stderr = StringBuffer();
      final stdoutDone = Completer<void>();
      final stderrDone = Completer<void>();
      runningProcess.stdout.transform(SystemEncoding().decoder).listen(
        (chunk) {
          if (stdout.length < 24000) {
            final remaining = 24000 - stdout.length;
            stdout.write(chunk.length > remaining ? chunk.substring(0, remaining) : chunk);
          }
        },
        onDone: () {
          if (!stdoutDone.isCompleted) stdoutDone.complete();
        },
        onError: (Object error) {
          if (!stdoutDone.isCompleted) stdoutDone.completeError(error);
        },
      );
      runningProcess.stderr.transform(SystemEncoding().decoder).listen(
        (chunk) {
          if (stderr.length < 12000) {
            final remaining = 12000 - stderr.length;
            stderr.write(chunk.length > remaining ? chunk.substring(0, remaining) : chunk);
          }
        },
        onDone: () {
          if (!stderrDone.isCompleted) stderrDone.complete();
        },
        onError: (Object error) {
          if (!stderrDone.isCompleted) stderrDone.completeError(error);
        },
      );

      final started = DateTime.now();
      final code = await runningProcess.exitCode.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          runningProcess.kill(ProcessSignal.sigterm);
          return 124;
        },
      );
      await cancellationSubscription?.cancel();
      try {
        await Future.wait<void>([stdoutDone.future, stderrDone.future])
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      final out = stdout.toString().trim();
      final err = stderr.toString().trim();
      final duration = DateTime.now().difference(started);
      final usedShell = shell == _fallbackShell ? 'Android sh' : 'Zion Userland Bash';
      if (code == 0) {
        return StepResult.success(
          out.isEmpty ? 'اكتمل الأمر دون مخرجات.' : out,
          data: {
            'exitCode': code,
            'stdout': out,
            'stderr': err,
            'shell': usedShell,
          },
          duration: duration,
        );
      }
      final reason = code == 124
          ? 'انتهت مهلة الأمر بعد $timeoutSeconds ثانية.'
          : (err.isNotEmpty ? err : 'انتهى الأمر برمز خروج $code.');
      return StepResult.failure(reason, duration: duration);
    } catch (error) {
      return StepResult.failure('تعذر تشغيل الأمر المحلي: $error');
    }
  }
}
