import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/xterm.dart';

import 'terminal_service.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final Terminal _terminal = Terminal(maxLines: 10000);
  final TerminalController _controller = TerminalController();
  StreamSubscription<String>? _outputSubscription;
  bool _interactive = false;
  bool _starting = false;
  double _fontSize = 13;

  TerminalService get _service => context.read<TerminalService>();

  @override
  void initState() {
    super.initState();
    _terminal.onOutput = (data) => _service.write(data);
    _terminal.onResize = (width, height, _, __) {
      unawaited(_service.resizeInteractive(rows: height, cols: width));
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final service = context.read<TerminalService>();
      unawaited(service.loadHistory());
      _outputSubscription = service.output.listen(_terminal.write);
      unawaited(_connect());
    });
  }

  Future<void> _connect() async {
    if (_starting || _service.isInteractiveRunning) return;
    setState(() => _starting = true);
    final started = await _service.startInteractive();
    if (!mounted) return;
    setState(() {
      _interactive = started;
      _starting = false;
    });
  }

  Future<void> _toggleInteractive() async {
    if (_service.isInteractiveRunning) {
      await _service.stopInteractive();
      if (mounted) setState(() => _interactive = false);
      return;
    }
    await _connect();
  }

  void _sendRaw(String value) {
    if (!_service.isInteractiveRunning) return;
    _service.write(value);
  }

  void _clear() {
    _terminal.eraseDisplay();
    _terminal.setCursor(0, 0);
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    unawaited(_service.stopInteractive());
    _controller.dispose();
    _terminal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B0A),
      appBar: AppBar(
        title: const Text('Zion OS Terminal'),
        actions: [
          IconButton(
            tooltip: _interactive ? 'إيقاف shell' : 'تشغيل shell',
            icon: Icon(_interactive ? Icons.stop_circle : Icons.play_arrow),
            onPressed: _starting ? null : _toggleInteractive,
          ),
          IconButton(
            tooltip: 'مسح الشاشة',
            icon: const Icon(Icons.clear_all),
            onPressed: _clear,
          ),
          PopupMenuButton<double>(
            tooltip: 'حجم الخط',
            icon: const Icon(Icons.text_fields),
            onSelected: (value) => setState(() => _fontSize = value),
            itemBuilder: (context) => [
              for (final size in [10.0, 12.0, 13.0, 15.0, 17.0, 20.0])
                PopupMenuItem(value: size, child: Text('${size.toInt()} px')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF111511),
            child: Row(
              children: [
                Icon(
                  _interactive ? Icons.circle : Icons.circle_outlined,
                  size: 9,
                  color: _interactive ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 7),
                Text(
                  _starting
                      ? 'Connecting to native PTY…'
                      : _interactive
                          ? 'Android PTY • /system/bin/sh • 10,000 scrollback lines'
                          : 'PTY unavailable / stopped',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: TerminalView(
              _terminal,
              controller: _controller,
              autofocus: true,
              backgroundOpacity: 1,
              cursorType: TerminalCursorType.block,
              textStyle: TerminalStyle(
                fontSize: _fontSize,
                fontFamily: 'monospace',
              ),
              simulateScroll: true,
            ),
          ),
          _ExtraKeys(onSend: _sendRaw),
        ],
      ),
    );
  }
}

class _ExtraKeys extends StatelessWidget {
  const _ExtraKeys({required this.onSend});

  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    const keys = <MapEntry<String, String>>[
      MapEntry('ESC', '\x1b'),
      MapEntry('TAB', '\t'),
      MapEntry('CTRL-C', '\x03'),
      MapEntry('ALT', '\x1b'),
      MapEntry('←', '\x1b[D'),
      MapEntry('↑', '\x1b[A'),
      MapEntry('↓', '\x1b[B'),
      MapEntry('→', '\x1b[C'),
      MapEntry('HOME', '\x1b[H'),
      MapEntry('END', '\x1b[F'),
    ];

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          itemCount: keys.length,
          separatorBuilder: (_, __) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final item = keys[index];
            return Material(
              color: const Color(0xFF171B18),
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () => onSend(item.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    child: Text(
                      item.key,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFFB7C7BA),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
