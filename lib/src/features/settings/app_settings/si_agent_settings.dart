import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SIAgentSettings extends StatefulWidget {
  const SIAgentSettings({super.key});

  @override
  State<SIAgentSettings> createState() => _SIAgentSettingsState();
}

class _SIAgentSettingsState extends State<SIAgentSettings> {
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
        'learning_rate': prefs.getDouble('si_learning_rate') ?? 0.1,
        'exploration_rate': prefs.getDouble('si_exploration_rate') ?? 0.1,
        'discount_factor': prefs.getDouble('si_discount_factor') ?? 0.95,
        'memory_size': prefs.getInt('si_memory_size') ?? 1000,
        'auto_attack': prefs.getBool('si_auto_attack') ?? true,
        'auto_learn': prefs.getBool('si_auto_learn') ?? true,
        'aggression_level': prefs.getInt('si_aggression_level') ?? 5,
        'scan_interval': prefs.getInt('si_scan_interval') ?? 30,
      };
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) await prefs.setDouble(key, value);
    else if (value is int) await prefs.setInt(key, value);
    else if (value is bool) await prefs.setBool(key, value);
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SI Agent Settings'),
        backgroundColor: Colors.purple.shade900,
      ),
      body: ListView(
        children: [
          _buildSliderSetting('Learning Rate', 'learning_rate', 0.01, 1.0, 0.01),
          _buildSliderSetting('Exploration Rate', 'exploration_rate', 0.01, 1.0, 0.01),
          _buildSliderSetting('Discount Factor', 'discount_factor', 0.5, 0.99, 0.01),
          _buildSliderSetting('Memory Size', 'memory_size', 100, 10000, 100),
          _buildSwitchSetting('Auto Attack Mode', 'auto_attack'),
          _buildSwitchSetting('Auto Learning Mode', 'auto_learn'),
          _buildSliderSetting('Aggression Level', 'aggression_level', 1, 10, 1),
          _buildSliderSetting('Scan Interval (seconds)', 'scan_interval', 10, 300, 10),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('Clear Learning Data', style: TextStyle(color: Colors.white)),
            onTap: () => _clearLearningData(),
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.green),
            title: const Text('Export Learning Data', style: TextStyle(color: Colors.white)),
            onTap: () => _exportLearningData(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(String label, String key, double min, double max, double step) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Slider(
        value: _settings[key].toDouble(),
        min: min,
        max: max,
        divisions: ((max - min) / step).toInt(),
        activeColor: Colors.purple,
        onChanged: (v) => _saveSetting(key, v),
      ),
      trailing: Text('${_settings[key]}', style: const TextStyle(color: Colors.purple)),
    );
  }

  Widget _buildSwitchSetting(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: _settings[key] ?? false,
      onChanged: (v) => _saveSetting(key, v),
      activeColor: Colors.purple,
    );
  }

  void _clearLearningData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('si_learning_data');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Learning data cleared')),
    );
  }

  void _exportLearningData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('si_learning_data');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Learning data exported')),
    );
  }
}
