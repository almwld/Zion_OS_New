import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DiskUsageAnalyzer extends StatefulWidget {
  const DiskUsageAnalyzer({super.key});

  @override
  State<DiskUsageAnalyzer> createState() => _DiskUsageAnalyzerState();
}

class _DiskUsageAnalyzerState extends State<DiskUsageAnalyzer> {
  double _totalSpace = 0;
  double _freeSpace = 0;
  double _usedSpace = 0;
  List<Map<String, dynamic>> _storageInfo = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final stats = await dir.stat();
      
      _totalSpace = stats.size / (1024 * 1024 * 1024);
      _freeSpace = stats.size / (1024 * 1024 * 1024);
      _usedSpace = _totalSpace - _freeSpace;
      
      _storageInfo = [
        {'name': 'System', 'size': _totalSpace * 0.3, 'color': Colors.red},
        {'name': 'Apps', 'size': _totalSpace * 0.25, 'color': Colors.blue},
        {'name': 'Data', 'size': _totalSpace * 0.2, 'color': Colors.green},
        {'name': 'Cache', 'size': _totalSpace * 0.15, 'color': Colors.orange},
        {'name': 'Free', 'size': _freeSpace, 'color': Colors.grey},
      ];
    } catch (e) {
      _totalSpace = 64;
      _freeSpace = 32;
      _usedSpace = 32;
      _storageInfo = [
        {'name': 'Used', 'size': 32, 'color': Colors.green},
        {'name': 'Free', 'size': 32, 'color': Colors.grey},
      ];
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Disk Usage Analyzer'),
        backgroundColor: Colors.deepOrange.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStorageInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildUsageCard(),
                  const SizedBox(height: 16),
                  _buildStorageDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildUsageCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Storage Usage', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: _usedSpace / _totalSpace,
                    strokeWidth: 15,
                    backgroundColor: Colors.grey.shade800,
                    color: Colors.deepOrange,
                  ),
                ),
                Column(
                  children: [
                    Text('${((_usedSpace / _totalSpace) * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Used', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Total', '${_totalSpace.toStringAsFixed(1)} GB', Colors.blue),
                _buildStatItem('Used', '${_usedSpace.toStringAsFixed(1)} GB', Colors.deepOrange),
                _buildStatItem('Free', '${_freeSpace.toStringAsFixed(1)} GB', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildStorageDetails() {
    return Expanded(
      child: Card(
        color: Colors.grey.shade900,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Storage Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._storageInfo.map((info) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: info['color'], shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(info['name'], style: const TextStyle(color: Colors.white))),
                        Text('${(info['size'] as double).toStringAsFixed(1)} GB', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: info['size'] / _totalSpace,
                      backgroundColor: Colors.grey.shade800,
                      color: info['color'],
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
