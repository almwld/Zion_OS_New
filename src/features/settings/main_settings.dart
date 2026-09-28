import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/advanced_theme.dart';

class MainSettings extends StatefulWidget {
  const MainSettings({super.key});

  @override
  State<MainSettings> createState() => _MainSettingsState();
}

class _MainSettingsState extends State<MainSettings> {
  final AdvancedTheme _theme = AdvancedTheme();
  late Map<String, dynamic> _appSettings;
  String _selectedCategory = 'Appearance';

  final List<String> _categories = [
    'Appearance', 'Theme', 'Window', 'Animation', 'Privacy', 'Apps', 'About'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appSettings = {
        'window_opacity': prefs.getDouble('window_opacity') ?? 0.95,
        'show_taskbar': prefs.getBool('show_taskbar') ?? true,
        'show_clock': prefs.getBool('show_clock') ?? true,
        'animations': prefs.getBool('animations') ?? true,
        'animation_speed': prefs.getDouble('animation_speed') ?? 1.0,
        'notifications': prefs.getBool('notifications') ?? true,
        'auto_update': prefs.getBool('auto_update') ?? true,
        'stealth_mode': prefs.getBool('stealth_mode') ?? false,
      };
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() => _appSettings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Zion Settings'),
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: Colors.grey.shade900,
      child: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (ctx, i) => ListTile(
          selected: _selectedCategory == _categories[i],
          selectedTileColor: Colors.green.withOpacity(0.2),
          leading: Icon(_getCategoryIcon(_categories[i]), color: Colors.green),
          title: Text(_categories[i], style: const TextStyle(color: Colors.white, fontSize: 13)),
          onTap: () => setState(() => _selectedCategory = _categories[i]),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Appearance': return Icons.palette;
      case 'Theme': return Icons.color_lens;
      case 'Window': return Icons.crop_din;
      case 'Animation': return Icons.animation;
      case 'Privacy': return Icons.lock;
      case 'Apps': return Icons.apps;
      default: return Icons.info;
    }
  }

  Widget _buildContent() {
    switch (_selectedCategory) {
      case 'Appearance': return _buildAppearanceSettings();
      case 'Theme': return _buildThemeSettings();
      case 'Window': return _buildWindowSettings();
      case 'Animation': return _buildAnimationSettings();
      case 'Privacy': return _buildPrivacySettings();
      case 'Apps': return _buildAppsSettings();
      default: return _buildAboutSettings();
    }
  }

  Widget _buildAppearanceSettings() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appearance Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSliderSetting('Window Opacity', 'window_opacity', 0.5, 1.0),
          _buildSwitchSetting('Show Taskbar', 'show_taskbar'),
          _buildSwitchSetting('Show Clock', 'show_clock'),
          _buildSwitchSetting('Glass Effect', 'glass_effect'),
          _buildSliderSetting('Blur Intensity', 'blur_intensity', 0, 20),
          _buildSliderSetting('Corner Radius', 'corner_radius', 0, 30),
        ],
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: ThemePreset.values.map((theme) => GestureDetector(
              onTap: () => _theme.setTheme(theme),
              child: Container(
                width: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.accent, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(theme.icon, color: theme.accent, size: 32),
                    const SizedBox(height: 8),
                    Text(theme.name, style: TextStyle(color: theme.accent, fontSize: 12)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowSettings() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Window Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSwitchSetting('Window Animations', 'window_animations'),
          _buildSliderSetting('Default Width', 'default_width', 600, 1200),
          _buildSliderSetting('Default Height', 'default_height', 400, 800),
          const SizedBox(height: 16),
          const Text('Window Positions', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _resetWindowPositions(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset All Window Positions'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationSettings() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Animation Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSwitchSetting('Enable Animations', 'animations'),
          _buildSliderSetting('Animation Speed', 'animation_speed', 0.5, 2.0),
          _buildSwitchSetting('Window Animations', 'window_animations'),
          _buildSwitchSetting('Desktop Animations', 'desktop_animations'),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Privacy & Security', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSwitchSetting('Stealth Mode', 'stealth_mode'),
          _buildSwitchSetting('Clear History', 'clear_history'),
          _buildSwitchSetting('Disable Logging', 'disable_logging'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _clearAllData(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsSettings() {
    final apps = ['Terminal', 'WiFi Panel', 'SI Agent', 'File Manager', 'Browser', 'Text Editor'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('App Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...apps.map((app) => Card(
            color: Colors.grey.shade900,
            child: ListTile(
              leading: Icon(_getAppIcon(app), color: Colors.green),
              title: Text(app, style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: () => _openAppSettings(app),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAboutSettings() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About Zion OS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            color: Colors.grey.shade900,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.security, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text('Zion OS v3.1', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Build: ${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  const Text('© 2026 almwld', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(String label, String key, double min, double max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Slider(
            value: _appSettings[key] ?? min,
            min: min,
            max: max,
            activeColor: Colors.green,
            onChanged: (v) => _saveSetting(key, v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: _appSettings[key] ?? false,
      onChanged: (v) => _saveSetting(key, v),
      activeColor: Colors.green,
    );
  }

  void _resetWindowPositions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('window_positions');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Window positions reset')),
    );
  }

  void _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _loadSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared')),
    );
  }

  void _openAppSettings(String app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$app Settings'),
        content: Text('Settings for $app will be available soon'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  IconData _getAppIcon(String app) {
    switch (app) {
      case 'Terminal': return Icons.terminal;
      case 'WiFi Panel': return Icons.wifi;
      case 'SI Agent': return Icons.psychology;
      case 'File Manager': return Icons.folder;
      case 'Browser': return Icons.public;
      default: return Icons.edit;
    }
  }
}
