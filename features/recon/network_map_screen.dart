import 'dart:io';

import 'package:flutter/material.dart';

class DiscoveredDevice {
  const DiscoveredDevice({required this.ip, required this.responseTimeMs});
  final String ip;
  final int responseTimeMs;
}

class NetworkMapScreen extends StatefulWidget {
  const NetworkMapScreen({super.key});
  @override
  State<NetworkMapScreen> createState() => _NetworkMapScreenState();
}

class _NetworkMapScreenState extends State<NetworkMapScreen> {
  final _subnetController = TextEditingController(text: '192.168.1.0/24');
  final List<DiscoveredDevice> _devices = <DiscoveredDevice>[];
  bool _scanning = false;
  int _scanned = 0;
  String? _current;
  String? _error;

  @override
  void dispose() {
    _subnetController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_scanning) return;
    final value = _subnetController.text.trim();
    final match = RegExp(r'^(\d{1,3}(?:\.\d{1,3}){2})\.0/24\$').firstMatch(value);
    if (match == null) {
      setState(() => _error = 'أدخل شبكة IPv4 بصيغة 192.168.1.0/24');
      return;
    }
    setState(() {
      _scanning = true;
      _scanned = 0;
      _devices.clear();
      _current = null;
      _error = null;
    });
    try {
      final base = match.group(1)!;
      for (var i = 1; i <= 254; i++) {
        if (!_scanning || !mounted) break;
        final host = '$base.$i';
        setState(() {
          _current = host;
          _scanned = i;
        });
        final timer = Stopwatch()..start();
        try {
          final result = await Process.run('ping', ['-c', '1', '-W', '1', host], runInShell: false).timeout(const Duration(seconds: 2));
          timer.stop();
          if (result.exitCode == 0 && mounted) {
            setState(() => _devices.add(DiscoveredDevice(ip: host, responseTimeMs: timer.elapsedMilliseconds)));
          }
        } catch (_) {
          // Unreachable host or unsupported ping binary.
        }
      }
    } finally {
      if (mounted) setState(() { _scanning = false; _current = null; });
    }
  }

  void _stopScan() {
    if (_scanning) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _scanned / 254;
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Network Map'), Text('استطلاع دفاعي للشبكة المحلية', style: TextStyle(fontSize: 12))]),
        actions: [IconButton(icon: Icon(_scanning ? Icons.stop : Icons.play_arrow), onPressed: _scanning ? _stopScan : _startScan)],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: TextField(controller: _subnetController, enabled: !_scanning, decoration: const InputDecoration(labelText: 'Local subnet', hintText: '192.168.1.0/24'))), const SizedBox(width: 12), ElevatedButton(onPressed: _scanning ? null : _startScan, child: const Text('Scan'))])),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        if (_scanning) Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('فحص ${_current ?? '...'} — $_scanned/254'), const SizedBox(height: 8), LinearProgressIndicator(value: progress)])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Align(alignment: Alignment.centerLeft, child: Text('${_devices.length} أجهزة مستجيبة'))),
        Expanded(child: _devices.isEmpty ? Center(child: Text(_scanning ? 'جاري الاستطلاع...' : 'لا توجد أجهزة مستجيبة')) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _devices.length, itemBuilder: (_, i) { final d = _devices[i]; return Card(child: ListTile(leading: const Icon(Icons.devices), title: Text(d.ip), subtitle: Text('استجابة: ${d.responseTimeMs} ms'))); }))
      ]),
    );
  }
}
