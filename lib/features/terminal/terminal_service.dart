import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../security/core/authorization_policy.dart';
import '../../security/core/security_core.dart';

final terminalServiceProvider = Provider<TerminalService>((ref) {
  final service = TerminalService(ref.read(securityCoreProvider));
  ref.onDispose(service.dispose);
  return service;
});

final securityCoreProvider = Provider<SecurityCore>((ref) {
  throw StateError('SecurityCore provider must be overridden by ZionOSApp');
});

class TerminalResult {
  const TerminalResult({required this.command, required this.stdout, required this.stderr, required this.exitCode, required this.duration, required this.shell});
  final String command;
  final String stdout;
  final String stderr;
  final int exitCode;
  final Duration duration;
  final String shell;
  bool get succeeded => exitCode == 0;

  String get formatted {
    final buffer = StringBuffer();
    if (stdout.isNotEmpty) buffer.write(stdout.trimRight());
    if (stderr.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(stderr.trimRight());
    }
    if (buffer.isEmpty) buffer.write('Exit code: $exitCode');
    return buffer.toString();
  }
}

class TerminalService {
  TerminalService(this._securityCore);

  static const _historyKey = 'zion_terminal_history_v1';
  static const _maxHistory = 500;
  static const _terminalAction = 'terminal.execute';

  final SecurityCore _securityCore;
  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  final List<String> _history = <String>[];
  final StreamController<String> _output = StreamController<String>.broadcast();

  Stream<String> get output => _output.stream;
  List<String> get history => List.unmodifiable(_history);
  bool get isInteractiveRunning => _process != null;

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _history
      ..clear()
      ..addAll(prefs.getStringList(_historyKey) ?? const <String>[]);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _history.take(_maxHistory).toList());
  }

  Future<String?> _findShell() async {
    for (final candidate in <String>['/system/bin/sh', '/bin/sh', 'sh']) {
      try {
        final check = await Process.run(candidate, const <String>['-c', 'exit 0'], runInShell: false);
        if (check.exitCode == 0) return candidate;
      } catch (_) {}
    }
    return null;
  }

  bool _authorized(String command) {
    final scope = AuthorizationScope(
      target: 'local-device',
      mode: SecurityMode.defensive,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
    );
    return _securityCore.canExecute(
      scope: scope,
      action: _terminalAction,
      requiresSimulation: false,
    );
  }

  void _audit({required String command, required String outcome, required int exitCode, required String shell, required Duration duration}) {
    _securityCore.auditLogger.log(
      action: _terminalAction,
      actor: 'zion-terminal',
      outcome: outcome,
      target: 'local-device',
      metadata: <String, Object?>{
        'command': command,
        'exitCode': exitCode,
        'shell': shell,
        'durationMs': duration.inMilliseconds,
        'interactive': isInteractiveRunning,
        'source': 'REAL_PROCESS',
      },
    );
  }

  Future<TerminalResult> execute(String command) async {
    final value = command.trim();
    if (value.isEmpty) return const TerminalResult(command: '', stdout: '', stderr: '', exitCode: 0, duration: Duration.zero, shell: 'none');
    if (value == 'help') {
      return const TerminalResult(command: 'help', stdout: 'Built-in: help, history, clear, exit, shell-status\nAll other commands execute through the real POSIX shell when available.\nExamples: pwd, ls, id, uname -a, getprop, ip addr, ip route, ps, df -h\nRemote access: use installed ssh/telnet clients when the runtime provides them.', stderr: '', exitCode: 0, duration: Duration.zero, shell: 'builtin');
    }
    if (value == 'clear') {
      _output.add('\x1b[2J\x1b[H');
      return const TerminalResult(command: 'clear', stdout: '', stderr: '', exitCode: 0, duration: Duration.zero, shell: 'builtin');
    }
    if (value == 'history') {
      return TerminalResult(command: value, stdout: List.generate(_history.length, (i) => '${i + 1}  ${_history[i]}').join('\n'), stderr: '', exitCode: 0, duration: Duration.zero, shell: 'builtin');
    }
    if (value == 'shell-status') {
      final shell = await _findShell();
      return TerminalResult(command: value, stdout: shell == null ? 'Shell: UNAVAILABLE' : 'Shell: AVAILABLE\nPath: $shell\nInteractive: $isInteractiveRunning', stderr: '', exitCode: shell == null ? 127 : 0, duration: Duration.zero, shell: shell ?? 'unavailable');
    }
    if (value == 'exit') {
      await stopInteractive();
      return const TerminalResult(command: 'exit', stdout: 'Interactive shell stopped.', stderr: '', exitCode: 0, duration: Duration.zero, shell: 'builtin');
    }

    if (!_authorized(value)) {
      const denied = TerminalResult(command: value, stdout: '', stderr: 'Command denied by Zion SecurityCore authorization policy.', exitCode: 126, duration: Duration.zero, shell: 'security-core');
      _audit(command: value, outcome: 'denied', exitCode: denied.exitCode, shell: denied.shell, duration: denied.duration);
      return denied;
    }

    _history.remove(value);
    _history.insert(0, value);
    if (_history.length > _maxHistory) _history.removeLast();
    unawaited(_saveHistory());

    final shell = await _findShell();
    if (shell == null) {
      const unavailable = TerminalResult(command: value, stdout: '', stderr: 'No POSIX shell is available on this Android runtime.', exitCode: 127, duration: Duration.zero, shell: 'unavailable');
      _audit(command: value, outcome: 'unavailable', exitCode: unavailable.exitCode, shell: unavailable.shell, duration: unavailable.duration);
      return unavailable;
    }
    final started = DateTime.now();
    try {
      final result = await Process.run(shell, <String>['-c', value], runInShell: false);
      final terminalResult = TerminalResult(command: value, stdout: result.stdout.toString(), stderr: result.stderr.toString(), exitCode: result.exitCode, duration: DateTime.now().difference(started), shell: shell);
      _audit(command: value, outcome: terminalResult.succeeded ? 'success' : 'failed', exitCode: terminalResult.exitCode, shell: terminalResult.shell, duration: terminalResult.duration);
      return terminalResult;
    } on ProcessException catch (e) {
      final terminalResult = TerminalResult(command: value, stdout: '', stderr: e.message, exitCode: 126, duration: DateTime.now().difference(started), shell: shell);
      _audit(command: value, outcome: 'process-error', exitCode: terminalResult.exitCode, shell: terminalResult.shell, duration: terminalResult.duration);
      return terminalResult;
    }
  }

  Future<void> startInteractive() async {
    if (_process != null) return;
    final shell = await _findShell();
    if (shell == null) {
      _output.add('ERROR: No POSIX shell is available on this runtime.');
      _audit(command: '<interactive-start>', outcome: 'unavailable', exitCode: 127, shell: 'unavailable', duration: Duration.zero);
      return;
    }
    if (!_authorized('<interactive-shell>')) {
      _output.add('ERROR: Interactive shell denied by Zion SecurityCore authorization policy.');
      return;
    }
    final started = DateTime.now();
    try {
      _process = await Process.start(shell, const <String>['-i'], runInShell: false);
      _stdoutSub = _process!.stdout.transform(utf8.decoder).listen(_output.add);
      _stderrSub = _process!.stderr.transform(utf8.decoder).listen(_output.add);
      _output.add('Connected to real shell: $shell\n');
      _audit(command: '<interactive-start>', outcome: 'success', exitCode: 0, shell: shell, duration: DateTime.now().difference(started));
    } catch (e) {
      _output.add('ERROR: Failed to start shell: $e');
      _audit(command: '<interactive-start>', outcome: 'process-error', exitCode: 126, shell: shell, duration: DateTime.now().difference(started));
      _process = null;
    }
  }

  void write(String input) {
    final process = _process;
    if (process == null) return;
    process.stdin.write(input);
    unawaited(process.stdin.flush());
  }

  Future<void> stopInteractive() async {
    final process = _process;
    if (process == null) return;
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    process.kill();
    _process = null;
    _audit(command: '<interactive-stop>', outcome: 'success', exitCode: 0, shell: 'process', duration: Duration.zero);
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> dispose() async {
    await stopInteractive();
    await _output.close();
  }
}
