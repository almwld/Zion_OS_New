import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockApp extends StatefulWidget {
  const AppLockApp({super.key});

  @override
  State<AppLockApp> createState() => _AppLockAppState();
}

class _AppLockAppState extends State<AppLockApp> {
  List<Map<String, dynamic>> _apps = [];
  List<Map<String, dynamic>> _lockedApps = [];
  String _currentPin = '1234';
  bool _isPinSet = true;
  bool _showLockedOnly = false;

  final List<Map<String, dynamic>> _allApps = [
    {'name': 'Terminal', 'icon': Icons.terminal, 'package': 'terminal'},
    {'name': 'File Manager', 'icon': Icons.folder, 'package': 'file_manager'},
    {'name': 'Browser', 'icon': Icons.public, 'package': 'browser'},
    {'name': 'Calculator', 'icon': Icons.calculate, 'package': 'calculator'},
    {'name': 'Settings', 'icon': Icons.settings, 'package': 'settings'},
    {'name': 'Notes', 'icon': Icons.note, 'package': 'notes'},
    {'name': 'Gallery', 'icon': Icons.photo_library, 'package': 'gallery'},
    {'name': 'Documents', 'icon': Icons.description, 'package': 'documents'},
    {'name': 'Email', 'icon': Icons.email, 'package': 'email'},
    {'name': 'WiFi Scanner', 'icon': Icons.wifi, 'package': 'wifi'},
    {'name': 'Password Cracker', 'icon': Icons.vpn_key, 'package': 'cracker'},
    {'name': 'DDoS Attack', 'icon': Icons.speed, 'package': 'ddos'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLockedApps();
    _loadPin();
  }

  Future<void> _loadLockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final locked = prefs.getStringList('locked_apps') ?? [];
    setState(() {
      _lockedApps = _allApps.where((app) => locked.contains(app['package'])).toList();
      _apps = _allApps.map((app) => {
        ...app,
        'locked': locked.contains(app['package']),
      }).toList();
    });
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('app_lock_pin');
    if (pin != null) {
      setState(() {
        _currentPin = pin;
        _isPinSet = true;
      });
    } else {
      setState(() {
        _isPinSet = false;
      });
    }
  }

  Future<void> _saveLockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final locked = _apps.where((app) => app['locked'] == true).map((app) => app['package'] as String).toList();
    await prefs.setStringList('locked_apps', locked);
    await _loadLockedApps();
  }

  Future<void> _changePin() async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPinController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New PIN (4 digits)',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              if (oldPinController.text == _currentPin && newPinController.text.length == 4) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('app_lock_pin', newPinController.text);
                setState(() => _currentPin = newPinController.text);
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN changed successfully'), backgroundColor: Color(0xFF00BCD4)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  Future<void> _setPin() async {
    final pinController = TextEditingController();
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set PIN', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: TextField(
          controller: pinController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Enter PIN (4 digits)',
            labelStyle: TextStyle(color: Color(0xFF00BCD4)),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              if (pinController.text.length == 4) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('app_lock_pin', pinController.text);
                setState(() {
                  _currentPin = pinController.text;
                  _isPinSet = true;
                });
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN set successfully'), backgroundColor: Color(0xFF00BCD4)),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _toggleLock(String package) {
    setState(() {
      final index = _apps.indexWhere((app) => app['package'] == package);
      if (index != -1) {
        _apps[index]['locked'] = !_apps[index]['locked'];
      }
    });
    _saveLockedApps();
  }

  @override
  Widget build(BuildContext context) {
    final displayApps = _showLockedOnly 
        ? _apps.where((app) => app['locked'] == true).toList()
        : _apps;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('App Lock', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_showLockedOnly ? Icons.apps : Icons.lock, color: Color(0xFF00BCD4)),
            onPressed: () => setState(() => _showLockedOnly = !_showLockedOnly),
          ),
          IconButton(
            icon: const Icon(Icons.fingerprint, color: Color(0xFF00BCD4)),
            onPressed: _isPinSet ? _changePin : _setPin,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
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
                _buildStatItem('Total Apps', _apps.length.toString(), Icons.apps),
                _buildStatItem('Locked', _apps.where((a) => a['locked'] == true).length.toString(), Icons.lock),
                _buildStatItem('Protected', '${((_apps.where((a) => a['locked'] == true).length / _apps.length) * 100).toInt()}%', Icons.shield),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                // Search functionality
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                hintText: 'Search apps...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Apps List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayApps.length,
              itemBuilder: (context, index) {
                final app = displayApps[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: app['locked'] 
                          ? Colors.red.withOpacity(0.3)
                          : const Color(0xFF00BCD4).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(app['icon'], color: const Color(0xFF00BCD4), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app['name'],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              app['package'],
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: app['locked'],
                        onChanged: (_) => _toggleLock(app['package']),
                        activeColor: Colors.red,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Color(0xFF00BCD4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Locked apps will require PIN to open',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
