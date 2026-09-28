import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/wm/window_manager.dart';
import 'core/services/kali_loader_service.dart';

class DesktopIconWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String kaliCommand;

  const DesktopIconWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.kaliCommand,
  });

  void _executeCommand(BuildContext context) async {
    final wm = context.read<WindowManager>();
    final terminalId = wm.open(
      label,
      KaliTerminalWindow(initialCommand: kaliCommand),
      width: 600,
      height: 400,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _executeCommand(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00FF41), size: 36),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF00FF41), fontSize: 11, fontFamily: 'monospace'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class KaliTerminalWindow extends StatefulWidget {
  final String initialCommand;

  const KaliTerminalWindow({super.key, this.initialCommand = ''});

  @override
  State<KaliTerminalWindow> createState() => _KaliTerminalWindowState();
}

class _KaliTerminalWindowState extends State<KaliTerminalWindow> {
  final TextEditingController _cmdCtrl = TextEditingController();
  final List<String> _output = [];
  final ScrollController _scrollCtrl = ScrollController();
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _output.add('Zion Terminal - Kali Linux');
    _output.add('اكتب "help" للمساعدة.');
    if (widget.initialCommand.isNotEmpty) {
      _execute(widget.initialCommand);
    }
  }

  Future<void> _execute(String cmd) async {
    setState(() {
      _output.add('> $cmd');
      _isExecuting = true;
    });

    try {
      final result = await KaliLoaderService.execute(cmd);
      setState(() {
        if (result['success'] == true) {
          final stdout = result['stdout']?.toString().trim();
          if (stdout != null && stdout.isNotEmpty) {
            _output.addAll(stdout.split('\n'));
          } else {
            _output.add('(تم التنفيذ بنجاح)');
          }
        } else {
          _output.add('خطأ: ${result['stderr'] ?? result['error'] ?? "غير معروف"}');
        }
        _isExecuting = false;
      });
    } catch (e) {
      setState(() {
        _output.add('خطأ في الاتصال: $e');
        _isExecuting = false;
      });
    }

    _cmdCtrl.clear();
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(8),
            itemCount: _output.length,
            itemBuilder: (context, i) => Text(
              _output[i],
              style: TextStyle(
                color: _output[i].startsWith('>')
                    ? const Color(0xFF00FF41)
                    : (_output[i].startsWith('خطأ') ? Colors.red : Colors.white70),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (_isExecuting)
          const LinearProgressIndicator(color: Color(0xFF00FF41)),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0E0A),
            border: Border(top: BorderSide(color: Color(0xFF1A3A1A))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              const Text(
                'zion:~# ',
                style: TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace', fontSize: 12),
              ),
              Expanded(
                child: TextField(
                  controller: _cmdCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  cursorColor: const Color(0xFF00FF41),
                  onSubmitted: _execute,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
