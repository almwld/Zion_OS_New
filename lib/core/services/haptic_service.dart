import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();
  
  bool _vibrationEnabled = true;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _vibrationEnabled = prefs.getBool('vibration') ?? true;
  }
  
  void lightImpact() {
    if (!_vibrationEnabled) return;
    HapticFeedback.lightImpact();
  }
  
  void mediumImpact() {
    if (!_vibrationEnabled) return;
    HapticFeedback.mediumImpact();
  }
  
  void heavyImpact() {
    if (!_vibrationEnabled) return;
    HapticFeedback.heavyImpact();
  }
  
  void selectionClick() {
    if (!_vibrationEnabled) return;
    HapticFeedback.selectionClick();
  }
  
  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) => p.setBool('vibration', enabled));
  }
}
