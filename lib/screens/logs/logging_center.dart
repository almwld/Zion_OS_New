import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/logging_service.dart';

class LoggingCenter extends StatefulWidget {
  const LoggingCenter({super.key});

  @override
  State<LoggingCenter> createState() => _LoggingCenterState();
}

class _LoggingCenterState extends State<LoggingCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LogLevel? _selectedFilter;
  String _searchQuery = '';
  
  final List<LogLevel> _filterOptions = [
    LogLevel.info,
    LogLevel.warning,
    LogLevel.error,
    LogLevel.success,
    LogLevel.security,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<LoggingService>(context);
    final stats = service.getLogStatistics();
    final logs = service.getLogs(level: _selectedFilter);
    
    final filteredLogs = _searchQuery.isEmpty
        ? logs
        : logs.where((log) =>
            log['message'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            log['source'].toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Logging & Audit', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF00BCD4)),
            onPressed: () => service.exportLogs(),
            tooltip: 'Export logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Color(0xFF00BCD4)),
            onPressed: () => _clearLogs(service),
            tooltip: 'Clear all logs',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Logs'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogsTab(service, filteredLogs),
          _buildStatisticsTab(stats),
        ],
      ),
    );
  }
  
  Widget _buildLogsTab(LoggingService service, List<Map<String, dynamic>> logs) {
    return Column(
      children: [
        // Search and Filter
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                  hintText: 'Search logs...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('ALL', style: TextStyle(color: Color(0xFF00BCD4))),
                      selected: _selectedFilter == null,
                      onSelected: (_) => setState(() => _selectedFilter = null),
                      backgroundColor: Colors.transparent,
                      selectedColor: const Color(0xFF00BCD4).withOpacity(0.2),
                    ),
                    const SizedBox(width: 8),
                    ..._filterOptions.map((filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter.toString().split('.').last.toUpperCase(), style: TextStyle(color: _getFilterColor(filter))),
                        selected: _selectedFilter == filter,
                        onSelected: (_) => setState(() => _selectedFilter = _selectedFilter == filter ? null : filter),
                        backgroundColor: Colors.transparent,
                        selectedColor: _getFilterColor(filter).withOpacity(0.2),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const Divider(color: Color(0xFF00BCD4), height: 1),
        
        // Logs List
        Expanded(
          child: logs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('No logs found', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final level = LogLevel.values.firstWhere(
                      (e) => e.toString().split('.').last == log['level'],
                      orElse: () => LogLevel.info,
                    );
                    final color = _getFilterColor(level);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(level.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(log['message'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log['level'].toUpperCase(),
                                  style: TextStyle(color: color, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(log['source'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              const Spacer(),
                              Text(_formatDate(log['timestamp']), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                          if (log['data'] != null && (log['data'] as Map).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  jsonEncode(log['data']),
                                  style: const TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildStatisticsTab(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Total Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Total Logs', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 10),
                Text('${stats['total']}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('Info', stats['info'], LogLevel.info),
              _buildStatCard('Warning', stats['warning'], LogLevel.warning),
              _buildStatCard('Error', stats['error'], LogLevel.error),
              _buildStatCard('Success', stats['success'], LogLevel.success),
              _buildStatCard('Security', stats['security'], LogLevel.security),
              _buildStatCard('Total', stats['total'], null),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Actions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportLogs(),
              icon: const Icon(Icons.download),
              label: const Text('Export All Logs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, int count, LogLevel? level) {
    final color = level != null ? _getFilterColor(level) : const Color(0xFF00BCD4);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Text('$count', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Color _getFilterColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return const Color(0xFF00BCD4);
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.success:
        return Colors.green;
      case LogLevel.debug:
        return Colors.purple;
      case LogLevel.security:
        return const Color(0xFFFF5722);
    }
  }
  
  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')} ${date.day}/${date.month}';
  }
  
  Future<void> _clearLogs(LoggingService service) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs', style: TextStyle(color: Color(0xFF00BCD4))),
        content: const Text('Delete all logs? This action cannot be undone.', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      await service.clearLogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs cleared'), backgroundColor: Color(0xFF00BCD4)),
      );
    }
  }
  
  Future<void> _exportLogs() async {
    final service = Provider.of<LoggingService>(context, listen: false);
    await service.exportLogs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs exported'), backgroundColor: Color(0xFF00BCD4)),
    );
  }
}

// Helper function for JSON encoding
String jsonEncode(Map<String, dynamic> data) {
  return data.toString();
}
