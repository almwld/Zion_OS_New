import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

class NetworkAnalyzer extends StatefulWidget {
  const NetworkAnalyzer({super.key});

  @override
  State<NetworkAnalyzer> createState() => _NetworkAnalyzerState();
}

class _NetworkAnalyzerState extends State<NetworkAnalyzer> {
  String _localIp = 'Loading...';
  String _publicIp = 'Loading...';
  List<NetworkInterface> _interfaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    setState(() => _isLoading = true);
    
    try {
      _interfaces = await NetworkInterface.list();
      final local = await _getLocalIp();
      final public = await _getPublicIp();
      
      setState(() {
        _localIp = local;
        _publicIp = public;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getLocalIp() async {
    for (final interface in _interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  Future<String> _getPublicIp() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://api.ipify.org'));
      final response = await request.close();
      final data = await response.transform(const Utf8Decoder()).join();
      client.close();
      return data.trim();
    } catch (_) {
      return 'Unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Network Analyzer'),
        backgroundColor: Colors.cyan.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNetworkInfo,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoCard('Local IP', _localIp, Icons.computer),
                  _buildInfoCard('Public IP', _publicIp, Icons.public),
                  _buildInterfacesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyan),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        subtitle: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInterfacesCard() {
    return Card(
      color: Colors.grey.shade900,
      child: ExpansionTile(
        leading: const Icon(Icons.settings_ethernet, color: Colors.cyan),
        title: const Text('Network Interfaces', style: TextStyle(color: Colors.white)),
        children: _interfaces.map((iface) => ListTile(
          title: Text(iface.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            iface.addresses.map((a) => '${a.address} (${a.type.name})').join(', '),
            style: const TextStyle(color: Colors.grey),
          ),
        )).toList(),
      ),
    );
  }
}
