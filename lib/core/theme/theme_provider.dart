import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  Color _primaryColor = const Color(0xFF00BCD4);

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey[900],
      dividerColor: Colors.grey[800],
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _primaryColor,
        surface: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: IconThemeData(color: _primaryColor),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.grey[100],
      dividerColor: Colors.grey[300],
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _primaryColor,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        foregroundColor: Colors.black87,
      ),
      iconTheme: IconThemeData(color: _primaryColor),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
      ),
    );
  }
}
