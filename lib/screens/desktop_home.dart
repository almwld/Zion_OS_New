import 'package:flutter/material.dart';
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
import 'apps/qr_scanner_simple.dart';
import 'apps/calendar_simple.dart';
import 'apps/gallery_simple.dart';
import 'apps/documents_simple.dart';
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
import 'apps/system_monitor.dart';
import 'apps/task_manager.dart';
import 'apps/network_analyzer.dart';
import 'apps/disk_analyzer.dart';
import 'apps/process_manager.dart';
import 'apps/system_info.dart';
import 'apps/network_tools.dart';
import 'apps/performance_monitor.dart';
import 'apps/battery_saver.dart';

class ZionDesktop extends StatefulWidget {
  const ZionDesktop({super.key});

  @override
  State<ZionDesktop> createState() => _ZionDesktopState();
}

class _ZionDesktopState extends State<ZionDesktop> {
  String _currentTime = "";
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {"name": "ATTACK", "icon": Icons.flash_on},
    {"name": "DEFENSE", "icon": Icons.shield},
    {"name": "ANALYSIS", "icon": Icons.analytics},
    {"name": "TOOLS", "icon": Icons.build},
  ];

  final List<Map<String, dynamic>> _apps = [
    // ATTACK
    {"name": "WIFI", "icon": Icons.wifi, "category": "ATTACK", "screen": const WiFiScannerApp()},
    {"name": "EXPLOIT", "icon": Icons.bug_report, "category": "ATTACK", "screen": const ExploitDBApp()},
    {"name": "CRACKER", "icon": Icons.vpn_key, "category": "ATTACK", "screen": const PasswordCrackerApp()},
    {"name": "DDOS", "icon": Icons.speed, "category": "ATTACK", "screen": const DDoSAttackApp()},
    {"name": "DATABASE", "icon": Icons.storage, "category": "ATTACK", "screen": const DatabaseHackingApp()},
    {"name": "CLOUD", "icon": Icons.cloud, "category": "ATTACK", "screen": const CloudAttacksApp()},
    
    // DEFENSE
    {"name": "STEALTH", "icon": Icons.visibility_off, "category": "DEFENSE", "screen": const StealthModeApp()},
    {"name": "CRYPTO", "icon": Icons.lock, "category": "DEFENSE", "screen": const CryptoToolApp()},
    
    // ANALYSIS
    {"name": "NETWORK", "icon": Icons.network_wifi, "category": "ANALYSIS", "screen": const NetworkScannerApp()},
    {"name": "FORENSICS", "icon": Icons.search, "category": "ANALYSIS", "screen": const ForensicsApp()},
    {"name": "TEXT ANALYZER", "icon": Icons.analytics, "category": "ANALYSIS", "screen": const TextAnalyzerApp()},
    
    // TOOLS
    {"name": "TERMINAL", "icon": Icons.terminal, "category": "TOOLS", "screen": const TerminalApp()},
    {"name": "FILE MANAGER", "icon": Icons.folder, "category": "TOOLS", "screen": const FileManagerApp()},
    {"name": "BROWSER", "icon": Icons.public, "category": "TOOLS", "screen": const WebBrowserApp()},
    {"name": "CALCULATOR", "icon": Icons.calculate, "category": "TOOLS", "screen": const CalculatorApp()},
    {"name": "UNIT CONV", "icon": Icons.science, "category": "TOOLS", "screen": const UnitConverterApp()},
    {"name": "PERCENT", "icon": Icons.percent, "category": "TOOLS", "screen": const PercentageCalculatorApp()},
    {"name": "DATE CALC", "icon": Icons.calculate, "category": "TOOLS", "screen": const DateCalculatorApp()},
    {"name": "NOTES", "icon": Icons.note, "category": "TOOLS", "screen": const NotesApp()},
    {"name": "WEATHER", "icon": Icons.wb_sunny, "category": "TOOLS", "screen": const WeatherApp()},
    {"name": "CURRENCY", "icon": Icons.attach_money, "category": "TOOLS", "screen": const CurrencyConverterApp()},
    {"name": "TRANSLATOR", "icon": Icons.translate, "category": "TOOLS", "screen": const TranslatorApp()},
    {"name": "MAPS", "icon": Icons.map, "category": "TOOLS", "screen": const MapsApp()},
    {"name": "RADIO", "icon": Icons.radio, "category": "TOOLS", "screen": const RadioApp()},
    {"name": "SHARE", "icon": Icons.share, "category": "TOOLS", "screen": const FileSharingApp()},
    {"name": "EMAIL", "icon": Icons.email, "category": "TOOLS", "screen": const EmailClient()},
    {"name": "SETTINGS", "icon": Icons.settings, "category": "TOOLS", "screen": const SettingsApp()},
    {"name": "QR CODE", "icon": Icons.qr_code_scanner, "category": "TOOLS", "screen": const QRScannerApp()},
    {"name": "CALENDAR", "icon": Icons.calendar_today, "category": "TOOLS", "screen": const CalendarApp()},
    {"name": "GALLERY", "icon": Icons.photo_library, "category": "TOOLS", "screen": const GalleryApp()},
    {"name": "DOCUMENTS", "icon": Icons.description, "category": "TOOLS", "screen": const DocumentsApp()},
    {"name": "MONITOR", "icon": Icons.assessment, "category": "TOOLS", "screen": const SystemMonitorApp()},
    {"name": "TASKS", "icon": Icons.list_alt, "category": "TOOLS", "screen": const TaskManagerApp()},
    {"name": "NET ANALYZER", "icon": Icons.analytics, "category": "TOOLS", "screen": const NetworkAnalyzerApp()},
    {"name": "DISK ANALYZER", "icon": Icons.storage, "category": "TOOLS", "screen": const DiskAnalyzerApp()},
    {"name": "PROCESS", "icon": Icons.code, "category": "TOOLS", "screen": const ProcessManagerApp()},
    {"name": "SYS INFO", "icon": Icons.info, "category": "TOOLS", "screen": const SystemInfoApp()},
    {"name": "NET TOOLS", "icon": Icons.wifi, "category": "TOOLS", "screen": const NetworkToolsApp()},
    {"name": "PERF MON", "icon": Icons.speed, "category": "TOOLS", "screen": const PerformanceMonitorApp()},
    {"name": "BATTERY", "icon": Icons.battery_charging_full, "category": "TOOLS", "screen": const BatterySaverApp()},
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        });
        _updateTime();
      }
    });
  }

  void _openApp(Map<String, dynamic> app) {
    if (app['screen'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => app['screen']),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final iconContainerSize = isSmallScreen ? 50.0 : 55.0;
    final iconSize = isSmallScreen ? 24.0 : 28.0;
    
    final filteredApps = _apps.where((app) => app['category'] == _categories[_selectedIndex]['name']).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [const Color(0xFF00BCD4).withOpacity(0.05), Colors.black, Colors.black],
          ),
        ),
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                border: Border(bottom: BorderSide(color: const Color(0xFF00BCD4).withOpacity(0.3))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ZION OS', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(
                    children: [
                      Icon(Icons.battery_full, color: const Color(0xFF00BCD4), size: 14),
                      const SizedBox(width: 8),
                      Icon(Icons.network_wifi, color: const Color(0xFF00BCD4), size: 14),
                      const SizedBox(width: 12),
                      Text(_currentTime, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Categories
            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: List.generate(_categories.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00BCD4).withOpacity(isSelected ? 0.6 : 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _categories[index]['name'],
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00BCD4) : Colors.white54,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // App Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isSmallScreen ? 3 : 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredApps.length,
                itemBuilder: (context, index) {
                  final app = filteredApps[index];
                  return GestureDetector(
                    onTap: () => _openApp(app),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.15)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: iconContainerSize,
                            height: iconContainerSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BCD4).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(app['icon'], color: const Color(0xFF00BCD4), size: iconSize),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            app['name'],
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Dock
            Container(
              height: 55,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDockIcon(Icons.terminal, 'TERM', () => _openApp(_apps.firstWhere((a) => a['name'] == 'TERMINAL'))),
                  const SizedBox(width: 12),
                  _buildDockIcon(Icons.folder, 'FILES', () => _openApp(_apps.firstWhere((a) => a['name'] == 'FILE MANAGER'))),
                  const SizedBox(width: 12),
                  _buildDockIcon(Icons.public, 'WEB', () => _openApp(_apps.firstWhere((a) => a['name'] == 'BROWSER'))),
                  const SizedBox(width: 12),
                  _buildDockIcon(Icons.calculate, 'CALC', () => _openApp(_apps.firstWhere((a) => a['name'] == 'CALCULATOR'))),
                  const SizedBox(width: 12),
                  _buildDockIcon(Icons.settings, 'SET', () => _openApp(_apps.firstWhere((a) => a['name'] == 'SETTINGS'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8)),
        ],
      ),
    );
  }
}
