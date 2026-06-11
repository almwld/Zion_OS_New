import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class ProcessManagerApp extends StatefulWidget {
  const ProcessManagerApp({super.key});

  @override
  State<ProcessManagerApp> createState() => _ProcessManagerAppState();
}

class _ProcessManagerAppState extends State<ProcessManagerApp> {
  List<Map<String, dynamic>> _processes = [];
  List<Map<String, dynamic>> _filteredProcesses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'cpu';
  bool _sortAscending = false;
  int _selectedTab = 0;
  Timer? _refreshTimer;
  
  // إحصائيات
  int _totalProcesses = 0;
  double _avgCpu = 0;
  double _avgMem = 0;
  int _systemProcesses = 0;
  int _userProcesses = 0;

  @override
  void initState() {
    super.initState();
    _loadProcesses();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadProcesses();
    });
  }

  Future<void> _loadProcesses() async {
    try {
      final result = await Process.run('ps', ['-e', '-o', 'pid,ppid,user,%cpu,%mem,vsz,rss,cmd'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      
      final List<Map<String, dynamic>> processes = [];
      for (var i = 1; i < lines.length && i < 100; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 8) {
          final cpu = double.tryParse(parts[3]) ?? 0;
          final mem = double.tryParse(parts[4]) ?? 0;
          final name = parts.sublist(7).join(' ').split('/').last;
          final user = parts[2];
          
          processes.add({
            'pid': parts[0],
            'ppid': parts[1],
            'user': user,
            'cpu': cpu,
            'mem': mem,
            'vsz': parts[5],
            'rss': parts[6],
            'name': name,
            'fullName': parts.sublist(7).join(' '),
            'isSystem': user == 'root' || user == 'system',
          });
        }
      }
      
      _totalProcesses = processes.length;
      _avgCpu = processes.fold<double>(0, (s, p) => s + p['cpu']) / processes.length;
      _avgMem = processes.fold<double>(0, (s, p) => s + p['mem']) / processes.length;
      _systemProcesses = processes.where((p) => p['isSystem']).length;
      _userProcesses = _totalProcesses - _systemProcesses;
      
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

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_processes);
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
        p['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p['pid'].toString().contains(_searchQuery) ||
        p['user'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_selectedTab == 1) {
      filtered = filtered.where((p) => p['cpu'] > 10).toList();
    } else if (_selectedTab == 2) {
      filtered = filtered.where((p) => p['mem'] > 20).toList();
    } else if (_selectedTab == 3) {
      filtered = filtered.where((p) => p['isSystem']).toList();
    } else if (_selectedTab == 4) {
      filtered = filtered.where((p) => !p['isSystem']).toList();
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
        case 'pid':
          comparison = int.parse(a['pid']).compareTo(int.parse(b['pid']));
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

  Future<void> _killProcess(String pid, String name) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Process', style: TextStyle(color: Color(0xFF00BCD4))),
        content: Text('Kill process $name (PID: $pid)?\n⚠️ Terminating system processes may cause instability.', style: const TextStyle(color: Colors.white)),
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

  Future<void> _reniceProcess(String pid, int priority) async {
    try {
      await Process.run('renice', ['-n', priority.toString(), '-p', pid], runInShell: true);
      _loadProcesses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Process priority changed'), backgroundColor: const Color(0xFF00BCD4)),
      );
    } catch (_) {}
  }

  void _showProcessDetails(Map<String, dynamic> process) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Process Details', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Process Name', process['name']),
            _buildDetailRow('PID', process['pid']),
            _buildDetailRow('Parent PID', process['ppid']),
            _buildDetailRow('User', process['user']),
            _buildDetailRow('CPU Usage', '${process['cpu'].toStringAsFixed(1)}%'),
            _buildDetailRow('Memory Usage', '${process['mem'].toStringAsFixed(1)}%'),
            _buildDetailRow('Virtual Size', process['vsz']),
            _buildDetailRow('RSS', process['rss']),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reniceProcess(process['pid'], 19),
                    icon: const Icon(Icons.speed),
                    label: const Text('Lower Priority'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _killProcess(process['pid'], process['name']),
                    icon: const Icon(Icons.stop),
                    label: const Text('Terminate'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Process Manager', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: _loadProcesses,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Stats Bar
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Processes', '$_totalProcesses', Icons.code),
                    _buildStatItem('Avg CPU', '${_avgCpu.toStringAsFixed(1)}%', Icons.memory),
                    _buildStatItem('Avg RAM', '${_avgMem.toStringAsFixed(1)}%', Icons.memory),
                    _buildStatItem('System', '$_systemProcesses', Icons.computer),
                    _buildStatItem('User', '$_userProcesses', Icons.person),
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
                isScrollable: true,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'High CPU'),
                  Tab(text: 'High RAM'),
                  Tab(text: 'System'),
                  Tab(text: 'User'),
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
                hintText: 'Search by name, PID or user...',
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
                _buildSortChip('PID', 'pid'),
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
                          final cpuColor = process['cpu'] > 50 ? Colors.red : 
                                          process['cpu'] > 20 ? Colors.orange : Colors.green;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: process['isSystem'] 
                                  ? Colors.purple.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: process['isSystem']
                                  ? Border.all(color: Colors.purple.withOpacity(0.3))
                                  : null,
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: process['isSystem'] 
                                      ? Colors.purple.withOpacity(0.2)
                                      : const Color(0xFF00BCD4).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  process['isSystem'] ? Icons.computer : Icons.code,
                                  color: process['isSystem'] ? Colors.purple : const Color(0xFF00BCD4),
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
                                    icon: const Icon(Icons.info_outline, color: Color(0xFF00BCD4), size: 18),
                                    onPressed: () => _showProcessDetails(process),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.stop, color: Colors.red, size: 18),
                                    onPressed: () => _killProcess(process['pid'], process['name']),
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
        Text(value, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 14, fontWeight: FontWeight.bold)),
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
}
