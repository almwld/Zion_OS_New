import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextEditorSettings extends StatefulWidget {
  const TextEditorSettings({super.key});

  @override
  State<TextEditorSettings> createState() => _TextEditorSettingsState();
}

class _TextEditorSettingsState extends State<TextEditorSettings> {
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
        'font_size': prefs.getInt('editor_font_size') ?? 14,
        'font_family': prefs.getString('editor_font_family') ?? 'monospace',
        'tab_size': prefs.getInt('editor_tab_size') ?? 2,
        'word_wrap': prefs.getBool('editor_word_wrap') ?? true,
        'show_line_numbers': prefs.getBool('editor_show_line_numbers') ?? true,
        'highlight_syntax': prefs.getBool('editor_highlight_syntax') ?? true,
        'auto_save': prefs.getBool('editor_auto_save') ?? true,
        'auto_save_interval': prefs.getInt('editor_auto_save_interval') ?? 30,
        'theme': prefs.getString('editor_theme') ?? 'dark',
      };
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) await prefs.setInt(key, value);
    else if (value is bool) await prefs.setBool(key, value);
    else if (value is String) await prefs.setString(key, value);
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Text Editor Settings'),
        backgroundColor: Colors.pink.shade900,
      ),
      body: ListView(
        children: [
          _buildSliderSetting('Font Size', 'font_size', 8, 24, 1),
          _buildDropdownSetting('Font Family', 'font_family', ['monospace', 'courier', 'ubuntu', 'roboto']),
          _buildSliderSetting('Tab Size (spaces)', 'tab_size', 2, 8, 1),
          _buildSwitchSetting('Word Wrap', 'word_wrap'),
          _buildSwitchSetting('Show Line Numbers', 'show_line_numbers'),
          _buildSwitchSetting('Syntax Highlighting', 'highlight_syntax'),
          _buildSwitchSetting('Auto Save', 'auto_save'),
          if (_settings['auto_save'] == true)
            _buildSliderSetting('Auto Save Interval (seconds)', 'auto_save_interval', 10, 300, 10),
          _buildDropdownSetting('Editor Theme', 'theme', ['dark', 'light', 'matrix', 'ocean']),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.folder_open, color: Colors.orange),
            title: const Text('Default Save Directory', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () => _selectDefaultDirectory(),
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
        activeColor: Colors.pink,
        onChanged: (v) => _saveSetting(key, v.toInt()),
      ),
      trailing: Text('${_settings[key]}', style: const TextStyle(color: Colors.pink)),
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
      activeColor: Colors.pink,
    );
  }

  void _selectDefaultDirectory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Default Directory'),
        content: const Text('Directory picker will be available soon'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
