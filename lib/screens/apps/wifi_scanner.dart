import 'package:flutter/material.dart';
import 'dart:io';

class WiFiScannerApp extends StatefulWidget {
  const WiFiScannerApp({super.key});

  @override
  State<WiFiScannerApp> createState() => _WiFiScannerAppState();
}

class _WiFiScannerAppState extends State<WiFiScannerApp> {
  List<Map<String, String>> _networks = [];
  bool _isScanning = false;
  String _errorMessage = '';
  String _currentWiFi = '';

  @override
  void initState() {
    super.initState();
    _getCurrentWiFi();
  }

  Future<void> _getCurrentWiFi() async {
    try {
      final result = await Process.run('dumpsys', ['wifi'], runInShell: true);
      final output = result.stdout.toString();
      final match = RegExp(r'mWifiInfo.*?SSID: "([^"]+)"', caseSensitive: false).firstMatch(output);
      if (match != null) {
        setState(() {
          _currentWiFi = match.group(1) ?? 'Unknown';
        });
      }
    } catch (_) {}
  }

  Future<void> _scanWiFi() async {
    setState(() {
      _isScanning = true;
      _networks.clear();
      _errorMessage = '';
    });

    try {
      // Using dumpsys wifi (Android)
      final result = await Process.run('dumpsys', ['wifi'], runInShell: true);
      final output = result.stdout.toString();
      
      // Parse WiFi networks from dumpsys
      final regex = RegExp(r'SSID: "([^"]+)".*?BSSID: ([0-9a-f:]+).*?RSSI: (-?\d+)', caseSensitive: false);
      final matches = regex.allMatches(output);
      
      final networksList = <Map<String, String>>[];
      for (final match in matches) {
        final ssid = match.group(1);
        final bssid = match.group(2);
        final rssi = match.group(3);
        if (ssid != null && ssid.isNotEmpty && ssid != 'unknown' && ssid != '<unknown ssid>') {
          networksList.add({
            'ssid': ssid,
            'bssid': bssid ?? 'Unknown',
            'signal': rssi ?? '0',
            'security': _getSecurityType(output, bssid ?? ''),
          });
        }
      }
      
      if (networksList.isEmpty) {
        setState(() {
          _errorMessage = 'No WiFi networks found. Make sure WiFi is enabled and location permission is granted.';
          _isScanning = false;
        });
        return;
      }
      
      setState(() {
        _networks = networksList;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error scanning networks: $e';
        _isScanning = false;
      });
    }
  }

  String _getSecurityType(String output, String bssid) {
    if (output.contains('WPA3') || output.contains('WPA3-Personal')) return 'WPA3';
    if (output.contains('WPA2') || output.contains('WPA2-PSK')) return 'WPA2';
    if (output.contains('WPA')) return 'WPA';
    if (output.contains('WEP')) return 'WEP';
    return 'Unknown';
  }

  int _getSignalStrength(int rssi) {
    if (rssi > -50) return 4;
    if (rssi > -60) return 3;
    if (rssi > -70) return 2;
    return 1;
  }

  IconData _getSignalIcon(int strength) {
    switch (strength) {
      case 4: return Icons.signal_cellular_4_bar;
      case 3: return Icons.signal_cellular_alt;
      case 2: return Icons.signal_cellular_alt;
      default: return Icons.signal_cellular_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('WiFi Scanner', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: _scanWiFi,
            tooltip: 'Scan networks',
          ),
        ],
      ),
      body: Column(
        children: [
          // Current WiFi Status
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF006064)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Connected to:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        _currentWiFi.isNotEmpty ? _currentWiFi : 'Not connected',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isScanning ? null : _scanWiFi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00BCD4),
                  ),
                  child: Text(_isScanning ? 'SCANNING...' : 'SCAN'),
                ),
              ],
            ),
          ),
          
          // Error Message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Networks List
          Expanded(
            child: _isScanning
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF00BCD4)),
                        SizedBox(height: 16),
                        Text('Scanning for networks...', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : _networks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, size: 64, color: Colors.white24),
                            SizedBox(height: 16),
                            Text('No networks found', style: TextStyle(color: Colors.white38)),
                            SizedBox(height: 8),
                            Text('Make sure WiFi is enabled', style: TextStyle(color: Colors.white24, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _networks.length,
                        itemBuilder: (context, index) {
                          final network = _networks[index];
                          final rssi = int.tryParse(network['signal'] ?? '-70') ?? -70;
                          final strength = _getSignalStrength(rssi);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(_getSignalIcon(strength), color: const Color(0xFF00BCD4), size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        network['ssid']!,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00BCD4).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              network['security']!,
                                              style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 10),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            network['bssid']!,
                                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${rssi} dBm',
                                  style: TextStyle(
                                    color: strength > 2 ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
