import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/theme_provider.dart';

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  final List<String> _languages = ['English', 'العربية'];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final currentLocale = context.locale.languageCode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: isDark ? Colors.black : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('appearance'.tr()),
          _buildSwitchTile('dark_mode'.tr(), themeProvider.isDarkMode, (_) => themeProvider.toggleTheme()),
          _buildSliderTile('font_size'.tr(), themeProvider.fontScale, 0.8, 1.5, (v) => themeProvider.setFontScale(v)),
          _buildSliderTile('icon_size'.tr(), themeProvider.iconSize, 48, 78, (v) => themeProvider.setIconSize(v)),
          _buildSectionHeader('security'.tr()),
          _buildInfoTile('change_pin'.tr(), () => _showChangePinDialog(themeProvider)),
          const Divider(),
          _buildLanguageSelector(currentLocale),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)));
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(title: Text(title), value: value, onChanged: onChanged, activeColor: const Color(0xFF00BCD4));
  }

  Widget _buildSliderTile(String title, double value, double min, double max, Function(double) onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Slider(value: value, min: min, max: max, onChanged: onChanged, activeColor: const Color(0xFF00BCD4)),
      trailing: Text(value.toStringAsFixed(1)),
    );
  }

  Widget _buildInfoTile(String title, VoidCallback onTap) {
    return ListTile(title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }

  Widget _buildLanguageSelector(String currentLocale) {
    return ListTile(
      title: Text('language'.tr()),
      trailing: DropdownButton<String>(
        value: currentLocale == 'ar' ? 'العربية' : 'English',
        items: const [
          DropdownMenuItem(value: 'English', child: Text('English')),
          DropdownMenuItem(value: 'العربية', child: Text('العربية')),
        ],
        onChanged: (value) {
          if (value == 'العربية') {
            context.setLocale(const Locale('ar'));
          } else {
            context.setLocale(const Locale('en'));
          }
        },
      ),
    );
  }

  void _showChangePinDialog(ThemeProvider tp) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('change_pin'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Old PIN'), autofocus: true),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New PIN (4 digits)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () async {
              if (await tp.changePin(oldCtrl.text, newCtrl.text)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed successfully'), backgroundColor: Color(0xFF00BCD4)));
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid PIN'), backgroundColor: Colors.red));
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }
}
