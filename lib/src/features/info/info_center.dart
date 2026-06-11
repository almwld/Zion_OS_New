import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

class InfoCenter extends StatefulWidget {
  const InfoCenter({super.key});

  @override
  State<InfoCenter> createState() => _InfoCenterState();
}

class _InfoCenterState extends State<InfoCenter> {
  final Battery _battery = Battery();
  Map<String, dynamic> _deviceInfo = {};
  Map<String, dynamic> _batteryInfo = {};
  Map<String, dynamic> _storageInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllInfo();
  }

  Future<void> _loadAllInfo() async {
    await _loadDeviceInfo();
    await _loadBatteryInfo();
    await _loadStorageInfo();
    setState(() => _isLoading = false);
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceInfo = {
        'model': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
        'version': androidInfo.version.release,
        'sdk': androidInfo.version.sdkInt,
        'board': androidInfo.board,
        'brand': androidInfo.brand,
        'device': androidInfo.device,
        'product': androidInfo.product,
      };
    }
  }

  Future<void> _loadBatteryInfo() async {
    final batteryLevel = await _battery.batteryLevel;
    final batteryStatus = await _battery.batteryStatus;
    _batteryInfo = {
      'level': batteryLevel,
      'status': batteryStatus.toString().split('.').last,
      'isCharging': batteryStatus == BatteryStatus.charging,
    };
  }

  Future<void> _loadStorageInfo() async {
    try {
      final stat = await Process.run('df', ['/data'], runInShell: true);
      final output = stat.stdout.toString();
      final lines = output.split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 6) {
          _storageInfo = {
            'total': parts[1],
            'used': parts[2],
            'free': parts[3],
            'usage': parts[4],
          };
        }
      }
    } catch (_) {
      _storageInfo = {'total': 'N/A', 'used': 'N/A', 'free': 'N/A', 'usage': 'N/A'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('معلومات الجهاز', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF41)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard('📱 الجهاز', _deviceInfo),
                  const SizedBox(height: 15),
                  _buildInfoCard('🔋 البطارية', _batteryInfo),
                  const SizedBox(height: 15),
                  _buildInfoCard('💾 التخزين', _storageInfo),
                  const SizedBox(height: 15),
                  _buildSystemInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...data.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('${entry.key}: ', style: const TextStyle(color: Colors.white54)),
                Expanded(
                  child: Text(entry.value.toString(), style: const TextStyle(color: Colors.white), textAlign: TextAlign.right),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00FF41).withOpacity(0.1), Colors.black],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚙️ معلومات النظام', style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Zion OS v3.3', style: TextStyle(color: Colors.white)),
          const Text('Flutter 3.22.0', style: TextStyle(color: Colors.white)),
          const Text('Android 10+', style: TextStyle(color: Colors.white)),
          const Text('وضع التشغيل: بدون روت', style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}
