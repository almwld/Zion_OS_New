import 'package:flutter/material.dart';

class ZionTheme {
  final String name;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;
  final String wallpaperType;

  const ZionTheme({
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
    required this.wallpaperType,
  });

  static const ZionTheme matrix = ZionTheme(
    name: 'Matrix',
    primaryColor: Color(0xFF00FF41),
    backgroundColor: Colors.black,
    surfaceColor: Color(0xFF0A0E0A),
    textColor: Color(0xFF00FF41),
    accentColor: Color(0xFF00FF41),
    wallpaperType: 'matrix_rain',
  );

  static const ZionTheme midnightBlue = ZionTheme(
    name: 'Midnight Blue',
    primaryColor: Color(0xFF0088FF),
    backgroundColor: Color(0xFF0A0A1A),
    surfaceColor: Color(0xFF0D0D2B),
    textColor: Color(0xFF00AAFF),
    accentColor: Color(0xFF0066CC),
    wallpaperType: 'particles',
  );

  static const ZionTheme bloodRed = ZionTheme(
    name: 'Blood Red',
    primaryColor: Color(0xFFFF0040),
    backgroundColor: Color(0xFF1A0A0A),
    surfaceColor: Color(0xFF2B0D0D),
    textColor: Color(0xFFFF3355),
    accentColor: Color(0xFFCC0033),
    wallpaperType: 'blood_drip',
  );

  static const ZionTheme goldPhoenix = ZionTheme(
    name: 'Gold Phoenix',
    primaryColor: Color(0xFFFFD700),
    backgroundColor: Color(0xFF1A1A0A),
    surfaceColor: Color(0xFF2B2B0D),
    textColor: Color(0xFFFFDD44),
    accentColor: Color(0xFFCCAA00),
    wallpaperType: 'fire_embers',
  );

  static const ZionTheme arcticFrost = ZionTheme(
    name: 'Arctic Frost',
    primaryColor: Color(0xFF00FFFF),
    backgroundColor: Color(0xFF0A1A1A),
    surfaceColor: Color(0xFF0D2B2B),
    textColor: Color(0xFF44FFFF),
    accentColor: Color(0xFF00CCCC),
    wallpaperType: 'snowflakes',
  );

  static final List<ZionTheme> allThemes = [matrix, midnightBlue, bloodRed, goldPhoenix, arcticFrost];
}

class ZionThemeEngine extends ChangeNotifier {
  ZionTheme _currentTheme = ZionTheme.matrix;

  ZionTheme get currentTheme => _currentTheme;

  void changeTheme(ZionTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  void cycleNext() {
    final currentIndex = ZionTheme.allThemes.indexOf(_currentTheme);
    final nextIndex = (currentIndex + 1) % ZionTheme.allThemes.length;
    _currentTheme = ZionTheme.allThemes[nextIndex];
    notifyListeners();
  }
}
