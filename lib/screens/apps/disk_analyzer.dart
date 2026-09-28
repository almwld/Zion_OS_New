import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class DiskAnalyzerApp extends StatefulWidget {
  const DiskAnalyzerApp({super.key});

  @override
  State<DiskAnalyzerApp> createState() => _DiskAnalyzerAppState();
}

class _DiskAnalyzerAppState extends State<DiskAnalyzerApp> {
  List<Map<String, dynamic>> _storageInfo = [];
  List<Map<String, dynamic>> _largeFiles = [];
  Map<String, double> _storageChart = {};
  bool _isScanning = false;
  String _scanPath = '/sdcard';
  double _totalStorage = 0;
  double _usedStorage = 0;
  double _freeStorage = 0;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final result = await Process.run('df', ['-h'], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      
      _storageInfo.clear();
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 6) {
          final usage = parts[4].replaceAll('%', '');
          _storageInfo.add({
            'device': parts[0],
            'size': parts[1],
            'used': parts[2],
            'available': parts[3],
            'usage': int.tryParse(usage) ?? 0,
            'mounted': parts[5],
          });
        }
      }
      
      if (_storageInfo.isNotEmpty) {
        final mainStorage = _storageInfo.firstWhere(
          (s) => s['mounted'] == '/data' || s['mounted'] == '/',
          orElse: () => _storageInfo.first,
        );
        _totalStorage = _parseSize(mainStorage['size']);
        _usedStorage = _parseSize(mainStorage['used']);
        _freeStorage = _parseSize(mainStorage['available']);
        
        _storageChart = {
          'Used': _usedStorage,
          'Free': _freeStorage,
        };
      }
      
      setState(() {});
    } catch (_) {}
  }

  double _parseSize(String size) {
    if (size.contains('G')) return double.parse(size.replaceAll('G', ''));
    if (size.contains('M')) return double.parse(size.replaceAll('M', '')) / 1024;
    if (size.contains('T')) return double.parse(size.replaceAll('T', '')) * 1024;
    return 0;
  }

  Future<void> _scanLargeFiles() async {
    setState(() {
      _isScanning = true;
      _largeFiles.clear();
    });

    try {
      final result = await Process.run('find', [_scanPath, '-type', 'f', '-size', '+10M'], runInShell: true);
      final files = result.stdout.toString().split('\n');
      
      for (final file in files) {
        if (file.isNotEmpty && await File(file).exists()) {
          try {
            final stat = await File(file).stat();
            if (stat.size > 10 * 1024 * 1024) {
              _largeFiles.add({
                'path': file,
                'name': file.split('/').last,
                'size': stat.size,
                'sizeFormatted': _formatSize(stat.size),
              });
            }
          } catch (_) {}
        }
        if (_largeFiles.length > 50) break;
      }
      
      _largeFiles.sort((a, b) => b['size'].compareTo(a['size']));
    } catch (_) {}

    setState(() {
      _isScanning = false;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Color _getUsageColor(int usage) {
    if (usage < 50) return Colors.green;
    if (usage < 80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final pieSections = _storageChart.entries.map((entry) => PieChartSectionData(
      value: entry.value,
      title: '${entry.key}\n${entry.value.toStringAsFixed(1)} GB',
      color: entry.key == 'Used' ? const Color(0xFF00BCD4) : Colors.grey,
      radius: 80,
      titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
    )).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Disk Analyzer', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: () {
              _loadStorageInfo();
              _scanLargeFiles();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Storage Overview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Storage Overview', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: pieSections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend('Used', const Color(0xFF00BCD4)),
                      const SizedBox(width: 20),
                      _buildLegend('Free', Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: ${_totalStorage.toStringAsFixed(1)} GB',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Storage Partitions
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
                  const Row(
                    children: [
                      Icon(Icons.storage, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Storage Partitions', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._storageInfo.map((partition) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(partition['mounted'], style: const TextStyle(color: Colors.white)),
                            Text(partition['size'], style: const TextStyle(color: Colors.white54)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: partition['usage'] / 100,
                          backgroundColor: Colors.white24,
                          color: _getUsageColor(partition['usage']),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Used: ${partition['used']}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            Text('Free: ${partition['available']}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Large Files Scan
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
                  const Row(
                    children: [
                      Icon(Icons.search, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Large Files (>10MB)', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          onChanged: (v) => _scanPath = v,
                          decoration: const InputDecoration(
                            hintText: 'Scan path',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isScanning ? null : _scanLargeFiles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.black,
                        ),
                        child: _isScanning
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('SCAN'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_largeFiles.isNotEmpty)
                    ..._largeFiles.take(10).map((file) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, color: Color(0xFF00BCD4), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file['name'],
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  file['sizeFormatted'],
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  if (_largeFiles.isEmpty && !_isScanning)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('No large files found', style: TextStyle(color: Colors.white38)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
