import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'terminal_logs.dart';

const EventChannel _nativeTerminalLogs = EventChannel('zion.os/terminal/logs');

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final List<String> _logs = ZionTerminalLogs.entries.toList();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _subscription;
  StreamSubscription<dynamic>? _nativeSubscription;

  @override
  void initState() {
    super.initState();
    _nativeSubscription = _nativeTerminalLogs.receiveBroadcastStream().listen(
      (event) => ZionTerminalLogs.add('Android: ${event.toString()}'),
      onError: (Object error) => ZionTerminalLogs.add('Android log stream error: $error'),
    );
    _subscription = ZionTerminalLogs.stream.listen((line) {
      if (!mounted) return;
      setState(() {
        _logs.add(line);
        if (_logs.length > 1500) _logs.removeRange(0, _logs.length - 1500);
      });
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
    _nativeSubscription?.cancel();
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
