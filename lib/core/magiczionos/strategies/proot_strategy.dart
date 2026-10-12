import 'dart:convert';
import 'dart:io';

import '../../userland/zion_proot.dart';
import 'strategy.dart';

class ProotStrategy extends RootStrategyBase {
  ProotStrategy({this.distroName = 'ubuntu'});

  final String distroName;
  final ZionProot _proot = const ZionProot();

  @override
  String get name => 'proot';

  @override
  String get displayName => 'PRoot (بدون Root)';

  @override
  String get description => 'بيئة Linux عبر PRoot الحقيقي داخل Zion Userland';

  @override
  int get priority => 50;

  @override
  bool get requiresRoot => false;

  ZionDistro get _distro => ZionDistro.values.firstWhere(
        (distro) => distro.name == distroName,
        orElse: () => ZionDistro.ubuntu,
      );

  @override
  Future<bool> isAvailable() async =>
      (await _proot.inspect()).status == ProotStatus.available &&
      await _proot.rootfsExists(_distro);

  @override
  Future<StrategyStatus> getStatus() async {
    final runtime = await _proot.inspect();
    if (runtime.status != ProotStatus.available) {
      return StrategyStatus.notConfigured;
    }
    return await _proot.rootfsExists(_distro)
        ? StrategyStatus.available
        : StrategyStatus.notConfigured;
  }

  @override
  Future<ExecutionResult> execute(
    String command, {
    Duration? timeout,
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final started = DateTime.now();
    if (command.trim().isEmpty) {
      return ExecutionResult.failure('أمر فارغ', name);
    }

    Process? process;
    try {
      process = await _proot.start(
        _distro,
        command: <String>['/bin/bash', '-lc', command],
        workingDirectory: workingDirectory,
        environment: environment,
      );

      // Start draining both pipes before waiting for the process. Reading one
      // pipe to completion first can deadlock when the other pipe fills.
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      var timedOut = false;
      final code = await process.exitCode.timeout(
        timeout ?? const Duration(seconds: 30),
        onTimeout: () {
          timedOut = true;
          process?.kill(ProcessSignal.sigterm);
          return 124;
        },
      );

      if (timedOut) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        process.kill(ProcessSignal.sigkill);
      }

      final out = await stdoutFuture.timeout(
        const Duration(seconds: 2),
        onTimeout: () => '',
      );
      final err = await stderrFuture.timeout(
        const Duration(seconds: 2),
        onTimeout: () => '',
      );
      final stderr = timedOut
          ? '$err\nCommand timed out and the PRoot process was terminated.'
          : err;

      return ExecutionResult(
        success: code == 0 && !timedOut,
        exitCode: code,
        stdout: out,
        stderr: stderr,
        duration: DateTime.now().difference(started),
        strategy: name,
      );
    } catch (error) {
      try {
        process?.kill(ProcessSignal.sigterm);
      } catch (_) {}
      return ExecutionResult.failure('خطأ: $error', name);
    }
  }

  @override
  Future<Process> startInteractiveShell({
    String? shell,
    String? workingDirectory,
    Map<String, String>? environment,
  }) =>
      _proot.start(
        _distro,
        command: <String>[shell ?? '/bin/bash', '--login', '-i'],
        workingDirectory: workingDirectory,
        environment: environment,
      );

  @override
  Future<void> dispose() async {}
}
