import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../security/core/authorization_policy.dart';
import '../../security/core/security_core.dart';
import 'terminal_capabilities.dart';

final terminalServiceProvider = Provider<TerminalService>((ref) {
  final service = TerminalService(ref.read(securityCoreProvider));
  ref.onDispose(service.dispose);
  return service;
});

final securityCoreProvider = Provider<SecurityCore>((ref) {
  throw StateError('SecurityCore provider must be overridden by ZionOSApp');
});

class TerminalResult {
  const TerminalResult({
    required this.command,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.duration,
    required this.shell,
  });

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
  String _interactiveInputBuffer = '';

  Stream<String> get output => _output.stream;
  List<String> get history => List.unmodifiable(_history);
  bool get isInteractiveRunning => _process != null;

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _history
      ..clear()
      ..addAll(prefs.getStringList(_historyKey) ?? const <String>[]);
    if (_history.length > _maxHistory) {
      _history.removeRange(_maxHistory, _history.length);
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _history.take(_maxHistory).toList());
  }

  Future<String?> _findExecutable(List<String> candidates) async {
    for (final candidate in candidates) {
      try {
        final result = await Process.run(
          candidate,
          const <String>['--version'],
          runInShell: false,
        );
        if (result.exitCode == 0 || candidate.startsWith('/')) return candidate;
      } catch (_) {}
    }
    return null;
  }

  Future<String?> _findShell() => _findExecutable(
        const <String>['/system/bin/sh', '/bin/sh', 'sh'],
      );

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

  void _audit({
    required String command,
    required String outcome,
    required int exitCode,
    required String shell,
    required Duration duration,
    bool? interactive,
  }) {
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
        'interactive': interactive ?? isInteractiveRunning,
        'source': 'REAL_PROCESS',
      },
    );
  }

  void _remember(String command) {
    _history.remove(command);
    _history.insert(0, command);
    if (_history.length > _maxHistory) _history.removeLast();
    unawaited(_saveHistory());
  }

  TerminalResult _builtinResult(String command, String stdout) {
    _audit(
      command: command,
      outcome: 'success',
      exitCode: 0,
      shell: 'builtin',
      duration: Duration.zero,
      interactive: false,
    );
    return TerminalResult(
      command: command,
      stdout: stdout,
      stderr: '',
      exitCode: 0,
      duration: Duration.zero,
      shell: 'builtin',
    );
  }

  Future<TerminalResult> execute(String command) async {
    final value = command.trim();
    if (value.isEmpty) {
      return const TerminalResult(
        command: '',
        stdout: '',
        stderr: '',
        exitCode: 0,
        duration: Duration.zero,
        shell: 'none',
      );
    }

    if (value == 'help' || value == 'zion-help') {
      return _builtinResult(
        value,
        'Built-in: help, capabilities, history, clear, exit, shell-status\n'
        'Real shell examples: pwd, ls, id, uname -a, getprop, ip addr, ip route, ps, df -h\n'
        'Network diagnostics: ping, ip, ss/netstat, traceroute, nslookup/dig when installed.\n'
        'Remote administration: ssh/telnet only when the real client exists in the runtime.\n'
        'No feature reports success unless the underlying runtime operation actually succeeds.',
      );
    }

    if (value == 'capabilities') {
      return _builtinResult(value, TerminalCapabilities.describe());
    }

    if (value == 'clear') {
      _output.add('\x1b[2J\x1b[H');
      return _builtinResult(value, '');
    }

    if (value == 'history') {
      return _builtinResult(
        value,
        List.generate(
          _history.length,
          (i) => '${i + 1}  ${_history[i]}',
        ).join('\n'),
      );
    }

    if (value == 'shell-status') {
      final shell = await _findShell();
      final result = TerminalResult(
        command: value,
        stdout: shell == null
            ? 'Shell: UNAVAILABLE'
            : 'Shell: AVAILABLE\nPath: $shell\nInteractive: $isInteractiveRunning',
        stderr: '',
        exitCode: shell == null ? 127 : 0,
        duration: Duration.zero,
        shell: shell ?? 'unavailable',
      );
      _audit(
        command: value,
        outcome: result.succeeded ? 'success' : 'unavailable',
        exitCode: result.exitCode,
        shell: result.shell,
        duration: result.duration,
        interactive: false,
      );
      return result;
    }

    if (value == 'exit') {
      await stopInteractive();
      return _builtinResult(value, 'Interactive shell stopped.');
    }

    if (!_authorized(value)) {
      const denied = TerminalResult(
        command: value,
        stdout: '',
        stderr: 'Command denied by Zion SecurityCore authorization policy.',
        exitCode: 126,
        duration: Duration.zero,
        shell: 'security-core',
      );
      _audit(
        command: value,
        outcome: 'denied',
        exitCode: denied.exitCode,
        shell: denied.shell,
        duration: denied.duration,
        interactive: false,
      );
      return denied;
    }

    _remember(value);

    final shell = await _findShell();
    if (shell == null) {
      const unavailable = TerminalResult(
        command: '',
        stdout: '',
        stderr: 'No POSIX shell is available on this Android runtime.',
        exitCode: 127,
        duration: Duration.zero,
        shell: 'unavailable',
      );
      final result = TerminalResult(
        command: value,
        stdout: unavailable.stdout,
        stderr: unavailable.stderr,
        exitCode: unavailable.exitCode,
        duration: unavailable.duration,
        shell: unavailable.shell,
      );
      _audit(
        command: value,
        outcome: 'unavailable',
        exitCode: result.exitCode,
        shell: result.shell,
        duration: result.duration,
        interactive: false,
      );
      return result;
    }

    final started = DateTime.now();
    try {
      final processResult = await Process.run(
        shell,
        <String>['-c', value],
        runInShell: false,
      );
      final result = TerminalResult(
        command: value,
        stdout: processResult.stdout.toString(),
        stderr: processResult.stderr.toString(),
        exitCode: processResult.exitCode,
        duration: DateTime.now().difference(started),
        shell: shell,
      );
      _audit(
        command: value,
        outcome: result.succeeded ? 'success' : 'failed',
        exitCode: result.exitCode,
        shell: result.shell,
        duration: result.duration,
        interactive: false,
      );
      return result;
    } on ProcessException catch (e) {
      final result = TerminalResult(
        command: value,
        stdout: '',
        stderr: e.message,
        exitCode: 126,
        duration: DateTime.now().difference(started),
        shell: shell,
      );
      _audit(
        command: value,
        outcome: 'process-error',
        exitCode: result.exitCode,
        shell: result.shell,
        duration: result.duration,
        interactive: false,
      );
      return result;
    }
  }

  Future<void> startInteractive() async {
    if (_process != null) return;

    final shell = await _findShell();
    if (shell == null) {
      _output.add('ERROR: No POSIX shell is available on this runtime.');
      _audit(
        command: '<interactive-start>',
        outcome: 'unavailable',
        exitCode: 127,
        shell: 'unavailable',
        duration: Duration.zero,
        interactive: true,
      );
      return;
    }

    if (!_authorized('<interactive-shell>')) {
      _output.add('ERROR: Interactive shell denied by Zion SecurityCore authorization policy.');
      _audit(
        command: '<interactive-start>',
        outcome: 'denied',
        exitCode: 126,
        shell: 'security-core',
        duration: Duration.zero,
        interactive: true,
      );
      return;
    }

    final started = DateTime.now();
    try {
      _process = await Process.start(
        shell,
        const <String>['-i'],
        runInShell: false,
      );
      _interactiveInputBuffer = '';
      _stdoutSub = _process!.stdout.transform(utf8.decoder).listen(_output.add);
      _stderrSub = _process!.stderr.transform(utf8.decoder).listen(_output.add);
      _output.add('Connected to real shell: $shell\n');
      _audit(
        command: '<interactive-start>',
        outcome: 'success',
        exitCode: 0,
        shell: shell,
        duration: DateTime.now().difference(started),
        interactive: true,
      );
    } catch (e) {
      _output.add('ERROR: Failed to start shell: $e');
      _audit(
        command: '<interactive-start>',
        outcome: 'process-error',
        exitCode: 126,
        shell: shell,
        duration: DateTime.now().difference(started),
        interactive: true,
      );
      _process = null;
    }
  }

  void write(String input) {
    final process = _process;
    if (process == null) return;

    _interactiveInputBuffer += input;
    final parts = _interactiveInputBuffer.split('\n');
    _interactiveInputBuffer = parts.removeLast();

    for (final rawCommand in parts) {
      final command = rawCommand.trim();
      if (command.isEmpty) continue;
      if (!_authorized(command)) {
        _output.add('\n[ZION] command denied by SecurityCore: $command\n');
        _audit(
          command: command,
          outcome: 'denied',
          exitCode: 126,
          shell: 'security-core',
          duration: Duration.zero,
          interactive: true,
        );
        continue;
      }
      _remember(command);
      _audit(
        command: command,
        outcome: 'submitted',
        exitCode: -1,
        shell: 'interactive',
        duration: Duration.zero,
        interactive: true,
      );
    }

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
    _interactiveInputBuffer = '';
    process.kill();
    _process = null;
    _audit(
      command: '<interactive-stop>',
      outcome: 'success',
      exitCode: 0,
      shell: 'process',
      duration: Duration.zero,
      interactive: true,
    );
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
