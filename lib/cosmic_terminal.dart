import 'package:flutter/material.dart';
import 'core/services/kali_loader_service.dart';

class CosmicTerminal extends StatefulWidget {
  const CosmicTerminal({super.key});

  @override
  State<CosmicTerminal> createState() => _CosmicTerminalState();
}

class _CosmicTerminalState extends State<CosmicTerminal> {
  final TextEditingController _cmdCtrl = TextEditingController();
  final List<String> _output = ['Zion Terminal v5.0 - Kali 600+ Tools', 'اكتب "help" للمساعدة.'];
  final ScrollController _scrollCtrl = ScrollController();
  bool _kaliAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkKali();
  }

  Future<void> _checkKali() async {
    final available = await KaliLoaderService.getStatus();
    setState(() {
      _kaliAvailable = available;
      _output.add(available ? '✅ Kali Linux متصل (600+ أداة).' : '⚠️ Kali غير متصل. نفذ "kali_install".');
    });
  }

  Future<void> _execute(String cmd) async {
    setState(() => _output.add('> $cmd'));

    if (_kaliAvailable) {
      final result = await KaliLoaderService.execute(cmd);
      setState(() {
        if (result['success'] == true) {
          _output.add(result['stdout']?.isNotEmpty == true ? result['stdout']! : '(تم التنفيذ)');
        } else {
          _output.add('Error: ${result['stderr'] ?? result['error'] ?? "Unknown"}');
        }
      });
    } else {
      _executeLocal(cmd);
    }

    _cmdCtrl.clear();
    _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _executeLocal(String cmd) {
    switch (cmd.trim().toLowerCase()) {
      case 'help': _output.add('kali_install, kali_status, nmap, msfconsole, sqlmap, hydra, aircrack-ng, john, nikto, dirb, wpscan, clear, exit'); break;
      case 'clear': _output.clear(); break;
      case 'kali_install': _output.add('Use the Dashboard button to install Kali.'); break;
      case 'kali_status': _output.add('Kali Available: $_kaliAvailable'); break;
      default: _output.add('Command not found or Kali not available: $cmd');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(children: [
          const Text('الطرفية الكونية', style: TextStyle(color: Color(0xFF00FF41), fontFamily: 'Cairo')),
          const SizedBox(width: 8),
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _kaliAvailable ? Colors.green : Colors.red)),
        ]),
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.close, color: Color(0xFF00FF41)), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(16), itemCount: _output.length, itemBuilder: (context, i) => Text(_output[i], style: TextStyle(color: _output[i].startsWith('>') ? const Color(0xFF00FF41) : (_output[i].startsWith('Error') ? Colors.red : Colors.white70), fontFamily: 'monospace', fontSize: 14)))),
        Container(decoration: const BoxDecoration(color: Color(0xFF0A0E0A), border: Border(top: BorderSide(color: Color(0xFF1A3A1A)))), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [const Text('zion:~# ', style: TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace')), Expanded(child: TextField(controller: _cmdCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'monospace'), decoration: const InputDecoration(border: InputBorder.none, isDense: true), cursorColor: const Color(0xFF00FF41), onSubmitted: _execute))])),
      ]),
    );
  }
}
