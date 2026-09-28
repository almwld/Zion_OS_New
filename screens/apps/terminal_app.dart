import 'terminal_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class TerminalApp extends StatefulWidget {
  const TerminalApp({super.key});

  @override
  State<TerminalApp> createState() => _TerminalAppState();
}

class _TerminalAppState extends State<TerminalApp> {
  final TextEditingController _commandController = TextEditingController();
  final List<String> _output = [];
  final ScrollController _scrollController = ScrollController();
  String _currentDir = '/data/data/com.termux/files/home';
  String _userName = 'zion';
  String _hostName = 'zion-os';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _updatePath();
    _updateUserHost();
    _addWelcomeMessage();
  }

  void _updatePath() {
    try {
      final result = Process.runSync('pwd', [], runInShell: true);
      if (result.exitCode == 0) {
        _currentDir = result.stdout.toString().trim();
      }
    } catch (_) {}
  }

  void _updateUserHost() {
    try {
      final userResult = Process.runSync('whoami', [], runInShell: true);
      if (userResult.exitCode == 0) {
        _userName = userResult.stdout.toString().trim();
      }
      final hostResult = Process.runSync('hostname', [], runInShell: true);
      if (hostResult.exitCode == 0) {
        _hostName = hostResult.stdout.toString().trim();
      }
    } catch (_) {}
  }

  void _addWelcomeMessage() {
    _addOutput('╔══════════════════════════════════════════════════════════════════╗');
    _addOutput('║                    ZION OS TERMINAL v4.0                          ║');
    _addOutput('╚══════════════════════════════════════════════════════════════════╝');
    _addOutput('');
    _addOutput('Type "help" for available commands');
  }

  void _addOutput(String text) {
    setState(() {
      _output.add(text);
    });
    _scrollToBottom();
  }

  void _executeCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    // استخدام سلسلة ثابتة بدون استخدام $ داخلها
    _addOutput('[' + _userName + '@' + _hostName + ' ' + _currentDir + '] > ' + command);
    _commandController.clear();
    setState(() => _isProcessing = true);

    if (command == 'clear' || command == 'cls') {
      setState(() {
        _output.clear();
        _isProcessing = false;
      });
      _addWelcomeMessage();
      return;
    }

    if (command == 'help') {
      _showHelp();
      setState(() => _isProcessing = false);
      return;
    }

    if (command == 'pwd') {
      _addOutput(_currentDir);
      setState(() => _isProcessing = false);
      return;
    }

    if (command == 'whoami') {
      _addOutput(_userName);
      setState(() => _isProcessing = false);
      return;
    }

    if (command == 'hostname') {
      _addOutput(_hostName);
      setState(() => _isProcessing = false);
      return;
    }

    if (command.startsWith('cd ')) {
      await _changeDirectory(command.substring(3).trim());
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final result = await Process.run('sh', ['-c', command], workingDirectory: _currentDir, runInShell: true);
      if (result.stdout.toString().isNotEmpty) {
        _addOutput(result.stdout.toString().trim());
      }
      if (result.stderr.toString().isNotEmpty) {
        _addOutput('[ERROR] ' + result.stderr.toString().trim());
      }
    } catch (e) {
      _addOutput('[ERROR] Command not found: ' + command);
    }

    setState(() => _isProcessing = false);
    _updatePath();
  }

  Future<void> _changeDirectory(String path) async {
    final newDir = path.startsWith('/') ? path : '$_currentDir/$path';
    try {
      final dir = Directory(newDir);
      if (await dir.exists()) {
        _currentDir = dir.path;
        _addOutput('Changed to: ' + _currentDir);
      } else {
        _addOutput('Directory not found: ' + path);
      }
    } catch (_) {
      _addOutput('Invalid directory: ' + path);
    }
  }

  void _showHelp() {
    _addOutput('═══════════════════════════════════════════════════════════════');
    _addOutput('ZION OS TERMINAL HELP');
    _addOutput('═══════════════════════════════════════════════════════════════');
    _addOutput('  help      - Show this help');
    _addOutput('  clear     - Clear screen');
    _addOutput('  pwd       - Show current directory');
    _addOutput('  whoami    - Show current user');
    _addOutput('  hostname  - Show hostname');
    _addOutput('  cd [dir]  - Change directory');
    _addOutput('═══════════════════════════════════════════════════════════════');
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Terminal', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // شريط الحالة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.black.withOpacity(0.8),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Color(0xFF00BCD4), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentDir,
                    style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 11, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _userName + '@' + _hostName,
                  style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          // مخرجات الطرفية
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _output.length,
                itemBuilder: (context, index) {
                  final line = _output[index];
                  final isError = line.startsWith('[ERROR]');
                  final isWelcome = line.startsWith('╔') || line.startsWith('║') || line.startsWith('╚');
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      line,
                      style: TextStyle(
                        color: isError ? Colors.red : (isWelcome ? const Color(0xFF00BCD4) : Colors.white70),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // شريط الإدخال
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(
                  '>',
                  style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16, fontFamily: 'monospace'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _executeCommand(),
                  ),
                ),
                if (_isProcessing)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00BCD4))),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00BCD4), size: 20),
                  onPressed: _executeCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

  bool _showShortcuts = false;

  void _toggleShortcuts() {
    // setState removed
  }
