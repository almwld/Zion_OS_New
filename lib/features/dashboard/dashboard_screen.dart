import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/unified_core_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _targetController = TextEditingController(text: '127.0.0.1');
  String _output = 'جاهز. اختر فحصاً دفاعياً.\n';
  bool _loading = false;

  Future<void> _execute(String command) async {
    setState(() => _loading = true);
    final service = context.read<UnifiedCoreService>();
    final result = await service.execute(command, target: _targetController.text.trim());
    if (!mounted) return;
    setState(() {
      _output = result;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Zion OS — Defensive Dashboard'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أدوات التشخيص الدفاعي فقط', style: TextStyle(color: Color(0xFF00FF41), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: const InputDecoration(labelText: 'Host / Domain', prefixIcon: Icon(Icons.language)),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF0A0E0A), borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(child: Text(_output, style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace', fontSize: 12))),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              _btn('System', 'system_info'),
              _btn('Ping', 'ping'),
              _btn('DNS', 'dns_lookup'),
              _btn('TLS', 'ssl_check'),
              _btn('HTTPS Headers', 'http_headers'),
              _btn('Help', 'help'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, String command) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ElevatedButton(onPressed: _loading ? null : () => _execute(command), child: Text(label)),
  );
}
