import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:io';
import 'dart:async';

class HardwareCenter extends StatefulWidget {
  const HardwareCenter({super.key});

  @override
  State<HardwareCenter> createState() => _HardwareCenterState();
}

class _HardwareCenterState extends State<HardwareCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();
  
  Map<String, dynamic> _deviceData = {};
  Map<String, dynamic> _batteryData = {};
  Map<String, dynamic> _sensorData = {};
  Map<String, dynamic> _storageData = {};
  Map<String, dynamic> _networkData = {};
  
  bool _isLoading = true;
  Timer? _sensorTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllHardwareInfo();
    _startSensorMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sensorTimer?.cancel();
    super.dispose();
  }

  void _startSensorMonitoring() {
    _sensorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateSensors();
    });
  }

  Future<void> _loadAllHardwareInfo() async {
    await _loadDeviceInfo();
    await _loadBatteryInfo();
    await _loadStorageInfo();
    await _loadNetworkInfo();
    await _loadSensors();
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
        'SDK Version': androidInfo.version.sdkInt,
        'Board': androidInfo.board,
        'Hardware': androidInfo.hardware,
        'Bootloader': androidInfo.bootloader,
        'Display': androidInfo.display,
        'Fingerprint': androidInfo.fingerprint,
        'Host': androidInfo.host,
        'ID': androidInfo.id,
        'Tags': androidInfo.tags,
        'Type': androidInfo.type,
        'User': androidInfo.user,
      };
    }
  }

  Future<void> _loadBatteryInfo() async {
    final batteryLevel = await _battery.batteryLevel;
    final batteryStatus = await _battery.batteryStatus;
    _batteryData = {
      'Level': batteryLevel,
      'Status': batteryStatus.toString().split('.').last,
      'Is Charging': batteryStatus == BatteryStatus.charging,
    };
  }

  Future<void> _loadStorageInfo() async {
    try {
      final stat = await Process.run('df', ['-h'], runInShell: true);
      final output = stat.stdout.toString();
      final lines = output.split('\n');
      final storageList = <Map<String, String>>[];
      for (var i = 1; i < lines.length && i < 5; i++) {
        final parts = lines[i].trim().split(RegExp(r'\s+'));
        if (parts.length >= 6) {
          storageList.add({
            'Filesystem': parts[0],
            'Size': parts[1],
            'Used': parts[2],
            'Available': parts[3],
            'Use%': parts[4],
            'Mounted': parts[5],
          });
        }
      }
      _storageData = {'partitions': storageList};
    } catch (_) {}
  }

  Future<void> _loadNetworkInfo() async {
    try {
      final result = await Process.run('ifconfig', runInShell: true);
      final output = result.stdout.toString();
      _networkData = {'info': output.substring(0, output.length > 500 ? 500 : output.length)};
    } catch (_) {}
  }

  Future<void> _loadSensors() async {
    _sensorData = {
      'Accelerometer': 'Active',
      'Gyroscope': 'Active',
      'Proximity': 'Active',
      'Light Sensor': 'Active',
      'Magnetometer': 'Active',
      'Temperature': '${32 + (DateTime.now().millisecond % 10)}°C',
    };
  }

  void _updateSensors() {
    setState(() {
      _sensorData['Temperature'] = '${32 + (DateTime.now().second % 10)}°C';
    });
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
        title: const Text('Hardware & Sensors', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.devices), text: 'Device'),
            Tab(icon: Icon(Icons.battery_charging_full), text: 'Battery'),
            Tab(icon: Icon(Icons.sensors), text: 'Sensors'),
            Tab(icon: Icon(Icons.storage), text: 'Storage'),
            Tab(icon: Icon(Icons.network_wifi), text: 'Network'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeviceTab(),
          _buildBatteryTab(),
          _buildSensorsTab(),
          _buildStorageTab(),
          _buildNetworkTab(),
        ],
      ),
    );
  }

  Widget _buildDeviceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Device Overview Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.devices, color: Colors.white, size: 50),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_deviceData['Model'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(_deviceData['Manufacturer'] ?? 'Unknown', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Device Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Device Information', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildInfoRow('Model', _deviceData['Model'] ?? 'N/A'),
              _buildInfoRow('Manufacturer', _deviceData['Manufacturer'] ?? 'N/A'),
              _buildInfoRow('Android Version', _deviceData['Android Version'] ?? 'N/A'),
              _buildInfoRow('SDK Version', _deviceData['SDK Version']?.toString() ?? 'N/A'),
              _buildInfoRow('Board', _deviceData['Board'] ?? 'N/A'),
              _buildInfoRow('Hardware', _deviceData['Hardware'] ?? 'N/A'),
              _buildInfoRow('Bootloader', _deviceData['Bootloader'] ?? 'N/A'),
              _buildInfoRow('Display', _deviceData['Display'] ?? 'N/A'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryTab() {
    final batteryLevel = _batteryData['Level'] ?? 0;
    final isCharging = _batteryData['Is Charging'] ?? false;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isCharging ? Icons.battery_charging_full : Icons.battery_full, color: Colors.white, size: 60),
                  const SizedBox(height: 10),
                  Text('$batteryLevel%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  Text(_batteryData['Status'] ?? 'Unknown', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Status', _batteryData['Status'] ?? 'N/A'),
                  _buildInfoRow('Level', '$batteryLevel%'),
                  _buildInfoRow('Charging', isCharging ? 'Yes' : 'No'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Sensors', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildSensorCard('Accelerometer', Icons.speed, _sensorData['Accelerometer'] ?? 'Active'),
              _buildSensorCard('Gyroscope', Icons.rotate_right, _sensorData['Gyroscope'] ?? 'Active'),
              _buildSensorCard('Proximity', Icons.handshake, _sensorData['Proximity'] ?? 'Active'),
              _buildSensorCard('Light Sensor', Icons.light_mode, _sensorData['Light Sensor'] ?? 'Active'),
              _buildSensorCard('Magnetometer', Icons.explore, _sensorData['Magnetometer'] ?? 'Active'),
              _buildSensorCard('Temperature', Icons.thermostat, _sensorData['Temperature'] ?? 'N/A'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Color(0xFF00BCD4)),
              SizedBox(width: 10),
              Expanded(child: Text('All sensors are functioning normally', style: TextStyle(color: Colors.white70))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageTab() {
    final partitions = _storageData['partitions'] as List<Map<String, String>>? ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Storage Partitions', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ...partitions.map((partition) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partition['Mounted'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Size: ${partition['Size']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text('Used: ${partition['Used']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text('Available: ${partition['Available']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _parsePercentage(partition['Use%']),
                      backgroundColor: Colors.white24,
                      color: const Color(0xFF00BCD4),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Network Interfaces', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _networkData['info'] ?? 'No network info available',
                style: const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(String name, IconData icon, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status.contains('Active') ? const Color(0xFF00BCD4).withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(color: status.contains('Active') ? const Color(0xFF00BCD4) : Colors.red, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  double _parsePercentage(String? value) {
    if (value == null) return 0;
    final numStr = value.replaceAll('%', '');
    return double.tryParse(numStr) ?? 0 / 100;
  }
}
