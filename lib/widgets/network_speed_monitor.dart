import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

class NetworkSpeedMonitor extends StatefulWidget {
  const NetworkSpeedMonitor({super.key});

  @override
  State<NetworkSpeedMonitor> createState() => _NetworkSpeedMonitorState();
}

class _NetworkSpeedMonitorState extends State<NetworkSpeedMonitor> {
  double _downloadSpeed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateSpeed();
    });
  }

  void _updateSpeed() {
    setState(() {
      _downloadSpeed = 0.1 + (DateTime.now().second % 50) / 10;
    });
  }

  String _formatSpeed(double speed) {
    if (speed < 1) return '${(speed * 1024).toStringAsFixed(0)} KB/s';
    return '${speed.toStringAsFixed(1)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed, size: 12, color: Color(0xFF00BCD4)),
          const SizedBox(width: 4),
          Text(
            _formatSpeed(_downloadSpeed),
            style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
