import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/zion_colors.dart';
import '../core/theme/zion_theme.dart';

/// Single live theme state for the desktop application.
class ThemeProvider extends ChangeNotifier {
  static const _darkKey = 'zion_is_dark';
  static const _primaryKey = 'zion_primary_color';

  bool _isDark = true;
  Color _primaryColor = ZionColors.cyan;

  ThemeProvider() {
    _load();
  }

  bool get isDarkMode => _isDark;
  bool get isDark => _isDark;
  Color get primaryColor => _primaryColor;

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

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkKey, _isDark);
      await prefs.setString(
        _primaryKey,
        _primaryColor.value == ZionColors.teal.value ? 'teal' : 'cyan',
      );
    } catch (_) {}
  }
}
