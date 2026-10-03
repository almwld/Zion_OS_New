import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ZionThemeType {
  matrix('Matrix', Color(0xFF7C4DFF), Color(0xFF7C4DFF)),
  cyberpunk('Cyberpunk', Color(0xFF7C4DFF), Color(0xFF7C4DFF)),
  ocean('Ocean Deep', Color(0xFF7C4DFF), Color(0xFF7C4DFF)),
  goldPhoenix('Gold Phoenix', Color(0xFF7C4DFF), Color(0xFF7C4DFF));

  final String name;
  final Color accent;
  final Color background;
  const ZionThemeType(this.name, this.accent, this.background);
}

class ThemeEngine {
  static final ThemeEngine _instance = ThemeEngine._internal();
  factory ThemeEngine() => _instance;
  ThemeEngine._internal();

  ZionThemeType _currentTheme = ZionThemeType.matrix;
  double _glassIntensity = 0.8;

  ZionThemeType get currentTheme => _currentTheme;
  double get glassIntensity => _glassIntensity;

  Future<void> setTheme(ZionThemeType theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.name);
  }

  Future<void> setGlassIntensity(double value) async {
    _glassIntensity = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('glass_intensity', _glassIntensity);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme');
    if (themeName != null) {
      _currentTheme = ZionThemeType.values.firstWhere(
        (t) => t.name == themeName,
        orElse: () => ZionThemeType.matrix,
      );
    }
    _glassIntensity = prefs.getDouble('glass_intensity') ?? 0.8;
  }

  Color get accent => _currentTheme.accent;
  Color get background => _currentTheme.background;

  Gradient getGradientBackground() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [background, background.withOpacity(0.8), accent.withOpacity(0.05)],
    );
  }
}
