import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/reports_service.dart';

class ReportsAnalyticsCenter extends StatefulWidget {
  const ReportsAnalyticsCenter({super.key});

  @override
  State<ReportsAnalyticsCenter> createState() => _ReportsAnalyticsCenterState();
}

class _ReportsAnalyticsCenterState extends State<ReportsAnalyticsCenter> with SingleTickerProviderStateMixin {
  late ReportsService _reportsService;
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _reportsService = ReportsService();
    _reportsService.init();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _reportsService.getDashboardStats();
    final reports = _reportsService.getReports();
    final filteredReports = _selectedFilter == 'all' 
        ? reports 
        : reports.where((r) => r['type'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: () => setState(() {}),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Color(0xFF00BCD4)),
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Reports')),
              const PopupMenuItem(value: 'scan', child: Text('Scans')),
              const PopupMenuItem(value: 'attack', child: Text('Attacks')),
              const PopupMenuItem(value: 'detection', child: Text('Detections')),
              const PopupMenuItem(value: 'backup', child: Text('Backups')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.list), text: 'Reports'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(stats),
          _buildReportsTab(filteredReports),
          _buildStatisticsTab(),
        ],
      ),
    );
  }
  
  Widget _buildDashboardTab(Map<String, dynamic> stats) {
    final barGroups = [
      BarChartGroupData(x: 0, barRods: [BarRod(toY: (stats['scans'] as int).toDouble(), color: Colors.blue, width: 20)]),
      BarChartGroupData(x: 1, barRods: [BarRod(toY: (stats['attacks'] as int).toDouble(), color: Colors.red, width: 20)]),
      BarChartGroupData(x: 2, barRods: [BarRod(toY: (stats['detections'] as int).toDouble(), color: Colors.orange, width: 20)]),
      BarChartGroupData(x: 3, barRods: [BarRod(toY: (stats['backups'] as int).toDouble(), color: Colors.green, width: 20)]),
    ];

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
              _buildStatCard('Total Reports', '${stats['total_reports']}', Icons.assessment, const Color(0xFF00BCD4)),
              _buildStatCard('Scans', '${stats['scans']}', Icons.scanner, Colors.blue),
              _buildStatCard('Attacks', '${stats['attacks']}', Icons.flash_on, Colors.red),
              _buildStatCard('Detections', '${stats['detections']}', Icons.security, Colors.orange),
              _buildStatCard('Backups', '${stats['backups']}', Icons.backup, Colors.green),
              _buildStatCard('Uptime', _formatUptime(247), Icons.timer, Colors.purple),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Bar Chart
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
                const Text('Activity Overview', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (barGroups.map((g) => g.barRods.first.toY).reduce((a,b) => a > b ? a : b) + 10),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const titles = ['Scans', 'Attacks', 'Detections', 'Backups'];
                              if (value.toInt() >= 0 && value.toInt() < titles.length) {
                                return Text(titles[value.toInt()], style: const TextStyle(color: Colors.white54, fontSize: 10));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
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
  
  Widget _buildReportsTab(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No reports found', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getTypeIcon(report['type']), color: _getTypeColor(report['type']), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      report['title'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTypeColor(report['type']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      report['type'].toUpperCase(),
                      style: TextStyle(color: _getTypeColor(report['type']), fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_formatDate(report['timestamp']), style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _exportReport(report['id']),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF00BCD4)),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteReport(report['id']),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatisticsTab() {
    final stats = _reportsService.getStatistics();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatDetailCard('Total Scans', '${stats['total_scans'] ?? 0}', Icons.scanner, Colors.blue),
        _buildStatDetailCard('Total Attacks', '${stats['total_attacks'] ?? 0}', Icons.flash_on, Colors.red),
        _buildStatDetailCard('Total Detections', '${stats['total_detections'] ?? 0}', Icons.security, Colors.orange),
        _buildStatDetailCard('Total Backups', '${stats['total_backups'] ?? 0}', Icons.backup, Colors.green),
        _buildStatDetailCard('Last Scan', stats['last_scan'] != null ? _formatDate(stats['last_scan']) : 'Never', Icons.history, Colors.blue),
        _buildStatDetailCard('Last Attack', stats['last_attack'] != null ? _formatDate(stats['last_attack']) : 'Never', Icons.history, Colors.red),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.1), Colors.black]),
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
  
  Widget _buildStatDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54)),
                Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'scan': return Icons.scanner;
      case 'attack': return Icons.flash_on;
      case 'detection': return Icons.security;
      case 'backup': return Icons.backup;
      default: return Icons.assessment;
    }
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'scan': return Colors.blue;
      case 'attack': return Colors.red;
      case 'detection': return Colors.orange;
      case 'backup': return Colors.green;
      default: return const Color(0xFF00BCD4);
    }
  }
  
  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatUptime(int hours) {
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    if (days > 0) return '$days d $remainingHours h';
    return '$hours h';
  }
  
  Future<void> _exportReport(String reportId) async {
    await _reportsService.exportReport(reportId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report exported'), backgroundColor: Color(0xFF00BCD4)),
    );
  }
  
  Future<void> _deleteReport(String reportId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report', style: TextStyle(color: Color(0xFF00BCD4))),
        content: const Text('Are you sure you want to delete this report?', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _reportsService.deleteReport(reportId);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted'), backgroundColor: Color(0xFF00BCD4)),
      );
    }
  }
}
