import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileManagerSettings extends StatefulWidget {
  const FileManagerSettings({super.key});

  @override
  State<FileManagerSettings> createState() => _FileManagerSettingsState();
}

class _FileManagerSettingsState extends State<FileManagerSettings> {
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
        'show_hidden': prefs.getBool('fm_show_hidden') ?? false,
        'show_file_extensions': prefs.getBool('fm_show_file_extensions') ?? true,
        'default_view': prefs.getString('fm_default_view') ?? 'grid',
        'sort_by': prefs.getString('fm_sort_by') ?? 'name',
        'sort_ascending': prefs.getBool('fm_sort_ascending') ?? true,
        'confirm_delete': prefs.getBool('fm_confirm_delete') ?? true,
        'thumbnail_size': prefs.getInt('fm_thumbnail_size') ?? 64,
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
        title: const Text('File Manager Settings'),
        backgroundColor: Colors.orange.shade900,
      ),
      body: ListView(
        children: [
          _buildSwitchSetting('Show Hidden Files', 'show_hidden'),
          _buildSwitchSetting('Show File Extensions', 'show_file_extensions'),
          _buildDropdownSetting('Default View', 'default_view', ['grid', 'list', 'details']),
          _buildDropdownSetting('Sort By', 'sort_by', ['name', 'size', 'date', 'type']),
          _buildSwitchSetting('Sort Ascending', 'sort_ascending'),
          _buildSwitchSetting('Confirm Delete', 'confirm_delete'),
          _buildSliderSetting('Thumbnail Size', 'thumbnail_size', 32, 128, 8),
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
        activeColor: Colors.orange,
        onChanged: (v) => _saveSetting(key, v.toInt()),
      ),
      trailing: Text('${_settings[key]}px', style: const TextStyle(color: Colors.orange)),
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
      activeColor: Colors.orange,
    );
  }
}
