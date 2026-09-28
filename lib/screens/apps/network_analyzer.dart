import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class NetworkAnalyzerApp extends StatefulWidget {
  const NetworkAnalyzerApp({super.key});

  @override
  State<NetworkAnalyzerApp> createState() => _NetworkAnalyzerAppState();
}

class _NetworkAnalyzerAppState extends State<NetworkAnalyzerApp> {
  List<Map<String, String>> _activeConnections = [];
  List<Map<String, String>> _openPorts = [];
  List<Map<String, String>> _networkInterfaces = [];
  List<FlSpot> _trafficHistory = [];
  bool _isScanning = false;
  String _targetHost = '';
  String _scanResult = '';
  int _dataPoint = 0;
  Timer? _monitorTimer;

  @override
  void initState() {
    super.initState();
    _initData();
    _startMonitoring();
    _loadNetworkInfo();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  void _initData() {
    for (int i = 0; i < 20; i++) {
      _trafficHistory.add(FlSpot(i.toDouble(), 0));
    }
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateActiveConnections();
      _updateTrafficHistory();
      setState(() {});
    });
  }

  Future<void> _loadNetworkInfo() async {
    await _updateNetworkInterfaces();
    await _updateActiveConnections();
  }

  Future<void> _updateNetworkInterfaces() async {
    _networkInterfaces.clear();
    try {
      final result = await Process.run('ip', ['addr', 'show'], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      String currentInterface = '';
      
      for (final line in lines) {
        if (line.contains(':') && !line.contains('lo:')) {
          currentInterface = line.split(':')[1].trim();
          _networkInterfaces.add({
            'name': currentInterface,
            'status': 'down',
            'ip': '',
          });
        } else if (currentInterface.isNotEmpty && line.contains('inet ')) {
          final ipMatch = RegExp(r'inet (\d+\.\d+\.\d+\.\d+)').firstMatch(line);
          if (ipMatch != null) {
            final index = _networkInterfaces.length - 1;
            _networkInterfaces[index]['ip'] = ipMatch.group(1)!;
            _networkInterfaces[index]['status'] = 'up';
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _updateActiveConnections() async {
    _activeConnections.clear();
    try {
      final result = await Process.run('netstat', ['-an'], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      
      for (final line in lines) {
        if (line.contains('ESTABLISHED') || line.contains('LISTEN')) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 6) {
            _activeConnections.add({
              'protocol': parts[0],
              'local': parts[3],
              'foreign': parts[4],
              'state': parts[5],
            });
          }
        }
      }
    } catch (_) {}
  }

  void _updateTrafficHistory() {
    _dataPoint++;
    final randomTraffic = 10 + (DateTime.now().second % 90);
    _trafficHistory.add(FlSpot(_dataPoint.toDouble(), randomTraffic.toDouble()));
    if (_trafficHistory.length > 20) _trafficHistory.removeAt(0);
  }

  Future<void> _scanPorts(String host) async {
    setState(() {
      _isScanning = true;
      _openPorts.clear();
      _scanResult = 'Scanning $host...';
    });

    final commonPorts = [21, 22, 23, 25, 53, 80, 443, 8080, 3306, 5432, 27017];
    final openPorts = <Map<String, String>>[];

    for (final port in commonPorts) {
      try {
        final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 1));
        openPorts.add({
          'port': port.toString(),
          'service': _getServiceName(port),
          'status': 'open',
        });
        socket.destroy();
      } catch (_) {
        // Port closed
      }
    }

    setState(() {
      _openPorts = openPorts;
      _isScanning = false;
      _scanResult = openPorts.isEmpty 
          ? 'No open ports found on $host'
          : 'Found ${openPorts.length} open ports on $host';
    });
  }

  String _getServiceName(int port) {
    const services = {
      21: 'FTP', 22: 'SSH', 23: 'Telnet', 25: 'SMTP', 53: 'DNS',
      80: 'HTTP', 443: 'HTTPS', 8080: 'HTTP-Alt', 3306: 'MySQL',
      5432: 'PostgreSQL', 27017: 'MongoDB',
    };
    return services[port] ?? 'Unknown';
  }

  Future<void> _pingHost(String host) async {
    setState(() {
      _isScanning = true;
      _scanResult = 'Pinging $host...';
    });

    try {
      final result = await Process.run('ping', ['-c', '3', '-W', '2', host], runInShell: true);
      final output = result.stdout.toString();
      
      // Extract ping times
      final times = RegExp(r'time=(\d+\.?\d*) ms').allMatches(output);
      final avgTime = times.map((m) => double.parse(m.group(1)!)).reduce((a, b) => a + b) / times.length;
      
      setState(() {
        _scanResult = '✅ Host $host is reachable\nAverage response: ${avgTime.toStringAsFixed(1)} ms';
        _isScanning = false;
      });
    } catch (_) {
      setState(() {
        _scanResult = '❌ Host $host is not reachable';
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Network Analyzer', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: _loadNetworkInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Network Traffic Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.show_chart, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Network Traffic', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _trafficHistory,
                            isCurved: true,
                            color: const Color(0xFF00BCD4),
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Network Interfaces
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings_ethernet, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Network Interfaces', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._networkInterfaces.map((iface) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          iface['status'] == 'up' ? Icons.check_circle : Icons.error,
                          color: iface['status'] == 'up' ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(iface['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(
                                iface['ip']! != '' ? iface['ip']! : 'No IP',
                                style: TextStyle(color: iface['ip']! != '' ? Colors.white54 : Colors.red, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iface['status'] == 'up' 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            iface['status']!,
                            style: TextStyle(
                              color: iface['status'] == 'up' ? Colors.green : Colors.red,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Port Scanner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.scanner, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Port Scanner', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          onChanged: (v) => _targetHost = v,
                          decoration: const InputDecoration(
                            hintText: 'Enter IP or hostname',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _targetHost.isNotEmpty && !_isScanning
                            ? () => _scanPorts(_targetHost)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('SCAN'),
                      ),
                    ],
                  ),
                  if (_openPorts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._openPorts.map((port) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text('Port ${port['port']}', style: const TextStyle(color: Colors.white)),
                          const Spacer(),
                          Text(port['service']!, style: const TextStyle(color: Colors.white54)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Ping Tool
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Ping Tool', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          onChanged: (v) => _targetHost = v,
                          decoration: const InputDecoration(
                            hintText: 'Enter IP or hostname',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _targetHost.isNotEmpty && !_isScanning
                            ? () => _pingHost(_targetHost)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('PING'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Scan Result
            if (_scanResult.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_scanResult.contains('✅') 
                      ? Colors.green 
                      : _scanResult.contains('❌') 
                          ? Colors.red 
                          : const Color(0xFF00BCD4)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _scanResult,
                  style: TextStyle(
                    color: _scanResult.contains('✅') 
                        ? Colors.green 
                        : _scanResult.contains('❌') 
                            ? Colors.red 
                            : const Color(0xFF00BCD4),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Active Connections
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Active Connections', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _activeConnections.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No active connections', style: TextStyle(color: Colors.white38)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _activeConnections.length > 10 ? 10 : _activeConnections.length,
                          itemBuilder: (context, index) {
                            final conn = _activeConnections[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    conn['foreign']!,
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${conn['protocol']} | ${conn['state']}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
