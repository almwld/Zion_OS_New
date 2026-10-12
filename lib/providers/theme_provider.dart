import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/zion_colors.dart';
import '../core/theme/zion_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const _darkKey = 'zion_is_dark';
  static const _primaryKey = 'zion_primary_color';
  static const _radarScaleKey = 'radar_scale';
  static const _radarPositionXKey = 'radar_position_x';
  static const _radarPositionYKey = 'radar_position_y';
  static const _cmatrixEnabledKey = 'cmatrix_enabled';
  static const _cmatrixMusnadKey = 'cmatrix_use_musnad';
  static const _cmatrixArabicKey = 'cmatrix_use_arabic';
  static const _cmatrixColorKey = 'cmatrix_color';
  static const _cmatrixOpacityKey = 'cmatrix_opacity';
  static const _cmatrixSpeedKey = 'cmatrix_speed';
  static const _cmatrixFontSizeKey = 'cmatrix_font_size';
  static const _fontScaleKey = 'font_scale';
  static const _iconSizeKey = 'icon_size';
  static const _pinHashKey = 'user_pin_hash';
  static const _pinSaltKey = 'user_pin_salt';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _isDark = true;
  Color _primaryColor = ZionColors.cyan;
  double _radarScale = 1.0;
  double _radarPositionX = 0.72;
  double _radarPositionY = 0.16;
  bool _cmatrixEnabled = true;
  bool _cmatrixUseMusnad = true;
  bool _cmatrixUseArabic = false;
  Color _cmatrixColor = ZionColors.cyan;
  double _cmatrixOpacity = 0.15;
  double _cmatrixSpeed = 2.2;
  double _cmatrixFontSize = 18.54;
  double _fontScale = 1.0;
  double _iconSize = 58.0;
  String? _pinHash;
  String? _pinSalt;
  bool _isReady = false;

  ThemeProvider() {
    _load();
  }

  bool get isDarkMode => _isDark;
  bool get isDark => _isDark;
  Color get primaryColor => _primaryColor;
  double get radarScale => _radarScale;
  double get radarPositionX => _radarPositionX;
  double get radarPositionY => _radarPositionY;
  bool get cmatrixEnabled => _cmatrixEnabled;
  bool get cmatrixUseMusnad => _cmatrixUseMusnad;
  bool get cmatrixUseArabic => _cmatrixUseArabic;
  Color get cmatrixColor => _cmatrixColor;
  double get cmatrixOpacity => _cmatrixOpacity;
  double get cmatrixSpeed => _cmatrixSpeed;
  double get cmatrixFontSize => _cmatrixFontSize;
  double get fontScale => _fontScale;
  double get iconSize => _iconSize;
  bool get isReady => _isReady;
  bool get hasPin => _pinHash != null && _pinSalt != null;

  Color get background =>
      _isDark ? ZionColors.darkBackground : ZionColors.lightBackground;
  Color get surface =>
      _isDark ? ZionColors.darkSurface : ZionColors.lightSurface;
  Color get card => _isDark ? ZionColors.darkCard : ZionColors.lightCard;
  Color get border =>
      _isDark ? ZionColors.darkBorder : ZionColors.lightBorder;
  Color get textPrimary =>
      _isDark ? ZionColors.darkTextPrimary : ZionColors.lightTextPrimary;
  Color get textSecondary =>
      _isDark ? ZionColors.darkTextSecondary : ZionColors.lightTextSecondary;
  Color get textDisabled =>
      _isDark ? ZionColors.darkTextDisabled : ZionColors.lightTextDisabled;
  Color get iconPrimary =>
      _isDark ? ZionColors.darkIconPrimary : ZionColors.lightIconPrimary;
  Color get iconSecondary =>
      _isDark ? ZionColors.darkIconSecondary : ZionColors.lightIconSecondary;
  Color get divider =>
      _isDark ? ZionColors.darkDivider : ZionColors.lightDivider;

  ThemeData get themeData => _isDark ? ZionTheme.dark : ZionTheme.light;
  ThemeData getThemeData() => themeData;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_darkKey) ?? true;
      _primaryColor =
          prefs.getString(_primaryKey) == 'teal' ? ZionColors.teal : ZionColors.cyan;
      _radarScale =
          (prefs.getDouble(_radarScaleKey) ?? 1.0).clamp(0.6, 2.5).toDouble();
      _radarPositionX =
          (prefs.getDouble(_radarPositionXKey) ?? 0.72).clamp(0.0, 1.0).toDouble();
      _radarPositionY =
          (prefs.getDouble(_radarPositionYKey) ?? 0.16).clamp(0.0, 1.0).toDouble();
      _cmatrixEnabled = prefs.getBool(_cmatrixEnabledKey) ?? true;
      _cmatrixUseMusnad = prefs.getBool(_cmatrixMusnadKey) ?? true;
      _cmatrixUseArabic = prefs.getBool(_cmatrixArabicKey) ?? false;
      final storedCMatrixColor = prefs.getInt(_cmatrixColorKey);
      _cmatrixColor = storedCMatrixColor == null || storedCMatrixColor == const Color(0xFF00FF41).value
          ? ZionColors.cyan
          : Color(storedCMatrixColor);
      _cmatrixOpacity =
          (prefs.getDouble(_cmatrixOpacityKey) ?? 0.15).clamp(0.0, 1.0).toDouble();
      _cmatrixSpeed =
          (prefs.getDouble(_cmatrixSpeedKey) ?? 2.2).clamp(0.5, 6.0).toDouble();
      _cmatrixFontSize =
          (prefs.getDouble(_cmatrixFontSizeKey) ?? 18.54).clamp(10.0, 32.0).toDouble();
      _fontScale =
          (prefs.getDouble(_fontScaleKey) ?? 1.0).clamp(0.8, 1.5).toDouble();
      _iconSize =
          (prefs.getDouble(_iconSizeKey) ?? 58.0).clamp(48.0, 78.0).toDouble();

      try {
        _pinHash = await _secureStorage.read(key: _pinHashKey);
        _pinSalt = await _secureStorage.read(key: _pinSaltKey);
      } catch (_) {
        _pinHash = null;
        _pinSalt = null;
      }

      final legacyPin = prefs.getString('user_pin');
      if (!hasPin && legacyPin != null && _isValidPin(legacyPin)) {
        try {
          await _storePin(legacyPin);
          await prefs.remove('user_pin');
        } catch (_) {}
      }
    } catch (_) {
      // Defaults remain active if persistence is unavailable.
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  void toggleTheme() => setTheme(!_isDark);

  void setTheme(bool isDark) {
    if (_isDark == isDark) return;
    _isDark = isDark;
    notifyListeners();
    _persist();
  }

  void setDarkMode(bool isDark) => setTheme(isDark);

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
    _persist();
  }

  Future<void> setRadarScale(double scale) async {
    _radarScale = scale.clamp(0.6, 2.5).toDouble();
    notifyListeners();
    await _persist();
  }

  Future<void> setRadarPosition(double x, double y) async {
    _radarPositionX = x.clamp(0.0, 1.0).toDouble();
    _radarPositionY = y.clamp(0.0, 1.0).toDouble();
    notifyListeners();
    await _persist();
  }

  Future<void> setCMatrix({
    bool? enabled,
    bool? useMusnad,
    bool? useArabic,
    Color? color,
    double? opacity,
    double? speed,
    double? fontSize,
  }) async {
    _cmatrixEnabled = enabled ?? _cmatrixEnabled;
    _cmatrixUseMusnad = useMusnad ?? _cmatrixUseMusnad;
    _cmatrixUseArabic = useArabic ?? _cmatrixUseArabic;
    _cmatrixColor = color ?? _cmatrixColor;
    _cmatrixOpacity =
        (opacity ?? _cmatrixOpacity).clamp(0.0, 1.0).toDouble();
    _cmatrixSpeed =
        (speed ?? _cmatrixSpeed).clamp(0.5, 6.0).toDouble();
    _cmatrixFontSize =
        (fontSize ?? _cmatrixFontSize).clamp(10.0, 32.0).toDouble();
    notifyListeners();
    await _persist();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value.clamp(0.8, 1.5).toDouble();
    notifyListeners();
    await _persist();
  }

  Future<void> setIconSize(double value) async {
    _iconSize = value.clamp(48.0, 78.0).toDouble();
    notifyListeners();
    await _persist();
  }

  Future<void> setCMatrixEnabled(bool value) => setCMatrix(enabled: value);
  Future<void> setCMatrixOpacity(double value) => setCMatrix(opacity: value);
  Future<void> setCMatrixSpeed(double value) => setCMatrix(speed: value);
  Future<void> setCMatrixFontSize(double value) => setCMatrix(fontSize: value);
  Future<void> setCMatrixUseMusnad(bool value) =>
      setCMatrix(useMusnad: value, useArabic: !value);
  Future<void> setCMatrixUseArabic(bool value) =>
      setCMatrix(useArabic: value, useMusnad: !value);
  Future<void> setCMatrixColor(Color value) => setCMatrix(color: value);

  Future<void> _storePin(String pin) async {
    final salt = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    final saltValue = base64UrlEncode(salt);
    final hash = sha256
        .convert(utf8.encode('$saltValue:$pin'))
        .toString();
    await _secureStorage.write(key: _pinSaltKey, value: saltValue);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    _pinSalt = saltValue;
    _pinHash = hash;
  }

  bool _isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

  Future<bool> setInitialPin(String newPin) async {
    if (!_isValidPin(newPin) || hasPin) return false;
    try {
      await _storePin(newPin);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool validatePin(String pin) {
    if (!hasPin || !_isValidPin(pin)) return false;
    return sha256.convert(utf8.encode('$_pinSalt:$pin')).toString() == _pinHash;
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    if (!validatePin(oldPin) || !_isValidPin(newPin)) return false;
    try {
      await _storePin(newPin);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkKey, _isDark);
      await prefs.setString(
        _primaryKey,
        _primaryColor.value == ZionColors.teal.value ? 'teal' : 'cyan',
      );
      await prefs.setDouble(_radarScaleKey, _radarScale);
      await prefs.setDouble(_radarPositionXKey, _radarPositionX);
      await prefs.setDouble(_radarPositionYKey, _radarPositionY);
      await prefs.setBool(_cmatrixEnabledKey, _cmatrixEnabled);
      await prefs.setBool(_cmatrixMusnadKey, _cmatrixUseMusnad);
      await prefs.setBool(_cmatrixArabicKey, _cmatrixUseArabic);
      await prefs.setInt(_cmatrixColorKey, _cmatrixColor.value);
      await prefs.setDouble(_cmatrixOpacityKey, _cmatrixOpacity);
      await prefs.setDouble(_cmatrixSpeedKey, _cmatrixSpeed);
      await prefs.setDouble(_cmatrixFontSizeKey, _cmatrixFontSize);
      await prefs.setDouble(_fontScaleKey, _fontScale);
      await prefs.setDouble(_iconSizeKey, _iconSize);
    } catch (_) {}
  }
}
