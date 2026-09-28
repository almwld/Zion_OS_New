import 'dart:async';
import 'dart:io';
import '../../features/terminal/native_pty_adapter.dart';
import '../../security/runtime/security_resource_guard.dart';

class TerminalService {
  static final TerminalService _instance = TerminalService._internal();
  factory TerminalService() => _instance;
  TerminalService._internal();

  final NativePtyAdapter _pty = NativePtyAdapter();
  final SecurityResourceGuard _security = SecurityResourceGuard();
  Process? _process;
  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final List<String> _commandHistory = <String>[];
  int _historyIndex = -1;
  String _currentDir = '';
  StreamSubscription<String>? _ptySubscription;
  bool _usingNativePty = false;

  Future<void> init() async {
    _currentDir = Directory.current.path;
    if (!_security.security.canExecute(
      scope: SecurityResourceGuard.terminalScope(),
      action: 'terminal.execute',
      requiresSimulation: false,
    )) {
      _outputController.add('[ZION][SECURITY] Terminal execution denied.\\n');
      return;
    }
    try {
      _usingNativePty = await _pty.start(
        rows: 32,
        cols: 120,
        shell: '/system/bin/sh',
      );
      if (_usingNativePty) {
        _ptySubscription = _pty.output.listen(_outputController.add);
        return;
      }
    } catch (_) {
      _usingNativePty = false;
    }
    await _startFallbackShell();
  }

  Future<void> _startFallbackShell() async {
    try {
      _process = await Process.start('sh', [], runInShell: true);
      _process!.stdout.transform(SystemEncoding().decoder).listen(_outputController.add);
      _process!.stderr
          .transform(SystemEncoding().decoder)
          .listen((data) => _outputController.add('\x1b[31m$data\x1b[0m'));
      _process!.exitCode.then((_) {
        if (!_outputController.isClosed) {
          _outputController.add('\n\x1b[33mProcess terminated.\x1b[0m\n');
        }
      });
    } catch (e) {
      _outputController.add('\x1b[31mError: $e\x1b[0m\n');
    }
  }

  Future<void> executeCommand(String command) async {
    if (command.trim().isEmpty) return;
    _commandHistory.add(command);
    _historyIndex = _commandHistory.length;

    if (_usingNativePty) {
      await _pty.write('$command\n');
      return;
    }

    _outputController.add('\x1b[32m\\$ $command\x1b[0m\n');
    if (command == 'clear' || command == 'cls') {
      _outputController.add('\x1b[2J\x1b[H');
      return;
    }
    if (command == 'pwd') {
      _outputController.add('$_currentDir\n');
      return;
    }
    if (command == 'cd' || command.startsWith('cd ')) {
      final newDir = command.length <= 2 ? '/sdcard' : command.substring(3).trim();
      try {
        final dir = Directory(
          newDir.startsWith('/') ? newDir : '$_currentDir/$newDir',
        );
        if (await dir.exists()) {
          _currentDir = dir.resolveSymbolicLinksSync();
          _outputController.add('$_currentDir\n');
        } else {
          _outputController.add('\x1b[31mDirectory not found: $newDir\x1b[0m\n');
        }
      } catch (_) {
        _outputController.add('\x1b[31mInvalid directory: $newDir\x1b[0m\n');
      }
      return;
    }
    try {
      final result =
          await Process.run('sh', <String>['-c', command], workingDirectory: _currentDir);
      if (result.stdout.toString().isNotEmpty) {
        _outputController.add(result.stdout.toString());
      }
      if (result.stderr.toString().isNotEmpty) {
        _outputController.add('\x1b[31m${result.stderr}\x1b[0m');
      }
    } catch (e) {
      _outputController.add('\x1b[31mError: $e\x1b[0m\n');
    }
  }

  String getPreviousCommand() {
    if (_commandHistory.isEmpty) return '';
    if (_historyIndex > 0) _historyIndex--;
    return _commandHistory[_historyIndex];
  }

  String getNextCommand() {
    if (_commandHistory.isEmpty) return '';
    if (_historyIndex < _commandHistory.length - 1) {
      _historyIndex++;
      return _commandHistory[_historyIndex];
    }
    _historyIndex = _commandHistory.length;
    return '';
  }

  Stream<String> get output => _outputController.stream;
  String get currentDir => _currentDir;
  bool get nativePtyActive => _usingNativePty;

  Future<void> dispose() async {
    await _ptySubscription?.cancel();
    _ptySubscription = null;
    await _pty.dispose();
    _process?.kill();
    _process = null;
    await _outputController.close();
  }
}
