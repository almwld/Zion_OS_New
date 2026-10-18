import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../../security/core/authorization_policy.dart';
import '../../security/core/security_core.dart';
import '../../core/userland/zion_userland_installer.dart';
import '../../core/userland/local_kali_bootstrap.dart';
import 'native_pty_adapter.dart';
import 'terminal_logs.dart';
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

  // The terminal UI and Super Agent share the selected live PTY service.
  // This prevents the agent from silently opening a disconnected shell.
  static TerminalService? _activeInteractiveService;
  static TerminalService? get activeInteractiveService => _activeInteractiveService;

  void activateForAgent() {
    _activeInteractiveService = this;
  }

  int _agentLeases = 0;
  bool _disposeRequested = false;
  bool _disposed = false;

  void retainForAgent() {
    if (_disposed) throw StateError('TerminalService has already been disposed.');
    _agentLeases++;
  }

  Future<void> releaseForAgent() async {
    if (_agentLeases > 0) _agentLeases--;
    if (_agentLeases == 0 && _disposeRequested) {
      await _disposeNow();
    }
  }

  void _releaseAgentTarget() {
    if (identical(_activeInteractiveService, this)) {
      _activeInteractiveService = null;
    }
  }

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
    'SHELL': '/system/bin/sh',
    'ZION_TERMINAL': '1',
  };
  static const String _userlandBash = '/data/data/com.zion.os/files/usr/bin/bash';
  static const Map<String, String> _userlandEnvironment = <String, String>{
    'HOME': '/data/data/com.zion.os/files/home',
    'PREFIX': '/data/data/com.zion.os/files/usr',
    'TMPDIR': '/data/data/com.zion.os/files/tmp',
    'PATH': '/data/data/com.zion.os/files/usr/bin:/data/data/com.zion.os/files/usr/sbin:/system/bin:/system/xbin:/vendor/bin',
    'LD_LIBRARY_PATH': '/data/data/com.zion.os/files/usr/lib:/data/data/com.zion.os/files/usr/lib64:/data/data/com.zion.os/files/usr/libexec',
    'TERM': 'xterm-256color',
    'COLORTERM': 'truecolor',
    'LANG': 'C.UTF-8',
    'LC_ALL': 'C.UTF-8',
    'SHELL': '/data/data/com.zion.os/files/usr/bin/bash',
    'ZION_TERMINAL': '1',
  };
  static const ZionUserlandInstaller _userlandInstaller = ZionUserlandInstaller();

  Map<String, String> _environmentFor(String shell) {
    final isUserland = shell == _userlandBash ||
        shell.startsWith('/data/data/com.zion.os/files/usr/bin/');
    final environment = Map<String, String>.from(
      isUserland ? _userlandEnvironment : _androidEnvironment,
    );
    if (isUserland) {
      const certificate = '/data/data/com.zion.os/files/usr/etc/tls/cert.pem';
      if (File(certificate).existsSync()) {
        environment['SSL_CERT_FILE'] = certificate;
        environment['CURL_CA_BUNDLE'] = certificate;
      }
    }
    return environment;
  }

  final SecurityCore _securityCore;
  final NativePtyAdapter _pty = NativePtyAdapter();
  StreamSubscription<String>? _ptyOutputSub;
  final List<String> _history = <String>[];
  final StreamController<String> _output = StreamController<String>.broadcast();
  void _emitOutput(String event) {
    // Async install/progress work may finish after a terminal tab is disposed.
    if (!_output.isClosed) _output.add(event);
  }
  String _interactiveInputBuffer = '';
  String? _interactiveShell;
  static const String _kaliRootfsPreferenceKey = 'zion_terminal_kali_rootfs_path_v1';
  static const String _defaultKaliRootfs = '/data/data/com.zion.os/files/home/.zion/dists/kali/rootfs';
  static String? _cachedKaliRootfsPath;

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

  Future<String?> _findUsableUserlandShell() async {
    final prefix = '/data/data/com.zion.os/files/usr';

    // bash.real is the actual ELF payload; bin/bash is only a small wrapper
    // and can be missing after an interrupted restore. Probe the payload
    // directly through Android's linker before requiring that wrapper to exist.
    final realBashPath = '$prefix/bin/bash.real';
    try {
      if (await File(realBashPath).exists()) {
        final linked = await Process.run(
          '/system/bin/linker64',
          <String>[realBashPath, '--version'],
          runInShell: false,
          environment: _userlandEnvironment,
        ).timeout(const Duration(seconds: 4));
        if (linked.exitCode == 0 && linked.stdout.toString().contains('GNU bash')) {
          _emitOutput('[Userland] Verified Bash ELF via Android linker: $realBashPath\\r\\n');
          return realBashPath;
        }
        _emitOutput('[Userland] Bash ELF probe failed: exit ${linked.exitCode}; ${linked.stderr}\\r\\n');
      }
    } catch (error) {
      _emitOutput('[Userland] Could not probe Bash ELF via linker64: $error\\r\\n');
    }

    for (final name in const <String>['bash', 'sh', 'dash']) {
      final path = '$prefix/bin/$name';
      try {
        if (!await File(path).exists()) continue;

        // Android can reject direct exec of a Termux ELF in app-private
        // storage even though the system linker can load it. Verify Bash via
        // linker64 with Zion's explicit LD_LIBRARY_PATH before probing the
        // wrapper with Process.run.
        if (name == 'bash') {
          final realPath = '$prefix/bin/bash.real';
          if (await File(realPath).exists()) {
            final linked = await Process.run(
              '/system/bin/linker64',
              <String>[realPath, '--version'],
              runInShell: false,
              environment: _userlandEnvironment,
            ).timeout(const Duration(seconds: 4));
            final versionOutput = linked.stdout.toString();
            if (linked.exitCode == 0 && versionOutput.contains('GNU bash')) {
              _emitOutput('[Userland] Verified Bash via Android linker: $realPath\r\n');
              // Keep the public wrapper as the selected path. Native PTY
              // launch maps /bash to bash.real and supplies the same library
              // environment, so shell selection matches this successful probe.
              return path;
            }
            _emitOutput('[Userland] linker64 Bash probe failed: exit ${linked.exitCode}; ${linked.stderr}\r\n');
          }
        }

        final result = await Process.run(
          path,
          const <String>['-c', 'printf ZION_SHELL_OK'],
          runInShell: false,
          environment: _userlandEnvironment,
        ).timeout(const Duration(seconds: 3));
        if (result.exitCode == 0 && result.stdout.toString().contains('ZION_SHELL_OK')) {
          _emitOutput('[Userland] Using verified shell: $path\r\n');
          return path;
        }
        _emitOutput('[Userland] Shell candidate failed: $path (exit ${result.exitCode}; ${result.stderr})\r\n');
        if (name == 'bash') {
          await diagnoseBashExecution(
            launchError: 'Process.run returned exit ${result.exitCode}; stdout=${result.stdout}; stderr=${result.stderr}',
          );
        }
      } catch (error) {
        _emitOutput('[Userland] Cannot execute $path: $error\r\n');
        if (name == 'bash') {
          await diagnoseBashExecution(launchError: error);
        }
      }
    }
    return null;
  }

  /// Collects on-device evidence for a Userland Bash launch failure.
  ///
  /// Dart does not expose every Android inode/security attribute directly, so
  /// this combines Dart metadata, Android toolbox output, a platform-shell
  /// control, the real ProcessException, dependency checks, and filtered logs.
  Future<void> diagnoseBashExecution({Object? launchError}) async {
    const bashPath = _userlandBash;
    const prefix = '/data/data/com.zion.os/files/usr';
    void add(String line) {
      ZionTerminalLogs.add(line);
    }

    add('========== Bash execution diagnosis ==========');
    add('path=$bashPath');
    if (launchError is ProcessException) {
      add('initial ProcessException: errno=${launchError.errorCode}; message=${launchError.message}; executable=${launchError.executable}');
    } else if (launchError != null) {
      add('initial launch error: $launchError');
    }

    final bash = File(bashPath);
    try {
      add('exists=${await bash.exists()}');
      if (await bash.exists()) {
        final stat = await bash.stat();
        add('stat: type=${stat.type}; size=${stat.size}; modified=${stat.modified.toIso8601String()}; mode=0${stat.mode.toRadixString(8)}');
        final bytes = await bash.openRead(0, 64).fold<List<int>>(<int>[], (all, part) => all..addAll(part));
        if (bytes.length >= 20 && bytes[0] == 0x7f && bytes[1] == 0x45 && bytes[2] == 0x4c && bytes[3] == 0x46) {
          final elfClass = bytes[4] == 2 ? 'ELF64' : (bytes[4] == 1 ? 'ELF32' : 'unknown-class-${bytes[4]}');
          final endian = bytes[5] == 1 ? Endian.little : Endian.big;
          final machine = ByteData.sublistView(Uint8List.fromList(bytes)).getUint16(18, endian);
          final arch = switch (machine) {
            183 => 'AArch64',
            40 => 'ARM',
            62 => 'x86_64',
            3 => 'x86',
            _ => 'unknown-e_machine-${machine}',
          };
          add('ELF: $elfClass; e_machine=$machine ($arch); endian=${bytes[5] == 1 ? "little" : "big"}');
        } else {
          add('ELF header: not ELF or shorter than 20 bytes');
        }
      }
    } catch (e) {
      add('Dart stat/read failed: $e');
    }

    Future<String> probe(String command, {Duration timeout = const Duration(seconds: 3)}) async {
      try {
        final result = await Process.run(
          '/system/bin/sh',
          <String>['-c', command],
          runInShell: false,
          environment: _androidEnvironment,
        ).timeout(timeout);
        final stdout = result.stdout.toString().trim();
        final stderr = result.stderr.toString().trim();
        return 'exit=${result.exitCode}${stdout.isEmpty ? "" : "; stdout=$stdout"}${stderr.isEmpty ? "" : "; stderr=$stderr"}';
      } catch (e) {
        return 'unavailable: $e';
      }
    }

    add('UID/GID/mode/SELinux label: ${await probe("ls -lnZ '$bashPath' 2>&1")}');
    add('app process SELinux context: ${await probe('cat /proc/self/attr/current 2>&1')}');
    add('toybox stat: ${await probe("toybox stat -c 'uid=%u gid=%g mode=%a type=%F' '$bashPath' 2>&1")}');

    try {
      final control = await Process.run(
        '/system/bin/sh',
        const <String>['-c', 'printf ZION_ANDROID_SHELL_OK'],
        runInShell: false,
        environment: _androidEnvironment,
      ).timeout(const Duration(seconds: 3));
      add('control /system/bin/sh: exit=${control.exitCode}; stdout=${control.stdout.toString().trim()}; stderr=${control.stderr.toString().trim()}');
    } catch (e) {
      add('control /system/bin/sh failed: $e');
    }

    // A second control uses a small native Android ELF (toybox), not just
    // the /system/bin/sh interpreter. This helps distinguish general app
    // process-execution restrictions from a Userland-specific binary issue.
    try {
      const toybox = '/system/bin/toybox';
      final toyboxStat = await File(toybox).stat();
      add('Android ELF control metadata: path=$toybox; type=${toyboxStat.type}; size=${toyboxStat.size}; mode=0${toyboxStat.mode.toRadixString(8)}');
      final toyboxRun = await Process.run(
        toybox,
        const <String>['true'],
        runInShell: false,
        environment: _androidEnvironment,
      ).timeout(const Duration(seconds: 3));
      add('Android ELF control /system/bin/toybox true: exit=${toyboxRun.exitCode}; stdout=${toyboxRun.stdout.toString().trim()}; stderr=${toyboxRun.stderr.toString().trim()}');
    } on ProcessException catch (e) {
      add('Android ELF control ProcessException: errno=${e.errorCode}; message=${e.message}; executable=${e.executable}');
    } catch (e) {
      add('Android ELF control failed: $e');
    }

    try {
      final result = await Process.run(
        bashPath,
        const <String>['-c', 'printf ZION_BASH_EXEC_OK'],
        runInShell: false,
        environment: _userlandEnvironment,
      ).timeout(const Duration(seconds: 4));
      add('Bash launch: exit=${result.exitCode}; stdout=${result.stdout.toString().trim()}; stderr=${result.stderr.toString().trim()}');
    } on ProcessException catch (e) {
      add('Bash ProcessException: errno=${e.errorCode}; message=${e.message}; executable=${e.executable}; arguments=${e.arguments}');
    } catch (e) {
      add('Bash launch failed: $e');
    }

    for (final tool in const <String>['file', 'readelf', 'ldd']) {
      add('tool $tool: ${await probe('command -v $tool 2>&1')}');
    }
    for (final library in const <String>[
      'libreadline.so.8', 'libiconv.so', 'libdl.so', 'libc.so',
      'libncursesw.so.6', 'libtinfo.so.6',
    ]) {
      add('$library exists=${await File('$prefix/lib/$library').exists()}');
    }

    add('readelf dependencies: ${await probe("if command -v readelf >/dev/null 2>&1; then readelf -d '$bashPath' 2>&1 | head -n 50; else echo readelf-unavailable; fi")}');
    add('ldd dependencies: ${await probe("if command -v ldd >/dev/null 2>&1; then ldd '$bashPath' 2>&1 | head -n 50; else echo ldd-unavailable; fi")}');

    try {
      final logs = await Process.run(
        '/system/bin/logcat',
        const <String>['-d', '-t', '500'],
        runInShell: false,
        environment: _androidEnvironment,
      ).timeout(const Duration(seconds: 5));
      final relevant = logs.stdout.toString().split('\n').where((line) =>
          RegExp(r'avc:\s*denied|SELinux|linker|CANNOT LINK EXECUTABLE|not found|Permission denied|execve|dlopen', caseSensitive: false).hasMatch(line)).toList();
      add('logcat relevant lines=${relevant.length}; logcat exit=${logs.exitCode}');
      for (final line in relevant.take(60)) {
        add('logcat: ${line.trim()}');
      }
      if (relevant.isEmpty) add('logcat: no matching lines visible; Android may restrict app access');
    } catch (e) {
      add('logcat unavailable/restricted: $e');
    }
    add('========== End Bash diagnosis ==========');
  }

  Future<String?> _findShell({bool installIfMissing = false}) async {
    try {
      // A usable sh/dash may remain after an incomplete backup restore. Check
      // it before invoking the installer so each app launch does not recopy
      // the entire Userland tree just because bash is absent.
      final existingUserlandShell = await _findUsableUserlandShell();
      if (existingUserlandShell != null) return existingUserlandShell;
      if (await _userlandInstaller.isInstalled(
        onProgress: (message) => _emitOutput('$message\r\n'),
      )) {
        final shell = await _findUsableUserlandShell();
        if (shell != null) return shell;
      }
      if (installIfMissing) {
        _emitOutput('[Terminal] First run: installing Userland from local storage...\r\n');
        final result = await _userlandInstaller.installLatest(
          onProgress: (message) => _emitOutput('$message\r\n'),
        );
        if (result.success && await _userlandInstaller.isInstalled()) {
          // A preserved Bash file may still be blocked by Android's execution
          // policy/linker. Verify an actual shell launch before selecting it;
          // installer success must never suppress the Android shell fallback.
          final installedShell = await _findUsableUserlandShell();
          if (installedShell != null) {
            _emitOutput('[Terminal] ✓ Userland shell ready: $installedShell\r\n');
            return installedShell;
          }
          _emitOutput('[Terminal] Userland files were preserved, but no bundled shell could execute; falling back to /system/bin/sh.\r\n');
        } else {
          _emitOutput('[Terminal] Userland unavailable: ${result.message}.\r\n');
        }
        final recoveredShell = await _findUsableUserlandShell();
        if (recoveredShell != null) {
          _emitOutput('[Terminal] Using recovered Userland shell: $recoveredShell\r\n');
          return recoveredShell;
        }
        _emitOutput('[Terminal] Falling back to /system/bin/sh.\r\n');
      }
    } catch (e) {
      _emitOutput('[Terminal] Userland check/install failed: $e\r\n');
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
    final result = await _pty.runCommand(
      command: command,
      shell: shell,
      timeout: _commandTimeout,
    );
    final terminalResult = TerminalResult(
      command: command,
      stdout: result.stdout,
      stderr: result.stderr,
      exitCode: result.exitCode,
      duration: DateTime.now().difference(started),
      shell: shell,
    );
    _audit(
      command: command,
      outcome: terminalResult.exitCode == 0
          ? 'success'
          : (terminalResult.exitCode == 124 ? 'timeout' : 'failed'),
      exitCode: terminalResult.exitCode,
      shell: shell,
      duration: terminalResult.duration,
      interactive: false,
    );
    return terminalResult;
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
      _emitOutput('\x1b[2J\x1b[H');
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

  Future<bool> _isValidLocalKaliRootfs(String path) async {
    try {
      final root = Directory(path);
      final bash = File('$path/bin/bash');
      final shell = File('$path/bin/sh');
      final env = File('$path/usr/bin/env');
      final release = File('$path/etc/os-release');
      if (!await root.exists() ||
          !await bash.exists() ||
          !await shell.exists() ||
          !await env.exists() ||
          !await release.exists() ||
          await bash.length() < 100000) {
        return false;
      }
      final releaseText = (await release.readAsString()).toLowerCase();
      if (!releaseText.contains('kali')) return false;

      // A real Kali ARM64 rootfs uses a Linux AArch64 ELF, not an Android
      // Bionic binary. Check the ELF machine before attempting PRoot launch.
      final header = await bash.openRead(0, 20).fold<List<int>>(
        <int>[],
        (bytes, part) => bytes..addAll(part),
      );
      if (header.length < 20 ||
          header[0] != 0x7f ||
          header[1] != 0x45 ||
          header[2] != 0x4c ||
          header[3] != 0x46 ||
          header[4] != 2 ||
          header[5] != 1) {
        return false;
      }
      final machine = ByteData.sublistView(Uint8List.fromList(header))
          .getUint16(18, Endian.little);
      if (machine != 183) return false;

      final interpreters = <String>[
        '$path/lib/ld-linux-aarch64.so.1',
        '$path/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1',
        '$path/usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1',
      ];
      for (final interpreter in interpreters) {
        if (await File(interpreter).exists()) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Recover a previously extracted rootfs.staging-* only after checking its
  /// distro identity, ARM64 ELF header, shell, env, and glibc interpreter.
  /// Promotion is a same-filesystem rename and never overwrites an existing
  /// final rootfs or deletes the staging tree.
  Future<String?> _recoverValidatedStagedKaliRootfs() async {
    const installedPath =
        '/data/data/com.zion.os/files/home/.zion/dists/kali/rootfs';
    final parent = Directory(
      '/data/data/com.zion.os/files/home/.zion/dists/kali',
    );
    try {
      if (!await parent.exists()) return null;
      final candidates = <Directory>[];
      await for (final entry in parent.list(followLinks: false)) {
        if (entry is Directory &&
            entry.path.split('/').last.startsWith('rootfs.staging-')) {
          candidates.add(entry);
        }
      }
      candidates.sort((a, b) => b.path.compareTo(a.path));
      for (final candidate in candidates) {
        if (!await _isValidLocalKaliRootfs(candidate.path)) continue;
        if (await FileSystemEntity.type(installedPath, followLinks: false) ==
            FileSystemEntityType.notFound) {
          try {
            final promoted = await candidate.rename(installedPath);
            if (await _isValidLocalKaliRootfs(promoted.path)) {
              _cachedKaliRootfsPath = promoted.path;
              _emitOutput(
                '[Kali] Recovered and validated existing staged rootfs at '
                '${promoted.path}; no archive download or re-extraction was needed.\r\n',
              );
              return promoted.path;
            }
          } catch (error) {
            _emitOutput(
              '[Kali] Safe rootfs promotion unavailable; preserving staged '
              'rootfs at ${candidate.path}: $error\r\n',
            );
          }
        }
        // If a final path already exists or rename is unavailable, the
        // validated staging path is still a usable local rootfs.
        _cachedKaliRootfsPath = candidate.path;
        _emitOutput(
          '[Kali] Using validated existing staging rootfs: '
          '${candidate.path}\r\n',
        );
        return candidate.path;
      }
    } catch (error) {
      _emitOutput('[Kali] Staging recovery scan failed safely: $error\r\n');
    }
    return null;
  }

  /// Prefer the configured/private Kali rootfs, then discover common local
  /// rootfs locations on shared storage. This is discovery only: no network,
  /// extraction, or file copying occurs while starting the agent runtime.
  Future<String?> _resolveLocalKaliRootfs() async {
    // First reuse the app-private rootfs created by the local offline installer.
    const installedRootfs = '/data/data/com.zion.os/files/home/.zion/dists/kali/rootfs';
    if (await _isValidLocalKaliRootfs(installedRootfs)) {
      _cachedKaliRootfsPath = installedRootfs;
      return installedRootfs;
    }
    final recoveredStaging = await _recoverValidatedStagedKaliRootfs();
    if (recoveredStaging != null) return recoveredStaging;

    // If the user explicitly selects Kali and the known local ARM64 archive is
    // present, import it offline into Kali's own rootfs location. Never unpack
    // it into Zion's usr prefix: a distro rootfs and the Termux runtime differ.
    try {
      final kaliBootstrap = const ZionLocalKaliBootstrap();
      final state = await kaliBootstrap.state();
      final localPackage = await kaliBootstrap.findLocalPackage();
      if (state != ZionKaliInstallState.ready && localPackage != null) {
        _emitOutput('[Kali] Local archive found; installing into the separate Kali rootfs (offline)...\r\n');
        final result = await kaliBootstrap.install(
          onProgress: (progress) => _emitOutput(
            '[Kali ${progress.percent}%] ${progress.message}\r\n',
          ),
        );
        if (result.isSuccess && result.value != null &&
            await File('${result.value!.path}/bin/bash').exists() &&
            await File('${result.value!.path}/bin/sh').exists()) {
          _cachedKaliRootfsPath = result.value!.path;
          return result.value!.path;
        }
        _emitOutput('[Kali] Local archive import failed: ${result.error}\r\n');
      } else if (state == ZionKaliInstallState.error) {
        _emitOutput('[Kali] Previous local rootfs state is invalid; a verified local archive is required to reinstall.\r\n');
      }
    } catch (error) {
      _emitOutput('[Kali] Local archive discovery/import failed: $error\r\n');
    }

    final cached = _cachedKaliRootfsPath;
    if (cached != null &&
        await File('$cached/bin/bash').exists() &&
        await File('$cached/bin/sh').exists()) {
      return cached;
    }
    final candidates = <String>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final configured = prefs.getString(_kaliRootfsPreferenceKey)?.trim();
      if (configured != null && configured.startsWith('/')) candidates.add(configured);
    } catch (_) {}
    candidates.addAll(const <String>[
      _defaultKaliRootfs,
      '/storage/emulated/0/kali-rootfs',
      '/storage/emulated/0/kali-arm64',
      '/storage/emulated/0/kali/rootfs',
      '/storage/emulated/0/Download/kali-rootfs',
      '/storage/emulated/0/Download/kali-arm64',
      '/storage/emulated/0/Download/kali/rootfs',
      '/storage/emulated/0/Downloads/kali-rootfs',
      '/storage/emulated/0/Downloads/kali-arm64',
    ]);
    for (final candidate in candidates.toSet()) {
      if (await File('$candidate/bin/bash').exists() &&
          await File('$candidate/bin/sh').exists()) {
        _cachedKaliRootfsPath = candidate;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kaliRootfsPreferenceKey, candidate);
        } catch (_) {}
        return candidate;
      }
    }

    // Bounded directory discovery finds locally extracted systems whose
    // directory name is not one of the common defaults.
    for (final parentPath in const <String>[
      '/storage/emulated/0',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
    ]) {
      final parent = Directory(parentPath);
      try {
        if (!await parent.exists()) continue;
        var inspected = 0;
        await for (final entity in parent.list(followLinks: false)) {
          if (entity is! Directory || inspected++ >= 200) continue;
          final name = entity.path.split('/').last.toLowerCase();
          if (!name.contains('kali') && !name.contains('rootfs') && !name.contains('linux')) continue;
          final path = entity.path;
          if (await File('$path/bin/bash').exists() &&
              await File('$path/bin/sh').exists()) {
            _cachedKaliRootfsPath = path;
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_kaliRootfsPreferenceKey, path);
            } catch (_) {}
            return path;
          }
        }
      } catch (_) {
        // Scoped storage or a missing directory is reported as unavailable.
      }
    }
    return null;
  }

  Future<bool> startInteractive({String? kaliRootfsPath}) async {
    // Do not run the full multi-process Bash diagnostic on every PTY start:
    // it can spend several seconds invoking logcat/readelf and delays the
    // Android-shell fallback. _findUsableUserlandShell() runs this diagnostic
    // only when an existing Bash candidate actually fails to launch; missing
    // files are covered by the bounded usr inventory below.
    try {
      await _userlandInstaller.logUsrDiagnostics(
        onProgress: ZionTerminalLogs.add,
      );
    } catch (error) {
      ZionTerminalLogs.add('Userland inventory diagnostic failed safely: $error');
    }
    try {
      final inventory = await _pty.inspectRuntime();
      if (inventory != null) {
        final nativeDir = inventory['nativeLibraryDir'];
        ZionTerminalLogs.add('APK nativeLibraryDir: $nativeDir');
        final libraries = inventory['libraries'];
        if (libraries is Map) {
          for (final entry in libraries.entries) {
            final details = entry.value;
            if (details is Map) {
              ZionTerminalLogs.add('${entry.key}: present=${details['present']}, size=${details['sizeBytes']} bytes');
            }
          }
        }
        ZionTerminalLogs.add('Userland Bash: exists=${inventory['bashExists']}, size=${inventory['bashSizeBytes']} bytes');
        ZionTerminalLogs.add('ZionUniversal: exists=${inventory['localBundleExists']}, entries=${inventory['localBundleEntries']}');
      }
    } catch (error) {
      ZionTerminalLogs.add('Runtime inventory unavailable: $error');
    }

    if (isInteractiveRunning && kaliRootfsPath == null && !(_interactiveShell?.startsWith('zion-kali@') ?? false)) return true;
    if (isInteractiveRunning && kaliRootfsPath != null && _interactiveShell == 'zion-kali@$kaliRootfsPath') return true;
    if (isInteractiveRunning) {
      await stopInteractive();
    }
    if (!_authorized('<interactive-shell>')) {
      _emitOutput('ERROR: Interactive shell denied by Zion SecurityCore authorization policy.');
      return false;
    }
    final started = DateTime.now();
    // The embedded Termux bootstrap must be extracted before
    // _ensureTerminalEnvironment() creates an otherwise-empty usr/ prefix.
    // Installation is idempotent and refuses to overwrite a non-empty prefix.
    try {
      final bootstrap = await _pty.ensureBootstrap();
      if (bootstrap != null) {
        final message = bootstrap['message']?.toString() ?? 'No bootstrap status returned.';
        _emitOutput('[Bootstrap] $message\r\n');
        if (bootstrap['success'] != true) {
          _emitOutput('[Bootstrap] status=${bootstrap['status'] ?? 'unknown'}; existing files were preserved.\r\n');
        }
      }
    } catch (error) {
      _emitOutput('[Bootstrap] Initialization failed safely: $error\r\n');
    }

    // Kali uses the installed Zion PRoot runtime and a local rootfs. Bootstrap
    // is still attempted above because PRoot itself may be supplied by PREFIX.
    await _ensureTerminalEnvironment();
    String? shell;
    if (kaliRootfsPath != null) {
      final path = kaliRootfsPath.trim();
      if (!path.startsWith('/') ||
          path.contains('|') ||
          path.contains('\\n') ||
          path.contains('\\r') ||
          path.contains('\\u0000')) {
        _emitOutput('[Kali] Invalid local rootfs path.\r\n');
        return false;
      }
      final rootfs = Directory(path);
      final bash = File('$path/bin/bash');
      final shellFile = File('$path/bin/sh');
      final proot = File('/data/data/com.zion.os/files/usr/bin/proot');
      final loader = File('/data/data/com.zion.os/files/usr/libexec/proot');
      if (!await rootfs.exists() ||
          !await bash.exists() ||
          !await shellFile.exists() ||
          !await _isValidLocalKaliRootfs(path)) {
        _emitOutput('[Kali] Invalid rootfs: expected a verified Kali ARM64 rootfs with bin/bash, bin/sh, usr/bin/env, and the glibc loader at $path. No files were copied.\r\n');
        return false;
      }
      final prootReady = await _pty.ensureProotRuntime();
      if (!prootReady || !await proot.exists() || !await loader.exists()) {
        _emitOutput('[Kali] Zion PRoot/loader could not be materialized from the bundled APK runtime.\r\n');
        return false;
      }
      shell = 'zion-kali@$path';
      _emitOutput('[Kali] Starting local rootfs without copying it: $path\r\n');
    } else {
      shell = await _findShell(installIfMissing: true);
    }
    if (shell == null) {
      _emitOutput('No usable Userland Bash or Android system shell is available on this device.\r\n');
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
    _emitOutput(shell == _userlandBash || shell.startsWith('/data/data/com.zion.os/files/usr/bin/')
        ? 'Userland Bash ready: $shell\\r\\n'
        : 'Android shell ready: $shell\\r\\n');

    // The interactive terminal must use the native PTY. A pipe-backed
    // Process.start() session is not a terminal: it cannot provide job
    // control, TTY ioctls, correct resize semantics, or reliable interactive
    // programs such as vim/top/nano.
    try {
      final ptyAvailable = await _pty.isAvailable();
      if (!ptyAvailable) {
        _emitOutput('ERROR: Native PTY is unavailable on this Android runtime.\r\n');
        return false;
      }
      await _ptyOutputSub?.cancel();
      _ptyOutputSub = _pty.output.listen(_emitOutput);
      final startedPty = await _pty.start(rows: 40, cols: 120, shell: shell);
      if (!startedPty) {
        _emitOutput('ERROR: Unable to start Android shell PTY: $shell\r\n');
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
      _emitOutput(shell == _userlandBash
          ? 'Connected to Userland: bash • native PTY\r\n'
          : 'Connected to Android system shell: $shell • native PTY\r\n');
      _interactiveShell = shell;
      _activeInteractiveService = this;
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
      _emitOutput('ERROR: Unable to start Android shell PTY: ${e.message}\r\n');
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
      _emitOutput('ERROR: Unable to start Android shell PTY: $e\r\n');
      return false;
    }
  }

  void write(String input) {
    if (input.isEmpty) return;
    if (!_pty.isRunning) {
      // TerminalView sends one callback for every typed character. Report the
      // stopped session on Enter only, not on every keypress.
      if (input.contains('\n') || input.contains('\r')) {
        _emitOutput(
          '\r\n\x1b[33m⚠️ [PTY] الجلسة متوقفة.\r\n'
          '\x1b[36m💡 اضغط زر ▶ لبدء جلسة جديدة.\x1b[0m\r\n',
        );
      }
      return;
    }
    // Android keyboards may submit Enter as CR, LF, or CRLF. Normalize
    // before forwarding to the PTY and before updating command history.
    final normalizedInput = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    unawaited(_pty.write(normalizedInput));
    final parts = (_interactiveInputBuffer + normalizedInput).split('\n');
    _interactiveInputBuffer = parts.removeLast();
    for (final rawCommand in parts) {
      final command = rawCommand.trim();
      if (command.isEmpty) continue;
      _remember(command);
      _audit(command: command, outcome: 'submitted', exitCode: -1, shell: 'android-system-shell', duration: Duration.zero, interactive: true);
    }
  }


  bool _agentCommandRunning = false;

  /// Executes one command through Zion's native PTY and captures its exit code.
  Future<TerminalResult> executeInInteractive(
    String command, {
    Duration timeout = const Duration(seconds: 30),
    String runtime = 'auto',
    String? rootfsPath,
  }) async {
    final value = command.trim();
    if (value.isEmpty) {
      return const TerminalResult(command: '', stdout: '', stderr: 'الأمر فارغ.',
        exitCode: 2, duration: Duration.zero, shell: 'zion-native-pty');
    }
    if (value.contains('\u0000')) {
      return const TerminalResult(command: '', stdout: '', stderr: 'الأمر يحتوي على محرف غير صالح.',
        exitCode: 2, duration: Duration.zero, shell: 'zion-native-pty');
    }
    if (!_authorized(value)) {
      final denied = TerminalResult(command: value, stdout: '',
        stderr: 'رفضت Zion SecurityCore تنفيذ الأمر.', exitCode: 126,
        duration: Duration.zero, shell: 'security-core');
      _audit(command: value, outcome: 'denied', exitCode: denied.exitCode,
        shell: denied.shell, duration: denied.duration, interactive: true);
      return denied;
    }
    if (_agentCommandRunning) {
      return const TerminalResult(command: '', stdout: '',
        stderr: 'يوجد أمر وكيل قيد التنفيذ في جلسة PTY.', exitCode: 125,
        duration: Duration.zero, shell: 'zion-native-pty');
    }

    if (!const {'auto', 'zion', 'kali', 'rootfs'}.contains(runtime)) {
      return TerminalResult(command: value, stdout: '',
        stderr: 'بيئة التنفيذ غير معروفة: $runtime', exitCode: 2,
        duration: Duration.zero, shell: 'zion-native-pty');
    }
    if (runtime == 'rootfs') {
      final requestedPath = rootfsPath?.trim() ?? '';
      final allowedLocalPath = requestedPath.startsWith('/storage/emulated/0/') ||
          requestedPath.startsWith('/data/data/com.zion.os/files/home/.zion/dists/');
      if (!allowedLocalPath ||
          requestedPath.contains('..') ||
          requestedPath.contains('|') ||
          requestedPath.contains('\u0000') ||
          !await File('$requestedPath/bin/bash').exists() ||
          !await File('$requestedPath/bin/sh').exists()) {
        return const TerminalResult(command: '', stdout: '',
          stderr: 'مسار rootfs المحلي غير صالح أو لا يحتوي bin/bash وbin/sh.',
          exitCode: 2, duration: Duration.zero, shell: 'rootfs-unavailable');
      }
      if (!isInteractiveRunning || _interactiveShell != 'zion-kali@$requestedPath') {
        await stopInteractive();
        if (!await startInteractive(kaliRootfsPath: requestedPath)) {
          return TerminalResult(command: value, stdout: '',
            stderr: 'تعذر تشغيل rootfs المحلي عبر Zion PRoot.',
            exitCode: 127, duration: Duration.zero, shell: 'rootfs-unavailable');
        }
      }
    } else if (runtime == 'kali') {
      final rootfsPath = await _resolveLocalKaliRootfs();
      if (rootfsPath == null) {
        return const TerminalResult(command: '', stdout: '',
          stderr: 'لم يُعثر على Kali rootfs محلي صالح. لم يتم تنزيل أي شيء.',
          exitCode: 127, duration: Duration.zero, shell: 'kali-unavailable');
      }
      if (!isInteractiveRunning || _interactiveShell != 'zion-kali@$rootfsPath') {
        await stopInteractive();
        if (!await startInteractive(kaliRootfsPath: rootfsPath)) {
          return TerminalResult(command: value, stdout: '',
            stderr: 'تعذر تشغيل Kali المحلي عبر Zion PRoot.',
            exitCode: 127, duration: Duration.zero, shell: 'kali-unavailable');
        }
      }
    } else if (runtime == 'zion' &&
        isInteractiveRunning &&
        (_interactiveShell?.startsWith('zion-kali@') ?? false)) {
      await stopInteractive();
      if (!await startInteractive()) {
        return TerminalResult(command: value, stdout: '',
          stderr: 'تعذر العودة إلى Zion Userland.',
          exitCode: 127, duration: Duration.zero, shell: 'zion-unavailable');
      }
    }
    _agentCommandRunning = true;
    final started = DateTime.now();
    final marker = '@@DART_MARKER@@';
    final output = StringBuffer();
    final completed = Completer<int>();
    StreamSubscription<String>? subscription;
    Timer? timer;
    Timer? interruptGraceTimer;
    try {
      if (!isInteractiveRunning && !await startInteractive()) {
        return TerminalResult(command: value, stdout: '',
          stderr: 'تعذر بدء جلسة Zion PTY.', exitCode: 127,
          duration: DateTime.now().difference(started), shell: 'unavailable');
      }
      subscription = _output.stream.listen((chunk) {
        if (completed.isCompleted) return;
        output.write(chunk);
        if (output.length > 100000) {
          final current = output.toString();
          output..clear()..write(current.substring(current.length - 100000));
        }
        final match = RegExp(
          '(?:^|\\r?\\n)' + RegExp.escape(marker) + r':(-?\d+)(?:\r?\n|$)',
        ).firstMatch(output.toString());
        if (match != null && !completed.isCompleted) {
          completed.complete(int.tryParse(match.group(1) ?? '') ?? 1);
        }
      });
      final wrapped = "$value; __zion_agent_status=\$?; printf '\\n$marker:%s\\n' \"\$__zion_agent_status\"";
      write('$wrapped\n');
      _remember(value);
      timer = Timer(timeout, () {
        if (completed.isCompleted) return;
        // Interrupt first. If the shell does not return to its prompt, recycle
        // the PTY so a timed-out process cannot poison the next agent command.
        write('\x03');
        interruptGraceTimer = Timer(const Duration(seconds: 2), () async {
          if (completed.isCompleted) return;
          _audit(
            command: value,
            outcome: 'timeout-pty-restart',
            exitCode: 124,
            shell: 'zion-native-pty',
            duration: DateTime.now().difference(started),
            interactive: true,
          );
          try {
            await stopInteractive();
            await startInteractive();
          } catch (restartError) {
            _audit(
              command: value,
              outcome: 'timeout-pty-restart-failed',
              exitCode: 124,
              shell: 'zion-native-pty',
              duration: DateTime.now().difference(started),
              interactive: true,
            );
            _emitOutput('[Super Agent] تعذر إعادة تشغيل PTY بعد انتهاء المهلة: $restartError\r\n');
          } finally {
            if (!completed.isCompleted) completed.complete(124);
          }
        });
      });
      final code = await completed.future;
      final raw = output.toString();
      final markerIndex = raw.lastIndexOf(marker);
      final captured = markerIndex >= 0 ? raw.substring(0, markerIndex) : raw;
      final clean = captured
          .replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '')
          .replaceAll('\r', '')
          .trim();
      final result = TerminalResult(
        command: value,
        stdout: clean.length > 24000 ? clean.substring(clean.length - 24000) : clean,
        stderr: code == 124 ? 'انتهت مهلة الأمر أو أُوقف بمقاطعة PTY.' : '',
        exitCode: code,
        duration: DateTime.now().difference(started),
        shell: 'zion-native-pty',
      );
      _audit(command: value,
        outcome: code == 0 ? 'success' : (code == 124 ? 'timeout-or-interrupt' : 'failed'),
        exitCode: code, shell: result.shell, duration: result.duration, interactive: true);
      return result;
    } catch (error) {
      final result = TerminalResult(command: value, stdout: '',
        stderr: 'فشل تنفيذ الأمر عبر PTY: $error', exitCode: 126,
        duration: DateTime.now().difference(started), shell: 'zion-native-pty');
      _audit(command: value, outcome: 'process-error', exitCode: result.exitCode,
        shell: result.shell, duration: result.duration, interactive: true);
      return result;
    } finally {
      timer?.cancel();
      interruptGraceTimer?.cancel();
      await subscription?.cancel();
      _agentCommandRunning = false;
    }
  }

  Future<void> interruptInteractive() async {
    if (isInteractiveRunning) await _pty.write('\x03');
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
    _interactiveShell = null;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    if (_agentLeases > 0) {
      _disposeRequested = true;
      return;
    }
    await _disposeNow();
  }

  Future<void> _disposeNow() async {
    if (_disposed) return;
    _disposed = true;
    _releaseAgentTarget();
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
