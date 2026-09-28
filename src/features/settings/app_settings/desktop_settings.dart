import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DesktopSettings extends StatefulWidget {
  const DesktopSettings({super.key});

  @override
  State<DesktopSettings> createState() => _DesktopSettingsState();
}

class _DesktopSettingsState extends State<DesktopSettings> {
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
        'wallpaper': prefs.getString('desktop_wallpaper') ?? 'matrix',
        'icon_size': prefs.getInt('desktop_icon_size') ?? 60,
        'icon_spacing': prefs.getInt('desktop_icon_spacing') ?? 30,
        'show_clock': prefs.getBool('desktop_show_clock') ?? true,
        'show_taskbar': prefs.getBool('desktop_show_taskbar') ?? true,
        'show_icons': prefs.getBool('desktop_show_icons') ?? true,
        'taskbar_position': prefs.getString('desktop_taskbar_position') ?? 'bottom',
        'animation_effects': prefs.getBool('desktop_animation_effects') ?? true,
        'desktop_grid': prefs.getInt('desktop_grid') ?? 4,
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
        title: const Text('Desktop Settings'),
        backgroundColor: Colors.green.shade900,
      ),
      body: ListView(
        children: [
          _buildDropdownSetting('Wallpaper', 'wallpaper', ['matrix', 'cyberpunk', 'ocean', 'forest', 'sunset', 'custom']),
          _buildSliderSetting('Icon Size', 'icon_size', 40, 100, 5),
          _buildSliderSetting('Icon Spacing', 'icon_spacing', 20, 60, 5),
          _buildSwitchSetting('Show Clock', 'show_clock'),
          _buildSwitchSetting('Show Taskbar', 'show_taskbar'),
          _buildSwitchSetting('Show Desktop Icons', 'show_icons'),
          _buildDropdownSetting('Taskbar Position', 'taskbar_position', ['bottom', 'top', 'left', 'right']),
          _buildSwitchSetting('Animation Effects', 'animation_effects'),
          _buildSliderSetting('Desktop Grid Columns', 'desktop_grid', 2, 8, 1),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Reset Desktop Layout', style: TextStyle(color: Colors.white)),
            onTap: () => _resetLayout(),
          ),
          ListTile(
            leading: const Icon(Icons.wallpaper, color: Colors.purple),
            title: const Text('Custom Wallpaper', style: TextStyle(color: Colors.white)),
            onTap: () => _selectWallpaper(),
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
        dropdownColor: Colors.grey.shade900,
      ),
    );
  }

  Widget _buildSwitchSetting(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: _settings[key] ?? false,
      onChanged: (v) => _saveSetting(key, v),
      activeColor: Colors.green,
    );
  }

  void _resetLayout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('desktop_layout');
    _loadSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Desktop layout reset')),
    );
  }

  void _selectWallpaper() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Wallpaper'),
        content: const Text('Wallpaper picker will be available soon'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
