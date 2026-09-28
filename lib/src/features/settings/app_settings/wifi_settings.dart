import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WifiSettings extends StatefulWidget {
  const WifiSettings({super.key});

  @override
  State<WifiSettings> createState() => _WifiSettingsState();
}

class _WifiSettingsState extends State<WifiSettings> {
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
        'scan_interval': prefs.getInt('wifi_scan_interval') ?? 10,
        'auto_scan': prefs.getBool('wifi_auto_scan') ?? true,
        'show_hidden': prefs.getBool('wifi_show_hidden') ?? false,
        'aggressive_scan': prefs.getBool('wifi_aggressive_scan') ?? false,
        'save_passwords': prefs.getBool('wifi_save_passwords') ?? true,
        'auto_attack': prefs.getBool('wifi_auto_attack') ?? false,
        'deauth_power': prefs.getInt('wifi_deauth_power') ?? 50,
      };
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) await prefs.setInt(key, value);
    else if (value is bool) await prefs.setBool(key, value);
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('WiFi Settings'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: ListView(
        children: [
          _buildSliderSetting('Scan Interval (seconds)', 'scan_interval', 5, 60),
          _buildSwitchSetting('Auto Scan', 'auto_scan'),
          _buildSwitchSetting('Show Hidden Networks', 'show_hidden'),
          _buildSwitchSetting('Aggressive Scan Mode', 'aggressive_scan'),
          _buildSwitchSetting('Save Passwords', 'save_passwords'),
          _buildSwitchSetting('Auto Attack on Discovery', 'auto_attack'),
          _buildSliderSetting('Deauth Attack Power', 'deauth_power', 10, 100),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Clear Saved Passwords', style: TextStyle(color: Colors.white)),
            onTap: () => _clearSavedPasswords(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(String label, String key, int min, int max) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Slider(
        value: _settings[key].toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: max - min,
        activeColor: Colors.blue,
        onChanged: (v) => _saveSetting(key, v.toInt()),
      ),
      trailing: Text('${_settings[key]}', style: const TextStyle(color: Colors.blue)),
    );
  }

  Widget _buildSwitchSetting(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: _settings[key] ?? false,
      onChanged: (v) => _saveSetting(key, v),
      activeColor: Colors.blue,
    );
  }

  void _clearSavedPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wifi_saved_passwords');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved passwords cleared')),
    );
  }
}
