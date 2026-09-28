import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';

class StatisticsCenter extends StatefulWidget {
  const StatisticsCenter({super.key});

  @override
  State<StatisticsCenter> createState() => _StatisticsCenterState();
}

class _StatisticsCenterState extends State<StatisticsCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 0;
  final List<String> _periods = ['Today', 'Week', 'Month', 'Year'];
  
  // إحصائيات النظام
  double _totalUptime = 0;
  int _totalScans = 0;
  int _totalAttacks = 0;
  int _totalDetections = 0;
  double _avgCpuLoad = 0;
  double _avgMemUsage = 0;
  
  // بيانات الرسم البياني
  List<FlSpot> _cpuSpots = [];
  List<FlSpot> _ramSpots = [];
  List<FlSpot> _networkSpots = [];
  
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
    _initChartData();
    _startStatsUpdate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statsTimer?.cancel();
    super.dispose();
  }

  void _startStatsUpdate() {
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateLiveStats();
    });
  }

  void _loadStatistics() {
    // محاكاة تحميل الإحصائيات
    _totalUptime = 247; // ساعات
    _totalScans = 1542;
    _totalAttacks = 89;
    _totalDetections = 234;
    _avgCpuLoad = 32.5;
    _avgMemUsage = 45.8;
  }

  void _updateLiveStats() {
    setState(() {
      _avgCpuLoad = 25 + (DateTime.now().second % 30);
      _avgMemUsage = 40 + (DateTime.now().millisecond % 20);
    });
  }

  void _initChartData() {
    for (int i = 0; i < 12; i++) {
      _cpuSpots.add(FlSpot(i.toDouble(), 20 + (i * 2.5) % 40));
      _ramSpots.add(FlSpot(i.toDouble(), 30 + (i * 1.8) % 35));
      _networkSpots.add(FlSpot(i.toDouble(), 10 + (i * 3) % 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Statistics & Reports', style: TextStyle(color: Color(0xFF00BCD4))),
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
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.show_chart), text: 'Charts'),
            Tab(icon: Icon(Icons.report), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildChartsTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('Uptime', '${(_totalUptime / 24).toStringAsFixed(1)} days', Icons.timer, const Color(0xFF00BCD4)),
              _buildStatCard('Total Scans', _totalScans.toString(), Icons.scanner, const Color(0xFF4CAF50)),
              _buildStatCard('Attacks', _totalAttacks.toString(), Icons.flash_on, const Color(0xFFFF5722)),
              _buildStatCard('Detections', _totalDetections.toString(), Icons.security, const Color(0xFF9C27B0)),
              _buildStatCard('Avg CPU', '${_avgCpuLoad.toStringAsFixed(1)}%', Icons.memory, const Color(0xFFFF9800)),
              _buildStatCard('Avg RAM', '${_avgMemUsage.toStringAsFixed(1)}%', Icons.memory, const Color(0xFF2196F3)),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Quick Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Statistics', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildQuickStat(Icons.speed, 'Peak CPU', '78%', Colors.red),
                _buildQuickStat(Icons.storage, 'Disk Used', '42.5 GB', Colors.orange),
                _buildQuickStat(Icons.cloud, 'Network', '125 MB/s', Colors.green),
                _buildQuickStat(Icons.devices, 'Active Sessions', '3', const Color(0xFF00BCD4)),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Period Selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_periods.length, (index) {
                final isSelected = _selectedPeriod == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _periods[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // CPU Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CPU Usage Trend', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RAM Usage Trend', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _ramSpots,
                          isCurved: true,
                          color: const Color(0xFF4CAF50),
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
          
          // Network Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Network Traffic', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _networkSpots,
                          isCurved: true,
                          color: const Color(0xFFFF9800),
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
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportCard(
          'System Report',
          'Complete system analysis and statistics',
          '2025-04-15',
          'PDF',
          Icons.assessment,
        ),
        _buildReportCard(
          'Security Report',
          'Threat detection and security events',
          '2025-04-14',
          'PDF',
          Icons.security,
        ),
        _buildReportCard(
          'Network Report',
          'Network activity and bandwidth usage',
          '2025-04-13',
          'CSV',
          Icons.network_wifi,
        ),
        _buildReportCard(
          'Performance Report',
          'CPU, RAM and system performance',
          '2025-04-12',
          'JSON',
          Icons.speed,
        ),
        _buildReportCard(
          'Attack Log',
          'Detailed attack attempts and results',
          '2025-04-11',
          'LOG',
          Icons.flash_on,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), Colors.black],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white54))),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String description, String date, String format, IconData icon) {
    return Container(
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
            child: Icon(icon, color: const Color(0xFF00BCD4), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                Text('$date • $format', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text('Download', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
