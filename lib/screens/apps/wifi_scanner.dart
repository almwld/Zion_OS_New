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

  Future<void> _scanWiFi() async {
    setState(() {
      _isScanning = true;
      _networks.clear();
    });

    try {
      final result = await Process.run('dumpsys', ['wifi'], runInShell: true);
      final output = result.stdout.toString();
      
      final regex = RegExp(r'SSID: "([^"]+)".*?BSSID: ([0-9a-f:]+).*?RSSI: (-?\d+)', caseSensitive: false);
      final matches = regex.allMatches(output);
      
      for (final match in matches) {
        _networks.add({
          'ssid': match.group(1) ?? 'Unknown',
          'bssid': match.group(2) ?? 'Unknown',
          'signal': match.group(3) ?? '0',
        });
      }
    } catch (e) {
      print('Error: $e');
    }

    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('WiFi Scanner', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00FF41)),
            onPressed: _scanWiFi,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isScanning)
            const LinearProgressIndicator(color: Color(0xFF00FF41)),
          Expanded(
            child: _networks.isEmpty && !_isScanning
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, color: Color(0xFF00FF41), size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'اضغط على زر التحديث لمسح الشبكات',
                          style: TextStyle(color: Color(0xFF00FF41)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _networks.length,
                    itemBuilder: (context, index) {
                      final network = _networks[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi, color: Color(0xFF00FF41), size: 30),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    network['ssid']!,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    network['bssid']!,
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF41).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${network['signal']} dBm',
                                style: const TextStyle(color: Color(0xFF00FF41), fontSize: 12),
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
