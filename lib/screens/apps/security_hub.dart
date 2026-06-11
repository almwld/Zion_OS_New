import 'package:flutter/material.dart';

class SecurityHubApp extends StatefulWidget {
  const SecurityHubApp({super.key});

  @override
  State<SecurityHubApp> createState() => _SecurityHubAppState();
}

class _SecurityHubAppState extends State<SecurityHubApp> {
  int _selectedCategory = 0;
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.apps},
    {'name': 'Protection', 'icon': Icons.shield},
    {'name': 'Privacy', 'icon': Icons.privacy_tip},
    {'name': 'Network', 'icon': Icons.network_wifi},
    {'name': 'System', 'icon': Icons.settings},
    {'name': 'Tools', 'icon': Icons.build},
  ];
  
  final List<Map<String, dynamic>> _tools = [
    // Protection
    {'name': 'Firewall', 'icon': Icons.firewall, 'category': 'Protection', 'enabled': true, 'description': 'Network traffic control'},
    {'name': 'App Lock', 'icon': Icons.lock, 'category': 'Protection', 'enabled': true, 'description': 'Lock sensitive apps'},
    {'name': 'Encryption', 'icon': Icons.encryption, 'category': 'Protection', 'enabled': true, 'description': 'Data encryption'},
    
    // Privacy
    {'name': 'Stealth Mode', 'icon': Icons.visibility_off, 'category': 'Privacy', 'enabled': true, 'description': 'Hide activities'},
    {'name': 'VPN', 'icon': Icons.vpn_key, 'category': 'Privacy', 'enabled': false, 'description': 'Secure connection'},
    {'name': 'Incognito', 'icon': Icons.incognito, 'category': 'Privacy', 'enabled': false, 'description': 'Private browsing'},
    
    // Network
    {'name': 'WiFi Scanner', 'icon': Icons.wifi, 'category': 'Network', 'enabled': true, 'description': 'Scan networks'},
    {'name': 'Network Monitor', 'icon': Icons.network_check, 'category': 'Network', 'enabled': true, 'description': 'Traffic monitor'},
    {'name': 'Network Tools', 'icon': Icons.analytics, 'category': 'Network', 'enabled': true, 'description': 'DNS, Ping, Traceroute'},
    
    // System
    {'name': 'Task Manager', 'icon': Icons.list_alt, 'category': 'System', 'enabled': true, 'description': 'Process management'},
    {'name': 'Performance Monitor', 'icon': Icons.speed, 'category': 'System', 'enabled': true, 'description': 'System performance'},
    {'name': 'Disk Analyzer', 'icon': Icons.storage, 'category': 'System', 'enabled': true, 'description': 'Storage analysis'},
    
    // Tools
    {'name': 'Password Manager', 'icon': Icons.vpn_key, 'category': 'Tools', 'enabled': true, 'description': 'Secure passwords'},
    {'name': 'Backup Manager', 'icon': Icons.backup, 'category': 'Tools', 'enabled': true, 'description': 'Data backup'},
    {'name': 'Cleaner', 'icon': Icons.cleaning_services, 'category': 'Tools', 'enabled': true, 'description': 'Clean junk files'},
  ];

  void _toggleTool(int index) {
    setState(() {
      _tools[index]['enabled'] = !_tools[index]['enabled'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTools = _selectedCategory == 0
        ? _tools
        : _tools.where((t) => t['category'] == _categories[_selectedCategory]['name']).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Security Hub', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Stats Overview
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Active', _tools.where((t) => t['enabled']).length.toString(), Icons.check_circle, Colors.green),
                _buildStatItem('Total', _tools.length.toString(), Icons.apps, Colors.white),
                _buildStatItem('Protected', '${((_tools.where((t) => t['enabled']).length / _tools.length) * 100).toInt()}%', Icons.shield, Colors.white),
              ],
            ),
          ),
          
          // Categories
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == index;
                final cat = _categories[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
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
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tools Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredTools.length,
              itemBuilder: (context, index) {
                final tool = filteredTools[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tool['enabled'] 
                          ? Colors.green.withOpacity(0.3)
                          : const Color(0xFF00BCD4).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(tool['icon'], color: const Color(0xFF00BCD4), size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tool['name'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        tool['description'],
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Switch(
                        value: tool['enabled'],
                        onChanged: (_) => _toggleTool(index),
                        activeColor: const Color(0xFF00BCD4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
