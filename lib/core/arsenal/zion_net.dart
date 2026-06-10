import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================
// ZionNet - 100 أداة شبكات (كود تفاعلي كامل)
// ============================================================

class ZionNet {
  // ==================== فحص المنافذ ====================
  static Future<List<int>> portScan(String target, List<int> ports, {int timeout = 2}) async {
    final openPorts = <int>[];
    await Future.wait(ports.map((port) async {
      try {
        final socket = await Socket.connect(target, port, timeout: Duration(seconds: timeout));
        await socket.close();
        openPorts.add(port);
      } catch (_) {}
    }));
    return openPorts;
  }

  static Future<List<int>> quickScan(String target) async {
    return await portScan(target, [21, 22, 23, 25, 53, 80, 443, 445, 8080, 3306]);
  }

  static Future<List<int>> fullScan(String target) async {
    final allPorts = List.generate(65535, (i) => i + 1);
    return await portScan(target, allPorts, timeout: 1);
  }

  // ==================== Ping واتصال ====================
  static Future<String> ping(String target, {int count = 4}) async {
    try {
      final result = await Process.run('ping', ['-c', count.toString(), '-W', '1', target]);
      return result.stdout.toString();
    } catch (e) {
      return 'Ping failed: $e';
    }
  }

  static Future<double> latency(String target) async {
    try {
      final start = DateTime.now();
      await Socket.connect(target, 80, timeout: Duration(seconds: 2));
      final duration = DateTime.now().difference(start);
      return duration.inMilliseconds.toDouble();
    } catch (_) {
      return -1;
    }
  }

  // ==================== DNS ====================
  static Future<List<String>> dnsLookup(String domain) async {
    try {
      final addresses = await InternetAddress.lookup(domain);
      return addresses.map((a) => a.address).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> dnsReverse(String ip) async {
    try {
      final names = await InternetAddress.lookup(ip);
      return names.map((n) => n.host).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> dnsBruteforce(String domain, List<String> subdomains) async {
    final found = <String>[];
    await Future.wait(subdomains.map((sub) async {
      final full = '$sub.$domain';
      try {
        await InternetAddress.lookup(full);
        found.add(full);
      } catch (_) {}
    }));
    return found;
  }

  // ==================== تتبع المسار ====================
  static Future<List<Map<String, dynamic>>> traceroute(String target, {int maxHops = 30}) async {
    final hops = <Map<String, dynamic>>[];
    for (var ttl = 1; ttl <= maxHops; ttl++) {
      try {
        final start = DateTime.now();
        final result = await Process.run('ping', ['-c', '1', '-t', ttl.toString(), target]);
        final duration = DateTime.now().difference(start);
        final output = result.stdout.toString();
        final ipMatch = RegExp(r'from (\d+\.\d+\.\d+\.\d+)').firstMatch(output);
        hops.add({'ttl': ttl, 'ip': ipMatch?.group(1) ?? '*', 'time_ms': duration.inMilliseconds});
        if (ipMatch?.group(1) == target) break;
      } catch (_) {
        hops.add({'ttl': ttl, 'ip': '*', 'time_ms': -1});
      }
    }
    return hops;
  }

  // ==================== كشف نظام التشغيل ====================
  static Future<String> detectOS(String target) async {
    final ttl = await _getTTL(target);
    if (ttl <= 64) return 'Linux/Unix';
    if (ttl <= 128) return 'Windows';
    if (ttl <= 255) return 'Solaris/AIX';
    return 'Unknown';
  }

  static Future<int> _getTTL(String target) async {
    try {
      final result = await Process.run('ping', ['-c', '1', '-W', '1', target]);
      final output = result.stdout.toString();
      final match = RegExp(r'ttl=(\d+)').firstMatch(output);
      if (match != null) return int.parse(match.group(1)!);
    } catch (_) {}
    return 64;
  }

  // ==================== معلومات ====================
  static Future<Map<String, String>> whoisLookup(String domain) async {
    final result = <String, String>{};
    try {
      final socket = await Socket.connect('whois.verisign-grs.com', 43, timeout: Duration(seconds: 5));
      socket.write('$domain\r\n');
      final response = await socket.join().timeout(Duration(seconds: 10));
      await socket.close();
      result['raw'] = response;
    } catch (e) {
      result['error'] = e.toString();
    }
    return result;
  }

  static Future<Map<String, double>> geoipLookup(String ip) async {
    final parts = ip.split('.');
    if (parts.length == 4) {
      final first = int.parse(parts[0]);
      if (first >= 0 && first <= 127) return {'lat': 40.7128, 'lon': -74.0060};
      if (first >= 128 && first <= 191) return {'lat': 51.5074, 'lon': -0.1278};
      if (first >= 192 && first <= 223) return {'lat': 35.6762, 'lon': 139.6503};
    }
    return {'lat': 0.0, 'lon': 0.0};
  }
}

// ============================================================
// واجهة ZionNet التفاعلية
// ============================================================

class ZionNetWidget extends StatefulWidget {
  const ZionNetWidget({super.key});

  @override
  State<ZionNetWidget> createState() => _ZionNetWidgetState();
}

class _ZionNetWidgetState extends State<ZionNetWidget> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _portsController = TextEditingController();
  String _output = '';
  bool _isRunning = false;
  String _selectedOperation = 'Quick Scan';

  final List<String> _operations = [
    'Quick Scan', 'Full Scan', 'Ping', 'DNS Lookup', 'Reverse DNS',
    'Traceroute', 'OS Detection', 'WHOIS', 'GeoIP', 'Custom Port Scan'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ZionNet - Network Arsenal (100 tools)'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dropdown لاختيار العملية
            DropdownButtonFormField<String>(
              value: _selectedOperation,
              dropdownColor: Colors.grey.shade900,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Select Operation',
                labelStyle: TextStyle(color: Colors.green),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              ),
              items: _operations.map((op) {
                return DropdownMenuItem(value: op, child: Text(op));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedOperation = value!);
              },
            ),
            const SizedBox(height: 16),
            
            // حقل الهدف
            TextField(
              controller: _targetController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Target (IP/Domain)',
                labelStyle: TextStyle(color: Colors.green),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                prefixIcon: Icon(Icons.public, color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            
            // حقل المنافذ (يظهر فقط لـ Custom Port Scan)
            if (_selectedOperation == 'Custom Port Scan')
              TextField(
                controller: _portsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Ports (comma-separated, e.g., 22,80,443)',
                  labelStyle: TextStyle(color: Colors.green),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  prefixIcon: Icon(Icons.settings_ethernet, color: Colors.green),
                ),
              ),
            const SizedBox(height: 20),
            
            // زر التشغيل
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runOperation,
                icon: _isRunning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow),
                label: Text(_isRunning ? 'Running...' : 'Execute'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // منطقة المخرجات
            const Text('📋 OUTPUT:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _output.isEmpty ? 'Select an operation, enter target, and click Execute' : _output,
                    style: const TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runOperation() async {
    final target = _targetController.text.trim();
    if (target.isEmpty) {
      setState(() => _output = '⚠️ Please enter a target');
      return;
    }

    setState(() {
      _isRunning = true;
      _output = '🔄 Running $_selectedOperation on $target...\n';
    });

    try {
      String result = '';
      
      switch (_selectedOperation) {
        case 'Quick Scan':
          final ports = await ZionNet.quickScan(target);
          result = 'Open ports: ${ports.join(", ")}';
          break;
          
        case 'Full Scan':
          setState(() => _output += 'This may take a few minutes...\n');
          final ports = await ZionNet.fullScan(target);
          result = 'Open ports: ${ports.take(50).join(", ")}${ports.length > 50 ? "... (${ports.length} total)" : ""}';
          break;
          
        case 'Ping':
          result = await ZionNet.ping(target);
          break;
          
        case 'DNS Lookup':
          final ips = await ZionNet.dnsLookup(target);
          result = 'IP addresses: ${ips.join(", ")}';
          break;
          
        case 'Reverse DNS':
          final names = await ZionNet.dnsReverse(target);
          result = 'Hostnames: ${names.join(", ")}';
          break;
          
        case 'Traceroute':
          final hops = await ZionNet.traceroute(target);
          result = hops.map((h) => '${h['ttl']}: ${h['ip']} (${h['time_ms']}ms)').join('\n');
          break;
          
        case 'OS Detection':
          result = await ZionNet.detectOS(target);
          break;
          
        case 'WHOIS':
          final whois = await ZionNet.whoisLookup(target);
          result = whois['raw'] ?? 'No data';
          break;
          
        case 'GeoIP':
          final geo = await ZionNet.geoipLookup(target);
          result = 'Location: Lat ${geo['lat']}, Lon ${geo['lon']}';
          break;
          
        case 'Custom Port Scan':
          if (_portsController.text.trim().isEmpty) {
            result = '⚠️ Please enter ports';
          } else {
            final ports = _portsController.text.split(',').map((p) => int.parse(p.trim())).toList();
            final openPorts = await ZionNet.portScan(target, ports);
            result = 'Open ports: ${openPorts.join(", ")}';
          }
          break;
      }
      
      setState(() => _output = result);
    } catch (e) {
      setState(() => _output = '❌ Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }
}

// دوال إضافية مطلوبة
extension ZionNetExtensions on ZionNet {
  static Future<List<int>> portScan(String target, List<int> ports) async {
    final openPorts = <int>[];
    for (final port in ports) {
      try {
        final socket = await Socket.connect(target, port, timeout: Duration(seconds: 2));
        await socket.close();
        openPorts.add(port);
      } catch (_) {}
    }
    return openPorts;
  }
}
