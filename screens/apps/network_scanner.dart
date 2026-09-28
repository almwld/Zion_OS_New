import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class NetworkScannerApp extends StatefulWidget {
  const NetworkScannerApp({super.key});

  @override
  State<NetworkScannerApp> createState() => _NetworkScannerAppState();
}

class _NetworkScannerAppState extends State<NetworkScannerApp> {
  final TextEditingController _subnetController = TextEditingController(text: '192.168.1');
  final TextEditingController _hostController = TextEditingController(text: '192.168.1.1');
  String _output = '';
  bool _isScanning = false;

  Future<void> _scanNetwork() async {
    setState(() {
      _isScanning = true;
      _output = '🔍 جاري فحص الشبكة الفرعية ${_subnetController.text}.0/24...\n\n';
    });

    final List<String> activeHosts = [];
    for (var i = 1; i <= 254; i++) {
      final ip = '${_subnetController.text}.$i';
      try {
        final result = await Process.run('ping', ['-c', '1', '-W', '1', ip], runInShell: true);
        if (result.exitCode == 0) {
          activeHosts.add(ip);
          _output += '✅ $ip\n';
        }
      } catch (_) {}
    }

    setState(() {
      _output += '\n📊 تم العثور على ${activeHosts.length} جهاز نشط';
      _isScanning = false;
    });
  }

  Future<void> _scanPorts() async {
    final ports = [21, 22, 23, 25, 53, 80, 443, 8080, 3306, 5432, 27017];
    setState(() {
      _isScanning = true;
      _output = '🔍 جاري فحص المنافذ على ${_hostController.text}...\n\n';
    });

    for (final port in ports) {
      try {
        final socket = await Socket.connect(_hostController.text, port, timeout: const Duration(seconds: 1));
        socket.destroy();
        _output += '✅ المنفذ $port مفتوح\n';
      } catch (_) {
        _output += '❌ المنفذ $port مغلق\n';
      }
    }

    setState(() {
      _output += '\n✅ اكتمل الفحص';
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: theme.isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: Text('Network Scanner', style: TextStyle(color: theme.primaryColor)),
        backgroundColor: theme.isDarkMode ? Colors.black : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _subnetController,
              style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'الشبكة الفرعية (مثال: 192.168.1)',
                labelStyle: TextStyle(color: theme.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'المضيف المستهدف (للمنافذ)',
                labelStyle: TextStyle(color: theme.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _scanNetwork,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('فحص الشبكة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _scanPorts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('فحص المنافذ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isScanning) LinearProgressIndicator(color: theme.primaryColor),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output.isEmpty ? 'نتائج الفحص ستظهر هنا...' : _output,
                    style: TextStyle(color: theme.primaryColor, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
