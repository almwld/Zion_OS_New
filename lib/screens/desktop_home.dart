import 'package:flutter/material.dart';
import 'apps/terminal_app.dart';
import 'apps/network_scanner.dart';
import 'apps/wifi_scanner.dart';
import 'apps/exploit_db.dart';

class DesktopHome extends StatefulWidget {
  const DesktopHome({super.key});

  @override
  State<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends State<DesktopHome> {
  String _currentTime = "";
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {"name": "Attack", "icon": Icons.flash_on},
    {"name": "Defense", "icon": Icons.shield},
    {"name": "Analysis", "icon": Icons.analytics},
    {"name": "Tools", "icon": Icons.build},
  ];

  final List<Map<String, dynamic>> _apps = [
    {"name": "Terminal", "icon": Icons.terminal, "category": "Tools", "screen": const TerminalApp()},
    {"name": "Network Scanner", "icon": Icons.network_wifi, "category": "Analysis", "screen": const NetworkScannerApp()},
    {"name": "WiFi Scanner", "icon": Icons.wifi, "category": "Attack", "screen": const WiFiScannerApp()},
    {"name": "Exploit DB", "icon": Icons.bug_report, "category": "Attack", "screen": const ExploitDBApp()},
    {"name": "Crypto Tool", "icon": Icons.lock, "category": "Defense", "screen": null},
    {"name": "Stealth", "icon": Icons.visibility_off, "category": "Defense", "screen": null},
    {"name": "DDoS", "icon": Icons.speed, "category": "Attack", "screen": null},
    {"name": "Forensics", "icon": Icons.search, "category": "Analysis", "screen": null},
    {"name": "Settings", "icon": Icons.settings, "category": "Tools", "screen": null},
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
          _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
        });
        _updateTime();
      }
    });
  }

  void _openApp(Map<String, dynamic> app) {
    if (app['screen'] != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => app['screen']));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قيد التطوير...'), backgroundColor: Color(0xFF00FF41)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = _apps.where((app) => app['category'] == _categories[_selectedIndex]['name']).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              border: Border(bottom: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Container(width: 50, child: const Icon(Icons.window, color: Color(0xFF00FF41))),
                Expanded(child: Container()),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(_currentTime, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 14)),
                ),
              ],
            ),
          ),
          Container(
            height: 50,
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
            ),
            child: Row(
              children: List.generate(_categories.length, (index) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _selectedIndex == index ? const Color(0xFF00FF41).withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_categories[index]['icon'], color: const Color(0xFF00FF41), size: 18),
                          const SizedBox(width: 8),
                          Text(_categories[index]['name'], style: const TextStyle(color: Color(0xFF00FF41), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.9,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredApps.length,
              itemBuilder: (context, index) {
                final app = filteredApps[index];
                return GestureDetector(
                  onTap: () => _openApp(app),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF41).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(app['icon'], color: const Color(0xFF00FF41), size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(app['name'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
