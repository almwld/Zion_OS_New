import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../core/theme/theme_manager.dart';

class NetworkCenter extends StatefulWidget {
  const NetworkCenter({super.key});

  @override
  State<NetworkCenter> createState() => _NetworkCenterState();
}

class _NetworkCenterState extends State<NetworkCenter> {
  final ThemeManager _themeManager = ThemeManager();
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // معلومات الشبكة الحقيقية
  String _wifiName = 'Scanning...';
  String _ipAddress = 'Scanning...';
  String _gateway = 'Scanning...';
  String _subnetMask = 'Scanning...';
  String _dns1 = 'Scanning...';
  String _dns2 = 'Scanning...';
  String _macAddress = 'Scanning...';
  String _networkType = 'Unknown';
  bool _isConnected = false;
  
  // سرعة الشبكة
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  double _ping = 0;
  bool _isTestingSpeed = false;
  
  // الأجهزة المتصلة
  List<Map<String, dynamic>> _connectedDevices = [];
  bool _isScanning = false;
  int _devicesFound = 0;
  
  // المنافذ المفتوحة
  List<Map<String, dynamic>> _openPorts = [];
  bool _isPortScanning = false;

  @override
  void initState() {
    super.initState();
    _loadRealNetworkInfo();
  }

  Future<void> _loadRealNetworkInfo() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
      _networkType = connectivityResult.toString().split('.').last;
    });
    
    if (connectivityResult == ConnectivityResult.wifi) {
      try {
        _wifiName = await _networkInfo.getWifiName() ?? 'Unknown';
        _ipAddress = await _networkInfo.getWifiIP() ?? '0.0.0.0';
        _gateway = await _networkInfo.getWifiGatewayIP() ?? '0.0.0.0';
        _subnetMask = await _networkInfo.getWifiSubmask() ?? '255.255.255.0';
        _dns1 = await _networkInfo.getWifiDNS1() ?? '0.0.0.0';
        _dns2 = await _networkInfo.getWifiDNS2() ?? '0.0.0.0';
        _macAddress = await _networkInfo.getWifiBSSID() ?? 'Unknown';
      } catch (e) {
        print('Error getting WiFi info: $e');
      }
    } else if (connectivityResult == ConnectivityResult.mobile) {
      _wifiName = 'Mobile Data';
      try {
        final interfaces = await NetworkInterface.list();
        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              _ipAddress = addr.address;
              break;
            }
          }
        }
      } catch (e) {}
    }
    
    setState(() {});
  }

  Future<void> _scanNetwork() async {
    if (_gateway == '0.0.0.0' || _gateway == 'Scanning...') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot scan: No gateway IP found')),
      );
      return;
    }
    
    setState(() {
      _isScanning = true;
      _connectedDevices.clear();
      _devicesFound = 0;
    });
    
    final subnet = _gateway.substring(0, _gateway.lastIndexOf('.'));
    
    for (var i = 1; i <= 20; i++) {
      final ip = '$subnet.$i';
      try {
        final result = await Process.run('ping', ['-c', '1', '-W', '1', ip]);
        if (result.exitCode == 0) {
          setState(() {
            _connectedDevices.add({
              'ip': ip,
              'name': await _getHostname(ip),
              'status': 'Online',
            });
            _devicesFound++;
          });
        }
      } catch (_) {}
    }
    
    setState(() => _isScanning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scan completed! Found $_devicesFound devices')),
    );
  }

  Future<String> _getHostname(String ip) async {
    try {
      final result = await InternetAddress.lookup(ip);
      if (result.isNotEmpty && result.first.host.isNotEmpty) {
        return result.first.host;
      }
    } catch (_) {}
    return 'Unknown';
  }

  Future<void> _testSpeed() async {
    setState(() {
      _isTestingSpeed = true;
      _downloadSpeed = 0;
      _uploadSpeed = 0;
    });

    final stopwatch = Stopwatch();
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: Duration(seconds: 5));
      stopwatch.start();
      await socket.close();
      stopwatch.stop();
      setState(() => _ping = stopwatch.elapsedMilliseconds.toDouble());
    } catch (_) {
      setState(() => _ping = -1);
    }

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://speed.cloudflare.com/__down?bytes=500000'));
      final start = DateTime.now();
      final response = await request.close();
      var bytesReceived = 0;
      await for (final data in response) {
        bytesReceived += data.length;
      }
      final duration = DateTime.now().difference(start);
      final speedMbps = (bytesReceived * 8) / (duration.inMilliseconds / 1000) / 1000000;
      setState(() => _downloadSpeed = speedMbps);
      client.close();
    } catch (_) {}
    
    setState(() => _isTestingSpeed = false);
  }

  Future<void> _scanPorts() async {
    setState(() {
      _isPortScanning = true;
      _openPorts.clear();
    });
    
    final commonPorts = [22, 80, 443, 8080];
    
    for (final port in commonPorts) {
      try {
        final socket = await Socket.connect(_ipAddress, port, timeout: Duration(milliseconds: 800));
        await socket.close();
        setState(() {
          _openPorts.add({
            'port': port,
            'service': _getServiceName(port),
            'status': 'open',
          });
        });
      } catch (_) {}
    }
    
    setState(() => _isPortScanning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Port scan completed! Found ${_openPorts.length} open ports')),
    );
  }

  String _getServiceName(int port) {
    switch (port) {
      case 22: return 'SSH';
      case 80: return 'HTTP';
      case 443: return 'HTTPS';
      case 8080: return 'HTTP-Alt';
      default: return 'Unknown';
    }
  }

  void _blockIP(String ip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Blocking $ip requires root access')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeManager.currentTheme;
    
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Network Center'),
        backgroundColor: theme.background,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRealNetworkInfo,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildNetworkInfoCard()),
            SliverToBoxAdapter(child: _buildSpeedCard()),
            SliverToBoxAdapter(child: _buildConnectedDevicesCard()),
            SliverToBoxAdapter(child: _buildPortsCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade900, Colors.cyan.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_isConnected ? Icons.wifi : Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 8),
              Text(_networkType, style: const TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          const Divider(color: Colors.white24),
          _buildInfoRow('Network', _wifiName),
          _buildInfoRow('IP Address', _ipAddress),
          _buildInfoRow('Gateway', _gateway),
          _buildInfoRow('Subnet Mask', _subnetMask),
          _buildInfoRow('DNS 1', _dns1),
          _buildInfoRow('DNS 2', _dns2),
          _buildInfoRow('MAC Address', _macAddress),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSpeedCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.speed, color: Colors.green),
              SizedBox(width: 8),
              Text('Speed Test', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSpeedStat('Ping', '${_ping.toInt()} ms', Colors.cyan),
              _buildSpeedStat('Download', '${_downloadSpeed.toStringAsFixed(1)} Mbps', Colors.green),
              _buildSpeedStat('Upload', '${_uploadSpeed.toStringAsFixed(1)} Mbps', Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isTestingSpeed ? null : _testSpeed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeManager.currentTheme.accent,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: _isTestingSpeed
                ? const CircularProgressIndicator()
                : const Text('TEST SPEED'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildConnectedDevicesCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.devices, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Connected Devices (${_connectedDevices.length})', style: const TextStyle(color: Colors.white, fontSize: 18)),
              const Spacer(),
              IconButton(
                icon: Icon(_isScanning ? Icons.stop : Icons.refresh, color: Colors.cyan),
                onPressed: _isScanning ? null : _scanNetwork,
              ),
            ],
          ),
          const Divider(),
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_isScanning && _connectedDevices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No devices found', style: TextStyle(color: Colors.grey))),
            ),
          ..._connectedDevices.map((device) => ListTile(
            dense: true,
            leading: const Icon(Icons.computer, color: Colors.cyan),
            title: Text(device['ip'], style: const TextStyle(color: Colors.white)),
            subtitle: Text(device['name'], style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.block, color: Colors.red),
              onPressed: () => _blockIP(device['ip']),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPortsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.usb, color: Colors.purple),
              const SizedBox(width: 8),
              Text('Open Ports (${_openPorts.length})', style: const TextStyle(color: Colors.white, fontSize: 18)),
              const Spacer(),
              IconButton(
                icon: Icon(_isPortScanning ? Icons.stop : Icons.search, color: Colors.purple),
                onPressed: _isPortScanning ? null : _scanPorts,
              ),
            ],
          ),
          const Divider(),
          if (_isPortScanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_isPortScanning && _openPorts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No open ports found', style: TextStyle(color: Colors.grey))),
            ),
          ..._openPorts.map((port) => ListTile(
            dense: true,
            leading: const Icon(Icons.router, color: Colors.purple),
            title: Text('Port ${port['port']}', style: const TextStyle(color: Colors.white)),
            subtitle: Text(port['service'], style: const TextStyle(color: Colors.grey)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('open', style: const TextStyle(color: Colors.green)),
            ),
          )),
        ],
      ),
    );
  }
}
