import 'dart:async';
import 'package:flutter/material.dart';
import '../core/agent_models.dart';
import '../core/agent_runtime.dart';

class ZionAgentScreen extends StatefulWidget {
  const ZionAgentScreen({super.key});
  @override
  State<ZionAgentScreen> createState() => _ZionAgentScreenState();
}

class _ZionAgentScreenState extends State<ZionAgentScreen> {
  final _input = TextEditingController();
  final _logs = <String>[];
  late final AgentRuntime _runtime;
  StreamSubscription<AgentEvent>? _sub;
  bool _busy = false;
  AgentResult? _result;

  @override
  void initState() {
    super.initState();
    _runtime = AgentRuntime();
    _sub = _runtime.events.listen((event) {
      if (!mounted) return;
      setState(() => _logs.add(event.message));
    });
  }

  Future<void> _run() async {
    final task = _input.text.trim();
    if (task.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    final result = await _runtime.run(task);
    if (!mounted) return;
    setState(() {
      _result = result;
      _busy = false;
    });
  }

  Future<void> _cancel() async {
    await _runtime.cancel();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF071018),
        appBar: AppBar(
          title: const Text('Zion Agent'),
          backgroundColor: const Color(0xFF101923),
          actions: [
            if (_busy)
              TextButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.orange),
                label: const Text('إيقاف', style: TextStyle(color: Colors.orange)),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  ..._logs.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(e, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace')),
                      )),
                  if (_result != null)
                    Card(
                      color: const Color(0xFF101923),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _result!.report ?? _result!.error ?? 'اكتملت المهمة.',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF101923),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLines: 3,
                      enabled: !_busy,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'اكتب مهمة معقدة...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _busy ? null : _run,
                    icon: const Icon(Icons.play_arrow, color: Color(0xFF00BCD4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    _runtime.dispose();
    super.dispose();
  }
}
