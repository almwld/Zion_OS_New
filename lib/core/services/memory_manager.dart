import 'dart:io';
import 'package:flutter/material.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();
  
  Future<Map<String, dynamic>> getMemoryStats() async {
    try {
      final result = await Process.run('free', ['-m'], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          return {
            'total': int.parse(parts[1]),
            'used': int.parse(parts[2]),
            'free': int.parse(parts[3]),
            'usagePercent': (int.parse(parts[2]) / int.parse(parts[1]) * 100).toStringAsFixed(1),
          };
        }
      }
    } catch (_) {}
    
    return {'total': 0, 'used': 0, 'free': 0, 'usagePercent': '0'};
  }
  
  Future<void> freeMemory() async {
    try {
      await Process.run('sync', [], runInShell: true);
      await Process.run('echo', ['3', '>', '/proc/sys/vm/drop_caches'], runInShell: true);
    } catch (_) {}
  }
  
  Widget buildMemoryWidget() {
    return FutureBuilder(
      future: getMemoryStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data!;
        final usagePercent = double.parse(stats['usagePercent']);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.memory, color: Color(0xFF00BCD4)),
                  SizedBox(width: 8),
                  Text('Memory Usage', style: TextStyle(color: Color(0xFF00BCD4))),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: usagePercent / 100,
                backgroundColor: Colors.white24,
                color: usagePercent > 80 ? Colors.red : Colors.green,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${stats['used']} MB', style: const TextStyle(color: Colors.white54)),
                  Text('${stats['total']} MB', style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
