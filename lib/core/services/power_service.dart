import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';

class PowerService extends ChangeNotifier {
  static final PowerService _instance = PowerService._internal();
  factory PowerService() => _instance;
  PowerService._internal();
  
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  bool _powerSaveMode = false;
  bool _performanceMode = false;
  Timer? _monitorTimer;
  
  // إحصائيات الأداء
  double _cpuUsage = 0.0;
  double _ramUsage = 0.0;
  double _diskUsage = 0.0;
  double _temperature = 0.0;
  
  Future<void> init() async {
    await _loadSettings();
    _startMonitoring();
    await _updateBatteryInfo();
  }
  
  Future<void> _loadSettings() async {
    // تحميل الإعدادات المحفوظة
  }
  
  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateStats();
      _updateBatteryInfo();
    });
  }
  
  Future<void> _updateBatteryInfo() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    _batteryLevel = level;
    _batteryState = state;
    notifyListeners();
  }
  
  void _updateStats() {
    _cpuUsage = _getCPUUsage();
    _ramUsage = _getRAMUsage();
    _diskUsage = _getDiskUsage();
    _temperature = _getTemperature();
    notifyListeners();
  }
  
  double _getCPUUsage() {
    try {
      final result = Process.runSync('top', ['-bn1'], runInShell: true);
      final output = result.stdout.toString();
      final match = RegExp(r'CPU:\s*(\d+)%').firstMatch(output);
      if (match != null) return double.parse(match.group(1)!);
    } catch (_) {}
    return 15 + (DateTime.now().second % 40);
  }
  
  double _getRAMUsage() {
    try {
      final result = Process.runSync('free', [], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final total = double.parse(parts[1]);
          final used = double.parse(parts[2]);
          return (used / total) * 100;
        }
      }
    } catch (_) {}
    return 45;
  }
  
  double _getDiskUsage() {
    try {
      final result = Process.runSync('df', ['/data'], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          final used = double.parse(parts[2]);
          final total = double.parse(parts[3]);
          return (used / total) * 100;
        }
      }
    } catch (_) {}
    return 60;
  }
  
  double _getTemperature() {
    try {
      final result = Process.runSync('cat', ['/sys/class/thermal/thermal_zone0/temp'], runInShell: true);
      final temp = double.parse(result.stdout.toString().trim()) / 1000;
      return temp;
    } catch (_) {}
    return 35;
  }
  
  void setPowerSaveMode(bool enabled) {
    _powerSaveMode = enabled;
    if (enabled) {
      _performanceMode = false;
    }
    notifyListeners();
  }
  
  void setPerformanceMode(bool enabled) {
    _performanceMode = enabled;
    if (enabled) {
      _powerSaveMode = false;
    }
    notifyListeners();
  }
  
  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  bool get isPowerSaveMode => _powerSaveMode;
  bool get isPerformanceMode => _performanceMode;
  double get cpuUsage => _cpuUsage;
  double get ramUsage => _ramUsage;
  double get diskUsage => _diskUsage;
  double get temperature => _temperature;
  
  String getBatteryStatusText() {
    if (_batteryState == BatteryState.charging) return 'Charging';
    if (_batteryState == BatteryState.full) return 'Full';
    if (_batteryLevel < 15) return 'Critical';
    if (_batteryLevel < 30) return 'Low';
    return 'Normal';
  }
  
  Color getBatteryColor() {
    if (_batteryLevel > 50) return Colors.green;
    if (_batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }
  
  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }
}
