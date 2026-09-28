import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TerminalSettings extends StatefulWidget {
  const TerminalSettings({super.key});

  @override
  State<TerminalSettings> createState() => _TerminalSettingsState();
}

class _TerminalSettingsState extends State<TerminalSettings> {
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
        'font_size': prefs.getInt('terminal_font_size') ?? 14,
        'font_family': prefs.getString('terminal_font_family') ?? 'monospace',
        'show_line_numbers': prefs.getBool('terminal_show_line_numbers') ?? true,
        'history_size': prefs.getInt('terminal_history_size') ?? 1000,
        'auto_copy': prefs.getBool('terminal_auto_copy') ?? true,
        'confirm_exit': prefs.getBool('terminal_confirm_exit') ?? true,
      };
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Terminal Settings'),
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        children: [
          _buildSliderSetting('Font Size', 'font_size', 8, 24),
          _buildDropdownSetting('Font Family', 'font_family', ['monospace', 'courier', 'ubuntu']),
          _buildSwitchSetting('Show Line Numbers', 'show_line_numbers'),
          _buildSliderSetting('History Size', 'history_size', 100, 10000),
          _buildSwitchSetting('Auto Copy', 'auto_copy'),
          _buildSwitchSetting('Confirm Exit', 'confirm_exit'),
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
        divisions: (max - min),
        activeColor: Colors.green,
        onChanged: (v) => _saveSetting(key, v.toInt()),
      ),
      trailing: Text('${_settings[key]}', style: const TextStyle(color: Colors.green)),
    );
  }

  Widget _buildDropdownSetting(String label, String key, List<String> items) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: DropdownButton<String>(
        value: _settings[key],
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: (v) => _saveSetting(key, v),
      ),
    );
  }

  Widget _buildSwitchSetting(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: _settings[key],
      onChanged: (v) => _saveSetting(key, v),
      activeColor: Colors.green,
    );
  }
}
