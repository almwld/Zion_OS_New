import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../src/core/services/system_metrics.dart';
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
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _updateStats();
      if (!mounted) return;
      _updateHistory();
      _updatePerformanceScore();
      setState(() {});
    });
  }

  Future<void> _updateStats() async {
    final metrics = await SystemMetrics.read();
    _currentCpu = metrics.cpuPercent;
    _currentRam = metrics.memoryPercent;
    _currentDisk = metrics.storagePercent;
    _currentUptime = metrics.uptime.inSeconds;
    _currentProcesses = metrics.processCount;
    _currentTemp = metrics.temperatureCelsius;
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
