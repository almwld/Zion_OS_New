import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'terminal_logs.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final List<String> _logs = ZionTerminalLogs.entries.toList();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ZionTerminalLogs.stream.listen((line) {
      if (!mounted) return;
      setState(() => _logs.add(line));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _copyLogs() async {
    await Clipboard.setData(ClipboardData(text: _logs.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ السجلات')),
    );
  }

  void _clearLogs() {
    ZionTerminalLogs.clear();
    setState(_logs.clear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111B),
      appBar: AppBar(
        title: const Text('Zion Logs'),
        backgroundColor: const Color(0xFF101D2A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'نسخ السجلات',
            onPressed: _copyLogs,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: 'مسح السجلات',
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(
              child: Text(
                'لا توجد سجلات تشخيصية بعد',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: _logs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: SelectableText(
                  _logs[index],
                  style: const TextStyle(
                    color: Color(0xFF9EDCFB),
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ),
    );
  }
}
