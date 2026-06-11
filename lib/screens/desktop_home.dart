import 'package:flutter/material.dart';
import 'dart:math';
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

class DesktopHome extends StatefulWidget {
  const DesktopHome({super.key});

  @override
  State<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends State<DesktopHome> with TickerProviderStateMixin {
  String _currentTime = "";
  String _currentDate = "";
  int _selectedIndex = 0;
  late AnimationController _holoController;
  late AnimationController _scanController;
  late Animation<double> _holoAnimation;
  late Animation<double> _scanAnimation;
  final Random _random = Random();

  final List<Map<String, dynamic>> _categories = [
    {"name": "⚡ ATTACK", "icon": Icons.flash_on, "color": 0xFF00FF41},
    {"name": "🛡️ DEFENSE", "icon": Icons.shield, "color": 0xFF00FF41},
    {"name": "📊 ANALYSIS", "icon": Icons.analytics, "color": 0xFF00FF41},
    {"name": "🔧 TOOLS", "icon": Icons.build, "color": 0xFF00FF41},
  ];

  final List<Map<String, dynamic>> _apps = [
    // Tools
    {"name": "TERMINAL", "icon": Icons.terminal, "category": "🔧 TOOLS", "screen": const TerminalApp()},
    {"name": "CRYPTO", "icon": Icons.lock, "category": "🔧 TOOLS", "screen": const CryptoToolApp()},
    {"name": "SETTINGS", "icon": Icons.settings, "category": "🔧 TOOLS", "screen": null},
    
    // Attack
    {"name": "WIFI", "icon": Icons.wifi, "category": "⚡ ATTACK", "screen": const WiFiScannerApp()},
    {"name": "EXPLOIT", "icon": Icons.bug_report, "category": "⚡ ATTACK", "screen": const ExploitDBApp()},
    {"name": "CRACKER", "icon": Icons.vpn_key, "category": "⚡ ATTACK", "screen": const PasswordCrackerApp()},
    {"name": "DDOS", "icon": Icons.speed, "category": "⚡ ATTACK", "screen": const DDoSAttackApp()},
    {"name": "DATABASE", "icon": Icons.storage, "category": "⚡ ATTACK", "screen": const DatabaseHackingApp()},
    {"name": "CLOUD", "icon": Icons.cloud, "category": "⚡ ATTACK", "screen": const CloudAttacksApp()},
    
    // Analysis
    {"name": "NETWORK", "icon": Icons.network_wifi, "category": "📊 ANALYSIS", "screen": const NetworkScannerApp()},
    {"name": "FORENSICS", "icon": Icons.search, "category": "📊 ANALYSIS", "screen": const ForensicsApp()},
    
    // Defense
    {"name": "STEALTH", "icon": Icons.visibility_off, "category": "🛡️ DEFENSE", "screen": const StealthModeApp()},
  ];

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    
    _holoController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _holoAnimation = Tween<double>(begin: 0.2, end: 0.7).animate(_holoController);
    
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(_scanController);
  }

  @override
  void dispose() {
    _holoController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _updateDateTime() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
          _currentDate = "${_getDay(now.weekday)} ${now.day} ${_getMonth(now.month)} ${now.year}";
        });
        _updateDateTime();
      }
    });
  }

  String _getDay(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
  }

  String _getMonth(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  void _openApp(Map<String, dynamic> app) {
    if (app['screen'] != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => app['screen']));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('COMING SOON'), backgroundColor: Color(0xFF00FF41)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = _apps.where((app) => app['category'] == _categories[_selectedIndex]['name']).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // خلفية Holographic
          AnimatedBuilder(
            animation: _holoAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      const Color(0xFF00FF41).withOpacity(_holoAnimation.value * 0.15),
                      Colors.black,
                      Colors.black,
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: HolographicGridPainter(_scanAnimation.value),
                ),
              );
            },
          ),
          
          Column(
            children: [
              // شريط الحالة - تصميم 2027
              Container(
                height: 110,
                padding: const EdgeInsets.fromLTRB(25, 50, 25, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // الوقت والتاريخ
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: _holoAnimation,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (rect) => LinearGradient(
                                colors: [
                                  const Color(0xFF00FF41),
                                  const Color(0xFF00FF41).withOpacity(_holoAnimation.value),
                                ],
                              ).createShader(rect),
                              child: Text(
                                _currentTime,
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 4,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentDate,
                          style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1),
                        ),
                      ],
                    ),
                    
                    // شعار Zion holographic
                    AnimatedBuilder(
                      animation: _holoAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00FF41).withOpacity(0.3),
                                const Color(0xFF00FF41).withOpacity(_holoAnimation.value),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF41).withOpacity(_holoAnimation.value),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Z",
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Categories - تصميم Neo
              Container(
                height: 55,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIndex == index;
                    final category = _categories[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFF00FF41).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFF00FF41) 
                                : const Color(0xFF00FF41).withOpacity(0.2),
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Text(
                          category['name'],
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00FF41) : Colors.white54,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Grid - تصميم Holographic Cards
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];
                    return _buildHolographicCard(app);
                  },
                ),
              ),
              
              // شريط سفلي - Holographic Dock
              Container(
                height: 75,
                margin: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDockItem(Icons.home, true, () {}),
                    _buildDockItem(Icons.apps, false, () {}),
                    _buildDockItem(Icons.notifications_none, false, () {}),
                    _buildDockItem(Icons.grid_view, false, () {}),
                    _buildDockItem(Icons.person_outline, false, () {}),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHolographicCard(Map<String, dynamic> app) {
    return GestureDetector(
      onTap: () => _openApp(app),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [const Color(0xFF00FF41).withOpacity(0.15), Colors.transparent],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(app['icon'], color: const Color(0xFF00FF41), size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              app['name'],
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: 1,
              color: const Color(0xFF00FF41).withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00FF41).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF00FF41) : Colors.white38,
          size: 22,
        ),
      ),
    );
  }
}

// تأثير Holographic Grid
class HolographicGridPainter extends CustomPainter {
  final double scanValue;
  
  HolographicGridPainter(this.scanValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF41).withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // خطوط أفقية
    for (var i = 0; i < 20; i++) {
      final y = i * size.height / 20;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // خطوط عمودية
    for (var i = 0; i < 15; i++) {
      final x = i * size.width / 15;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // خط المسح الضوئي
    final scanPaint = Paint()
      ..color = const Color(0xFF00FF41).withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final scanY = scanValue * size.height;
    canvas.drawRect(Rect.fromLTWH(0, scanY - 2, size.width, 4), scanPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
