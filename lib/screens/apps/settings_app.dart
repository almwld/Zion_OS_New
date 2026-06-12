import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
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
  String _selectedLanguage = 'ar';
  double _animationSpeed = 1.0;
  int _fontSize = 14;
  String _currentPin = '1234';

  final List<String> _themeColors = ['Turquoise', 'Cyan', 'Green', 'Blue', 'Purple', 'Orange'];
  final List<Map<String, dynamic>> _languages = [
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
  ];

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
      _selectedLanguage = prefs.getString('language') ?? 'ar';
      _animationSpeed = prefs.getDouble('animation_speed') ?? 1.0;
      _fontSize = prefs.getInt('font_size') ?? 14;
      _currentPin = prefs.getString('user_pin') ?? '1234';
    });
    _applyThemeColor();
    _applyFontSize();
  }

  void _applyThemeColor() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    Color primaryColor;
    switch (_selectedThemeColor) {
      case 'Turquoise': primaryColor = const Color(0xFF00BCD4); break;
      case 'Cyan': primaryColor = Colors.cyan; break;
      case 'Green': primaryColor = Colors.green; break;
      case 'Blue': primaryColor = Colors.blue; break;
      case 'Purple': primaryColor = Colors.purple; break;
      case 'Orange': primaryColor = Colors.orange; break;
      default: primaryColor = const Color(0xFF00BCD4);
    }
    themeProvider.setPrimaryColor(primaryColor);
  }

  void _applyFontSize() {
    // سيتم تطبيق حجم الخط في جميع أنحاء التطبيق
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is int) await prefs.setInt(key, value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$key ${'saved'.tr()}'), backgroundColor: const Color(0xFF00BCD4)),
    );
  }

  void _changeLanguage(String langCode) {
    setState(() => _selectedLanguage = langCode);
    context.setLocale(Locale(langCode));
    _saveSetting('language', langCode);
  }

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('change_pin'.tr(), style: const TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'current_pin'.tr(),
                labelStyle: const TextStyle(color: Color(0xFF00BCD4)),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPinController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'new_pin'.tr(),
                labelStyle: const TextStyle(color: Color(0xFF00BCD4)),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPinController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'confirm_pin'.tr(),
                labelStyle: const TextStyle(color: Color(0xFF00BCD4)),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (oldPinController.text == _currentPin) {
                if (newPinController.text == confirmPinController.text && newPinController.text.length == 4) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_pin', newPinController.text);
                  _currentPin = newPinController.text;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN changed successfully'), backgroundColor: Color(0xFF00BCD4)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN mismatch or invalid'), backgroundColor: Colors.red),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wrong current PIN'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('save'.tr(), style: const TextStyle(color: Color(0xFF00BCD4))),
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
        title: Text('settings'.tr(), style: TextStyle(color: themeProvider.primaryColor)),
        backgroundColor: isDark ? Colors.black : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(Icons.palette, 'appearance'.tr()),
          _buildSwitchTile('dark_mode'.tr(), isDark, (v) => themeProvider.toggleTheme()),
          _buildThemeSelector(),
          _buildLanguageSelector(),
          _buildFontSizeSlider(),
          
          _buildSectionHeader(Icons.tune, 'behavior'.tr()),
          _buildSwitchTile('notifications'.tr(), _notifications, (v) {
            setState(() { _notifications = v; _saveSetting('notifications', v); });
          }),
          _buildSwitchTile('sound_effects'.tr(), _soundEffects, (v) {
            setState(() { _soundEffects = v; _saveSetting('sound_effects', v); });
          }),
          _buildSwitchTile('vibration'.tr(), _vibration, (v) {
            setState(() { _vibration = v; _saveSetting('vibration', v); });
          }),
          _buildSwitchTile('auto_update'.tr(), _autoUpdate, (v) {
            setState(() { _autoUpdate = v; _saveSetting('auto_update', v); });
          }),
          _buildSwitchTile('stealth_mode'.tr(), _stealthMode, (v) {
            setState(() { _stealthMode = v; _saveSetting('stealth_mode', v); });
          }),
          
          _buildSliderTile('animation_speed'.tr(), _animationSpeed, 0.5, 2.0, (v) {
            setState(() { _animationSpeed = v; _saveSetting('animation_speed', v); });
          }),
          
          _buildSectionHeader(Icons.security, 'security'.tr()),
          _buildInfoTile(Icons.lock, 'change_pin'.tr(), 'update_security_pin'.tr(), _showChangePinDialog),
          _buildInfoTile(Icons.fingerprint, 'biometric'.tr(), 'enable_fingerprint'.tr(), () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon'), backgroundColor: Color(0xFF00BCD4)),
            );
          }),
          _buildInfoTile(Icons.security, 'encryption'.tr(), 'aes256_active'.tr(), () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Encryption is active'), backgroundColor: Color(0xFF00BCD4)),
            );
          }),
          
          _buildSectionHeader(Icons.info, 'about'.tr()),
          _buildInfoTile(Icons.info, 'version'.tr(), 'Zion OS 4.0.0', () {}),
          _buildInfoTile(Icons.build, 'build'.tr(), '2027.06.11', () {}),
          _buildInfoTile(Icons.code, 'developer'.tr(), 'Zion Security Team', () {}),
          
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('reset'.tr(), style: const TextStyle(color: Color(0xFF00BCD4))),
                    content: Text('reset_confirm'.tr(), style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.black,
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white54))),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('reset'.tr(), style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  await _loadSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('reset_done'.tr()), backgroundColor: Color(0xFF00BCD4)),
                  );
                }
              },
              icon: const Icon(Icons.restore),
              label: Text('reset'.tr()),
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
              onTap: () => setState(() { _selectedThemeColor = color; _saveSetting('theme_color', color); _applyThemeColor(); }),
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
            items: _languages.map((lang) => DropdownMenuItem(
              value: lang['code'],
              child: Row(
                children: [
                  Text(lang['flag'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(lang['name']),
                ],
              ),
            )).toList(),
            onChanged: (v) => _changeLanguage(v!),
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
              setState(() { _fontSize = v.toInt(); _saveSetting('font_size', v.toInt()); _applyFontSize(); });
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
