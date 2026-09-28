import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  turquoise,
  cyberGreen,
  neonBlue,
  darkPurple,
  sunset,
  matrix,
  holographic,
  midnight,
  aurora,
  ember,
}

class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme.turquoise;
  
  ThemeManager() {
    _loadTheme();
  }
  
  AppTheme get currentTheme => _currentTheme;
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    if (themeName != null) {
      _currentTheme = AppTheme.values.firstWhere(
        (e) => e.toString() == themeName,
        orElse: () => AppTheme.turquoise,
      );
      notifyListeners();
    }
  }
  
  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.toString());
    notifyListeners();
  }
  
  ThemeData getThemeData() {
    switch (_currentTheme) {
      case AppTheme.turquoise:
        return _buildTurquoiseTheme();
      case AppTheme.cyberGreen:
        return _buildCyberGreenTheme();
      case AppTheme.neonBlue:
        return _buildNeonBlueTheme();
      case AppTheme.darkPurple:
        return _buildDarkPurpleTheme();
      case AppTheme.sunset:
        return _buildSunsetTheme();
      case AppTheme.matrix:
        return _buildMatrixTheme();
      case AppTheme.holographic:
        return _buildHolographicTheme();
      case AppTheme.midnight:
        return _buildMidnightTheme();
      case AppTheme.aurora:
        return _buildAuroraTheme();
      case AppTheme.ember:
        return _buildEmberTheme();
    }
  }
  
  ThemeData _buildTurquoiseTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF00BCD4),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF00BCD4)),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Color(0xFF00BCD4),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00BCD4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF00BCD4).withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
        ),
      ),
    );
  }
  
  ThemeData _buildCyberGreenTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF00FF41),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF00FF41)),
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A0A),
        foregroundColor: Color(0xFF00FF41),
        elevation: 0,
      ),
    );
  }
  
  ThemeData _buildNeonBlueTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF2196F3),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF2196F3)),
      scaffoldBackgroundColor: const Color(0xFF001133),
    );
  }
  
  ThemeData _buildDarkPurpleTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF9C27B0),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF9C27B0)),
      scaffoldBackgroundColor: const Color(0xFF1A0B2E),
    );
  }
  
  ThemeData _buildSunsetTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFFFF5722),
      colorScheme: const ColorScheme.dark(primary: Color(0xFFFF5722)),
      scaffoldBackgroundColor: const Color(0xFF1A0A0A),
    );
  }
  
  ThemeData _buildMatrixTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF33FF33),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF33FF33)),
      scaffoldBackgroundColor: Colors.black,
    );
  }
  
  ThemeData _buildHolographicTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFFE040FB),
      colorScheme: const ColorScheme.dark(primary: Color(0xFFE040FB)),
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
    );
  }
  
  ThemeData _buildMidnightTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF3F51B5),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF3F51B5)),
      scaffoldBackgroundColor: const Color(0xFF0A0A20),
    );
  }
  
  ThemeData _buildAuroraTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF4CAF50),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF4CAF50)),
      scaffoldBackgroundColor: const Color(0xFF0A1A0A),
    );
  }
  
  ThemeData _buildEmberTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFFFF6B00),
      colorScheme: const ColorScheme.dark(primary: Color(0xFFFF6B00)),
      scaffoldBackgroundColor: const Color(0xFF1A0A00),
    );
  }
}
