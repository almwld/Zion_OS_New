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
    primaryColor: Color(0xFF7C4DFF),
    backgroundColor: Colors.black,
    surfaceColor: Color(0xFF7C4DFF),
    textColor: Color(0xFF7C4DFF),
    accentColor: Color(0xFF7C4DFF),
    wallpaperType: 'matrix_rain',
  );

  static const ZionTheme midnightBlue = ZionTheme(
    name: 'Midnight Blue',
    primaryColor: Color(0xFF7C4DFF),
    backgroundColor: Color(0xFF7C4DFF),
    surfaceColor: Color(0xFF7C4DFF),
    textColor: Color(0xFF7C4DFF),
    accentColor: Color(0xFF7C4DFF),
    wallpaperType: 'particles',
  );

  static const ZionTheme bloodRed = ZionTheme(
    name: 'Blood Red',
    primaryColor: Color(0xFF7C4DFF),
    backgroundColor: Color(0xFF7C4DFF),
    surfaceColor: Color(0xFF7C4DFF),
    textColor: Color(0xFF7C4DFF),
    accentColor: Color(0xFF7C4DFF),
    wallpaperType: 'blood_drip',
  );

  static const ZionTheme goldPhoenix = ZionTheme(
    name: 'Gold Phoenix',
    primaryColor: Color(0xFF7C4DFF),
    backgroundColor: Color(0xFF7C4DFF),
    surfaceColor: Color(0xFF7C4DFF),
    textColor: Color(0xFF7C4DFF),
    accentColor: Color(0xFF7C4DFF),
    wallpaperType: 'fire_embers',
  );

  static const ZionTheme arcticFrost = ZionTheme(
    name: 'Arctic Frost',
    primaryColor: Color(0xFF7C4DFF),
    backgroundColor: Color(0xFF7C4DFF),
    surfaceColor: Color(0xFF7C4DFF),
    textColor: Color(0xFF7C4DFF),
    accentColor: Color(0xFF7C4DFF),
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
