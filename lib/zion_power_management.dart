import 'dart:async';

import 'package:flutter/foundation.dart';

import 'core/services/zion_platform_service.dart';

class PowerProfile {
  final String name;
  final String description;
  final double cpuMaxFreq;
  final int brightnessPercent;
  final bool wifiOn;
  final bool bluetoothOn;
  final bool animationsOn;

  PowerProfile({
    required this.name,
    required this.description,
    required this.cpuMaxFreq,
    required this.brightnessPercent,
    required this.wifiOn,
    required this.bluetoothOn,
    required this.animationsOn,
  });

  static final PowerProfile performance = PowerProfile(
    name: 'الأداء العالي',
    description: 'أقصى أداء للمعالج',
    cpuMaxFreq: 2.8,
    brightnessPercent: 100,
    wifiOn: true,
    bluetoothOn: true,
    animationsOn: true,
  );
  static final PowerProfile balanced = PowerProfile(
    name: 'متوازن',
    description: 'توازن بين الأداء والبطارية',
    cpuMaxFreq: 1.8,
    brightnessPercent: 70,
    wifiOn: true,
    bluetoothOn: false,
    animationsOn: true,
  );
  static final PowerProfile powerSave = PowerProfile(
    name: 'توفير الطاقة',
    description: 'أقصى توفير للبطارية',
    cpuMaxFreq: 1.2,
    brightnessPercent: 40,
    wifiOn: true,
    bluetoothOn: false,
    animationsOn: false,
  );
  static final PowerProfile ultraSave = PowerProfile(
    name: 'توفير فائق',
    description: 'وضع الطوارئ',
    cpuMaxFreq: 0.8,
    brightnessPercent: 20,
    wifiOn: false,
    bluetoothOn: false,
    animationsOn: false,
  );
}

/// Power state backed by Android's real battery service.
///
/// Power profiles remain UI policy objects; they do not claim to change CPU
/// governors, brightness, Wi-Fi, or Bluetooth because a normal Android app
/// cannot safely control those system components without privileged access.
class ZionPowerManagement extends ChangeNotifier {
  ZionPowerManagement({ZionPlatformService? platform})
      : _platform = platform ?? ZionPlatformService.instance {
    unawaited(refresh());
  }

  final ZionPlatformService _platform;
  Timer? _refreshTimer;

  PowerProfile _currentProfile = PowerProfile.balanced;
  int _batteryLevel = 0;
  bool _isCharging = false;
  double? _temperature;
  double? _voltage;
  String _estimatedTime = 'غير متاح';
  bool _available = false;

  PowerProfile get currentProfile => _currentProfile;
  int get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;
  double get temperature => _temperature ?? 0;
  double? get temperatureOrNull => _temperature;
  double? get voltage => _voltage;
  String get estimatedTime => _estimatedTime;
  bool get isAvailable => _available;

  Future<void> refresh() async {
    try {
      final info = await _platform.getBatteryInfo();
      final level = info['level'];
      final temperature = info['temperatureC'];
      final voltage = info['voltageV'];

      _available = info['available'] == true;
      if (level is num) _batteryLevel = level.round().clamp(0, 100);
      _isCharging = info['charging'] == true;
      _temperature = temperature is num ? temperature.toDouble() : null;
      _voltage = voltage is num ? voltage.toDouble() : null;
      _estimatedTime = 'غير متاح';
      notifyListeners();
    } catch (_) {
      _available = false;
      notifyListeners();
    }
  }

  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => refresh());
    unawaited(refresh());
  }

  void stopMonitoring() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void setProfile(PowerProfile profile) {
    _currentProfile = profile;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
