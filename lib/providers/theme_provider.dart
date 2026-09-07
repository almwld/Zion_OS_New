import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _pinHashKey = 'user_pin_hash';
  static const _pinSaltKey = 'user_pin_salt';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _isDarkMode = true;
  Color _primaryColor = const Color(0xFF00BCD4);
  double _fontScale = 1.0;
  double _iconSize = 58.0;
  String? _pinHash;
  String? _pinSalt;
  bool _isReady = false;

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  double get fontScale => _fontScale;
  double get iconSize => _iconSize;
  bool get isReady => _isReady;
  bool get hasPin => _pinHash != null && _pinSalt != null;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? true;
    _fontScale = prefs.getDouble('font_scale') ?? 1.0;
    _iconSize = prefs.getDouble('icon_size') ?? 58.0;

    _pinHash = await _secureStorage.read(key: _pinHashKey);
    _pinSalt = await _secureStorage.read(key: _pinSaltKey);

    // One-time migration from the legacy plaintext PIN.
    final legacyPin = prefs.getString('user_pin');
    if (!hasPin && legacyPin != null && RegExp(r'^\d{4}$').hasMatch(legacyPin)) {
      await _storePin(legacyPin);
      await prefs.remove('user_pin');
    }

    final colorHex = prefs.getString('theme_color');
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        _primaryColor = Color(int.parse(colorHex));
      } catch (_) {
        _primaryColor = const Color(0xFF00BCD4);
      }
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> _storePin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltValue = base64UrlEncode(salt);
    final hash = _hashPin(pin, saltValue);
    await _secureStorage.write(key: _pinSaltKey, value: saltValue);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    _pinSalt = saltValue;
    _pinHash = hash;
  }

  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  Future<bool> setInitialPin(String newPin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(newPin)) return false;
    await _storePin(newPin);
    notifyListeners();
    return true;
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    if (!validatePin(oldPin) || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      return false;
    }
    await _storePin(newPin);
    notifyListeners();
    return true;
  }

  bool validatePin(String pin) {
    if (!hasPin || !RegExp(r'^\d{4}$').hasMatch(pin)) return false;
    return _hashPin(pin, _pinSalt!) == _pinHash;
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_color', color.value.toString());
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.8, 1.5);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', _fontScale);
    notifyListeners();
  }

  Future<void> setIconSize(double size) async {
    _iconSize = size.clamp(48.0, 78.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('icon_size', _iconSize);
    notifyListeners();
  }

  ThemeData getThemeData() {
    final baseTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    return baseTheme.copyWith(
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _isDarkMode ? Colors.black : Colors.grey[50],
      textTheme: baseTheme.textTheme.apply(
        bodyColor: _isDarkMode ? Colors.white : Colors.black87,
        displayColor: _isDarkMode ? Colors.white : Colors.black87,
        fontFamily: 'Cairo',
        fontSizeFactor: _fontScale,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        foregroundColor: _primaryColor,
      ),
      iconTheme: IconThemeData(
        color: _primaryColor,
        size: 24 * (_iconSize / 58),
      ),
    );
  }
}
