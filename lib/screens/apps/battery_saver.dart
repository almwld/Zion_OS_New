import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';

class BatterySaverApp extends StatefulWidget {
  const BatterySaverApp({super.key});

  @override
  State<BatterySaverApp> createState() => _BatterySaverAppState();
}

class _BatterySaverAppState extends State<BatterySaverApp> {
  final Battery _battery = Battery();
  
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  bool _powerSaveMode = false;
  bool _darkMode = true;
  bool _backgroundSync = false;
  bool _autoBrightness = true;
  int _screenTimeout = 30;
  double _estimatedTime = 0;
  Timer? _monitorTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startMonitoring();
    _updateBatteryInfo();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateBatteryInfo();
    });
  }

  void _loadSettings() {
    // Load saved settings
  }

  Future<void> _updateBatteryInfo() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    setState(() {
      _batteryLevel = level;
      _batteryState = state;
      _estimatedTime = _calculateEstimatedTime(level);
    });
  }

  double _calculateEstimatedTime(int level) {
    // Rough estimation: ~1% per hour on idle
    if (_powerSaveMode) return level * 1.5;
    if (_backgroundSync) return level * 0.8;
    return level * 1.0;
  }

  String _getBatteryStatus() {
    if (_batteryState == BatteryState.charging) return 'Charging ⚡';
    if (_batteryState == BatteryState.full) return 'Full ✅';
    if (_batteryLevel < 15) return 'Critical ⚠️';
    if (_batteryLevel < 30) return 'Low 🔋';
    return 'Normal ✓';
  }

  Color _getBatteryColor() {
    if (_batteryLevel > 50) return Colors.green;
    if (_batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Battery Saver', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Battery Level Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getBatteryColor(), _getBatteryColor().withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Battery Level', style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '$_batteryLevel%',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getBatteryStatus(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _batteryLevel / 100,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estimated: ${_estimatedTime.toStringAsFixed(0)} hours remaining',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Power Save Mode
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Power Save Mode', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Reduce background activity to save battery', style: TextStyle(color: Colors.white54)),
                    value: _powerSaveMode,
                    onChanged: (v) => setState(() => _powerSaveMode = v),
                    activeColor: const Color(0xFF00BCD4),
                  ),
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Dark theme saves battery on AMOLED screens', style: TextStyle(color: Colors.white54)),
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    activeColor: const Color(0xFF00BCD4),
                  ),
                  SwitchListTile(
                    title: const Text('Background Sync', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Sync apps in background', style: TextStyle(color: Colors.white54)),
                    value: _backgroundSync,
                    onChanged: (v) => setState(() => _backgroundSync = v),
                    activeColor: const Color(0xFF00BCD4),
                  ),
                  SwitchListTile(
                    title: const Text('Auto Brightness', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Automatically adjust screen brightness', style: TextStyle(color: Colors.white54)),
                    value: _autoBrightness,
                    onChanged: (v) => setState(() => _autoBrightness = v),
                    activeColor: const Color(0xFF00BCD4),
                  ),
                  ListTile(
                    title: const Text('Screen Timeout', style: TextStyle(color: Colors.white)),
                    subtitle: Text('$_screenTimeout seconds', style: const TextStyle(color: Colors.white54)),
                    trailing: DropdownButton<int>(
                      value: _screenTimeout,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Color(0xFF00BCD4)),
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 sec')),
                        DropdownMenuItem(value: 30, child: Text('30 sec')),
                        DropdownMenuItem(value: 60, child: Text('1 min')),
                        DropdownMenuItem(value: 120, child: Text('2 min')),
                      ],
                      onChanged: (v) => setState(() => _screenTimeout = v!),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Battery Usage Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Battery Usage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUsageItem('Screen', 35, Colors.blue),
                  _buildUsageItem('System', 25, Colors.purple),
                  _buildUsageItem('Apps', 20, Colors.orange),
                  _buildUsageItem('Network', 12, Colors.green),
                  _buildUsageItem('Other', 8, Colors.grey),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('Battery Tips', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('🔋 Lower screen brightness'),
                  _buildTip('📱 Close unused apps'),
                  _buildTip('🌙 Use Dark Mode on AMOLED'),
                  _buildTip('📡 Turn off WiFi when not needed'),
                  _buildTip('⚡ Enable Power Save Mode'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageItem(String label, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white)),
              Text('$percentage%', style: TextStyle(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white24,
            color: color,
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(tip, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}
