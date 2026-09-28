import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreset {
  matrix('Matrix', Color(0xFF00FF41), Color(0xFF000000), Icons.code),
  cyberpunk('Cyberpunk', Color(0xFFFF00FF), Color(0xFF0D0D0D), Icons.flash_on),
  ocean('Ocean Deep', Color(0xFF00BFFF), Color(0xFF001F3F), Icons.water),
  goldPhoenix('Gold Phoenix', Color(0xFFFFD700), Color(0xFF1A1A00), Icons.whatshot),
  royalPurple('Royal Purple', Color(0xFF9B59B6), Color(0xFF1A0F2E), Icons.star),
  emerald('Emerald', Color(0xFF50C878), Color(0xFF003322), Icons.eco),
  ruby('Ruby', Color(0xFFE0115F), Color(0xFF33001A), Icons.favorite),
  arctic('Arctic Frost', Color(0xFF00FFFF), Color(0xFF001F1F), Icons.ac_unit),
  sunset('Sunset', Color(0xFFFF6B35), Color(0xFF331A00), Icons.wb_sunny),
  midnight('Midnight', Color(0xFF6A0DAD), Color(0xFF0A0A2A), Icons.nightlight),
  forest('Forest', Color(0xFF228B22), Color(0xFF0A2A0A), Icons.park),
  lava('Lava', Color(0xFFFF4500), Color(0xFF2A0A00), Icons.whatshot);

  final String name;
  final Color accent;
  final Color background;
  final IconData icon;
  const ThemePreset(this.name, this.accent, this.background, this.icon);
}

class AdvancedTheme {
  static final AdvancedTheme _instance = AdvancedTheme._internal();
  factory AdvancedTheme() => _instance;
  AdvancedTheme._internal();

  ThemePreset _currentTheme = ThemePreset.matrix;
  double _blurIntensity = 10.0;
  double _cornerRadius = 12.0;
  double _animationSpeed = 1.0;
  bool _darkMode = true;
  bool _glassEffect = true;
  bool _animations = true;

  ThemePreset get currentTheme => _currentTheme;
  double get blurIntensity => _blurIntensity;
  double get cornerRadius => _cornerRadius;
  bool get glassEffect => _glassEffect;

  Future<void> setTheme(ThemePreset theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.name);
  }

  Future<void> setBlurIntensity(double value) async {
    _blurIntensity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('blur_intensity', value);
  }

  Future<void> setCornerRadius(double value) async {
    _cornerRadius = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('corner_radius', value);
  }

  Future<void> toggleGlassEffect() async {
    _glassEffect = !_glassEffect;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glass_effect', _glassEffect);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme');
    if (themeName != null) {
      _currentTheme = ThemePreset.values.firstWhere(
        (t) => t.name == themeName,
        orElse: () => ThemePreset.matrix,
      );
    }
    _blurIntensity = prefs.getDouble('blur_intensity') ?? 10.0;
    _cornerRadius = prefs.getDouble('corner_radius') ?? 12.0;
    _glassEffect = prefs.getBool('glass_effect') ?? true;
  }

  BoxDecoration getGlassDecoration() {
    if (!_glassEffect) {
      return BoxDecoration(color: _currentTheme.background);
    }
    return BoxDecoration(
      color: _currentTheme.background.withOpacity(0.3),
      borderRadius: BorderRadius.circular(_cornerRadius),
      border: Border.all(color: _currentTheme.accent.withOpacity(0.3)),
      boxShadow: [
        BoxShadow(
          color: _currentTheme.accent.withOpacity(0.1),
          blurRadius: _blurIntensity,
          spreadRadius: 2,
        ),
      ],
    );
  }

  BoxDecoration getNeumorphismDecoration({bool isPressed = false}) {
    return BoxDecoration(
      color: _currentTheme.background,
      borderRadius: BorderRadius.circular(_cornerRadius),
      boxShadow: isPressed
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 5,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                offset: const Offset(-3, -3),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(3, 3),
                blurRadius: 6,
              ),
            ],
    );
  }
}
