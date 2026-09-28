import 'package:flutter/material.dart';
import 'dart:async';

class ZionSystemMonitor extends StatefulWidget {
  const ZionSystemMonitor({super.key});

  @override
  State<ZionSystemMonitor> createState() => _ZionSystemMonitorState();
}

class _ZionSystemMonitorState extends State<ZionSystemMonitor> {
  late Timer _timer;
  double _cpuUsage = 23.5;
  double _ramUsage = 45.2;
  double _diskUsage = 67.8;
  int _processes = 147;
  String _uptime = '2:34:17';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _cpuUsage = (_cpuUsage + (DateTime.now().millisecond % 10) - 5).clamp(5.0, 95.0);
        _ramUsage = (_ramUsage + (DateTime.now().millisecond % 5) - 2.5).clamp(10.0, 90.0);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Monitor', style: TextStyle(color: Color(0xFF00FF41), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _MonitorBar(label: 'CPU', value: _cpuUsage, color: _cpuUsage > 80 ? Colors.red : const Color(0xFF00FF41)),
          const SizedBox(height: 12),
          _MonitorBar(label: 'RAM', value: _ramUsage, color: _ramUsage > 80 ? Colors.red : Colors.blue),
          const SizedBox(height: 12),
          _MonitorBar(label: 'Disk', value: _diskUsage, color: _diskUsage > 90 ? Colors.red : Colors.orange),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF1A3A1A)),
          const SizedBox(height: 12),
          _InfoRow(label: 'العمليات', value: '$_processes'),
          _InfoRow(label: 'مدة التشغيل', value: _uptime),
          _InfoRow(label: 'Kali Linux', value: 'متصل (600+ أداة)'),
          _InfoRow(label: 'الشبكة', value: '192.168.1.100'),
        ],
      ),
    );
  }
}

class _MonitorBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MonitorBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 12)),
            Text('${value.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A1A),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
