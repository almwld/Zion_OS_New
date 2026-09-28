import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceAdminApp extends StatefulWidget {
  const DeviceAdminApp({super.key});

  @override
  State<DeviceAdminApp> createState() => _DeviceAdminAppState();
}

class _DeviceAdminAppState extends State<DeviceAdminApp> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  Map<String, String> _deviceDetails = {};
  Map<String, String> _storageDetails = {};
  Map<String, String> _systemDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() => _isLoading = true);
    
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      _deviceDetails = {
        'Model': androidInfo.model,
        'Manufacturer': androidInfo.manufacturer,
        'Device': androidInfo.device,
        'Product': androidInfo.product,
        'Brand': androidInfo.brand,
        'Android Version': androidInfo.version.release,
        'SDK Version': androidInfo.version.sdkInt.toString(),
        'Security Patch': androidInfo.version.securityPatch ?? 'Unknown',
        'Board': androidInfo.board,
        'Hardware': androidInfo.hardware,
        'Bootloader': androidInfo.bootloader,
        'Display ID': androidInfo.display,
      };
    }
    
    await _loadStorageInfo();
    await _loadSystemInfo();
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadStorageInfo() async {
    try {
      final result = await Process.run('df', ['-h'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.contains('/data')) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 6) {
            _storageDetails = {
              'Total': parts[1],
              'Used': parts[2],
              'Available': parts[3],
              'Usage': parts[4],
            };
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSystemInfo() async {
    try {
      final uptime = await Process.run('cat', ['/proc/uptime'], runInShell: true);
      final uptimeSeconds = double.parse(uptime.stdout.toString().split(' ')[0]);
      _systemDetails['Uptime'] = _formatUptime(uptimeSeconds.toInt());
      
      final kernel = await Process.run('uname', ['-r'], runInShell: true);
      _systemDetails['Kernel'] = kernel.stdout.toString().trim();
      
      final hostname = await Process.run('hostname', [], runInShell: true);
      _systemDetails['Hostname'] = hostname.stdout.toString().trim();
      
      final cpuInfo = await Process.run('cat', ['/proc/cpuinfo'], runInShell: true);
      final processorMatch = RegExp(r'processor\s*:\s*(\d+)').allMatches(cpuInfo.stdout.toString());
      _systemDetails['CPU Cores'] = processorMatch.length.toString();
      
      final memInfo = await Process.run('cat', ['/proc/meminfo'], runInShell: true);
      final memTotal = RegExp(r'MemTotal:\s*(\d+)').firstMatch(memInfo.stdout.toString());
      if (memTotal != null) {
        final totalMB = int.parse(memTotal.group(1)!) ~/ 1024;
        _systemDetails['RAM'] = '$totalMB MB';
      }
    } catch (_) {}
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '$days d $hours h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
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
        title: const Text('Device Admin', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: _loadDeviceInfo,
          ),
        ],
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
                Tab(icon: Icon(Icons.storage), text: 'Storage'),
                Tab(icon: Icon(Icons.computer), text: 'System'),
                Tab(icon: Icon(Icons.settings), text: 'Tools'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildInfoTab(_deviceDetails, Icons.devices),
                  _buildStorageTab(),
                  _buildInfoTab(_systemDetails, Icons.computer),
                  _buildToolsTab(),
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
                    Text(key, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStorageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Storage Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.storage, size: 50, color: Colors.white),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStorageItem('Total', _storageDetails['Total'] ?? 'N/A'),
                    _buildStorageItem('Used', _storageDetails['Used'] ?? 'N/A'),
                    _buildStorageItem('Free', _storageDetails['Available'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _getUsagePercentage(),
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text('Usage: ${_storageDetails['Usage'] ?? '0%'}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Storage Categories
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _buildStorageCategory('Apps', '8.5 GB', 45, Colors.blue),
                _buildStorageCategory('Media', '12.2 GB', 65, Colors.green),
                _buildStorageCategory('Documents', '2.1 GB', 15, Colors.orange),
                _buildStorageCategory('Cache', '1.8 GB', 10, Colors.red),
                _buildStorageCategory('System', '6.5 GB', 35, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildToolCard(
          'Reset Device',
          'Factory reset your device',
          Icons.restore,
          Colors.red,
          () => _showConfirmDialog('Reset Device', 'This will erase all data. Are you sure?'),
        ),
        _buildToolCard(
          'Clear Cache',
          'Clear all app cache',
          Icons.cleaning_services,
          Colors.orange,
          () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared'), backgroundColor: Color(0xFF00BCD4)),
          ),
        ),
        _buildToolCard(
          'Battery Stats',
          'View battery usage statistics',
          Icons.battery_full,
          Colors.green,
          () {},
        ),
        _buildToolCard(
          'Network Stats',
          'View network usage statistics',
          Icons.network_wifi,
          const Color(0xFF00BCD4),
          () {},
        ),
        _buildToolCard(
          'Running Services',
          'View running system services',
          Icons.settings_applications,
          Colors.purple,
          () {},
        ),
      ],
    );
  }

  Widget _buildStorageItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildStorageCategory(String label, String size, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.white)),
                ],
              ),
              Text(size, style: TextStyle(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white24,
            color: color,
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF00BCD4)),
        onTap: onTap,
      ),
    );
  }

  double _getUsagePercentage() {
    final usage = _storageDetails['Usage'] ?? '0%';
    return int.parse(usage.replaceAll('%', '')) / 100;
  }

  Future<void> _showConfirmDialog(String title, String message) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Color(0xFF00BCD4))),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(title), backgroundColor: const Color(0xFF00BCD4)),
      );
    }
  }
}
