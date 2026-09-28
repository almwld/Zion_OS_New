import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrowserSettings extends StatefulWidget {
  const BrowserSettings({super.key});

  @override
  State<BrowserSettings> createState() => _BrowserSettingsState();
}

class _BrowserSettingsState extends State<BrowserSettings> {
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
        'homepage': prefs.getString('browser_homepage') ?? 'https://www.google.com',
        'search_engine': prefs.getString('browser_search_engine') ?? 'google',
        'block_popups': prefs.getBool('browser_block_popups') ?? true,
        'block_ads': prefs.getBool('browser_block_ads') ?? false,
        'clear_history': prefs.getBool('browser_clear_history') ?? false,
        'private_mode': prefs.getBool('browser_private_mode') ?? false,
        'javascript': prefs.getBool('browser_javascript') ?? true,
        'cookies': prefs.getBool('browser_cookies') ?? true,
      };
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    else if (value is String) await prefs.setString(key, value);
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Browser Settings'),
        backgroundColor: Colors.teal.shade900,
      ),
      body: ListView(
        children: [
          _buildTextFieldSetting('Homepage', 'homepage'),
          _buildDropdownSetting('Search Engine', 'search_engine', ['google', 'bing', 'duckduckgo', 'yahoo']),
          _buildSwitchSetting('Block Pop-ups', 'block_popups'),
          _buildSwitchSetting('Block Ads', 'block_ads'),
          _buildSwitchSetting('Clear History on Exit', 'clear_history'),
          _buildSwitchSetting('Private Mode', 'private_mode'),
          _buildSwitchSetting('JavaScript', 'javascript'),
          _buildSwitchSetting('Cookies', 'cookies'),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.red),
            title: const Text('Clear Browsing History', style: TextStyle(color: Colors.white)),
            onTap: () => _clearHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldSetting(String label, String key) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: TextField(
        controller: TextEditingController(text: _settings[key]),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onSubmitted: (v) => _saveSetting(key, v),
      ),
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
      activeColor: Colors.teal,
    );
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('browser_history');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Browsing history cleared')),
    );
  }
}
