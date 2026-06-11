import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/floating_radar_chart.dart';
import '../widgets/floating_window_manager.dart';
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

class ZionDesktop extends StatefulWidget {
  const ZionDesktop({super.key});

  @override
  State<ZionDesktop> createState() => _ZionDesktopState();
}

class _ZionDesktopState extends State<ZionDesktop> {
  final GlobalKey<FloatingWindowManagerState> _windowManagerKey = GlobalKey();
  String _currentTime = "";
  int _selectedIndex = 0;
  bool _showRadarChart = true;

  final List<Map<String, dynamic>> _categories = [
    {"name": "ATTACK", "icon": Icons.flash_on, "color": 0xFFFF5722},
    {"name": "DEFENSE", "icon": Icons.shield, "color": 0xFF4CAF50},
    {"name": "ANALYSIS", "icon": Icons.analytics, "color": 0xFF2196F3},
    {"name": "TOOLS", "icon": Icons.build, "color": 0xFF9C27B0},
  ];

  final List<Map<String, dynamic>> _apps = [
    {"name": "TERMINAL", "icon": Icons.terminal, "category": "TOOLS", "screen": const TerminalApp()},
    {"name": "FILE MANAGER", "icon": Icons.folder, "category": "TOOLS", "screen": const FileManagerApp()},
    {"name": "BROWSER", "icon": Icons.public, "category": "TOOLS", "screen": const WebBrowserApp()},
    {"name": "SETTINGS", "icon": Icons.settings, "category": "TOOLS", "screen": const SettingsApp()},
    {"name": "SECURITY HUB", "icon": Icons.security, "category": "TOOLS", "screen": const SecurityHubApp()},
    {"name": "TOOLS HUB", "icon": Icons.build, "category": "TOOLS", "screen": const ToolsHubApp()},
    {"name": "PERF HUB", "icon": Icons.speed, "category": "TOOLS", "screen": const PerformanceHubApp()},
    {"name": "DATA HUB", "icon": Icons.storage, "category": "TOOLS", "screen": const DataHubApp()},
    {"name": "NOTES", "icon": Icons.note, "category": "TOOLS", "screen": const NotesApp()},
    {"name": "WEATHER", "icon": Icons.wb_sunny, "category": "TOOLS", "screen": const WeatherApp()},
    {"name": "MAPS", "icon": Icons.map, "category": "TOOLS", "screen": const MapsApp()},
    {"name": "RADIO", "icon": Icons.radio, "category": "TOOLS", "screen": const RadioApp()},
    {"name": "EMAIL", "icon": Icons.email, "category": "TOOLS", "screen": const EmailClient()},
    {"name": "GALLERY", "icon": Icons.photo_library, "category": "TOOLS", "screen": const GalleryApp()},
    {"name": "VIDEO", "icon": Icons.play_circle_filled, "category": "TOOLS", "screen": const VideoPlayerApp()},
    {"name": "CLOCK", "icon": Icons.access_time, "category": "TOOLS", "screen": const AlarmsClockApp()},
    {"name": "CALENDAR", "icon": Icons.calendar_today, "category": "TOOLS", "screen": const CalendarApp()},
    {"name": "QR CODE", "icon": Icons.qr_code_scanner, "category": "TOOLS", "screen": const QRScannerApp()},
    {"name": "DOCUMENTS", "icon": Icons.description, "category": "TOOLS", "screen": const DocumentsApp()},
    {"name": "BACKUP", "icon": Icons.backup, "category": "TOOLS", "screen": const BackupManagerApp()},
    {"name": "CLEANER", "icon": Icons.cleaning_services, "category": "TOOLS", "screen": const CleanerApp()},
    {"name": "APP LOCK", "icon": Icons.lock, "category": "TOOLS", "screen": const AppLockApp()},
    {"name": "NOTIFY", "icon": Icons.notifications, "category": "TOOLS", "screen": const NotificationManagerApp()},
    {"name": "WIFI", "icon": Icons.wifi, "category": "ATTACK", "screen": const WiFiScannerApp()},
    {"name": "EXPLOIT", "icon": Icons.bug_report, "category": "ATTACK", "screen": const ExploitDBApp()},
    {"name": "CRACKER", "icon": Icons.vpn_key, "category": "ATTACK", "screen": const PasswordCrackerApp()},
    {"name": "DDOS", "icon": Icons.speed, "category": "ATTACK", "screen": const DDoSAttackApp()},
    {"name": "DATABASE", "icon": Icons.storage, "category": "ATTACK", "screen": const DatabaseHackingApp()},
    {"name": "CLOUD", "icon": Icons.cloud, "category": "ATTACK", "screen": const CloudAttacksApp()},
    {"name": "STEALTH", "icon": Icons.visibility_off, "category": "DEFENSE", "screen": const StealthModeApp()},
    {"name": "CRYPTO", "icon": Icons.lock, "category": "DEFENSE", "screen": const CryptoToolApp()},
    {"name": "BATTERY", "icon": Icons.battery_charging_full, "category": "DEFENSE", "screen": const BatterySaverApp()},
    {"name": "NETWORK", "icon": Icons.network_wifi, "category": "ANALYSIS", "screen": const NetworkScannerApp()},
    {"name": "FORENSICS", "icon": Icons.search, "category": "ANALYSIS", "screen": const ForensicsApp()},
    {"name": "TEXT ANALYZER", "icon": Icons.analytics, "category": "ANALYSIS", "screen": const TextAnalyzerApp()},
    {"name": "CALCULATOR", "icon": Icons.calculate, "category": "ANALYSIS", "screen": const CalculatorApp()},
    {"name": "UNIT CONV", "icon": Icons.science, "category": "ANALYSIS", "screen": const UnitConverterApp()},
    {"name": "PERCENT", "icon": Icons.percent, "category": "ANALYSIS", "screen": const PercentageCalculatorApp()},
    {"name": "DATE CALC", "icon": Icons.calculate, "category": "ANALYSIS", "screen": const DateCalculatorApp()},
    {"name": "CURRENCY", "icon": Icons.attach_money, "category": "ANALYSIS", "screen": const CurrencyConverterApp()},
    {"name": "TRANSLATOR", "icon": Icons.translate, "category": "ANALYSIS", "screen": const TranslatorApp()},
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

  void _openAppAsFloating(Map<String, dynamic> app) {
    if (app['screen'] != null) {
      _windowManagerKey.currentState?.openWindow(
        app['name'],
        app['screen'],
      );
    }
  }

  void _openAppAsFullscreen(Map<String, dynamic> app) {
    if (app['screen'] != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => app['screen']));
    }
  }

  void _toggleRadar() {
    setState(() {
      _showRadarChart = !_showRadarChart;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final iconSize = isSmall ? 36.0 : 42.0;
    final iconContainer = isSmall ? 50.0 : 58.0;
    
    final filteredApps = _apps.where((app) => app['category'] == _categories[_selectedIndex]['name']).toList();

    return FloatingWindowManager(
      key: _windowManagerKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF0A2E38).withOpacity(0.3),
                    Colors.black,
                    Colors.black,
                  ],
                ),
              ),
              child: CustomPaint(painter: GridPatternPainter()),
            ),
            
            // Main Content
            Column(
              children: [
                // Status Bar
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text("Z", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "ZION OS",
                            style: GoogleFonts.orbitron(
                              color: const Color(0xFF00BCD4),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleRadar,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _showRadarChart ? const Color(0xFF00BCD4).withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.radar, color: const Color(0xFF00BCD4), size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.battery_full, color: Color(0xFF00BCD4), size: 16),
                          const SizedBox(width: 6),
                          const Icon(Icons.network_wifi, color: Color(0xFF00BCD4), size: 16),
                          const SizedBox(width: 12),
                          Text(_currentTime, style: GoogleFonts.orbitron(color: const Color(0xFF00BCD4), fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Categories
                Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      final cat = _categories[index];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : const Color(0xFF00BCD4).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(cat['icon'], color: isSelected ? Colors.black : const Color(0xFF00BCD4), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                cat['name'],
                                style: TextStyle(
                                  color: isSelected ? Colors.black : const Color(0xFF00BCD4),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Apps Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmall ? 3 : 4,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      return GestureDetector(
                        onTap: () => _openAppAsFloating(app),
                        onLongPress: () => _openAppAsFullscreen(app),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: iconContainer,
                                height: iconContainer,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(app['icon'], color: Colors.white, size: iconSize),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                app['name'],
                                style: GoogleFonts.orbitron(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
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
                  height: 65,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDockIcon(Icons.terminal, 'TERM', () => _openAppAsFloating(_apps.firstWhere((a) => a['name'] == 'TERMINAL'))),
                      _buildDockIcon(Icons.folder, 'FILES', () => _openAppAsFloating(_apps.firstWhere((a) => a['name'] == 'FILE MANAGER'))),
                      _buildDockIcon(Icons.public, 'WEB', () => _openAppAsFloating(_apps.firstWhere((a) => a['name'] == 'BROWSER'))),
                      _buildDockIcon(Icons.security, 'HUB', () => _openAppAsFloating(_apps.firstWhere((a) => a['name'] == 'SECURITY HUB'))),
                      _buildDockIcon(Icons.settings, 'SET', () => _openAppAsFloating(_apps.firstWhere((a) => a['name'] == 'SETTINGS'))),
                    ],
                  ),
                ),
              ],
            ),
            
            // Floating Radar Chart
            if (_showRadarChart)
              FloatingRadarChart(onClose: () => setState(() => _showRadarChart = false)),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 9)),
        ],
      ),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BCD4).withOpacity(0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
