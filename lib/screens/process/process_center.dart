import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class ProcessCenter extends StatefulWidget {
  const ProcessCenter({super.key});

  @override
  State<ProcessCenter> createState() => _ProcessCenterState();
}

class _ProcessCenterState extends State<ProcessCenter> {
  List<Map<String, dynamic>> _processes = [];
  List<Map<String, dynamic>> _filteredProcesses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'cpu';
  bool _sortAscending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadProcesses();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadProcesses();
    });
  }

  Future<void> _loadProcesses() async {
    try {
      final result = await Process.run('ps', ['-e', '-o', 'pid,ppid,user,%cpu,%mem,vsz,rss,cmd'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      
      final List<Map<String, dynamic>> processes = [];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 8) {
          processes.add({
            'pid': parts[0],
            'ppid': parts[1],
            'user': parts[2],
            'cpu': double.tryParse(parts[3]) ?? 0,
            'mem': double.tryParse(parts[4]) ?? 0,
            'vsz': parts[5],
            'rss': parts[6],
            'name': parts.sublist(7).join(' '),
            'selected': false,
          });
        }
      }
      
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
        p['pid'].toString().contains(_searchQuery)
      ).toList();
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
        case 'pid':
          comparison = int.parse(a['pid']).compareTo(int.parse(b['pid']));
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
        content: Text('Kill process $name (PID: $pid)?', style: const TextStyle(color: Colors.white)),
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
          SnackBar(content: Text('Process $name terminated'), backgroundColor: Color(0xFF00BCD4)),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to terminate process'), backgroundColor: Colors.red),
        );
      }
    }
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _killProcess(process['pid'], process['name']);
                },
                icon: const Icon(Icons.stop),
                label: const Text('Terminate Process'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
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
    final totalCpu = _processes.fold<double>(0, (sum, p) => sum + p['cpu']);
    final totalMem = _processes.fold<double>(0, (sum, p) => sum + p['mem']);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Process Control Center', style: TextStyle(color: Color(0xFF00BCD4))),
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
      ),
      body: Column(
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
                _buildStatItem('Processes', _processes.length.toString()),
                _buildStatItem('Total CPU', '${totalCpu.toStringAsFixed(1)}%'),
                _buildStatItem('Total RAM', '${totalMem.toStringAsFixed(1)}%'),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Sort by:', style: TextStyle(color: Colors.white54)),
                const SizedBox(width: 10),
                _buildSortChip('CPU', 'cpu'),
                _buildSortChip('Memory', 'mem'),
                _buildSortChip('Name', 'name'),
                _buildSortChip('PID', 'pid'),
                const Spacer(),
                IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: Color(0xFF00BCD4), size: 18),
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
          
          const SizedBox(height: 10),
          
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
                                          process['cpu'] > 25 ? Colors.orange : Colors.green;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.code, color: Color(0xFF00BCD4), size: 20),
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
                                    icon: const Icon(Icons.stop, color: Colors.red, size: 18),
                                    onPressed: () => _killProcess(process['pid'], process['name']),
                                  ),
                                ],
                              ),
                              onTap: () => _showProcessDetails(process),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF00BCD4).withOpacity(0.3),
          ),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF00BCD4) : Colors.white54, fontSize: 11)),
      ),
    );
  }
}
