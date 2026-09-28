import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdvancedSettings extends StatefulWidget {
  const AdvancedSettings({super.key});

  @override
  State<AdvancedSettings> createState() => _AdvancedSettingsState();
}

class _AdvancedSettingsState extends State<AdvancedSettings> {
  bool _darkMode = true;
  bool _animations = true;
  bool _notifications = true;
  bool _autoStart = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? true;
      _animations = prefs.getBool('animations') ?? true;
      _notifications = prefs.getBool('notifications') ?? true;
      _autoStart = prefs.getBool('auto_start') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setBool('animations', _animations);
    await prefs.setBool('notifications', _notifications);
    await prefs.setBool('auto_start', _autoStart);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Advanced Settings'),
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
            secondary: const Icon(Icons.dark_mode, color: Colors.purple),
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Animations', style: TextStyle(color: Colors.white)),
            secondary: const Icon(Icons.animation, color: Colors.blue),
            value: _animations,
            onChanged: (v) {
              setState(() => _animations = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Notifications', style: TextStyle(color: Colors.white)),
            secondary: const Icon(Icons.notifications, color: Colors.green),
            value: _notifications,
            onChanged: (v) {
              setState(() => _notifications = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Auto Start', style: TextStyle(color: Colors.white)),
            secondary: const Icon(Icons.power_settings_new, color: Colors.orange),
            value: _autoStart,
            onChanged: (v) {
              setState(() => _autoStart = v);
              _saveSettings();
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.red),
            title: const Text('Clear All Data', style: TextStyle(color: Colors.white)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Data'),
                  content: const Text('Are you sure? This action cannot be undone.'),
                  backgroundColor: Colors.grey.shade900,
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.blue),
            title: const Text('About', style: TextStyle(color: Colors.white)),
            trailing: const Text('Zion OS v3.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
