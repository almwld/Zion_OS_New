import 'package:flutter/material.dart';

class CosmicTerminal extends StatefulWidget {
  const CosmicTerminal({super.key});

  @override
  State<CosmicTerminal> createState() => _CosmicTerminalState();
}

class _CosmicTerminalState extends State<CosmicTerminal> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _lines = [];
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _addLine('═══════════════════════════════════════════════════════════════', false, false);
    _addLine('🔥 ZION OS v3.1 - COSMIC TERMINAL', false, false);
    _addLine('═══════════════════════════════════════════════════════════════', false, false);
    _addLine('', false, false);
    _addLine('📌 Available Commands:', false, false);
    _addLine('   help     - Show all commands', false, false);
    _addLine('   clear    - Clear terminal screen', false, false);
    _addLine('   exit     - Close terminal', false, false);
    _addLine('   scan     - Scan local network', false, false);
    _addLine('   attack   - Execute attack on target', false, false);
    _addLine('   status   - Show system status', false, false);
    _addLine('   wifi     - Scan WiFi networks', false, false);
    _addLine('   tools    - List available tools', false, false);
    _addLine('', false, false);
    _addLine('═══════════════════════════════════════════════════════════════', false, false);
    _addLine('✅ Terminal ready. Type "help" to begin.', false, false);
    _addLine('', false, false);
  }

  void _addLine(String text, bool isCommand, bool isError) {
    setState(() {
      _lines.add({
        'text': text,
        'isCommand': isCommand,
        'isError': isError,
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _executeCommand(String command) async {
    if (command.trim().isEmpty) return;
    
    // استخدام escape لعلامة $
    final prompt = 'zion@os:~' + '\$ ';
    _addLine('$prompt${command.trim()}', true, false);
    _inputController.clear();
    setState(() => _isExecuting = true);

    final cmd = command.trim().toLowerCase();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (cmd == 'help' || cmd == '?') {
      _addLine('', false, false);
      _addLine('╔═══════════════════════════════════════════════════════════════╗', false, false);
      _addLine('║                    COMMAND REFERENCE                          ║', false, false);
      _addLine('╠═══════════════════════════════════════════════════════════════╣', false, false);
      _addLine('║  help     - Show this help message                           ║', false, false);
      _addLine('║  clear    - Clear terminal screen                           ║', false, false);
      _addLine('║  exit     - Close terminal window                           ║', false, false);
      _addLine('║  scan     - Scan network for devices                        ║', false, false);
      _addLine('║  attack   - Execute attack on target                        ║', false, false);
      _addLine('║  status   - Display system status                           ║', false, false);
      _addLine('║  wifi     - Scan for WiFi networks                          ║', false, false);
      _addLine('║  tools    - List all available tools                        ║', false, false);
      _addLine('╚═══════════════════════════════════════════════════════════════╝', false, false);
      _addLine('', false, false);
    } 
    else if (cmd == 'clear') {
      setState(() => _lines.clear());
      _addLine('Screen cleared.', false, false);
    } 
    else if (cmd == 'exit') {
      Navigator.pop(context);
    } 
    else if (cmd == 'scan') {
      _addLine('🔍 Scanning network...', false, false);
      await Future.delayed(const Duration(seconds: 1));
      _addLine('✅ Scan completed.', false, false);
      _addLine('   📍 Found devices:', false, false);
      _addLine('      • 192.168.1.1 (Gateway)', false, false);
      _addLine('      • 192.168.1.100 (Device 1)', false, false);
      _addLine('      • 192.168.1.101 (Device 2)', false, false);
      _addLine('', false, false);
    } 
    else if (cmd.startsWith('attack')) {
      final parts = cmd.split(' ');
      final target = parts.length > 1 ? parts[1] : '192.168.1.1';
      _addLine('⚔️ Executing attack on $target...', false, false);
      await Future.delayed(const Duration(seconds: 2));
      _addLine('✅ Attack completed!', false, false);
      _addLine('   🔓 Vulnerabilities found: 3', false, false);
      _addLine('   🔑 Credentials obtained: admin:password', false, false);
      _addLine('', false, false);
    } 
    else if (cmd == 'status') {
      _addLine('', false, false);
      _addLine('╔═══════════════════════════════════════════════════════════════╗', false, false);
      _addLine('║                      SYSTEM STATUS                            ║', false, false);
      _addLine('╠═══════════════════════════════════════════════════════════════╣', false, false);
      _addLine('║  Version:     Zion OS v3.1                                   ║', false, false);
      _addLine('║  Build:       Final Release                                  ║', false, false);
      _addLine('║  Tools:       1000+ Security Tools                           ║', false, false);
      _addLine('║  SI Agent:    Active & Learning                              ║', false, false);
      _addLine('║  Neural Net:  5 Layers, 64 Neurons                           ║', false, false);
      _addLine('║  Status:      Ready                                          ║', false, false);
      _addLine('╚═══════════════════════════════════════════════════════════════╝', false, false);
      _addLine('', false, false);
    } 
    else if (cmd == 'wifi') {
      _addLine('📡 Scanning WiFi networks...', false, false);
      await Future.delayed(const Duration(seconds: 1));
      _addLine('✅ Found 3 networks:', false, false);
      _addLine('   • Home WiFi (2.4GHz) - Signal: 85%', false, false);
      _addLine('   • Guest Network (5GHz) - Signal: 65%', false, false);
      _addLine('   • Neighbor AP (2.4GHz) - Signal: 45%', false, false);
      _addLine('', false, false);
    } 
    else if (cmd == 'tools') {
      _addLine('', false, false);
      _addLine('╔═══════════════════════════════════════════════════════════════╗', false, false);
      _addLine('║                    AVAILABLE TOOLS                            ║', false, false);
      _addLine('╠═══════════════════════════════════════════════════════════════╣', false, false);
      _addLine('║  📡 Network:  ZionNet (100 tools)                            ║', false, false);
      _addLine('║  🔐 Cracking: ZionCrack (100 tools)                          ║', false, false);
      _addLine('║  💀 Exploits: ZionExploit (100 tools)                        ║', false, false);
      _addLine('║  🌐 Web:      ZionWeb (100 tools)                            ║', false, false);
      _addLine('║  📶 Wireless: ZionWireless (100 tools)                       ║', false, false);
      _addLine('║  🕸️ MITM:     ZionMITM (100 tools)                           ║', false, false);
      _addLine('║  🔍 Forensics:ZionForensics (100 tools)                      ║', false, false);
      _addLine('║  🎯 Post:     ZionPostExploit (100 tools)                    ║', false, false);
      _addLine('║  👻 Evasion:  ZionEvasion (100 tools)                        ║', false, false);
      _addLine('║  🚀 Advanced: ZionAdvanced (100 tools)                       ║', false, false);
      _addLine('╚═══════════════════════════════════════════════════════════════╝', false, false);
      _addLine('', false, false);
    } 
    else if (cmd.isNotEmpty) {
      _addLine('❌ Command not found: "$cmd". Type "help" for available commands.', false, true);
    }
    
    setState(() => _isExecuting = false);
    _addLine('', false, false);
  }

  @override
  Widget build(BuildContext context) {
    // استخدام escape لعلامة $
    final promptText = 'zion@os:~' + '\$ ';
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00FF41), Colors.black]),
              border: const Border(bottom: BorderSide(color: Color(0xFF00FF41))),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Color(0xFF00FF41), size: 28),
                const SizedBox(width: 12),
                const Text('COSMIC TERMINAL', style: TextStyle(color: Color(0xFF00FF41), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const Spacer(),
                if (_isExecuting) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF41))),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                final line = _lines[index];
                Color textColor = Colors.white;
                if (line['isCommand'] == true) textColor = const Color(0xFF00FF41);
                if (line['isError'] == true) textColor = Colors.red;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(
                    line['text'],
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: line['isCommand'] == true ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: const Border(top: BorderSide(color: Color(0xFF00FF41))),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(promptText, style: const TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: _executeCommand,
                    enabled: !_isExecuting,
                    autofocus: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
