import 'package:flutter/material.dart';

class ZionAdvancedTerminal extends StatefulWidget {
  const ZionAdvancedTerminal({super.key});

  @override
  State<ZionAdvancedTerminal> createState() => _ZionAdvancedTerminalState();
}

class _ZionAdvancedTerminalState extends State<ZionAdvancedTerminal> {
  final TextEditingController _cmdCtrl = TextEditingController();
  final List<Map<String, dynamic>> _output = [];
  final ScrollController _scrollCtrl = ScrollController();
  final List<String> _commandHistory = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _output.add({'type': 'system', 'text': 'Zion Advanced Terminal v6.0'});
    _output.add({'type': 'system', 'text': 'اكتب "help" للمساعدة.'});
  }

  void _execute(String cmd) {
    if (cmd.trim().isEmpty) return;
    _commandHistory.add(cmd.trim());
    _historyIndex = -1;

    setState(() {
      _output.add({'type': 'command', 'text': '> $cmd'});
    });

    final parts = cmd.trim().split(' ');
    final command = parts[0].toLowerCase();

    switch (command) {
      case 'help':
        _addOutput('system', 'الأوامر المتاحة:');
        _addOutput('system', '  help, clear, echo, date, whoami, ls, pwd, cd, cat, history, sysinfo, netstat, ps, kill, scan, crack, encrypt, decrypt');
        _addOutput('system', '  kali <command> - تنفيذ أمر في Kali Linux');
        _addOutput('system', '  script <name> - تشغيل سكريبت');
        _addOutput('system', '  plugin <name> - تشغيل إضافة');
        break;
      case 'clear':
        _output.clear();
        break;
      case 'echo':
        _addOutput('output', parts.sublist(1).join(' '));
        break;
      case 'date':
        _addOutput('output', DateTime.now().toString());
        break;
      case 'whoami':
        _addOutput('output', 'root@zion');
        break;
      case 'ls':
        _addOutput('output', 'bin  boot  dev  etc  home  lib  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var');
        break;
      case 'pwd':
        _addOutput('output', '/root');
        break;
      case 'history':
        for (int i = 0; i < _commandHistory.length; i++) {
          _addOutput('output', '  ${i + 1}  ${_commandHistory[i]}');
        }
        break;
      case 'sysinfo':
        _addOutput('output', 'OS: Zion Linux 1.5.0');
        _addOutput('output', 'Kernel: ZionKernel 5.15.0');
        _addOutput('output', 'Kali Tools: 600+');
        _addOutput('output', 'CPU: 8 cores @ 2.8GHz');
        _addOutput('output', 'RAM: 8GB / 12GB');
        break;
      case 'netstat':
        _addOutput('output', 'tcp  0  0  192.168.1.100:4444  0.0.0.0:*  LISTEN');
        _addOutput('output', 'tcp  0  0  127.0.0.1:9050      0.0.0.0:*  LISTEN');
        _addOutput('output', 'udp  0  0  0.0.0.0:5353        0.0.0.0:*');
        break;
      case 'ps':
        _addOutput('output', 'PID   USER     COMMAND');
        _addOutput('output', '1     root     /sbin/init');
        _addOutput('output', '147   root     /usr/sbin/sshd');
        _addOutput('output', '289   root     zion_terminal');
        break;
      default:
        if (command == 'kali' && parts.length > 1) {
          _addOutput('output', '[Kali] جاري تنفيذ: ${parts.sublist(1).join(' ')}');
          _addOutput('output', '[Kali] تم التنفيذ بنجاح.');
        } else if (command == 'script' && parts.length > 1) {
          _addOutput('output', '[Script] جاري تشغيل السكريبت: ${parts[1]}');
        } else if (command == 'plugin' && parts.length > 1) {
          _addOutput('output', '[Plugin] جاري تشغيل الإضافة: ${parts[1]}');
        } else {
          _addOutput('error', 'command not found: $command');
        }
    }

    _cmdCtrl.clear();
    _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _addOutput(String type, String text) {
    setState(() {
      _output.add({'type': type, 'text': text});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(8),
              itemCount: _output.length,
              itemBuilder: (context, i) {
                final entry = _output[i];
                Color color;
                switch (entry['type']) {
                  case 'command': color = const Color(0xFF00FF41); break;
                  case 'error': color = Colors.red; break;
                  case 'system': color = Colors.yellow; break;
                  default: color = Colors.white70;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(entry['text'], style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12)),
                );
              },
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(color: Color(0xFF0A0E0A), border: Border(top: BorderSide(color: Color(0xFF1A3A1A)))),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            const Text('root@zion:~# ', style: TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace', fontSize: 12)),
            Expanded(child: TextField(
              controller: _cmdCtrl,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              cursorColor: const Color(0xFF00FF41),
              onSubmitted: _execute,
            )),
          ]),
        ),
      ],
    );
  }
}
