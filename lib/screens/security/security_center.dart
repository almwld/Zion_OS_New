import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class SecurityCenter extends StatefulWidget {
  const SecurityCenter({super.key});

  @override
  State<SecurityCenter> createState() => _SecurityCenterState();
}

class _SecurityCenterState extends State<SecurityCenter> {
  bool _firewallEnabled = true;
  bool _intrusionDetection = true;
  bool _realTimeProtection = true;
  bool _networkMonitor = true;
  bool _appSandbox = true;
  bool _encryptionEnabled = true;
  
  List<Map<String, dynamic>> _threats = [];
  List<Map<String, dynamic>> _recentEvents = [];
  Timer? _scanTimer;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
    _startMonitoring();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _scanForThreats();
    });
  }

  void _loadSecurityStatus() {
    setState(() {
      _threats = [
        {'name': 'Unauthorized Access', 'severity': 'High', 'time': '5 min ago', 'status': 'Blocked'},
        {'name': 'Suspicious Connection', 'severity': 'Medium', 'time': '15 min ago', 'status': 'Monitored'},
        {'name': 'Malware Scan', 'severity': 'Low', 'time': '1 hour ago', 'status': 'Clean'},
      ];
      
      _recentEvents = [
        {'event': 'Firewall Updated', 'time': '2 min ago', 'type': 'info'},
        {'event': 'New Device Connected', 'time': '10 min ago', 'type': 'warning'},
        {'event': 'System Scan Completed', 'time': '30 min ago', 'type': 'success'},
        {'event': 'Security Patch Applied', 'time': '1 hour ago', 'type': 'info'},
      ];
    });
  }

  void _scanForThreats() {
    // محاكاة فحص التهديدات
  }

  void _runFullScan() async {
    setState(() => _isScanning = true);
    
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() {
      _isScanning = false;
      _threats.insert(0, {
        'name': 'System Scan Completed',
        'severity': 'Info',
        'time': 'Just now',
        'status': 'No threats found',
      });
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan completed - System is secure'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Security Center', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield, color: Color(0xFF00BCD4)),
            onPressed: _runFullScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Security Score
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Security Score',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: 0.92,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 8,
                        ),
                      ),
                      const Text(
                        '92%',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your system is well protected',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Protection Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Protection Status', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildSwitchItem('Firewall', _firewallEnabled, (v) => setState(() => _firewallEnabled = v)),
                  _buildSwitchItem('Intrusion Detection', _intrusionDetection, (v) => setState(() => _intrusionDetection = v)),
                  _buildSwitchItem('Real-time Protection', _realTimeProtection, (v) => setState(() => _realTimeProtection = v)),
                  _buildSwitchItem('Network Monitor', _networkMonitor, (v) => setState(() => _networkMonitor = v)),
                  _buildSwitchItem('App Sandbox', _appSandbox, (v) => setState(() => _appSandbox = v)),
                  _buildSwitchItem('Encryption', _encryptionEnabled, (v) => setState(() => _encryptionEnabled = v)),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    Icons.vpn_key,
                    'Change PIN',
                    'Update security PIN',
                    () => _showChangePinDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    Icons.fingerprint,
                    'Biometric',
                    'Enable fingerprint',
                    () {},
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    Icons.encryption,
                    'Encrypt Files',
                    'Secure your data',
                    () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    Icons.backup,
                    'Backup Now',
                    'Protect your data',
                    () {},
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Threat Detection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Threat Detection', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._threats.map((threat) => _buildThreatItem(threat)),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Recent Events
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Events', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._recentEvents.map((event) => _buildEventItem(event)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Full Scan Button
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.all(20),
                child: LinearProgressIndicator(color: Color(0xFF00BCD4)),
              ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _runFullScan,
                icon: Icon(_isScanning ? Icons.hourglass_empty : Icons.shield),
                label: Text(_isScanning ? 'Scanning...' : 'Run Full Security Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00BCD4), size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatItem(Map<String, dynamic> threat) {
    Color color;
    switch (threat['severity']) {
      case 'High':
        color = Colors.red;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(threat['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                Text(threat['time'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(threat['status'], style: TextStyle(color: color, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    IconData icon;
    Color color;
    switch (event['type']) {
      case 'warning':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icon = Icons.info;
        color = const Color(0xFF00BCD4);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['event'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                Text(event['time'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    final TextEditingController oldPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    
    showDialog(
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
                labelText: 'New PIN',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (oldPinController.text == '1234' && newPinController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN changed successfully'), backgroundColor: Color(0xFF00BCD4)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wrong current PIN'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }
}
