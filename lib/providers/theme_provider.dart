import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/zion_colors.dart';
import '../core/theme/zion_theme.dart';

/// Single live theme state for the desktop application.
class ThemeProvider extends ChangeNotifier {
  static const _darkKey = 'zion_is_dark';
  static const _primaryKey = 'zion_primary_color';
  static const _radarScaleKey = 'radar_scale';
  static const _cmatrixEnabledKey = 'cmatrix_enabled';
  static const _cmatrixMusnadKey = 'cmatrix_use_musnad';
  static const _cmatrixArabicKey = 'cmatrix_use_arabic';
  static const _cmatrixColorKey = 'cmatrix_color';
  static const _cmatrixOpacityKey = 'cmatrix_opacity';
  static const _cmatrixSpeedKey = 'cmatrix_speed';
  static const _cmatrixFontSizeKey = 'cmatrix_font_size';

  bool _isDark = true;
  Color _primaryColor = ZionColors.cyan;
  double _radarScale = 1.0;
  bool _cmatrixEnabled = true;
  bool _cmatrixUseMusnad = true;
  bool _cmatrixUseArabic = false;
  Color _cmatrixColor = const Color(0xFF00FF41);
  double _cmatrixOpacity = 0.15;
  double _cmatrixSpeed = 2.2;
  double _cmatrixFontSize = 18.0;

  ThemeProvider() {
    _load();
  }

  bool get isDarkMode => _isDark;
  bool get isDark => _isDark;
  Color get primaryColor => _primaryColor;
  double get radarScale => _radarScale;
  bool get cmatrixEnabled => _cmatrixEnabled;
  bool get cmatrixUseMusnad => _cmatrixUseMusnad;
  bool get cmatrixUseArabic => _cmatrixUseArabic;
  Color get cmatrixColor => _cmatrixColor;
  double get cmatrixOpacity => _cmatrixOpacity;
  double get cmatrixSpeed => _cmatrixSpeed;
  double get cmatrixFontSize => _cmatrixFontSize;

  Color get background =>
      _isDark ? ZionColors.darkBackground : ZionColors.lightBackground;
  Color get surface =>
      _isDark ? ZionColors.darkSurface : ZionColors.lightSurface;
  Color get card => _isDark ? ZionColors.darkCard : ZionColors.lightCard;
  Color get border => _isDark ? ZionColors.darkBorder : ZionColors.lightBorder;
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
      final value = prefs.getString(_primaryKey);
      _primaryColor = value == 'teal' ? ZionColors.teal : ZionColors.cyan;
      _radarScale = (prefs.getDouble(_radarScaleKey) ?? 1.0).clamp(0.6, 2.0);
      _cmatrixEnabled = prefs.getBool(_cmatrixEnabledKey) ?? true;
      _cmatrixUseMusnad = prefs.getBool(_cmatrixMusnadKey) ?? true;
      _cmatrixUseArabic = prefs.getBool(_cmatrixArabicKey) ?? false;
      _cmatrixColor = Color(prefs.getInt(_cmatrixColorKey) ?? const Color(0xFF00FF41).value);
      _cmatrixOpacity = (prefs.getDouble(_cmatrixOpacityKey) ?? 0.15).clamp(0.0, 1.0);
      _cmatrixSpeed = (prefs.getDouble(_cmatrixSpeedKey) ?? 2.2).clamp(0.5, 6.0);
      _cmatrixFontSize = (prefs.getDouble(_cmatrixFontSizeKey) ?? 18.0).clamp(10.0, 32.0);
      notifyListeners();
    } catch (_) {}
  }

  void toggleTheme() {
    setTheme(!_isDark);
  }

  void setTheme(bool isDark) {
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
    _radarScale = scale.clamp(0.6, 2.0);
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
    _cmatrixOpacity = (opacity ?? _cmatrixOpacity).clamp(0.0, 1.0);
    _cmatrixSpeed = (speed ?? _cmatrixSpeed).clamp(0.5, 6.0);
    _cmatrixFontSize = (fontSize ?? _cmatrixFontSize).clamp(10.0, 32.0);
    notifyListeners();
    await _persist();
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
      await prefs.setBool(_cmatrixEnabledKey, _cmatrixEnabled);
      await prefs.setBool(_cmatrixMusnadKey, _cmatrixUseMusnad);
      await prefs.setBool(_cmatrixArabicKey, _cmatrixUseArabic);
      await prefs.setInt(_cmatrixColorKey, _cmatrixColor.value);
      await prefs.setDouble(_cmatrixOpacityKey, _cmatrixOpacity);
      await prefs.setDouble(_cmatrixSpeedKey, _cmatrixSpeed);
      await prefs.setDouble(_cmatrixFontSizeKey, _cmatrixFontSize);
    } catch (_) {}
  }
}
