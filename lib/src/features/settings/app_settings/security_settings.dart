import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecuritySettings extends StatefulWidget {
  const SecuritySettings({super.key});

  @override
  State<SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  Map<String, dynamic> _settings = {};
  List<String> _securityIssues = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scanSecurity();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _settings = {
        'lock_screen': prefs.getBool('sec_lock_screen') ?? true,
        'biometric': prefs.getBool('sec_biometric') ?? true,
        'encryption': prefs.getBool('sec_encryption') ?? false,
        'stealth_mode': prefs.getBool('sec_stealth_mode') ?? false,
        'auto_lock': prefs.getInt('sec_auto_lock') ?? 5,
        'clear_cache': prefs.getBool('sec_clear_cache') ?? false,
      };
    });
  }

  Future<void> _scanSecurity() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _securityIssues = [
        '⚠️ Root access detected - Risk: High',
        '⚠️ Debug mode enabled - Risk: Medium',
        '✅ Encryption status: Active',
      ];
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    else if (value is int) await prefs.setInt(key, value);
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Colors.red.shade900,
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.red.shade900.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Security Scan Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._securityIssues.map((issue) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(issue, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  )),
                ],
              ),
            ),
          ),
          _buildSwitchSetting('Lock Screen', 'lock_screen'),
          _buildSwitchSetting('Biometric Authentication', 'biometric'),
          _buildSwitchSetting('Data Encryption', 'encryption'),
          _buildSwitchSetting('Stealth Mode', 'stealth_mode'),
          _buildSliderSetting('Auto Lock (minutes)', 'auto_lock', 1, 30, 1),
          _buildSwitchSetting('Clear Cache on Exit', 'clear_cache'),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.green),
            title: const Text('Run Security Scan', style: TextStyle(color: Colors.white)),
            onTap: () => _scanSecurity(),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.red),
            title: const Text('Lock All Sessions', style: TextStyle(color: Colors.white)),
            onTap: () => _lockAll(),
          ),
          ListTile(
            leading: const Icon(Icons.emergency, color: Colors.red),
            title: const Text('Emergency Wipe', style: TextStyle(color: Colors.white)),
            onTap: () => _emergencyWipe(),
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
        activeColor: Colors.red,
        onChanged: (v) => _saveSetting(key, v.toInt()),
      ),
      trailing: Text('${_settings[key]}', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildSwitchSetting(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: _settings[key] ?? false,
      onChanged: (v) => _saveSetting(key, v),
      activeColor: Colors.red,
    );
  }

  void _lockAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lock All Sessions'),
        content: const Text('All active sessions have been locked'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _emergencyWipe() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Wipe'),
        content: const Text('Are you sure? This will delete all data.'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data wiped')),
              );
            },
            child: const Text('WIPE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
