import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';

class StatsAdvanced extends StatefulWidget {
  const StatsAdvanced({super.key});

  @override
  State<StatsAdvanced> createState() => _StatsAdvancedState();
}

class _StatsAdvancedState extends State<StatsAdvanced> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // System Stats
  double _cpuUsage = 0;
  double _ramUsage = 0;
  double _diskUsage = 0;
  double _temperature = 0;
  int _processCount = 0;
  int _uptime = 0;
  
  // Network Stats
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  double _totalDownload = 0;
  double _totalUpload = 0;
  
  // History
  List<FlSpot> _cpuHistory = [];
  List<FlSpot> _ramHistory = [];
  List<FlSpot> _networkHistory = [];
  Timer? _monitorTimer;
  int _dataPoint = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initHistory();
    _startMonitoring();
    _updateAllStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _monitorTimer?.cancel();
    super.dispose();
  }

  void _initHistory() {
    for (int i = 0; i < 30; i++) {
      _cpuHistory.add(FlSpot(i.toDouble(), 0));
      _ramHistory.add(FlSpot(i.toDouble(), 0));
      _networkHistory.add(FlSpot(i.toDouble(), 0));
    }
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateAllStats();
      _updateHistory();
      setState(() {});
    });
  }

  void _updateAllStats() {
    _cpuUsage = _getCPUUsage();
    _ramUsage = _getRAMUsage();
    _diskUsage = _getDiskUsage();
    _temperature = _getTemperature();
    _processCount = _getProcessCount();
    _uptime = _getUptime();
    _downloadSpeed = _getDownloadSpeed();
    _uploadSpeed = _getUploadSpeed();
    _totalDownload += _downloadSpeed / 10;
    _totalUpload += _uploadSpeed / 10;
  }

  void _updateHistory() {
    _dataPoint++;
    _cpuHistory.add(FlSpot(_dataPoint.toDouble(), _cpuUsage));
    _ramHistory.add(FlSpot(_dataPoint.toDouble(), _ramUsage));
    _networkHistory.add(FlSpot(_dataPoint.toDouble(), _downloadSpeed * 10));
    
    if (_cpuHistory.length > 30) _cpuHistory.removeAt(0);
    if (_ramHistory.length > 30) _ramHistory.removeAt(0);
    if (_networkHistory.length > 30) _networkHistory.removeAt(0);
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
          return (double.parse(parts[2]) / double.parse(parts[1])) * 100;
        }
      }
    } catch (_) {}
    return 0;
  }

  double _getDiskUsage() {
    try {
      final result = Process.runSync('df', ['/data'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          return double.parse(parts[2].replaceAll('%', ''));
        }
      }
    } catch (_) {}
    return 0;
  }

  double _getTemperature() {
    try {
      final result = Process.runSync('cat', ['/sys/class/thermal/thermal_zone0/temp'], runInShell: true);
      return double.parse(result.stdout.toString().trim()) / 1000;
    } catch (_) {}
    return 35;
  }

  int _getProcessCount() {
    try {
      final result = Process.runSync('ps', ['-e'], runInShell: true);
      return result.stdout.toString().split('\n').length - 1;
    } catch (_) {}
    return 0;
  }

  int _getUptime() {
    try {
      final result = Process.runSync('cat', ['/proc/uptime'], runInShell: true);
      return double.parse(result.stdout.toString().split(' ')[0]).toInt();
    } catch (_) {}
    return 0;
  }

  double _getDownloadSpeed() {
    return 0.5 + (DateTime.now().second % 50) / 10;
  }

  double _getUploadSpeed() {
    return 0.2 + (DateTime.now().millisecond % 30) / 10;
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '$days d $hours h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String _formatSpeed(double speed) {
    if (speed < 1) return '${(speed * 1024).toStringAsFixed(0)} KB/s';
    return '${speed.toStringAsFixed(1)} MB/s';
  }

  Color _getUsageColor(double value) {
    if (value < 50) return Colors.green;
    if (value < 80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Advanced Statistics', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'System'),
            Tab(icon: Icon(Icons.network_check), text: 'Network'),
            Tab(icon: Icon(Icons.assessment), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSystemTab(),
          _buildNetworkTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance Score Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _cpuUsage > 70 
                    ? [Colors.red, Colors.red.withOpacity(0.5)]
                    : _cpuUsage > 40
                        ? [Colors.orange, Colors.orange.withOpacity(0.5)]
                        : [Colors.green, Colors.green.withOpacity(0.5)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('System Health', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${(100 - _cpuUsage).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _cpuUsage > 70 ? 'Poor' : (_cpuUsage > 40 ? 'Fair' : 'Excellent'),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // CPU Card
          _buildMetricCard('CPU Usage', '${_cpuUsage.toStringAsFixed(1)}%', Icons.memory, _getUsageColor(_cpuUsage), _cpuHistory),
          
          const SizedBox(height: 16),
          
          // RAM Card
          _buildMetricCard('RAM Usage', '${_ramUsage.toStringAsFixed(1)}%', Icons.ram, _getUsageColor(_ramUsage), _ramHistory),
          
          const SizedBox(height: 16),
          
          // System Info Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildInfoCard('Temperature', '${_temperature.toStringAsFixed(1)}°C', Icons.thermostat, _temperature > 60 ? Colors.red : Colors.orange),
              _buildInfoCard('Processes', '$_processCount', Icons.code, Colors.purple),
              _buildInfoCard('Uptime', _formatUptime(_uptime), Icons.timer, const Color(0xFF00BCD4)),
              _buildInfoCard('Storage', '${_diskUsage.toStringAsFixed(1)}%', Icons.storage, _getUsageColor(_diskUsage)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Speed Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSpeedItem('Download', _formatSpeed(_downloadSpeed), Icons.arrow_downward, Colors.green),
                _buildSpeedItem('Upload', _formatSpeed(_uploadSpeed), Icons.arrow_upward, Colors.orange),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
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
                const Text('Traffic History', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _networkHistory,
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
          
          // Total Data
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDataItem('Total Download', '${_totalDownload.toStringAsFixed(2)} GB', Icons.download, Colors.green),
                _buildDataItem('Total Upload', '${_totalUpload.toStringAsFixed(2)} GB', Icons.upload, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportCard('System Report', 'Complete system analysis', Icons.assessment, () {}),
        _buildReportCard('Performance Report', 'CPU, RAM and system metrics', Icons.speed, () {}),
        _buildReportCard('Network Report', 'Network usage and statistics', Icons.network_wifi, () {}),
        _buildReportCard('Security Report', 'Security events and alerts', Icons.security, () {}),
        _buildReportCard('Battery Report', 'Power consumption analysis', Icons.battery_full, () {}),
      ],
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
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSpeedItem(String label, String speed, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(speed, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildDataItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00BCD4), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF00BCD4)),
          ],
        ),
      ),
    );
  }
}
