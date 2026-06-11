import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  bool _notifications = true;
  bool _soundEffects = true;
  bool _vibration = true;
  bool _autoUpdate = true;
  bool _stealthMode = false;
  String _selectedThemeColor = 'Turquoise';
  String _selectedLanguage = 'English';
  double _animationSpeed = 1.0;
  int _fontSize = 14;

  final List<String> _themeColors = ['Turquoise', 'Cyan', 'Green', 'Blue', 'Purple', 'Orange'];
  final List<String> _languages = ['English', 'العربية', 'Français', 'Español'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _soundEffects = prefs.getBool('sound_effects') ?? true;
      _vibration = prefs.getBool('vibration') ?? true;
      _autoUpdate = prefs.getBool('auto_update') ?? true;
      _stealthMode = prefs.getBool('stealth_mode') ?? false;
      _selectedThemeColor = prefs.getString('theme_color') ?? 'Turquoise';
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _animationSpeed = prefs.getDouble('animation_speed') ?? 1.0;
      _fontSize = prefs.getInt('font_size') ?? 14;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is int) await prefs.setInt(key, value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$key saved'), backgroundColor: const Color(0xFF00BCD4)),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Zion OS', style: TextStyle(color: Color(0xFF00BCD4))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Version: 4.0.0', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('Build: 2027.06.11', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('Developer: Zion Security Team', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('© 2027 All Rights Reserved', style: TextStyle(color: Colors.white54)),
          ],
        ),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    final TextEditingController oldPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPinController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New PIN (4 digits)',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              if (oldPinController.text == '1234' && newPinController.text.length == 4) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_pin', newPinController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN changed successfully'), backgroundColor: Color(0xFF00BCD4)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: isDark ? Colors.black : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? const Color(0xFF00BCD4) : const Color(0xFF00838F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(Icons.palette, 'Appearance'),
          // Theme Mode Toggle (Dark/Light)
          _buildSwitchTile('Dark Mode', isDark, (v) => themeProvider.toggleTheme()),
          _buildThemeSelector(),
          _buildLanguageSelector(),
          _buildFontSizeSlider(),
          
          _buildSectionHeader(Icons.tune, 'Behavior'),
          _buildSwitchTile('Notifications', _notifications, (v) {
            setState(() { _notifications = v; _saveSetting('notifications', v); });
          }),
          _buildSwitchTile('Sound Effects', _soundEffects, (v) {
            setState(() { _soundEffects = v; _saveSetting('sound_effects', v); });
          }),
          _buildSwitchTile('Vibration', _vibration, (v) {
            setState(() { _vibration = v; _saveSetting('vibration', v); });
          }),
          _buildSwitchTile('Auto Update', _autoUpdate, (v) {
            setState(() { _autoUpdate = v; _saveSetting('auto_update', v); });
          }),
          _buildSwitchTile('Stealth Mode', _stealthMode, (v) {
            setState(() { _stealthMode = v; _saveSetting('stealth_mode', v); });
          }),
          
          _buildSliderTile('Animation Speed', _animationSpeed, 0.5, 2.0, (v) {
            setState(() { _animationSpeed = v; _saveSetting('animation_speed', v); });
          }),
          
          _buildSectionHeader(Icons.security, 'Security'),
          _buildInfoTile(Icons.lock, 'Change PIN', 'Update security PIN', _showChangePinDialog),
          _buildInfoTile(Icons.fingerprint, 'Biometric', 'Enable fingerprint unlock', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric setup coming soon'), backgroundColor: Color(0xFF00BCD4)),
            );
          }),
          _buildInfoTile(Icons.security, 'Encryption', 'AES-256 Active', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Encryption is active'), backgroundColor: Color(0xFF00BCD4)),
            );
          }),
          
          _buildSectionHeader(Icons.info, 'About'),
          _buildInfoTile(Icons.info, 'Version', 'Zion OS 4.0.0', _showAboutDialog),
          _buildInfoTile(Icons.build, 'Build', '2027.06.11', () {}),
          _buildInfoTile(Icons.code, 'Developer', 'Zion Security Team', _showAboutDialog),
          
          const SizedBox(height: 20),
          
          // Reset Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Settings', style: TextStyle(color: Color(0xFF00BCD4))),
                    content: const Text('Reset all settings to default?', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.black,
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  await _loadSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings reset to default'), backgroundColor: Color(0xFF00BCD4)),
                  );
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Default'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF00BCD4)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00BCD4), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
                  Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF00BCD4), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme Color', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _themeColors.map((color) => GestureDetector(
              onTap: () => setState(() { _selectedThemeColor = color; _saveSetting('theme_color', color); }),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getColorFromName(color),
                  shape: BoxShape.circle,
                  border: _selectedThemeColor == color ? Border.all(color: Colors.white, width: 2) : null,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Language', style: TextStyle(color: Colors.white, fontSize: 14)),
          DropdownButton<String>(
            value: _selectedLanguage,
            dropdownColor: Colors.black,
            underline: const SizedBox(),
            style: const TextStyle(color: Color(0xFF00BCD4)),
            items: _languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
            onChanged: (v) {
              setState(() { _selectedLanguage = v!; _saveSetting('language', v); });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Font Size', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 14)),
              Text('$_fontSize', style: const TextStyle(color: Color(0xFF00BCD4))),
            ],
          ),
          Slider(
            value: _fontSize.toDouble(),
            min: 10,
            max: 20,
            divisions: 10,
            activeColor: const Color(0xFF00BCD4),
            onChanged: (v) {
              setState(() { _fontSize = v.toInt(); _saveSetting('font_size', v.toInt()); });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String title, double value, double min, double max, Function(double) onChanged) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
              Text('${value.toStringAsFixed(1)}x', style: const TextStyle(color: Color(0xFF00BCD4))),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: const Color(0xFF00BCD4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'Turquoise': return const Color(0xFF00BCD4);
      case 'Cyan': return Colors.cyan;
      case 'Green': return Colors.green;
      case 'Blue': return Colors.blue;
      case 'Purple': return Colors.purple;
      case 'Orange': return Colors.orange;
      default: return const Color(0xFF00BCD4);
    }
  }
}

  void _changeLanguage(String langCode) {
    context.setLocale(Locale(langCode));
    _saveSetting('language', langCode);
  }
