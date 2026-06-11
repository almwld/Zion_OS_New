import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class PerformanceHubApp extends StatefulWidget {
  const PerformanceHubApp({super.key});

  @override
  State<PerformanceHubApp> createState() => _PerformanceHubAppState();
}

class _PerformanceHubAppState extends State<PerformanceHubApp> {
  // Live data
  double _cpuUsage = 0;
  double _ramUsage = 0;
  double _storageUsage = 0;
  double _temperature = 0;
  int _processCount = 0;
  String _uptime = '';
  
  // History for charts
  List<FlSpot> _cpuHistory = [];
  List<FlSpot> _ramHistory = [];
  Timer? _monitorTimer;
  int _dataPoint = 0;

  @override
  void initState() {
    super.initState();
    _initHistory();
    _startMonitoring();
    _updateStats();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  void _initHistory() {
    for (int i = 0; i < 20; i++) {
      _cpuHistory.add(FlSpot(i.toDouble(), 0));
      _ramHistory.add(FlSpot(i.toDouble(), 0));
    }
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateStats();
      _updateHistory();
      setState(() {});
    });
  }

  void _updateStats() {
    _cpuUsage = _getCPUUsage();
    _ramUsage = _getRAMUsage();
    _storageUsage = _getStorageUsage();
    _temperature = _getTemperature();
    _processCount = _getProcessCount();
    _uptime = _getUptime();
  }

  void _updateHistory() {
    _dataPoint++;
    _cpuHistory.add(FlSpot(_dataPoint.toDouble(), _cpuUsage));
    _ramHistory.add(FlSpot(_dataPoint.toDouble(), _ramUsage));
    if (_cpuHistory.length > 20) _cpuHistory.removeAt(0);
    if (_ramHistory.length > 20) _ramHistory.removeAt(0);
  }

  double _getCPUUsage() {
    try {
      final result = Process.runSync('top', ['-bn1'], runInShell: true);
      final match = RegExp(r'CPU:\s*(\d+)%').firstMatch(result.stdout.toString());
      if (match != null) return double.parse(match.group(1)!);
    } catch (_) {}
    return 0;
  }

  double _getRAMUsage() {
    try {
      final result = Process.runSync('free', [], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final total = double.parse(parts[1]);
          final used = double.parse(parts[2]);
          return (used / total) * 100;
        }
      }
    } catch (_) {}
    return 0;
  }

  double _getStorageUsage() {
    try {
      final result = Process.runSync('df', ['/data'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          final used = double.parse(parts[2]);
          final total = double.parse(parts[3]);
          return (used / total) * 100;
        }
      }
    } catch (_) {}
    return 0;
  }

  double _getTemperature() {
    try {
      final result = Process.runSync('cat', ['/sys/class/thermal/thermal_zone0/temp'], runInShell: true);
      final temp = double.parse(result.stdout.toString().trim()) / 1000;
      return temp;
    } catch (_) {}
    return 35;
  }

  int _getProcessCount() {
    try {
      final result = Process.runSync('ps', ['-e'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      return lines.length - 1;
    } catch (_) {}
    return 0;
  }

  String _getUptime() {
    try {
      final result = Process.runSync('cat', ['/proc/uptime'], runInShell: true);
      final uptimeSeconds = double.parse(result.stdout.toString().split(' ')[0]);
      final days = (uptimeSeconds / 86400).toInt();
      final hours = ((uptimeSeconds % 86400) / 3600).toInt();
      final minutes = ((uptimeSeconds % 3600) / 60).toInt();
      if (days > 0) return '$days d $hours h';
      if (hours > 0) return '${hours}h ${minutes}m';
      return '${minutes}m';
    } catch (_) {}
    return 'Unknown';
  }

  Color _getUsageColor(double value) {
    if (value < 50) return Colors.green;
    if (value < 80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final performanceScore = ((100 - _cpuUsage) * 0.4 + (100 - _ramUsage) * 0.3 + (100 - _storageUsage) * 0.3).toInt();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Performance Hub', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Performance Score Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: performanceScore > 80
                      ? [Colors.green, Colors.green.withOpacity(0.5)]
                      : performanceScore > 50
                          ? [Colors.orange, Colors.orange.withOpacity(0.5)]
                          : [Colors.red, Colors.red.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Performance Score', style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '$performanceScore',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    performanceScore > 80 ? 'Excellent' : (performanceScore > 50 ? 'Fair' : 'Poor'),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // CPU Section
            _buildMetricCard('CPU Usage', '${_cpuUsage.toStringAsFixed(1)}%', Icons.memory, _getUsageColor(_cpuUsage), _cpuHistory),
            
            const SizedBox(height: 16),
            
            // RAM Section
            _buildMetricCard('RAM Usage', '${_ramUsage.toStringAsFixed(1)}%', Icons.ram, _getUsageColor(_ramUsage), _ramHistory),
            
            const SizedBox(height: 16),
            
            // Storage & Battery Row
            Row(
              children: [
                Expanded(child: _buildSimpleMetric('Storage', '${_storageUsage.toStringAsFixed(1)}%', Icons.storage, _getUsageColor(_storageUsage))),
                const SizedBox(width: 12),
                Expanded(child: _buildSimpleMetric('Temperature', '${_temperature.toStringAsFixed(1)}°C', Icons.thermostat, _temperature > 60 ? Colors.red : Colors.orange)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Processes & Uptime Row
            Row(
              children: [
                Expanded(child: _buildSimpleMetric('Processes', '$_processCount', Icons.code, Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _buildSimpleMetric('Uptime', _uptime, Icons.timer, const Color(0xFF00BCD4))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, List<FlSpot> history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: double.tryParse(value.replaceAll('%', ''))! / 100,
            backgroundColor: Colors.white24,
            color: color,
            minHeight: 6,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: history,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}
