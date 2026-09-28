import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  List<Map<String, dynamic>> _processes = [];
  List<Map<String, dynamic>> _filteredProcesses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'cpu';
  bool _sortAscending = false;
  int _selectedTab = 0;
  Timer? _refreshTimer;
  Timer? _autoOptimizeTimer;
  
  // إحصائيات الأداء
  double _totalCpu = 0;
  double _totalMem = 0;
  int _criticalProcesses = 0;
  int _optimizedCount = 0;
  bool _autoOptimize = true;
  String _optimizationStatus = 'مراقبة النظام...';

  @override
  void initState() {
    super.initState();
    _loadProcesses();
    _startAutoRefresh();
    _startAutoOptimize();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _autoOptimizeTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadProcesses();
    });
  }

  void _startAutoOptimize() {
    _autoOptimizeTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_autoOptimize) {
        _autoOptimizeSystem();
      }
    });
  }

  Future<void> _loadProcesses() async {
    try {
      final result = await Process.run('ps', ['-e', '-o', 'pid,ppid,user,%cpu,%mem,cmd'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      
      final List<Map<String, dynamic>> processes = [];
      for (var i = 1; i < lines.length && i < 80; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 6) {
          final cpu = double.tryParse(parts[3]) ?? 0;
          final mem = double.tryParse(parts[4]) ?? 0;
          processes.add({
            'pid': parts[0],
            'ppid': parts[1],
            'user': parts[2],
            'cpu': cpu,
            'mem': mem,
            'name': parts.sublist(5).join(' ').split('/').last,
            'fullName': parts.sublist(5).join(' '),
            'critical': cpu > 30 || mem > 50,
          });
        }
      }
      
      _totalCpu = processes.fold<double>(0, (sum, p) => sum + p['cpu']);
      _totalMem = processes.fold<double>(0, (sum, p) => sum + p['mem']);
      _criticalProcesses = processes.where((p) => p['critical']).length;
      
      setState(() {
        _processes = processes;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _autoOptimizeSystem() async {
    final highCpuProcesses = _processes.where((p) => 
      p['cpu'] > 25 && 
      !p['name'].contains('system') && 
      !p['name'].contains('kernel') &&
      !p['name'].contains('Zion') &&
      p['user'] != 'root'
    ).toList();
    
    if (highCpuProcesses.isEmpty) {
      setState(() {
        _optimizationStatus = '✅ النظام يعمل بكفاءة عالية';
      });
      return;
    }
    
    setState(() {
      _optimizationStatus = '🔄 تحسين الأداء... جاري معالجة ${highCpuProcesses.length} عملية';
    });
    
    int optimized = 0;
    for (final process in highCpuProcesses.take(3)) {
      try {
        await Process.run('renice', ['-n', '19', '-p', process['pid']], runInShell: true);
        optimized++;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    setState(() {
      _optimizedCount = optimized;
      _optimizationStatus = '✅ تم تحسين $optimized عملية - حرر ${(highCpuProcesses.fold<double>(0, (s, p) => s + p['cpu']) / 10).toStringAsFixed(1)}% من المعالج';
    });
  }

  Future<void> _killProcess(String pid, String name) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Process', style: TextStyle(color: Color(0xFF00BCD4))),
        content: Text('Kill process $name (PID: $pid)?\n⚠️ This may affect system stability.', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kill', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await Process.run('kill', ['-9', pid], runInShell: true);
        _loadProcesses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Process $name terminated'), backgroundColor: const Color(0xFF00BCD4)),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to terminate process'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _optimizeSingleProcess(Map<String, dynamic> process) async {
    try {
      await Process.run('renice', ['-n', '19', '-p', process['pid']], runInShell: true);
      _loadProcesses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Process ${process['name']} optimized'), backgroundColor: const Color(0xFF00BCD4)),
      );
    } catch (_) {}
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_processes);
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
        p['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p['pid'].toString().contains(_searchQuery)
      ).toList();
    }
    
    if (_selectedTab == 1) {
      filtered = filtered.where((p) => p['cpu'] > 15).toList();
    } else if (_selectedTab == 2) {
      filtered = filtered.where((p) => p['mem'] > 20).toList();
    } else if (_selectedTab == 3) {
      filtered = filtered.where((p) => p['critical']).toList();
    }
    
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'cpu':
          comparison = a['cpu'].compareTo(b['cpu']);
          break;
        case 'mem':
          comparison = a['mem'].compareTo(b['mem']);
          break;
        case 'name':
          comparison = a['name'].compareTo(b['name']);
          break;
        default:
          comparison = a['cpu'].compareTo(b['cpu']);
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _filteredProcesses = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final performanceScore = ((100 - (_totalCpu / _processes.length).clamp(0, 100)) * 0.7 + 
                              (100 - (_totalMem / _processes.length).clamp(0, 100)) * 0.3).toInt();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Smart Task Manager', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Switch(
            value: _autoOptimize,
            onChanged: (v) => setState(() => _autoOptimize = v),
            activeColor: const Color(0xFF00BCD4),
          ),
          const Text('Auto', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: _loadProcesses,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Performance Card
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPerformanceColor(performanceScore),
                      _getPerformanceColor(performanceScore).withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('System Health', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('$performanceScore%', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: performanceScore / 100,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _optimizationStatus,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    if (_optimizedCount > 0)
                      Text(
                        '🔄 تم تحسين $_optimizedCount عملية',
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 10),
                      ),
                  ],
                ),
              ),
              
              // Stats Bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Processes', _processes.length.toString(), Icons.code),
                    _buildStatItem('CPU', '${_totalCpu.toStringAsFixed(1)}%', Icons.memory),
                    _buildStatItem('RAM', '${_totalMem.toStringAsFixed(1)}%', Icons.memory),
                    _buildStatItem('Critical', '$_criticalProcesses', Icons.warning),
                  ],
                ),
              ),
              
              // Tabs
              TabBar(
                onTap: (index) => setState(() {
                  _selectedTab = index;
                  _applyFilters();
                }),
                labelColor: const Color(0xFF00BCD4),
                unselectedLabelColor: Colors.white54,
                indicatorColor: const Color(0xFF00BCD4),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'High CPU'),
                  Tab(text: 'High RAM'),
                  Tab(text: 'Critical'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                hintText: 'Search by name or PID...',
                hintStyle: const TextStyle(color: Colors.white38),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF00BCD4)),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          // Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Sort by:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 8),
                _buildSortChip('CPU', 'cpu'),
                _buildSortChip('RAM', 'mem'),
                _buildSortChip('Name', 'name'),
                const Spacer(),
                IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: const Color(0xFF00BCD4), size: 18),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Process List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
                : _filteredProcesses.isEmpty
                    ? const Center(child: Text('No processes found', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: _filteredProcesses.length,
                        itemBuilder: (context, index) {
                          final process = _filteredProcesses[index];
                          final cpuColor = process['cpu'] > 40 ? Colors.red : 
                                          process['cpu'] > 20 ? Colors.orange : Colors.green;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: process['critical'] 
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: process['critical']
                                  ? Border.all(color: Colors.red.withOpacity(0.3))
                                  : null,
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  process['critical'] ? Icons.warning : Icons.code,
                                  color: process['critical'] ? Colors.red : const Color(0xFF00BCD4),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                process['name'],
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'PID: ${process['pid']} | User: ${process['user']}',
                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (process['cpu'] > 15)
                                    IconButton(
                                      icon: const Icon(Icons.speed, color: Color(0xFF00BCD4), size: 18),
                                      onPressed: () => _optimizeSingleProcess(process),
                                      tooltip: 'Optimize',
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cpuColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${process['cpu'].toStringAsFixed(1)}%',
                                      style: TextStyle(color: cpuColor, fontSize: 10),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00BCD4).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${process['mem'].toStringAsFixed(1)}%',
                                      style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 10),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.stop, color: Colors.red, size: 18),
                                    onPressed: () => _killProcess(process['pid'], process['name']),
                                    tooltip: 'Terminate',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00BCD4), size: 16),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _applyFilters();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF00BCD4).withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00BCD4) : Colors.white54,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Color _getPerformanceColor(int score) {
    if (score > 80) return Colors.green;
    if (score > 50) return Colors.orange;
    return Colors.red;
  }
}
