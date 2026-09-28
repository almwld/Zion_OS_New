import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
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
        'enable_notifications': prefs.getBool('notif_enable') ?? true,
        'attack_alerts': prefs.getBool('notif_attack_alerts') ?? true,
        'scan_complete': prefs.getBool('notif_scan_complete') ?? true,
        'target_discovered': prefs.getBool('notif_target_discovered') ?? true,
        'show_banner': prefs.getBool('notif_show_banner') ?? true,
        'play_sound': prefs.getBool('notif_play_sound') ?? true,
        'vibrate': prefs.getBool('notif_vibrate') ?? false,
        'popup_position': prefs.getString('notif_popup_position') ?? 'top_right',
        'notification_timeout': prefs.getInt('notif_timeout') ?? 5,
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
        title: const Text('Notification Settings'),
        backgroundColor: Colors.cyan.shade900,
      ),
      body: ListView(
        children: [
          _buildSwitchSetting('Enable Notifications', 'enable_notifications'),
          if (_settings['enable_notifications'] == true) ...[
            _buildSwitchSetting('Attack Alerts', 'attack_alerts'),
            _buildSwitchSetting('Scan Complete Alerts', 'scan_complete'),
            _buildSwitchSetting('Target Discovered Alerts', 'target_discovered'),
            _buildSwitchSetting('Show Banner', 'show_banner'),
            _buildSwitchSetting('Play Sound', 'play_sound'),
            _buildSwitchSetting('Vibrate', 'vibrate'),
            _buildDropdownSetting('Popup Position', 'popup_position', ['top_left', 'top_right', 'bottom_left', 'bottom_right', 'center']),
            _buildSliderSetting('Notification Timeout (seconds)', 'notification_timeout', 2, 15, 1),
          ],
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.notifications_off, color: Colors.red),
            title: const Text('Test Notification', style: TextStyle(color: Colors.white)),
            onTap: () => _testNotification(),
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
        activeColor: Colors.cyan,
        onChanged: (v) => _saveSetting(key, v.toInt()),
      ),
      trailing: Text('${_settings[key]}s', style: const TextStyle(color: Colors.cyan)),
    );
  }

  Widget _buildDropdownSetting(String label, String key, List<String> items) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: DropdownButton<String>(
        value: _settings[key],
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: (v) => _saveSetting(key, v),
        dropdownColor: Colors.grey.shade900,
      ),
    );
  }

  Widget _buildSwitchSetting(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: _settings[key] ?? false,
      onChanged: (v) => _saveSetting(key, v),
      activeColor: Colors.cyan,
    );
  }

  void _testNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔔 Test notification received!')),
    );
  }
}
