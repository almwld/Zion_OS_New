import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';

class SystemMonitorApp extends StatefulWidget {
  const SystemMonitorApp({super.key});

  @override
  State<SystemMonitorApp> createState() => _SystemMonitorAppState();
}

class _SystemMonitorAppState extends State<SystemMonitorApp> {
  double _cpuUsage = 0;
  double _ramUsage = 0;
  double _diskUsage = 0;
  double _temperature = 0;
  int _totalRam = 0;
  int _usedRam = 0;
  int _freeRam = 0;
  int _totalDisk = 0;
  int _usedDisk = 0;
  int _freeDisk = 0;
  int _processCount = 0;
  int _uptime = 0;
  
  List<FlSpot> _cpuHistory = [];
  List<FlSpot> _ramHistory = [];
  Timer? _timer;
  int _dataPoint = 0;

  @override
  void initState() {
    super.initState();
    _initData();
    _startMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initData() {
    for (int i = 0; i < 20; i++) {
      _cpuHistory.add(FlSpot(i.toDouble(), 0));
      _ramHistory.add(FlSpot(i.toDouble(), 0));
    }
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateStats();
      _updateHistory();
      setState(() {});
    });
  }

  void _updateStats() {
    _cpuUsage = _getCPUUsage();
    _ramUsage = _getRAMUsage();
    _diskUsage = _getDiskUsage();
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
      final output = result.stdout.toString();
      final match = RegExp(r'CPU:\s*(\d+)%').firstMatch(output);
      if (match != null) return double.parse(match.group(1)!);
    } catch (_) {}
    return 0;
  }

  double _getRAMUsage() {
    try {
      final result = Process.runSync('free', [], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          _totalRam = int.parse(parts[1]) ~/ 1024;
          _usedRam = int.parse(parts[2]) ~/ 1024;
          _freeRam = int.parse(parts[3]) ~/ 1024;
          return (int.parse(parts[2]) / int.parse(parts[1])) * 100;
        }
      }
    } catch (_) {}
    return 0;
  }

  double _getDiskUsage() {
    try {
      final result = Process.runSync('df', ['/data'], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 6) {
          _totalDisk = int.parse(parts[1]) ~/ (1024 * 1024);
          _usedDisk = int.parse(parts[2]) ~/ (1024 * 1024);
          _freeDisk = int.parse(parts[3]) ~/ (1024 * 1024);
          return (int.parse(parts[2]) / int.parse(parts[1])) * 100;
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

  int _getUptime() {
    try {
      final result = Process.runSync('cat', ['/proc/uptime'], runInShell: true);
      final uptimeSeconds = double.parse(result.stdout.toString().split(' ')[0]);
      return uptimeSeconds.toInt();
    } catch (_) {}
    return 0;
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (days > 0) return '$days d $hours h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Color _getStatusColor(double value) {
    if (value < 30) return Colors.green;
    if (value < 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('System Monitor', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: () => _updateStats(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // CPU Card
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
                      Icon(Icons.memory, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('CPU Usage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _cpuUsage / 100,
                          backgroundColor: Colors.white24,
                          color: _getStatusColor(_cpuUsage),
                          
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_cpuUsage.toStringAsFixed(1)}%',
                        style: TextStyle(color: _getStatusColor(_cpuUsage), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _cpuHistory,
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
            
            // RAM Card
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
                      Icon(Icons.memory, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('RAM Usage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _ramUsage / 100,
                          backgroundColor: Colors.white24,
                          color: _getStatusColor(_ramUsage),
                          
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_ramUsage.toStringAsFixed(1)}%',
                        style: TextStyle(color: _getStatusColor(_ramUsage), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total: ${_totalRam} MB', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('Used: ${_usedRam} MB', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('Free: ${_freeRam} MB', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _ramHistory,
                            isCurved: true,
                            color: Colors.green,
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
            
            // Storage Card
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
                      Icon(Icons.storage, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Storage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _diskUsage / 100,
                          backgroundColor: Colors.white24,
                          color: _getStatusColor(_diskUsage),
                          
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_diskUsage.toStringAsFixed(1)}%',
                        style: TextStyle(color: _getStatusColor(_diskUsage), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total: ${_totalDisk} GB', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('Used: ${_usedDisk} GB', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('Free: ${_freeDisk} GB', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // System Info Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard('Temperature', '${_temperature.toStringAsFixed(1)}°C', Icons.thermostat, Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard('Processes', '$_processCount', Icons.code, const Color(0xFF00BCD4)),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard('Uptime', _formatUptime(_uptime), Icons.timer, Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard('Platform', 'Android', Icons.android, Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
