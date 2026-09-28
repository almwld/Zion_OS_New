import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();
  
  // Theme Settings
  bool _darkMode = true;
  String _themeColor = 'Turquoise';
  String _fontFamily = 'Default';
  double _fontSize = 14.0;
  
  // Security Settings
  bool _biometricEnabled = false;
  bool _autoLockEnabled = true;
  int _autoLockTimeout = 30;
  String _pinCode = '1234';
  
  // Notification Settings
  bool _pushNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // Privacy Settings
  bool _incognitoMode = false;
  bool _clearHistoryOnExit = false;
  
  // Performance Settings
  bool _animationsEnabled = true;
  String _performanceMode = 'Balanced';
  
  // Display Settings
  String _language = 'en';
  String _dateFormat = 'DD/MM/YYYY';
  String _timeFormat = '24h';
  
  Future<void> init() async {
    await _loadAllSettings();
  }
  
  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _darkMode = prefs.getBool('dark_mode') ?? true;
    _themeColor = prefs.getString('theme_color') ?? 'Turquoise';
    _fontFamily = prefs.getString('font_family') ?? 'Default';
    _fontSize = prefs.getDouble('font_size') ?? 14.0;
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    _autoLockEnabled = prefs.getBool('auto_lock_enabled') ?? true;
    _autoLockTimeout = prefs.getInt('auto_lock_timeout') ?? 30;
    _pinCode = prefs.getString('pin_code') ?? '1234';
    _pushNotifications = prefs.getBool('push_notifications') ?? true;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _incognitoMode = prefs.getBool('incognito_mode') ?? false;
    _clearHistoryOnExit = prefs.getBool('clear_history_on_exit') ?? false;
    _animationsEnabled = prefs.getBool('animations_enabled') ?? true;
    _performanceMode = prefs.getString('performance_mode') ?? 'Balanced';
    _language = prefs.getString('language') ?? 'en';
    _dateFormat = prefs.getString('date_format') ?? 'DD/MM/YYYY';
    _timeFormat = prefs.getString('time_format') ?? '24h';
    
    notifyListeners();
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setString('theme_color', _themeColor);
    await prefs.setString('font_family', _fontFamily);
    await prefs.setDouble('font_size', _fontSize);
    await prefs.setBool('biometric_enabled', _biometricEnabled);
    await prefs.setBool('auto_lock_enabled', _autoLockEnabled);
    await prefs.setInt('auto_lock_timeout', _autoLockTimeout);
    await prefs.setString('pin_code', _pinCode);
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setBool('incognito_mode', _incognitoMode);
    await prefs.setBool('clear_history_on_exit', _clearHistoryOnExit);
    await prefs.setBool('animations_enabled', _animationsEnabled);
    await prefs.setString('performance_mode', _performanceMode);
    await prefs.setString('language', _language);
    await prefs.setString('date_format', _dateFormat);
    await prefs.setString('time_format', _timeFormat);
    notifyListeners();
  }
  
  // Getters
  bool get darkMode => _darkMode;
  String get themeColor => _themeColor;
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  bool get biometricEnabled => _biometricEnabled;
  bool get autoLockEnabled => _autoLockEnabled;
  int get autoLockTimeout => _autoLockTimeout;
  String get pinCode => _pinCode;
  bool get pushNotifications => _pushNotifications;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get incognitoMode => _incognitoMode;
  bool get clearHistoryOnExit => _clearHistoryOnExit;
  bool get animationsEnabled => _animationsEnabled;
  String get performanceMode => _performanceMode;
  String get language => _language;
  String get dateFormat => _dateFormat;
  String get timeFormat => _timeFormat;
  
  // Setters
  set darkMode(bool value) { _darkMode = value; _saveSettings(); }
  set themeColor(String value) { _themeColor = value; _saveSettings(); }
  set fontFamily(String value) { _fontFamily = value; _saveSettings(); }
  set fontSize(double value) { _fontSize = value; _saveSettings(); }
  set biometricEnabled(bool value) { _biometricEnabled = value; _saveSettings(); }
  set autoLockEnabled(bool value) { _autoLockEnabled = value; _saveSettings(); }
  set autoLockTimeout(int value) { _autoLockTimeout = value; _saveSettings(); }
  set pinCode(String value) { _pinCode = value; _saveSettings(); }
  set pushNotifications(bool value) { _pushNotifications = value; _saveSettings(); }
  set soundEnabled(bool value) { _soundEnabled = value; _saveSettings(); }
  set vibrationEnabled(bool value) { _vibrationEnabled = value; _saveSettings(); }
  set incognitoMode(bool value) { _incognitoMode = value; _saveSettings(); }
  set clearHistoryOnExit(bool value) { _clearHistoryOnExit = value; _saveSettings(); }
  set animationsEnabled(bool value) { _animationsEnabled = value; _saveSettings(); }
  set performanceMode(String value) { _performanceMode = value; _saveSettings(); }
  set language(String value) { _language = value; _saveSettings(); }
  set dateFormat(String value) { _dateFormat = value; _saveSettings(); }
  set timeFormat(String value) { _timeFormat = value; _saveSettings(); }
  
  Future<void> resetToDefault() async {
    _darkMode = true;
    _themeColor = 'Turquoise';
    _fontFamily = 'Default';
    _fontSize = 14.0;
    _biometricEnabled = false;
    _autoLockEnabled = true;
    _autoLockTimeout = 30;
    _pinCode = '1234';
    _pushNotifications = true;
    _soundEnabled = true;
    _vibrationEnabled = true;
    _incognitoMode = false;
    _clearHistoryOnExit = false;
    _animationsEnabled = true;
    _performanceMode = 'Balanced';
    _language = 'en';
    _dateFormat = 'DD/MM/YYYY';
    _timeFormat = '24h';
    await _saveSettings();
  }
}
