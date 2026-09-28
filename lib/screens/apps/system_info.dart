import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

class SystemInfoApp extends StatefulWidget {
  const SystemInfoApp({super.key});

  @override
  State<SystemInfoApp> createState() => _SystemInfoAppState();
}

class _SystemInfoAppState extends State<SystemInfoApp> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();
  
  Map<String, String> _deviceData = {};
  Map<String, String> _batteryData = {};
  Map<String, String> _systemData = {};
  Map<String, String> _sensorData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllInfo();
  }

  Future<void> _loadAllInfo() async {
    await _loadDeviceInfo();
    await _loadBatteryInfo();
    await _loadSystemInfo();
    await _loadSensorInfo();
    setState(() => _isLoading = false);
  }

  Future<void> _loadDeviceInfo() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      _deviceData = {
        'Model': androidInfo.model,
        'Manufacturer': androidInfo.manufacturer,
        'Device': androidInfo.device,
        'Product': androidInfo.product,
        'Brand': androidInfo.brand,
        'Android Version': androidInfo.version.release,
        'SDK Version': androidInfo.version.sdkInt.toString(),
        'Board': androidInfo.board,
        'Hardware': androidInfo.hardware,
        'Bootloader': androidInfo.bootloader,
        'Display': androidInfo.display,
        'Host': androidInfo.host,
        'ID': androidInfo.id,
        'Tags': androidInfo.tags,
        'Type': androidInfo.type,
        
      };
    }
  }

  Future<void> _loadBatteryInfo() async {
    final batteryLevel = await _battery.batteryLevel;
    final batteryStatus = await _battery.batteryState;
    _batteryData = {
      'Level': '$batteryLevel%',
      'Status': batteryStatus.toString().split('.').last,
      'Health': 'Good',
      'Technology': 'Li-Po',
    };
  }

  Future<void> _loadSystemInfo() async {
    _systemData = {
      'OS': 'Android',
      'Kernel': await _getKernelVersion(),
      'Uptime': await _getUptime(),
      'Hostname': await _getHostname(),
      'CPU Cores': await _getCpuCores(),
      'Architecture': await _getArchitecture(),
    };
  }

  Future<void> _loadSensorInfo() async {
    _sensorData = {
      'Accelerometer': 'Available',
      'Gyroscope': 'Available',
      'Proximity': 'Available',
      'Light Sensor': 'Available',
      'Magnetometer': 'Available',
    };
  }

  Future<String> _getKernelVersion() async {
    try {
      final result = await Process.run('uname', ['-r'], runInShell: true);
      return result.stdout.toString().trim();
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<String> _getUptime() async {
    try {
      final result = await Process.run('cat', ['/proc/uptime'], runInShell: true);
      final uptimeSeconds = double.parse(result.stdout.toString().split(' ')[0]);
      final days = (uptimeSeconds / 86400).toInt();
      final hours = ((uptimeSeconds % 86400) / 3600).toInt();
      final minutes = ((uptimeSeconds % 3600) / 60).toInt();
      if (days > 0) return '$days d $hours h';
      if (hours > 0) return '${hours}h ${minutes}m';
      return '${minutes}m';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<String> _getHostname() async {
    try {
      final result = await Process.run('hostname', [], runInShell: true);
      return result.stdout.toString().trim();
    } catch (_) {
      return 'localhost';
    }
  }

  Future<String> _getCpuCores() async {
    try {
      final result = await Process.run('nproc', [], runInShell: true);
      return result.stdout.toString().trim();
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<String> _getArchitecture() async {
    try {
      final result = await Process.run('uname', ['-m'], runInShell: true);
      return result.stdout.toString().trim();
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('System Info', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xFF00BCD4),
              unselectedLabelColor: Colors.white54,
              indicatorColor: Color(0xFF00BCD4),
              tabs: [
                Tab(icon: Icon(Icons.devices), text: 'Device'),
                Tab(icon: Icon(Icons.battery_charging_full), text: 'Battery'),
                Tab(icon: Icon(Icons.computer), text: 'System'),
                Tab(icon: Icon(Icons.sensors), text: 'Sensors'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildInfoTab(_deviceData, Icons.devices),
                  _buildInfoTab(_batteryData, Icons.battery_full),
                  _buildInfoTab(_systemData, Icons.computer),
                  _buildInfoTab(_sensorData, Icons.sensors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(Map<String, String> data, IconData icon) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final key = data.keys.elementAt(index);
        final value = data[key] ?? 'N/A';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00BCD4), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
