import 'package:flutter/material.dart';

class AppModel extends ChangeNotifier {
  bool _isDarkMode = true;
  String _currentLanguage = 'ar';
  String _currentTheme = 'turquoise';
  
  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;
  String get currentTheme => _currentTheme;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  void setLanguage(String lang) {
    _currentLanguage = lang;
    notifyListeners();
  }
  
  void setTheme(String theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}
