import 'dart:async';
import 'dart:io';

import 'package:project_zion/security/core/security_core.dart';

class ResourceLimits {
  const ResourceLimits({
    this.maxRuntime = const Duration(minutes: 10),
    this.maxOutputBytes = 4 * 1024 * 1024,
  });

  final Duration maxRuntime;
  final int maxOutputBytes;
}

class GuardedProcessResult {
  const GuardedProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.timedOut,
    required this.outputLimited,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;
  final bool outputLimited;
}

/// SecurityCore-owned process boundary. It never escalates privileges and
/// refuses execution when the security capability is not authorized.
class SecurityResourceGuard {
  SecurityResourceGuard({
    SecurityCore? security,
    this.limits = const ResourceLimits(),
  }) : security = security ?? SecurityCore();

  final SecurityCore security;
  final ResourceLimits limits;

  Future<GuardedProcessResult> run({
    required String executable,
    List<String> arguments = const <String>[],
    String? workingDirectory,
    required AuthorizationScope scope,
    bool requiresSimulation = false,
  }) async {
    if (!security.canExecute(
      scope: scope,
      action: 'terminal.execute',
      requiresSimulation: requiresSimulation,
    )) {
      throw StateError('SecurityCore denied terminal execution.');
    }

    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: false,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    var outputBytes = 0;
    var outputLimited = false;

    Future<void> collect(
      Stream<List<int>> stream,
      StringBuffer target,
    ) async {
      await for (final chunk in stream) {
        if (outputBytes >= limits.maxOutputBytes) {
          outputLimited = true;
          continue;
        }
        final remaining = limits.maxOutputBytes - outputBytes;
        final accepted = chunk.length > remaining
            ? chunk.sublist(0, remaining)
            : chunk;
        outputBytes += accepted.length;
        target.write(String.fromCharCodes(accepted));
        if (accepted.length != chunk.length) outputLimited = true;
      }
    }

    final stdoutFuture = collect(process.stdout, stdoutBuffer);
    final stderrFuture = collect(process.stderr, stderrBuffer);
    var timedOut = false;
    var exitCode = -1;
    try {
      exitCode = await process.exitCode.timeout(limits.maxRuntime);
    } on TimeoutException {
      timedOut = true;
      process.kill(ProcessSignal.sigterm);
      try {
        exitCode = await process.exitCode.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
      }
    }
    await Future.wait(<Future<void>>[stdoutFuture, stderrFuture]);

    return GuardedProcessResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
      timedOut: timedOut,
      outputLimited: outputLimited,
    );
  }
}
