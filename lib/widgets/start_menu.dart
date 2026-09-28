import 'package:flutter/material.dart';

class StartMenu extends StatefulWidget {
  final VoidCallback onClose;
  
  const StartMenu({super.key, required this.onClose});

  @override
  State<StartMenu> createState() => _StartMenuState();
}

class _StartMenuState extends State<StartMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 400,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Center(child: Text("Z", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00BCD4)))),
                          ),
                          const SizedBox(width: 15),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Zion OS 2027", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("Secure Mode Active", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Menu Items
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildMenuItem(Icons.terminal, "Terminal"),
                          _buildMenuItem(Icons.network_wifi, "Network Scanner"),
                          _buildMenuItem(Icons.wifi, "WiFi Scanner"),
                          _buildMenuItem(Icons.bug_report, "Exploit Database"),
                          _buildMenuItem(Icons.lock, "Crypto Tool"),
                          _buildMenuItem(Icons.visibility_off, "Stealth Mode"),
                          _buildMenuItem(Icons.vpn_key, "Password Cracker"),
                          _buildMenuItem(Icons.speed, "DDoS Attack"),
                          const Divider(color: Color(0xFF00BCD4), height: 1),
                          _buildMenuItem(Icons.settings, "Settings"),
                          _buildMenuItem(Icons.power_settings_new, "Lock Screen"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00BCD4), size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      onTap: () {
        widget.onClose();
      },
      hoverColor: const Color(0xFF00BCD4).withOpacity(0.1),
    );
  }
}
