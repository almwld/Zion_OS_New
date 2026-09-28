import 'package:flutter/material.dart';

class ZionWifiPanel extends StatefulWidget {
  const ZionWifiPanel({super.key});

  @override
  State<ZionWifiPanel> createState() => _ZionWifiPanelState();
}

class _ZionWifiPanelState extends State<ZionWifiPanel> {
  List<String> _networks = [];
  bool _isScanning = false;

  Future<void> _scanNetworks() async {
    setState(() {
      _isScanning = true;
      _networks = [];
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _networks = ['WiFi Network 1', 'WiFi Network 2', 'WiFi Network 3'];
      _isScanning = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _scanNetworks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Zion WiFi Panel'), backgroundColor: Colors.blue.shade900),
      body: _isScanning
          ? const Center(child: CircularProgressIndicator())
          : _networks.isEmpty
              ? const Center(child: Text('No networks found', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: _networks.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: const Icon(Icons.wifi, color: Colors.blue),
                    title: Text(_networks[i], style: const TextStyle(color: Colors.white)),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Attack'),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(onPressed: _scanNetworks, backgroundColor: Colors.blue, child: const Icon(Icons.refresh)),
    );
  }
}
