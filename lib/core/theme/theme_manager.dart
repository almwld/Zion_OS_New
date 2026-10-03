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
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Color(0xFF7C4DFF),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF7C4DFF).withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
        ),
      ),
    );
  }
  
  ThemeData _buildCyberGreenTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: const Color(0xFF7C4DFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF7C4DFF),
        foregroundColor: Color(0xFF7C4DFF),
        elevation: 0,
      ),
    );
  }
  
  ThemeData _buildNeonBlueTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: const Color(0xFF7C4DFF),
    );
  }
  
  ThemeData _buildDarkPurpleTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: const Color(0xFF7C4DFF),
    );
  }
  
  ThemeData _buildSunsetTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: const Color(0xFF7C4DFF),
    );
  }
  
  ThemeData _buildMatrixTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: Colors.black,
    );
  }
  
  ThemeData _buildHolographicTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: const Color(0xFF7C4DFF),
    );
  }
  
  ThemeData _buildMidnightTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: const Color(0xFF7C4DFF),
    );
  }
  
  ThemeData _buildAuroraTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: const Color(0xFF7C4DFF),
    );
  }
  
  ThemeData _buildEmberTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF7C4DFF),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      scaffoldBackgroundColor: const Color(0xFF7C4DFF),
    );
  }
}
