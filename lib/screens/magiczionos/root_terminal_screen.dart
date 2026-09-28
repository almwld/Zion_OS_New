import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/magiczionos/magiczionos_provider.dart';

class MagiczionosRootTerminalScreen extends StatefulWidget {
  const MagiczionosRootTerminalScreen({super.key});
  @override State<MagiczionosRootTerminalScreen> createState() => _MagiczionosRootTerminalScreenState();
}
class _MagiczionosRootTerminalScreenState extends State<MagiczionosRootTerminalScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Process? _process;
  String _output = '';
  @override void dispose() { _input.dispose(); _scroll.dispose(); _process?.kill(); super.dispose(); }
  Future<void> _start(MagiczionosProvider provider) async {
    try {
      final process = await provider.core.startShell();
      _process = process;
      process.stdout.transform(utf8.decoder).listen((data) { if (mounted) setState(() => _output += data); });
      process.stderr.transform(utf8.decoder).listen((data) { if (mounted) setState(() => _output += data); });
      process.exitCode.then((code) { if (mounted) setState(() => _output += '\n[exit $code]\n'); });
      process.stdin.writeln('echo ZION_TEST_OK');
      if (mounted) setState(() => _output += '\n[interactive shell started]\n');
    } catch (e) { setState(() => _output += '\n[ERROR] $e\n'); }
  }
  void _send() { final p = _process; final command = _input.text; if (p == null || command.trim().isEmpty) return; p!.stdin.writeln(command); _input.clear(); }
  @override Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MagiczionosProvider()..initialize(),
      child: Consumer<MagiczionosProvider>(builder: (context, provider, _) => Scaffold(
        appBar: AppBar(title: Text('Root Terminal — ${provider.activeStrategy?.displayName ?? 'لا توجد استراتيجية'}'), actions: [IconButton(onPressed: () => _start(provider), icon: const Icon(Icons.play_arrow))]),
        body: Column(children: [
          Expanded(child: Container(color: Colors.black, width: double.infinity, padding: const EdgeInsets.all(12), child: SingleChildScrollView(controller: _scroll, child: SelectableText(_output, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')))),
          SafeArea(child: Row(children: [Expanded(child: TextField(controller: _input, decoration: const InputDecoration(hintText: 'أمر آمن...'), onSubmitted: (_) => _send())), IconButton(onPressed: _send, icon: const Icon(Icons.send))]))
        ]),
      )),
    );
  }
}