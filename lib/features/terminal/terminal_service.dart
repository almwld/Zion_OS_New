import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../../security/core/authorization_policy.dart';
import '../../security/core/security_core.dart';
import 'native_pty_adapter.dart';
import 'terminal_capabilities.dart';

class _TerminalEnvironment {
  const _TerminalEnvironment({required this.home, required this.prefix, required this.tmp});
  final String home;
  final String prefix;
  final String tmp;
}

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
  static const _commandTimeout = Duration(seconds: 30);
  static const MethodChannel _platformChannel = MethodChannel('zion.os/platform');

  final SecurityCore _securityCore;
  final NativePtyAdapter _pty = NativePtyAdapter();
  StreamSubscription<String>? _ptyOutputSub;
  final List<String> _history = <String>[];
  final StreamController<String> _output = StreamController<String>.broadcast();
  String _interactiveInputBuffer = '';

  Stream<String> get output => _output.stream;
  List<String> get history => List.unmodifiable(_history);
  bool get isInteractiveRunning => _pty.isRunning;
  bool get isNativePtyRunning => _pty.isRunning;

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
    _history
      ..clear()
      ..addAll(prefs.getStringList(_historyKey) ?? const <String>[]);
    if (_history.length > _maxHistory) {
      _history.removeRange(_maxHistory, _history.length);
    }
    } catch (_) {
      // Platform preferences are optional for terminal execution. Headless
      // tests and early startup can legitimately have no ServicesBinding.
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_historyKey, _history.take(_maxHistory).toList());
    } catch (_) {
      // History persistence must never surface an unhandled async error or
      // prevent an otherwise successful real shell command.
    }
  }

  Future<String?> _findExecutable(List<String> candidates) async {
    for (final candidate in candidates) {
      try {
        final result = await Process.run(candidate, const <String>['--version'], runInShell: false);
        if (result.exitCode == 0 || candidate.startsWith('/')) return candidate;
      } catch (_) {}
    }
    return null;
  }

  Future<String?> _findShell() async {
    // Zion Terminal is a real Userland terminal. Android /system/bin/sh is
    // intentionally NOT a fallback: running it would break the Termux-like
    // contract (job control, Userland paths, package environment).
    const candidates = <String>[
      '/data/data/com.zion.os/files/usr/bin/bash',
      '/data/data/com.zion.os/files/usr/bin/zsh',
      '/data/data/com.zion.os/files/usr/bin/fish',
      '/data/data/com.zion.os/files/usr/bin/ash',
    ];
    for (final candidate in candidates) {
      try {
        final stat = await File(candidate).stat();
        if (stat.type != FileSystemEntityType.file) continue;
        final result = await Process.run(
          candidate,
          const <String>['-c', 'exit 0'],
          runInShell: false,
        ).timeout(const Duration(seconds: 2));
        if (result.exitCode == 0) return candidate;
      } catch (_) {}
    }
    return null;
  }

  Future<_TerminalEnvironment> _ensureTerminalEnvironment() async {
    final base = Directory('/data/data/com.zion.os/files');
    final home = Directory(base.path + '/home');
    final prefix = Directory(base.path + '/usr');
    final tmp = Directory(base.path + '/tmp');
    try {
      await home.create(recursive: true);
      await Directory(prefix.path + '/bin').create(recursive: true);
      await Directory(prefix.path + '/sbin').create(recursive: true);
      await Directory(prefix.path + '/lib').create(recursive: true);
      await Directory(prefix.path + '/lib64').create(recursive: true);
      await tmp.create(recursive: true);
      await Directory(base.path + '/etc').create(recursive: true);
    } catch (_) {
      // Process.start below reports the filesystem failure if creation fails.
    }
    return _TerminalEnvironment(home: home.path, prefix: prefix.path, tmp: tmp.path);
  }

  bool _authorized(String command) {
    final scope = AuthorizationScope(
      target: 'local-device',
      mode: SecurityMode.defensive,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
    );
    return _securityCore.canExecute(scope: scope, action: _terminalAction, requiresSimulation: false);
  }

  void _audit({required String command, required String outcome, required int exitCode, required String shell, required Duration duration, bool? interactive}) {
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
    _audit(command: command, outcome: 'success', exitCode: 0, shell: 'builtin', duration: Duration.zero, interactive: false);
    return TerminalResult(command: command, stdout: stdout, stderr: '', exitCode: 0, duration: Duration.zero, shell: 'builtin');
  }

  Future<TerminalResult> _runBounded({
    required String command,
    required String shell,
  }) async {
    final started = DateTime.now();
    Process? process;
    try {
      process = await Process.start(shell, <String>['-c', command], runInShell: false);
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode.timeout(
        _commandTimeout,
        onTimeout: () {
          process?.kill(ProcessSignal.sigterm);
          return 124;
        },
      );
      if (exitCode == 124) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (process != null) {
          process.kill(ProcessSignal.sigkill);
        }
      }
      final result = TerminalResult(
        command: command,
        stdout: await stdoutFuture,
        stderr: exitCode == 124
            ? '${await stderrFuture}\nCommand timed out after ${_commandTimeout.inSeconds}s and the process was terminated.'
            : await stderrFuture,
        exitCode: exitCode,
        duration: DateTime.now().difference(started),
        shell: shell,
      );
      _audit(
        command: command,
        outcome: exitCode == 0 ? 'success' : (exitCode == 124 ? 'timeout' : 'failed'),
        exitCode: exitCode,
        shell: shell,
        duration: result.duration,
        interactive: false,
      );
      return result;
    } on ProcessException catch (e) {
      final result = TerminalResult(
        command: command,
        stdout: '',
        stderr: e.message,
        exitCode: 126,
        duration: DateTime.now().difference(started),
        shell: shell,
      );
      _audit(
        command: command,
        outcome: 'process-error',
        exitCode: result.exitCode,
        shell: shell,
        duration: result.duration,
        interactive: false,
      );
      return result;
    }
  }

  Future<TerminalResult> execute(String command) async {
    final value = command.trim();
    if (value.isEmpty) return const TerminalResult(command: '', stdout: '', stderr: '', exitCode: 0, duration: Duration.zero, shell: 'none');
    if (value == 'help' || value == 'zion-help') {
      return _builtinResult(value, 'Built-in: help, capabilities, termux-status, history, clear, exit, shell-status\nReal shell examples: pwd, ls, id, uname -a, getprop, ip addr, ip route, ps, df -h\nNetwork diagnostics: ping, ip, ss/netstat, DNS lookup when installed.\nInteractive Android terminal uses a real child shell process; no shell success is simulated.');
    }
    if (value == 'wifi' || value == 'wifi scan' || value == 'wifi-scan') return _scanWifiBuiltin(value);
    if (value == 'capabilities') return _builtinResult(value, TerminalCapabilities.describe());
    if (value == 'termux-status') return _builtinResult(value, await TerminalCapabilities.describeRuntime());
    if (value == 'clear') {
      _output.add('\x1b[2J\x1b[H');
      return _builtinResult(value, '');
    }
    if (value == 'history') return _builtinResult(value, List.generate(_history.length, (i) => '${i + 1}  ${_history[i]}').join('\n'));
    if (value == 'shell-status') {
      final shell = await _findShell();
      final ptyAvailable = await _pty.isAvailable();
      final result = TerminalResult(command: value, stdout: shell == null ? 'Shell: UNAVAILABLE\nInteractive shell: ${ptyAvailable ? 'AVAILABLE' : 'UNAVAILABLE'}' : 'Shell: AVAILABLE\nPath: $shell\nInteractive shell: ${ptyAvailable ? 'AVAILABLE' : 'UNAVAILABLE'}\nInteractive: $isInteractiveRunning', stderr: '', exitCode: shell == null ? 127 : 0, duration: Duration.zero, shell: shell ?? 'unavailable');
      _audit(command: value, outcome: result.succeeded ? 'success' : 'unavailable', exitCode: result.exitCode, shell: result.shell, duration: result.duration, interactive: false);
      return result;
    }
    if (value == 'exit') {
      await stopInteractive();
      return _builtinResult(value, 'Interactive shell stopped.');
    }
    if (!_authorized(value)) {
      final denied = TerminalResult(command: value, stdout: '', stderr: 'Command denied by Zion SecurityCore authorization policy.', exitCode: 126, duration: Duration.zero, shell: 'security-core');
      _audit(command: value, outcome: 'denied', exitCode: denied.exitCode, shell: denied.shell, duration: denied.duration, interactive: false);
      return denied;
    }
    _remember(value);
    final shell = await _findShell();
    if (shell == null) {
      final result = TerminalResult(command: value, stdout: '', stderr: 'No POSIX shell is available on this Android runtime.', exitCode: 127, duration: Duration.zero, shell: 'unavailable');
      _audit(command: value, outcome: 'unavailable', exitCode: result.exitCode, shell: result.shell, duration: result.duration, interactive: false);
      return result;
    }
    return _runBounded(command: value, shell: shell);
  }

  Future<TerminalResult> _scanWifiBuiltin(String command) async {
    final started = DateTime.now();
    try {
      final raw = await _platformChannel.invokeMethod<Map<dynamic, dynamic>>('wifiScan');
      final data = Map<String, dynamic>.from(raw ?? const {});
      final status = (data['status'] ?? 'UNAVAILABLE').toString();
      final reason = (data['reason'] ?? '').toString();
      final rawNetworks = data['networks'];
      final networks = rawNetworks is List ? rawNetworks.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : const <Map<String, dynamic>>[];
      final lines = <String>['ZION Wi-Fi scanner: $status', if (reason.isNotEmpty) reason, 'Networks: ${networks.length}'];
      for (final n in networks) { lines.add('${n['ssid'] ?? '<hidden>'} | ${n['bssid'] ?? '?'} | ${n['signal'] ?? '?'} dBm | ${n['frequencyMHz'] ?? '?'} MHz | Ch ${n['channel'] ?? '?'} | ${n['capabilities'] ?? 'Unknown'}'); }
      final exitCode = status == 'AVAILABLE' ? 0 : (status == 'PERMISSION_REQUIRED' ? 126 : 127);
      final result = TerminalResult(command: command, stdout: lines.join('\n'), stderr: '', exitCode: exitCode, duration: DateTime.now().difference(started), shell: 'android-wifimanager');
      _audit(command: command, outcome: result.succeeded ? 'success' : 'unavailable', exitCode: result.exitCode, shell: result.shell, duration: result.duration, interactive: false);
      return result;
    } on PlatformException catch (e) {
      final result = TerminalResult(command: command, stdout: '', stderr: e.message ?? 'Android Wi-Fi service unavailable.', exitCode: 127, duration: DateTime.now().difference(started), shell: 'android-wifimanager');
      _audit(command: command, outcome: 'unavailable', exitCode: result.exitCode, shell: result.shell, duration: result.duration, interactive: false);
      return result;
    }
  }

  Future<bool> startInteractive() async {
    if (isInteractiveRunning) return true;
    if (!_authorized('<interactive-shell>')) {
      _output.add('ERROR: Interactive shell denied by Zion SecurityCore authorization policy.');
      return false;
    }
    final started = DateTime.now();
    // Create app-local terminal directories before Process.start().
    await _ensureTerminalEnvironment();
    final shell = await _findShell();
    if (shell == null) {
      _output.add('ERROR: No POSIX shell is available on this Android runtime.');
      return false;
    }

    // The interactive terminal must use the native PTY. A pipe-backed
    // Process.start() session is not a terminal: it cannot provide job
    // control, TTY ioctls, correct resize semantics, or reliable interactive
    // programs such as vim/top/nano.
    try {
      final ptyAvailable = await _pty.isAvailable();
      if (!ptyAvailable) {
        _output.add('ERROR: Zion PTY is unavailable on this Android runtime.\\r\\n');
        return false;
      }
      await _ptyOutputSub?.cancel();
      _ptyOutputSub = _pty.output.listen(_output.add);
      final startedPty = await _pty.start(rows: 40, cols: 120, shell: shell);
      if (!startedPty) {
        _output.add('ERROR: Unable to start Zion Userland PTY: $shell\\r\\n');
        _audit(
          command: '<interactive-start>',
          outcome: 'process-error',
          exitCode: 126,
          shell: shell,
          duration: DateTime.now().difference(started),
          interactive: true,
        );
        return false;
      }
      _interactiveInputBuffer = '';
      _output.add('Connected to Zion Userland: $shell • PTY\\r\\n');
      _audit(
        command: '<interactive-start>',
        outcome: 'success',
        exitCode: 0,
        shell: shell,
        duration: DateTime.now().difference(started),
        interactive: true,
      );
      return true;
    } on ProcessException catch (e) {
      _output.add('ERROR: Unable to start Zion Userland PTY: ${e.message}\\r\\n');
      _audit(
        command: '<interactive-start>',
        outcome: 'process-error',
        exitCode: 126,
        shell: shell,
        duration: DateTime.now().difference(started),
        interactive: true,
      );
      return false;
    } catch (e) {
      _output.add('ERROR: Unable to start Zion Userland PTY: $e\\r\\n');
      return false;
    }
  }

  void write(String input) {
    if (input.isEmpty) return;
    if (!_pty.isRunning) return;
    unawaited(_pty.write(input));
    final parts = (_interactiveInputBuffer + input).split('\\n');
    _interactiveInputBuffer = parts.removeLast();
    for (final rawCommand in parts) {
      final command = rawCommand.trim();
      if (command.isEmpty) continue;
      _remember(command);
      _audit(command: command, outcome: 'submitted', exitCode: -1, shell: 'process-shell', duration: Duration.zero, interactive: true);
    }
  }

  Future<bool> resizeInteractive({required int rows, required int cols}) async {
    if (!_pty.isRunning) return false;
    return _pty.resize(rows: rows, cols: cols);
  }

  Future<void> stopInteractive() async {
    if (_pty.isRunning) {
      _audit(command: '<interactive-stop>', outcome: 'success', exitCode: 0, shell: 'zion-userland-pty', duration: Duration.zero, interactive: true);
    }
    await _pty.stop();
    await _ptyOutputSub?.cancel();
    _ptyOutputSub = null;
    _interactiveInputBuffer = '';
  }

  Future<void> dispose() async {
    await stopInteractive();
    await _pty.dispose();
    await _output.close();
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

}
