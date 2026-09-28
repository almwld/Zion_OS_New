import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

class SystemMonitor extends StatefulWidget {
  const SystemMonitor({super.key});

  @override
  State<SystemMonitor> createState() => _SystemMonitorState();
}

class _SystemMonitorState extends State<SystemMonitor> {
  double _cpuUsage = 0.0;
  double _memoryUsage = 0.0;
  double _diskUsage = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateStats();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _updateStats());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateStats() async {
    try {
      final cpu = await _getCpuUsage();
      final memory = await _getMemoryUsage();
      final disk = await _getDiskUsage();
      
      setState(() {
        _cpuUsage = cpu;
        _memoryUsage = memory;
        _diskUsage = disk;
      });
    } catch (_) {}
  }

  Future<double> _getCpuUsage() async {
    try {
      final result = await Process.run('top', ['-bn1']);
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.contains('%Cpu')) {
          final parts = line.split(',');
          for (final part in parts) {
            if (part.contains('id')) {
              final idle = double.tryParse(part.trim().split(' ')[0]) ?? 0;
              return 100 - idle;
            }
          }
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<double> _getMemoryUsage() async {
    try {
      final result = await Process.run('free', []);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].trim().split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final total = double.tryParse(parts[1]) ?? 1;
          final used = double.tryParse(parts[2]) ?? 0;
          return (used / total) * 100;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<double> _getDiskUsage() async {
    try {
      final result = await Process.run('df', ['-h', '/']);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].trim().split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          final used = parts[4].replaceAll('%', '');
          return double.tryParse(used) ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('System Monitor'),
        backgroundColor: Colors.purple.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildGaugeCard('CPU Usage', _cpuUsage, Colors.cyan),
            const SizedBox(height: 16),
            _buildGaugeCard('Memory Usage', _memoryUsage, Colors.green),
            const SizedBox(height: 16),
            _buildGaugeCard('Disk Usage', _diskUsage, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeCard(String title, double value, Color color) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
                const Spacer(),
                Text('${value.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey.shade800,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
