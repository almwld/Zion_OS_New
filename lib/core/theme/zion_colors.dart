import 'package:flutter/material.dart';

/// Stable Zion OS design tokens.
///
/// Keep the core identity cyan/teal. Feature and operational screens may add
/// their own semantic accents, but the application shell must remain visually
/// consistent.
class ZionColors {
  ZionColors._();

  static const cyan = Color(0xFF00BCD4);
  static const teal = Color(0xFF006064);
  static const cyanLight = Color(0xFF80DEEA);

  static const neonIndigo = cyan;
  static const indigoDeep = teal;
  static const indigoLight = cyanLight;

  static const success = Color(0xFF00C853);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFFF5252);
  static const info = cyan;

  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF0A0E1A);
  static const darkCard = Color(0xFF121826);
  static const darkBorder = Color(0xFF1A2333);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB0B8C4);
  static const darkTextDisabled = Color(0xFF5A6470);
  static const darkIconPrimary = cyan;
  static const darkIconSecondary = darkTextSecondary;
  static const darkDivider = darkBorder;

  static const lightBackground = Color(0xFFF5F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE0E6ED);
  static const lightTextPrimary = Color(0xFF0A0E1A);
  static const lightTextSecondary = Color(0xFF4A5568);
  static const lightTextDisabled = Color(0xFFA0AEC0);
  static const lightIconPrimary = teal;
  static const lightIconSecondary = lightTextSecondary;
  static const lightDivider = lightBorder;

  static const attackRed = Color(0xFFFF5252);
  static const defenseGreen = Color(0xFF00C853);
  static const analysisBlue = Color(0xFF2196F3);
  static const toolsOrange = Color(0xFFFF9800);

  static const appPalette = <Color>[
    cyan,
    teal,
    cyanLight,
    defenseGreen,
    analysisBlue,
    toolsOrange,
    error,
    warning,
  ];

  static const primaryGradient = LinearGradient(
    colors: [cyan, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [darkSurface, darkBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const lightGradient = LinearGradient(
    colors: [lightBackground, Color(0xFFE8ECF1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
