import 'package:flutter/material.dart';
import 'dart:io';

class BatteryInfoDialog extends StatelessWidget {
  const BatteryInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Battery Information', style: TextStyle(color: Color(0xFF00BCD4))),
      backgroundColor: Colors.black,
      content: FutureBuilder(
        future: _getBatteryInfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
          }
          final info = snapshot.data as Map<String, dynamic>;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Level', '${info['level']}%', _getLevelColor(info['level'])),
              _buildInfoRow('Status', info['status'], _getStatusColor(info['status'])),
              _buildInfoRow('Temperature', '${info['temperature']}°C', Colors.orange),
              _buildInfoRow('Health', info['health'], Colors.green),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Color(0xFF00BCD4))),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getBatteryInfo() async {
    try {
      final result = await Process.run('dumpsys', ['battery'], runInShell: true);
      final output = result.stdout.toString();
      final levelMatch = RegExp(r'level: (\d+)').firstMatch(output);
      final tempMatch = RegExp(r'temperature: (\d+)').firstMatch(output);
      final statusMatch = RegExp(r'status: (\d+)').firstMatch(output);
      final healthMatch = RegExp(r'health: (\d+)').firstMatch(output);
      
      const statuses = {1: 'Unknown', 2: 'Charging', 3: 'Discharging', 4: 'Not charging', 5: 'Full'};
      const healths = {1: 'Unknown', 2: 'Good', 3: 'Overheat', 4: 'Dead', 5: 'Over voltage', 6: 'Unspecified failure', 7: 'Cold'};
      
      return {
        'level': levelMatch != null ? int.parse(levelMatch.group(1)!) : 0,
        'temperature': tempMatch != null ? int.parse(tempMatch.group(1)!) / 10 : 0,
        'status': statuses[int.parse(statusMatch?.group(1) ?? '1')] ?? 'Unknown',
        'health': healths[int.parse(healthMatch?.group(1) ?? '1')] ?? 'Unknown',
      };
    } catch (_) {
      return {'level': 0, 'temperature': 0, 'status': 'Unknown', 'health': 'Unknown'};
    }
  }

  Color _getLevelColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    if (status == 'Charging') return Colors.green;
    if (status == 'Full') return Colors.blue;
    return Colors.white54;
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
