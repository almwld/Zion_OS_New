import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class WiFiScannerApp extends StatefulWidget {
  const WiFiScannerApp({super.key});

  @override
  State<WiFiScannerApp> createState() => _WiFiScannerAppState();
}

class _WiFiScannerAppState extends State<WiFiScannerApp> {
  List<Map<String, String>> _networks = [];
  bool _isScanning = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() => _hasPermission = status.isGranted);
    if (_hasPermission) _scanWiFi();
  }

  Future<void> _scanWiFi() async {
    if (!_hasPermission) return;
    setState(() { _isScanning = true; _networks.clear(); });
    await Future.delayed(const Duration(seconds: 2));
    try {
      final result = await Process.run('dumpsys', ['wifi'], runInShell: true);
      final output = result.stdout.toString();
      final regex = RegExp(r'SSID: "([^"]+)".*?BSSID: ([0-9a-f:]+).*?RSSI: (-?\d+)');
      final matches = regex.allMatches(output);
      for (final match in matches) {
        final ssid = match.group(1);
        if (ssid != null && ssid.isNotEmpty && ssid != 'unknown' && ssid != '<unknown ssid>') {
          _networks.add({'ssid': ssid, 'bssid': match.group(2) ?? 'Unknown', 'signal': match.group(3) ?? '0', 'security': 'WPA2'});
        }
      }
    } catch (_) {}
    setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('WiFi Scanner', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)), onPressed: _scanWiFi)],
      ),
      body: !_hasPermission
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.location_off, size: 64, color: Colors.white24),
              const Text('Location Permission Required', style: TextStyle(color: Colors.white38)),
              ElevatedButton(onPressed: _requestLocationPermission, child: const Text('Grant Permission')),
            ]))
          : _isScanning
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
              : _networks.isEmpty
                  ? const Center(child: Text('No networks found', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: _networks.length,
                      itemBuilder: (ctx, i) {
                        final n = _networks[i];
                        return ListTile(
                          leading: const Icon(Icons.wifi, color: Color(0xFF00BCD4)),
                          title: Text(n['ssid']!, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${n['signal']} dBm • ${n['security']}', style: const TextStyle(color: Colors.white54)),
                        );
                      },
                    ),
    );
  }
}
