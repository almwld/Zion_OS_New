import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/biometric_service.dart';

class SettingsCenter extends StatefulWidget {
  const SettingsCenter({super.key});

  @override
  State<SettingsCenter> createState() => _SettingsCenterState();
}

class _SettingsCenterState extends State<SettingsCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  final List<String> _themeColors = ['Turquoise', 'Cyan', 'Green', 'Blue', 'Purple', 'Orange', 'Red'];
  final List<String> _fontFamilies = ['Default', 'Roboto', 'Open Sans', 'Cairo'];
  final List<String> _performanceModes = ['Power Save', 'Balanced', 'Performance', 'Turbo'];
  final List<String> _languages = ['English', 'العربية', 'Français', 'Español'];
  final List<String> _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY/MM/DD'];
  final List<String> _timeFormats = ['24h', '12h'];
  final List<int> _timeoutOptions = [15, 30, 60, 120, 300];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showChangePinDialog(SettingsService settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN', style: TextStyle(color: Color(0xFF00BCD4))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newPinController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New PIN',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPinController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              if (_newPinController.text == _confirmPinController.text && _newPinController.text.length == 4) {
                settings.pinCode = _newPinController.text;
                _newPinController.clear();
                _confirmPinController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN changed successfully'), backgroundColor: Color(0xFF00BCD4)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match or invalid'), backgroundColor: Colors.red),
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
    final settings = Provider.of<SettingsService>(context);
    final biometric = Provider.of<BiometricService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.palette), text: 'Appearance'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            Tab(icon: Icon(Icons.speed), text: 'Performance'),
            Tab(icon: Icon(Icons.language), text: 'Display'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppearanceTab(settings),
          _buildSecurityTab(settings, biometric),
          _buildNotificationsTab(settings),
          _buildPerformanceTab(settings),
          _buildDisplayTab(settings),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab(SettingsService settings) {
    return ListView(
      children: [
        _buildSectionHeader('Theme', Icons.palette),
        _buildThemeSelector(settings),
        _buildSwitchTile('Dark Mode', settings.darkMode, (v) => settings.darkMode = v),
        
        _buildSectionHeader('Typography', Icons.text_fields),
        _buildDropdownTile('Font Family', settings.fontFamily, _fontFamilies, (v) => settings.fontFamily = v),
        _buildSliderTile('Font Size', settings.fontSize, 10, 20, (v) => settings.fontSize = v),
        
        _buildSectionHeader('Layout', Icons.dashboard),
        _buildSwitchTile('Animations', settings.animationsEnabled, (v) => settings.animationsEnabled = v),
        
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSecurityTab(SettingsService settings, BiometricService biometric) {
    return ListView(
      children: [
        _buildSectionHeader('Authentication', Icons.fingerprint),
        if (biometric.isBiometricAvailable)
          _buildSwitchTile('Biometric Authentication', settings.biometricEnabled, (v) => settings.biometricEnabled = v),
        _buildSwitchTile('Auto Lock', settings.autoLockEnabled, (v) => settings.autoLockEnabled = v),
        if (settings.autoLockEnabled)
          _buildDropdownTile('Auto Lock Timeout', '${settings.autoLockTimeout} seconds', 
              _timeoutOptions.map((e) => '$e seconds').toList(), (v) {
            settings.autoLockTimeout = int.parse(v.split(' ')[0]);
          }),
        _buildInfoTile('Change PIN', 'Update your security PIN', Icons.lock, () => _showChangePinDialog(settings)),
        
        _buildSectionHeader('Privacy', Icons.privacy_tip),
        _buildSwitchTile('Incognito Mode', settings.incognitoMode, (v) => settings.incognitoMode = v),
        _buildSwitchTile('Clear History on Exit', settings.clearHistoryOnExit, (v) => settings.clearHistoryOnExit = v),
        
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildNotificationsTab(SettingsService settings) {
    return ListView(
      children: [
        _buildSectionHeader('Push Notifications', Icons.notifications),
        _buildSwitchTile('Enable Notifications', settings.pushNotifications, (v) => settings.pushNotifications = v),
        _buildSwitchTile('Sound', settings.soundEnabled, (v) => settings.soundEnabled = v),
        _buildSwitchTile('Vibration', settings.vibrationEnabled, (v) => settings.vibrationEnabled = v),
        
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildPerformanceTab(SettingsService settings) {
    return ListView(
      children: [
        _buildSectionHeader('Performance Mode', Icons.speed),
        _buildDropdownTile('Mode', settings.performanceMode, _performanceModes, (v) => settings.performanceMode = v),
        _buildSwitchTile('Background Processes', true, (v) {}),
        
        _buildSectionHeader('Memory', Icons.memory),
        _buildInfoTile('Clear Cache', 'Free up storage space', Icons.cleaning_services, () {}),
        _buildInfoTile('Memory Usage', 'View memory statistics', Icons.analytics, () {}),
        
        const SizedBox(height: 30),
        
        // Reset Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Settings', style: TextStyle(color: Color(0xFF00BCD4))),
                  content: const Text('Reset all settings to default values?', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.black,
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed == true) {
                await settings.resetToDefault();
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayTab(SettingsService settings) {
    return ListView(
      children: [
        _buildSectionHeader('Language', Icons.language),
        _buildDropdownTile('Language', settings.language, _languages, (v) => settings.language = v),
        
        _buildSectionHeader('Date & Time', Icons.calendar_today),
        _buildDropdownTile('Date Format', settings.dateFormat, _dateFormats, (v) => settings.dateFormat = v),
        _buildDropdownTile('Time Format', settings.timeFormat, _timeFormats, (v) => settings.timeFormat = v),
        
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF00BCD4)),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String title, String value, List<String> items, Function(String) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          DropdownButton<String>(
            value: value,
            dropdownColor: Colors.black,
            underline: const SizedBox(),
            style: const TextStyle(color: Color(0xFF00BCD4)),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String title, double value, double min, double max, Function(double) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text('${value.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFF00BCD4))),
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

  Widget _buildInfoTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00BCD4)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF00BCD4)),
      onTap: onTap,
    );
  }

  Widget _buildThemeSelector(SettingsService settings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme Color', style: TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _themeColors.map((color) => GestureDetector(
              onTap: () => settings.themeColor = color,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getColorFromName(color),
                  shape: BoxShape.circle,
                  border: settings.themeColor == color
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                ),
              ),
            )).toList(),
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
      case 'Red': return Colors.red;
      default: return const Color(0xFF00BCD4);
    }
  }
}
