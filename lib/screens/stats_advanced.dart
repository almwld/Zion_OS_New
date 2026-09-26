import 'package:flutter/material.dart';
import '../../core/services/zion_platform_service.dart';

class StatsAdvanced extends StatefulWidget {
  const StatsAdvanced({super.key});
  @override
  State<StatsAdvanced> createState() => _StatsAdvancedState();
}

class _StatsAdvancedState extends State<StatsAdvanced> {
  final _platform = ZionPlatformService.instance;
  Map<String, Object?> _battery = const {};
  Map<String, Object?> _network = const {};
  Map<String, Object?> _storage = const {};
  String? _error;
  bool _loading = true;

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _platform.getBatteryInfo(),
        _platform.getNetworkInfo(),
        _platform.getStorageInfo(),
      ]);
      if (!mounted) return;
      setState(() {
        _battery = results[0];
        _network = results[1];
        _storage = results[2];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Runtime data unavailable: $e'; });
    }
  }

  String _value(Map<String, Object?> data, String key) => data[key]?.toString() ?? 'UNAVAILABLE';

  Widget _card(String title, IconData icon, Map<String, Object?> data, List<String> keys) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: const Color(0xFF00BCD4)), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          ...keys.map((key) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Text(key, style: const TextStyle(color: Colors.white60))),
              Text(_value(data, key), style: const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace')),
            ]),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Advanced Statistics', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)), onPressed: _refresh)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) Card(color: Colors.orange.withOpacity(0.12), child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent)))),
                  _card('Battery', Icons.battery_full, _battery, ['level', 'charging', 'temperature', 'voltage']),
                  _card('Network', Icons.network_check, _network, ['transport', 'connected', 'ipAddress']),
                  _card('Storage', Icons.storage, _storage, ['totalBytes', 'freeBytes', 'usedBytes']),
                  const SizedBox(height: 8),
                  const Text('Values shown here come from the Android runtime. Unsupported metrics remain UNAVAILABLE rather than being simulated.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
    );
  }
}
