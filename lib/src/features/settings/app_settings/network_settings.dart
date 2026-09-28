import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkSettings extends StatefulWidget {
  const NetworkSettings({super.key});

  @override
  State<NetworkSettings> createState() => _NetworkSettingsState();
}

class _NetworkSettingsState extends State<NetworkSettings> {
  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _settings = {
        'proxy_enabled': prefs.getBool('net_proxy_enabled') ?? false,
        'proxy_host': prefs.getString('net_proxy_host') ?? '',
        'proxy_port': prefs.getInt('net_proxy_port') ?? 8080,
        'timeout': prefs.getInt('net_timeout') ?? 30,
        'retry_count': prefs.getInt('net_retry_count') ?? 3,
        'user_agent': prefs.getString('net_user_agent') ?? 'ZionOS/3.0',
        'stealth_mode': prefs.getBool('net_stealth_mode') ?? false,
        'dns_server': prefs.getString('net_dns_server') ?? '8.8.8.8',
      };
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    else if (value is String) await prefs.setString(key, value);
    else if (value is int) await prefs.setInt(key, value);
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Network Settings'),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: ListView(
        children: [
          _buildSwitchSetting('Enable Proxy', 'proxy_enabled'),
          if (_settings['proxy_enabled'] == true) ...[
            _buildTextFieldSetting('Proxy Host', 'proxy_host'),
            _buildSliderSetting('Proxy Port', 'proxy_port', 1, 65535, 1),
          ],
          _buildSliderSetting('Connection Timeout (seconds)', 'timeout', 5, 120, 5),
          _buildSliderSetting('Retry Count', 'retry_count', 1, 10, 1),
          _buildTextFieldSetting('User Agent', 'user_agent'),
          _buildSwitchSetting('Stealth Mode', 'stealth_mode'),
          _buildTextFieldSetting('DNS Server', 'dns_server'),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.speed, color: Colors.green),
            title: const Text('Test Connection', style: TextStyle(color: Colors.white)),
            onTap: () => _testConnection(),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Reset Network Settings', style: TextStyle(color: Colors.white)),
            onTap: () => _resetSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(String label, String key, int min, int max, int step) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Slider(
        value: _settings[key].toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: (max - min) ~/ step,
        activeColor: Colors.indigo,
        onChanged: (v) => _saveSetting(key, v.toInt()),
      ),
      trailing: Text('${_settings[key]}', style: const TextStyle(color: Colors.indigo)),
    );
  }

  Widget _buildTextFieldSetting(String label, String key) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: TextField(
        controller: TextEditingController(text: _settings[key]),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onSubmitted: (v) => _saveSetting(key, v),
      ),
    );
  }

  Widget _buildSwitchSetting(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: _settings[key] ?? false,
      onChanged: (v) => _saveSetting(key, v),
      activeColor: Colors.indigo,
    );
  }

  void _testConnection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing connection...')),
    );
  }

  void _resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('net_proxy_enabled');
    await prefs.remove('net_proxy_host');
    await prefs.remove('net_proxy_port');
    _loadSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network settings reset')),
    );
  }
}
