import 'dart:io';
import 'dart:async';

class TerminalService {
  static final TerminalService _instance = TerminalService._internal();
  factory TerminalService() => _instance;
  TerminalService._internal();
  
  Process? _process;
  StreamController<String> _outputController = StreamController<String>.broadcast();
  List<String> _commandHistory = [];
  int _historyIndex = -1;
  String _currentDir = '';
  
  Future<void> init() async {
    _currentDir = Directory.current.path;
    await _startShell();
  }
  
  Future<void> _startShell() async {
    try {
      _process = await Process.start('sh', [], runInShell: true);
      
      _process!.stdout.transform(SystemEncoding().decoder).listen((data) {
        _outputController.add(data);
      });
      
      _process!.stderr.transform(SystemEncoding().decoder).listen((data) {
        _outputController.add('\x1b[31m$data\x1b[0m');
      });
      
      _process!.exitCode.then((_) {
        _outputController.add('\n\x1b[33mProcess terminated. Restarting...\x1b[0m\n');
        _startShell();
      });
    } catch (e) {
      _outputController.add('\x1b[31mError: $e\x1b[0m\n');
    }
  }
  
  Future<void> executeCommand(String command) async {
    if (command.isEmpty) return;
    
    _commandHistory.add(command);
    _historyIndex = _commandHistory.length;
    
    _outputController.add('\x1b[32m\$ $command\x1b[0m\n');
    
    if (command == 'clear' || command == 'cls') {
      _outputController.add('\x1b[2J\x1b[H');
      return;
    }
    
    if (command == 'pwd') {
      _outputController.add('$_currentDir\n');
      return;
    }
    
    if (command.startsWith('cd ')) {
      final newDir = command.substring(3).trim();
      try {
        if (newDir.isEmpty) {
          _currentDir = '/sdcard';
        } else {
          final dir = Directory(newDir.startsWith('/') ? newDir : '$_currentDir/$newDir');
          if (await dir.exists()) {
            _currentDir = dir.path;
          } else {
            _outputController.add('\x1b[31mDirectory not found: $newDir\x1b[0m\n');
          }
        }
      } catch (_) {
        _outputController.add('\x1b[31mInvalid directory: $newDir\x1b[0m\n');
      }
      return;
    }
    
    try {
      final result = await Process.run('sh', ['-c', command], workingDirectory: _currentDir);
      if (result.stdout.toString().isNotEmpty) {
        _outputController.add(result.stdout.toString());
      }
      if (result.stderr.toString().isNotEmpty) {
        _outputController.add('\x1b[31m${result.stderr.toString()}\x1b[0m');
      }
    } catch (e) {
      _outputController.add('\x1b[31mError: $e\x1b[0m\n');
    }
  }
  
  String getPreviousCommand() {
    if (_commandHistory.isEmpty) return '';
    if (_historyIndex > 0) {
      _historyIndex--;
    }
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
  
  void dispose() {
    _process?.kill();
    _outputController.close();
  }
}
