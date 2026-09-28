import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';

class PerformanceMonitorApp extends StatefulWidget {
  const PerformanceMonitorApp({super.key});

  @override
  State<PerformanceMonitorApp> createState() => _PerformanceMonitorAppState();
}

class _PerformanceMonitorAppState extends State<PerformanceMonitorApp> {
  List<FlSpot> _cpuSpots = [];
  List<FlSpot> _ramSpots = [];
  List<FlSpot> _diskSpots = [];
  List<FlSpot> _tempSpots = [];
  
  double _currentCpu = 0;
  double _currentRam = 0;
  double _currentDisk = 0;
  double _currentTemp = 0;
  int _currentProcesses = 0;
  int _currentUptime = 0;
  
  Timer? _monitorTimer;
  int _dataPoint = 0;
  
  String _performanceStatus = 'Excellent';
  Color _performanceColor = Colors.green;
  int _performanceScore = 100;

  @override
  void initState() {
    super.initState();
    _initData();
    _startMonitoring();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  void _initData() {
    for (int i = 0; i < 30; i++) {
      _cpuSpots.add(FlSpot(i.toDouble(), 0));
      _ramSpots.add(FlSpot(i.toDouble(), 0));
      _diskSpots.add(FlSpot(i.toDouble(), 0));
      _tempSpots.add(FlSpot(i.toDouble(), 35));
    }
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateStats();
      _updateHistory();
      _updatePerformanceScore();
      setState(() {});
    });
  }

  void _updateStats() {
    _currentCpu = _getCPUUsage();
    _currentRam = _getRAMUsage();
    _currentDisk = _getDiskUsage();
    _currentTemp = _getTemperature();
    _currentProcesses = _getProcessCount();
    _currentUptime = _getUptime();
  }

  void _updateHistory() {
    _dataPoint++;
    _cpuSpots.add(FlSpot(_dataPoint.toDouble(), _currentCpu));
    _ramSpots.add(FlSpot(_dataPoint.toDouble(), _currentRam));
    _diskSpots.add(FlSpot(_dataPoint.toDouble(), _currentDisk));
    _tempSpots.add(FlSpot(_dataPoint.toDouble(), _currentTemp));
    
    if (_cpuSpots.length > 30) _cpuSpots.removeAt(0);
    if (_ramSpots.length > 30) _ramSpots.removeAt(0);
    if (_diskSpots.length > 30) _diskSpots.removeAt(0);
    if (_tempSpots.length > 30) _tempSpots.removeAt(0);
  }

  void _updatePerformanceScore() {
    int score = 100;
    if (_currentCpu > 80) score -= 30;
    else if (_currentCpu > 60) score -= 20;
    else if (_currentCpu > 40) score -= 10;
    
    if (_currentRam > 80) score -= 20;
    else if (_currentRam > 60) score -= 10;
    
    if (_currentTemp > 70) score -= 20;
    else if (_currentTemp > 55) score -= 10;
    
    _performanceScore = score.clamp(0, 100);
    
    if (_performanceScore > 80) {
      _performanceStatus = 'Excellent';
      _performanceColor = Colors.green;
    } else if (_performanceScore > 60) {
      _performanceStatus = 'Good';
      _performanceColor = Colors.orange;
    } else {
      _performanceStatus = 'Poor';
      _performanceColor = Colors.red;
    }
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
          final total = double.parse(parts[1]);
          final used = double.parse(parts[2]);
          return (used / total) * 100;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Performance Monitor', style: TextStyle(color: Color(0xFF00BCD4))),
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
                  colors: [_performanceColor, _performanceColor.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Performance Score', style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '$_performanceScore',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _performanceStatus,
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // CPU Chart
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.memory, color: Color(0xFF00BCD4)),
                          SizedBox(width: 8),
                          Text('CPU Usage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        '${_currentCpu.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _currentCpu / 100,
                    backgroundColor: Colors.white24,
                    color: _getCpuColor(_currentCpu),
                    minHeight: 10,
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
                            spots: _cpuSpots,
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
            
            // RAM Chart
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.memory, color: Color(0xFF00BCD4)),
                          SizedBox(width: 8),
                          Text('RAM Usage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        '${_currentRam.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _currentRam / 100,
                    backgroundColor: Colors.white24,
                    color: Colors.green,
                    minHeight: 10,
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
                            spots: _ramSpots,
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
            
            // Storage Chart
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storage, color: Color(0xFF00BCD4)),
                          SizedBox(width: 8),
                          Text('Storage Usage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        '${_currentDisk.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _currentDisk / 100,
                    backgroundColor: Colors.white24,
                    color: Colors.orange,
                    minHeight: 10,
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
                            spots: _diskSpots,
                            isCurved: true,
                            color: Colors.orange,
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
            
            // Stats Grid
            Row(
              children: [
                Expanded(child: _buildStatCard('Temperature', '${_currentTemp.toStringAsFixed(1)}°C', Icons.thermostat, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Processes', '$_currentProcesses', Icons.code, Colors.purple)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: _buildStatCard('Uptime', _formatUptime(_currentUptime), Icons.timer, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Platform', 'Android', Icons.android, Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Color _getCpuColor(double usage) {
    if (usage < 30) return Colors.green;
    if (usage < 70) return Colors.orange;
    return Colors.red;
  }
}
