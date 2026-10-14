import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../../security/core/authorization_policy.dart';
import '../../security/core/security_core.dart';
import '../../core/userland/zion_userland_installer.dart';
import 'native_pty_adapter.dart';
import 'terminal_capabilities.dart';

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
  static const Map<String, String> _androidEnvironment = <String, String>{
    'HOME': '/data/data/com.zion.os/files/home',
    'TMPDIR': '/data/data/com.zion.os/files/tmp',
    'PATH': '/system/bin:/system/xbin:/vendor/bin',
    'TERM': 'xterm-256color',
    'COLORTERM': 'truecolor',
    'LANG': 'C.UTF-8',
    'LC_ALL': 'C.UTF-8',
  };
  static const String _userlandBash = '/data/data/com.zion.os/files/usr/bin/bash';
  static const Map<String, String> _userlandEnvironment = <String, String>{
    'HOME': '/data/data/com.zion.os/files/home',
    'PREFIX': '/data/data/com.zion.os/files/usr',
    'TMPDIR': '/data/data/com.zion.os/files/tmp',
    'PATH': '/data/data/com.zion.os/files/usr/bin:/data/data/com.zion.os/files/usr/sbin:/system/bin:/system/xbin:/vendor/bin',
    'LD_LIBRARY_PATH': '/data/data/com.zion.os/files/usr/lib:/data/data/com.zion.os/files/usr/lib64',
    'TERM': 'xterm-256color',
    'COLORTERM': 'truecolor',
    'LANG': 'C.UTF-8',
    'LC_ALL': 'C.UTF-8',
  };
  static const ZionUserlandInstaller _userlandInstaller = ZionUserlandInstaller();

  Map<String, String> _environmentFor(String shell) =>
      shell == _userlandBash || shell.startsWith('/data/data/com.zion.os/files/usr/bin/')
          ? _userlandEnvironment
          : _androidEnvironment;

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

  Future<String?> _findShell({bool installIfMissing = false}) async {
    try {
      if (await _userlandInstaller.isInstalled(
        onProgress: (message) => _output.add('$message\r\n'),
      )) return _userlandBash;
      if (installIfMissing) {
        _output.add('[Terminal] First run: installing Userland from local storage...\r\n');
        final result = await _userlandInstaller.installLatest(
          onProgress: (message) => _output.add('$message\r\n'),
        );
        if (result.success && await _userlandInstaller.isInstalled()) {
          _output.add('[Terminal] ✓ Userland ready\r\n');
          return _userlandBash;
        }
        _output.add('[Terminal] Userland unavailable: ${result.message}. Falling back to Android shell.\r\n');
      }
    } catch (e) {
      _output.add('[Terminal] Userland check/install failed: $e\r\n');
    }

    const shell = '/system/bin/sh';
    try {
      if (!await File(shell).exists()) return null;
      final result = await Process.run(
        shell,
        const <String>['-c', 'exit 0'],
        runInShell: false,
        environment: _androidEnvironment,
      ).timeout(const Duration(seconds: 2));
      return result.exitCode == 0 ? shell : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureTerminalEnvironment() async {
    final base = Directory('/data/data/com.zion.os/files');
    try {
      await Directory(base.path + '/home').create(recursive: true);
      await Directory(base.path + '/tmp').create(recursive: true);
    } catch (_) {
      // The shell startup will report a concrete error if private storage fails.
    }
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
      process = await Process.start(
        shell,
        <String>['-c', command],
        runInShell: false,
        environment: _environmentFor(shell),
      );
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
        exitCode: e.errorCode ?? 126,
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
      return _builtinResult(value, 'Built-in: help, capabilities, zion-status, history, clear, exit, shell-status\nAndroid shell commands: pwd, ls, cat, id, uname -a, getprop, ip, ps, df, settings (permissions vary).\nCommands available depend on Android version and vendor image; common applets are provided by toybox.\nShell: /system/bin/sh with native PTY; no Zion Userland or root access is implied.');
    }
    if (value == 'wifi' || value == 'wifi scan' || value == 'wifi-scan') return _scanWifiBuiltin(value);
    if (value == 'capabilities') return _builtinResult(value, TerminalCapabilities.describe());
    if (value == 'zion-status') return _builtinResult(value, await TerminalCapabilities.describeRuntime());
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

  Future<bool> startInteractive({String? kaliRootfsPath}) async {
    if (isInteractiveRunning && kaliRootfsPath == null) return true;
    if (!_authorized('<interactive-shell>')) {
      _output.add('ERROR: Interactive shell denied by Zion SecurityCore authorization policy.');
      return false;
    }
    final started = DateTime.now();
    // Kali is a selectable PTY profile, not a Userland installation step.
    // Its rootfs remains at the caller-supplied path; Zion only supplies PRoot.
    await _ensureTerminalEnvironment();
    String? shell;
    if (kaliRootfsPath != null) {
      final rootfsPath = kaliRootfsPath.trim();
      if (!rootfsPath.startsWith('/') ||
          rootfsPath.contains('|') ||
          rootfsPath.contains('\\n') ||
          rootfsPath.contains('\\r') ||
          rootfsPath.contains('\\u0000')) {
        _output.add('[Kali] مسار rootfs غير صالح؛ استخدم مسارًا مطلقًا دون أسطر جديدة.\\r\\n');
        return false;
      }
      final rootfs = Directory(rootfsPath);
      final proot = File('/data/data/com.zion.os/files/usr/bin/proot');
      final loader = File('/data/data/com.zion.os/files/usr/libexec/proot');
      if (!await rootfs.exists() ||
          !await File('$rootfsPath/bin/bash').exists() ||
          !await File('$rootfsPath/bin/sh').exists()) {
        _output.add('[Kali] لم يُعثر على rootfs صالح في: $rootfsPath (المطلوب bin/bash وbin/sh). لم يتم نسخ الملفات.\\r\\n');
        return false;
      }
      if (!await proot.exists() || !await loader.exists()) {
        _output.add('[Kali] أدوات Zion PRoot غير مكتملة؛ ثبّت/أصلح PRoot داخل Zion Userland أولًا. لم تتم محاولة تنزيل Kali أو نسخه.\\r\\n');
        return false;
      }
      try {
        final mode = (await proot.stat()).mode;
        if ((mode & 0x49) == 0) {
          _output.add('[Kali] ملف PRoot موجود لكنه غير قابل للتنفيذ: ${proot.path}\\r\\n');
          return false;
        }
      } catch (_) {
        _output.add('[Kali] تعذر فحص صلاحية تشغيل PRoot.\\r\\n');
        return false;
      }
      shell = 'zion-kali@$rootfsPath';
    } else {
      shell = await _findShell(installIfMissing: true);
    }
    if (shell == null) {
      _output.add('No usable Userland Bash or Android system shell is available on this device.\r\n');
      _audit(
        command: '<interactive-start>',
        outcome: 'unavailable',
        exitCode: 127,
        shell: 'unavailable',
        duration: DateTime.now().difference(started),
        interactive: false,
      );
      return false;
    }
    _output.add(shell == _userlandBash
        ? 'Userland Bash ready: $shell\r\n'
        : 'Android shell ready: $shell\r\n');

    // The interactive terminal must use the native PTY. A pipe-backed
    // Process.start() session is not a terminal: it cannot provide job
    // control, TTY ioctls, correct resize semantics, or reliable interactive
    // programs such as vim/top/nano.
    try {
      final ptyAvailable = await _pty.isAvailable();
      if (!ptyAvailable) {
        _output.add('ERROR: Native PTY is unavailable on this Android runtime.\r\n');
        return false;
      }
      await _ptyOutputSub?.cancel();
      _ptyOutputSub = _pty.output.listen(_output.add);
      final startedPty = await _pty.start(rows: 40, cols: 120, shell: shell);
      if (!startedPty) {
        _output.add('ERROR: Unable to start Android shell PTY: $shell\r\n');
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
      _output.add(shell == _userlandBash
          ? 'Connected to Userland: bash • native PTY\r\n'
          : 'Connected to Android system shell: $shell • native PTY\r\n');
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
      _output.add('ERROR: Unable to start Android shell PTY: ${e.message}\r\n');
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
      _output.add('ERROR: Unable to start Android shell PTY: $e\r\n');
      return false;
    }
  }

  void write(String input) {
    if (input.isEmpty) return;
    if (!_pty.isRunning) {
      // TerminalView sends one callback for every typed character. Report the
      // stopped session on Enter only, not on every keypress.
      if (input.contains('\n') || input.contains('\r')) {
        _output.add(
          '\r\n\x1b[33m⚠️ [PTY] الجلسة متوقفة.\r\n'
          '\x1b[36m💡 اضغط زر ▶ لبدء جلسة جديدة.\x1b[0m\r\n',
        );
      }
      return;
    }
    unawaited(_pty.write(input));
    final parts = (_interactiveInputBuffer + input).split('\n');
    _interactiveInputBuffer = parts.removeLast();
    for (final rawCommand in parts) {
      final command = rawCommand.trim();
      if (command.isEmpty) continue;
      _remember(command);
      _audit(command: command, outcome: 'submitted', exitCode: -1, shell: 'android-system-shell', duration: Duration.zero, interactive: true);
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
