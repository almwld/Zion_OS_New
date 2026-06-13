import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';
import '../widgets/floating_radar_chart.dart';
import '../widgets/radar_chart_widget.dart';
import '../widgets/background_selector.dart';
import '../widgets/floating_window_manager.dart';
import '../utils/icon_mapper.dart';
import 'apps/terminal_app.dart';
import 'apps/network_scanner.dart';
import 'apps/wifi_scanner.dart';
import 'apps/exploit_db.dart';
import 'apps/crypto_tool.dart';
import 'apps/stealth_mode.dart';
import 'apps/password_cracker.dart';
import 'apps/ddos_attack.dart';
import 'apps/forensics.dart';
import 'apps/database_hacking.dart';
import 'apps/cloud_attacks.dart';
import 'apps/settings_app.dart';
import 'apps/file_manager.dart';
import 'apps/web_browser.dart';
import 'apps/text_analyzer.dart';
import 'apps/calculator.dart';
import 'apps/notes_app.dart';
import 'apps/weather_app.dart';
import 'apps/currency_converter.dart';
import 'apps/translator_app.dart';
import 'apps/maps_app.dart';
import 'apps/radio_app.dart';
import 'apps/file_sharing.dart';
import 'apps/email_client.dart';
import 'apps/date_calculator.dart';
import 'apps/unit_converter.dart';
import 'apps/percentage_calculator.dart';
import 'apps/battery_saver.dart';
import 'apps/backup_manager.dart';
import 'apps/cleaner.dart';
import 'apps/app_lock.dart';
import 'apps/notification_manager.dart';
import 'apps/gallery_app.dart';
import 'apps/video_player_app.dart';
import 'apps/alarms_clock.dart';
import 'apps/calendar_simple.dart';
import 'apps/qr_scanner_simple.dart';
import 'apps/documents_simple.dart';
import 'apps/security_hub.dart';
import 'apps/tools_hub.dart';
import 'apps/performance_hub.dart';
import 'apps/data_hub.dart';
import 'apps/network_hub.dart';
import 'apps/privacy_hub.dart';
import 'apps/automation_hub.dart';

class ZionDesktop extends StatefulWidget {
  const ZionDesktop({super.key});

  @override
  State<ZionDesktop> createState() => _ZionDesktopState();
}

class _ZionDesktopState extends State<ZionDesktop> {
  final GlobalKey<FloatingWindowManagerState> _windowManagerKey = GlobalKey();
  String _currentTime = "";
  String _currentDate = "";
  int _batteryLevel = 85;
  int _selectedIndex = 0;
  bool _showRadarChart = true;
  List<Widget> _openWindows = [];

  final List<Map<String, dynamic>> _categories = [
    {"name": "attack", "icon": Icons.flash_on},
    {"name": "defense", "icon": Icons.shield},
    {"name": "analysis", "icon": Icons.analytics},
    {"name": "tools", "icon": Icons.build},
  ];

  final List<Map<String, dynamic>> _apps = [
    // ATTACK
    {"name": "WIFI", "icon": Icons.wifi, "category": "attack", "screen": const WiFiScannerApp()},
    {"name": "EXPLOIT", "icon": Icons.bug_report, "category": "attack", "screen": const ExploitDBApp()},
    {"name": "CRACKER", "icon": Icons.vpn_key, "category": "attack", "screen": const PasswordCrackerApp()},
    {"name": "DDOS", "icon": Icons.speed, "category": "attack", "screen": const DDoSAttackApp()},
    {"name": "DATABASE", "icon": Icons.storage, "category": "attack", "screen": const DatabaseHackingApp()},
    {"name": "CLOUD", "icon": Icons.cloud, "category": "attack", "screen": const CloudAttacksApp()},
    // DEFENSE
    {"name": "STEALTH", "icon": Icons.visibility_off, "category": "defense", "screen": const StealthModeApp()},
    {"name": "CRYPTO", "icon": Icons.lock, "category": "defense", "screen": const CryptoToolApp()},
    {"name": "BATTERY", "icon": Icons.battery_charging_full, "category": "defense", "screen": const BatterySaverApp()},
    // ANALYSIS
    {"name": "NETWORK", "icon": Icons.network_wifi, "category": "analysis", "screen": const NetworkScannerApp()},
    {"name": "FORENSICS", "icon": Icons.search, "category": "analysis", "screen": const ForensicsApp()},
    {"name": "TEXT ANALYZER", "icon": Icons.analytics, "category": "analysis", "screen": const TextAnalyzerApp()},
    // TOOLS
    {"name": "TERMINAL", "icon": Icons.terminal, "category": "tools", "screen": const TerminalApp()},
    {"name": "FILE MANAGER", "icon": Icons.folder, "category": "tools", "screen": const FileManagerApp()},
    {"name": "BROWSER", "icon": Icons.public, "category": "tools", "screen": const WebBrowserApp()},
    {"name": "SETTINGS", "icon": Icons.settings, "category": "tools", "screen": const SettingsApp()},
    {"name": "CALCULATOR", "icon": Icons.calculate, "category": "tools", "screen": const CalculatorApp()},
    {"name": "NOTES", "icon": Icons.note, "category": "tools", "screen": const NotesApp()},
    {"name": "WEATHER", "icon": Icons.wb_sunny, "category": "tools", "screen": const WeatherApp()},
    {"name": "MAPS", "icon": Icons.map, "category": "tools", "screen": const MapsApp()},
    {"name": "RADIO", "icon": Icons.radio, "category": "tools", "screen": const RadioApp()},
    {"name": "EMAIL", "icon": Icons.email, "category": "tools", "screen": const EmailClient()},
    {"name": "GALLERY", "icon": Icons.photo_library, "category": "tools", "screen": const GalleryApp()},
    {"name": "VIDEO", "icon": Icons.play_circle_filled, "category": "tools", "screen": const VideoPlayerApp()},
    {"name": "CLOCK", "icon": Icons.access_time, "category": "tools", "screen": const AlarmsClockApp()},
    {"name": "CALENDAR", "icon": Icons.calendar_today, "category": "tools", "screen": const CalendarApp()},
    {"name": "QR CODE", "icon": Icons.qr_code_scanner, "category": "tools", "screen": const QRScannerApp()},
    {"name": "DOCUMENTS", "icon": Icons.description, "category": "tools", "screen": const DocumentsApp()},
    {"name": "BACKUP", "icon": Icons.backup, "category": "tools", "screen": const BackupManagerApp()},
    {"name": "CLEANER", "icon": Icons.cleaning_services, "category": "tools", "screen": const CleanerApp()},
    {"name": "APP LOCK", "icon": Icons.lock, "category": "tools", "screen": const AppLockApp()},
    {"name": "NOTIFY", "icon": Icons.notifications, "category": "tools", "screen": const NotificationManagerApp()},
    {"name": "SECURITY HUB", "icon": Icons.security, "category": "tools", "screen": const SecurityHubApp()},
    {"name": "TOOLS HUB", "icon": Icons.build, "category": "tools", "screen": const ToolsHubApp()},
    {"name": "PERF HUB", "icon": Icons.speed, "category": "tools", "screen": const PerformanceHubApp()},
    {"name": "DATA HUB", "icon": Icons.storage, "category": "tools", "screen": const DataHubApp()},
    {"name": "NET HUB", "icon": Icons.network_check, "category": "tools", "screen": const NetworkHubApp()},
    {"name": "PRIV HUB", "icon": Icons.privacy_tip, "category": "tools", "screen": const PrivacyHubApp()},
    {"name": "AUTO HUB", "icon": Icons.settings, "category": "tools", "screen": const AutomationHubApp()},
    {"name": "UNIT CONV", "icon": Icons.science, "category": "tools", "screen": const UnitConverterApp()},
    {"name": "PERCENT", "icon": Icons.percent, "category": "tools", "screen": const PercentageCalculatorApp()},
    {"name": "DATE CALC", "icon": Icons.calculate, "category": "tools", "screen": const DateCalculatorApp()},
    {"name": "CURRENCY", "icon": Icons.attach_money, "category": "tools", "screen": const CurrencyConverterApp()},
    {"name": "TRANSLATOR", "icon": Icons.translate, "category": "tools", "screen": const TranslatorApp()},
  ];

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _getBatteryLevel();
  }

  void _updateDateTime() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          _currentDate = "${now.day}/${now.month}/${now.year}";
        });
        _updateDateTime();
      }
    });
  }

  void _getBatteryLevel() {
    // محاكاة (سيتم ربطه بالبيانات الحقيقية لاحقاً)
  }

  void _openApp(Map<String, dynamic> app) {
    if (app['screen'] != null) {
      _windowManagerKey.currentState?.openWindow(app['name'], app['screen']);
    }
  }

  void _showQuickSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quick Settings', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 18)),
            const Divider(color: Color(0xFF00BCD4)),
            ListTile(leading: const Icon(Icons.brightness_6, color: Color(0xFF00BCD4)), title: const Text('Dark Mode'), trailing: Switch(value: Provider.of<ThemeProvider>(context).isDarkMode, onChanged: (_) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme())),
            ListTile(leading: const Icon(Icons.wallpaper, color: Color(0xFF00BCD4)), title: const Text('Change Background'), onTap: () { Navigator.pop(_); showDialog(context: context, builder: (_) => const BackgroundSelector()); }),
            ListTile(leading: const Icon(Icons.settings, color: Color(0xFF00BCD4)), title: const Text('Open Settings'), onTap: () { Navigator.pop(_); _openApp(_apps.firstWhere((a) => a['name'] == 'SETTINGS')); }),
          ],
        ),
      ),
    );
  }

  void _showBatteryInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.95),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Battery', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 18)),
            const Divider(color: Color(0xFF00BCD4)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.battery_full, color: Colors.green, size: 40),
              const SizedBox(width: 16),
              Text('$_batteryLevel%', style: const TextStyle(color: Colors.white, fontSize: 24)),
            ]),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _batteryLevel / 100, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Estimated remaining: 8h 30m', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final iconSize = Provider.of<ThemeProvider>(context).iconSize;
    final filteredApps = _apps.where((a) => a['category'] == _categories[_selectedIndex]['name'].tr()).toList();

    return FloatingWindowManager(
      key: _windowManagerKey,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        body: Stack(
          children: [
            // الخلفية
            Container(decoration: BoxDecoration(gradient: RadialGradient(colors: isDark ? [const Color(0xFF0A2E38), Colors.black] : [const Color(0xFFE0F7FA), Colors.white]))),
            // المحتوى الرئيسي
            Column(
              children: [
                // شريط الحالة المتقدم
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // الساعة والتاريخ (قابل للنقر)
                      GestureDetector(
                        onTap: _showQuickSettings,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_currentTime, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(_currentDate, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ),
                      // البطارية (قابلة للنقر)
                      GestureDetector(
                        onTap: _showBatteryInfo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Icon(Icons.battery_full, color: Colors.green, size: 18),
                              const SizedBox(width: 4),
                              Text('$_batteryLevel%', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // فئات التطبيقات
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (ctx, i) {
                      final isSelected = _selectedIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(isSelected ? 0 : 0.3)),
                          ),
                          child: Center(child: Text(_categories[i]['name'].tr(), style: TextStyle(color: isSelected ? Colors.black : const Color(0xFF00BCD4)))),
                        ),
                      );
                    },
                  ),
                ),
                // شبكة التطبيقات
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.9, crossAxisSpacing: 16, mainAxisSpacing: 16),
                    itemCount: filteredApps.length,
                    itemBuilder: (ctx, i) {
                      final app = filteredApps[i];
                      return GestureDetector(
                        onTap: () => _openApp(app),
                        child: Column(
                          children: [
                            Container(
                              width: iconSize, height: iconSize,
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]), borderRadius: BorderRadius.circular(16)),
                              child: IconMapper.getIcon(app['name'], size: iconSize * 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(app['name'].tr(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // شريط سفلي (Dock)
                Container(
                  height: 70,
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDockIcon(Icons.terminal, 'TERMINAL', _openApp),
                      _buildDockIcon(Icons.folder, 'FILE MANAGER', _openApp),
                      _buildDockIcon(Icons.public, 'BROWSER', _openApp),
                      _buildDockIcon(Icons.security, 'SECURITY HUB', _openApp),
                      _buildDockIcon(Icons.settings, 'SETTINGS', _openApp),
                    ],
                  ),
                ),
              ],
            ),
            // الرادار العائم
            if (_showRadarChart) FloatingRadarChart(onClose: () => setState(() => _showRadarChart = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildDockIcon(IconData icon, String appName, Function(Map<String, dynamic>) onTap) {
    final app = _apps.firstWhere((a) => a['name'] == appName);
    return GestureDetector(
      onTap: () => onTap(app),
      child: Column(
        children: [
          Container(width: 45, height: 45, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 22)),
          const SizedBox(height: 4),
          Text(appName.tr(), style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ],
      ),
    );
  }
}
