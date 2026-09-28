import 'package:flutter/material.dart';
import '../../core/services/terminal_service.dart';

class AdvancedTerminal extends StatefulWidget {
  const AdvancedTerminal({super.key});

  @override
  State<AdvancedTerminal> createState() => _AdvancedTerminalState();
}

class _AdvancedTerminalState extends State<AdvancedTerminal> {
  late TerminalService _terminalService;
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _outputLines = [];
  
  @override
  void initState() {
    super.initState();
    _terminalService = TerminalService();
    _terminalService.init();
    _terminalService.output.listen(_addOutput);
  }
  
  @override
  void dispose() {
    _terminalService.dispose();
    super.dispose();
  }
  
  void _addOutput(String data) {
    final lines = data.split('\n');
    setState(() {
      _outputLines.addAll(lines);
      if (_outputLines.length > 1000) {
        _outputLines.removeRange(0, _outputLines.length - 1000);
      }
    });
    _scrollToBottom();
  }
  
  void _executeCommand() {
    final command = _commandController.text.trim();
    if (command.isNotEmpty) {
      _terminalService.executeCommand(command);
      _commandController.clear();
    }
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _clearScreen() {
    setState(() {
      _outputLines.clear();
    });
  }
  
  void _showCommands() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Quick Commands', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildCommandTile('ls -la', 'List all files'),
                  _buildCommandTile('pwd', 'Show current directory'),
                  _buildCommandTile('cd /sdcard', 'Go to SD card'),
                  _buildCommandTile('mkdir folder', 'Create new folder'),
                  _buildCommandTile('rm -rf file', 'Delete file'),
                  _buildCommandTile('cat file.txt', 'View file content'),
                  _buildCommandTile('cp source dest', 'Copy file'),
                  _buildCommandTile('mv source dest', 'Move file'),
                  _buildCommandTile('ps aux', 'Show processes'),
                  _buildCommandTile('top', 'Show system stats'),
                  _buildCommandTile('df -h', 'Show disk usage'),
                  _buildCommandTile('free -m', 'Show memory usage'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommandTile(String command, String description) {
    return ListTile(
      leading: const Icon(Icons.terminal, color: Color(0xFF00BCD4)),
      title: Text(command, style: const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace')),
      subtitle: Text(description, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      onTap: () {
        _commandController.text = command;
        Navigator.pop(context);
        _executeCommand();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.terminal, color: Color(0xFF00BCD4)),
            const SizedBox(width: 8),
            Text('Terminal - ${_terminalService.currentDir.split('/').last}', style: const TextStyle(color: Color(0xFF00BCD4))),
          ],
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.code, color: Color(0xFF00BCD4)),
            onPressed: _showCommands,
            tooltip: 'Quick commands',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Color(0xFF00BCD4)),
            onPressed: _clearScreen,
            tooltip: 'Clear screen',
          ),
        ],
      ),
      body: Column(
        children: [
          // Terminal Output
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _outputLines.length,
                itemBuilder: (context, index) {
                  final line = _outputLines[index];
                  return SelectableText(
                    line,
                    style: _getLineStyle(line),
                  );
                },
              ),
            ),
          ),
          
          // Input Bar
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(
                  '\$',
                  style: TextStyle(
                    color: const Color(0xFF00BCD4),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
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
  
  TextStyle _getLineStyle(String line) {
    if (line.startsWith('\x1b[32m')) {
      return const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace', fontSize: 12);
    } else if (line.startsWith('\x1b[31m')) {
      return const TextStyle(color: Colors.red, fontFamily: 'monospace', fontSize: 12);
    } else if (line.startsWith('\x1b[33m')) {
      return const TextStyle(color: Colors.orange, fontFamily: 'monospace', fontSize: 12);
    }
    return const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12);
  }
}
