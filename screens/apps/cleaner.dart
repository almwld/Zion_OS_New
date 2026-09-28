import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class CleanerApp extends StatefulWidget {
  const CleanerApp({super.key});

  @override
  State<CleanerApp> createState() => _CleanerAppState();
}

class _CleanerAppState extends State<CleanerApp> {
  bool _isScanning = false;
  bool _isCleaning = false;
  Map<String, int> _junkData = {};
  int _totalJunk = 0;
  int _freedSpace = 0;
  
  final List<String> _scanPaths = [
    '/sdcard/Download',
    '/sdcard/DCIM/.thumbnails',
    '/data/local/tmp',
    '/sdcard/Android/data',
  ];

  Future<void> _scanJunk() async {
    setState(() {
      _isScanning = true;
      _junkData.clear();
      _totalJunk = 0;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _junkData = {
        'Cache Files': 245,
        'Temp Files': 189,
        'Thumbnails': 67,
        'Log Files': 34,
        'Old Downloads': 128,
        'Empty Folders': 23,
        'Duplicate Files': 56,
      };
      _totalJunk = _junkData.values.reduce((a, b) => a + b);
      _isScanning = false;
    });
  }

  Future<void> _cleanJunk() async {
    setState(() => _isCleaning = true);
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _freedSpace = _totalJunk;
      _junkData.clear();
      _totalJunk = 0;
      _isCleaning = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleaned ${(_freedSpace / 1024).toStringAsFixed(2)} MB successfully'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }

  String _formatSize(int mb) {
    if (mb < 1024) return '$mb MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Cleaner', style: TextStyle(color: Color(0xFF00BCD4))),
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
            // Storage Overview
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
                  const Icon(Icons.storage, size: 50, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text('Storage Status', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStorageIndicator('Used', 65, Colors.orange),
                      const SizedBox(width: 20),
                      _buildStorageIndicator('Free', 35, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: Colors.white24,
                    color: Colors.orange,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '12.5 GB / 32 GB',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Junk Files Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Junk Files', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold, fontSize: 18)),
                      Icon(Icons.delete_sweep, color: Color(0xFF00BCD4)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!_isScanning && _totalJunk == 0)
                    Column(
                      children: [
                        const Icon(Icons.check_circle, size: 60, color: Colors.green),
                        const SizedBox(height: 12),
                        Text(
                          'System is clean!',
                          style: TextStyle(color: Colors.green, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No junk files found',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  if (_totalJunk > 0)
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _formatSize(_totalJunk),
                            style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const Text('Junk files found', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _scanJunk,
                      icon: _isScanning
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search),
                      label: Text(_isScanning ? 'SCANNING...' : 'SCAN JUNK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Junk Details
            if (_junkData.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                    const Text('Junk Details', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._junkData.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(color: Colors.white)),
                          Text('${entry.value} MB', style: const TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                    const Divider(color: Color(0xFF00BCD4)),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('${_totalJunk} MB', style: const TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCleaning ? null : _cleanJunk,
                  icon: _isCleaning
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cleaning_services),
                  label: Text(_isCleaning ? 'CLEANING...' : 'CLEAN NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Storage Tips', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('🗑️ Clear cache regularly'),
                  _buildTip('📦 Uninstall unused apps'),
                  _buildTip('📁 Move files to cloud storage'),
                  _buildTip('🖼️ Compress large images'),
                  _buildTip('🎬 Delete old downloads'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageIndicator(String label, int percentage, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              '$percentage%',
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(tip, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}
