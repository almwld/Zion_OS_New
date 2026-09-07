import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'terminal_service.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});
  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _commandController = TextEditingController();
  final _scrollController = ScrollController();
  final List<String> _lines = <String>[];
  StreamSubscription<String>? _outputSubscription;
  int _historyIndex = -1;
  bool _interactive = false;
  bool _busy = false;

  TerminalService get _service => context.read<TerminalService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final service = context.read<TerminalService>();
      unawaited(service.loadHistory());
      _outputSubscription = service.output.listen((text) {
        if (!mounted) return;
        setState(() => _lines.add(text));
        _scrollToBottom();
      });
      setState(() {
        _lines.addAll(const <String>[
          'ZION OS TERMINAL',
          'Real POSIX shell interface — output is from the device runtime.',
          'Type "help" for Zion commands or execute normal shell commands.',
          '',
        ]);
      });
    });
  }

  Future<void> _run() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;
    _commandController.clear();
    if (_interactive) {
      _service.write('$command\n');
      return;
    }
    setState(() {
      _lines.add('zion$ $command');
      _busy = true;
      _historyIndex = -1;
    });
    _scrollToBottom();
    final result = await _service.execute(command);
    if (!mounted) return;
    setState(() {
      if (result.formatted.isNotEmpty) _lines.add(result.formatted);
      _lines.add('[exit ${result.exitCode} | ${result.duration.inMilliseconds} ms]');
      _busy = false;
    });
    _scrollToBottom();
  }

  Future<void> _toggleInteractive() async {
    if (_interactive) {
      await _service.stopInteractive();
      if (mounted) setState(() => _interactive = false);
      return;
    }
    await _service.startInteractive();
    if (mounted) setState(() => _interactive = _service.isInteractiveRunning);
  }

  void _historyUp() {
    final history = _service.history;
    if (history.isEmpty) return;
    setState(() {
      _historyIndex = (_historyIndex + 1).clamp(0, history.length - 1);
      _commandController.text = history[_historyIndex];
      _commandController.selection = TextSelection.collapsed(offset: _commandController.text.length);
    });
  }

  void _historyDown() {
    final history = _service.history;
    if (_historyIndex <= 0) {
      setState(() {
        _historyIndex = -1;
        _commandController.clear();
      });
      return;
    }
    setState(() {
      _historyIndex--;
      _commandController.text = history[_historyIndex];
      _commandController.selection = TextSelection.collapsed(offset: _commandController.text.length);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TerminalService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zion OS Terminal'),
        actions: <Widget>[
          IconButton(tooltip: _interactive ? 'إيقاف shell' : 'تشغيل shell تفاعلي', icon: Icon(_interactive ? Icons.stop_circle : Icons.terminal), onPressed: _toggleInteractive),
          IconButton(tooltip: 'مسح الشاشة', icon: const Icon(Icons.clear_all), onPressed: () => setState(_lines.clear)),
          IconButton(tooltip: 'مسح السجل المحفوظ', icon: const Icon(Icons.history_toggle_off), onPressed: () async { await service.clearHistory(); if (mounted) setState(() => _historyIndex = -1); }),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [Icon(_interactive ? Icons.circle : Icons.circle_outlined, size: 10), const SizedBox(width: 8), Text(_interactive ? 'Interactive shell: CONNECTED' : 'Command mode: READY')])),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF090B0A),
              child: SelectionArea(child: ListView.builder(controller: _scrollController, itemCount: _lines.length, itemBuilder: (context, index) => SelectableText(_lines[index], style: TextStyle(color: _lines[index].startsWith('zion$') ? const Color(0xFF00FF41) : const Color(0xFFD0D7D2), fontFamily: 'monospace', fontSize: 13, height: 1.35))),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              color: const Color(0xFF111511),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.keyboard_arrow_up), onPressed: _historyUp),
                IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: _historyDown),
                const Text('zion$ ', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41))),
                Expanded(child: TextField(controller: _commandController, enabled: !_busy, autofocus: true, style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace'), decoration: const InputDecoration(border: InputBorder.none, hintText: 'أدخل الأمر...'), onSubmitted: (_) => _run())),
                IconButton(tooltip: 'تنفيذ', icon: Icon(_busy ? Icons.hourglass_top : Icons.send), onPressed: _busy ? null : _run),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
