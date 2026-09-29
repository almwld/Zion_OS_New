import 'package:flutter/material.dart';
class ZionColors {
  ZionColors._();
  static const cyan=Color(0xFF00BCD4), teal=Color(0xFF00838F), cyanLight=Color(0xFF4DD0E1);
  static const success=Color(0xFF00E676), warning=Color(0xFFFFC107), error=Color(0xFFFF1744), info=Color(0xFF2196F3);
  static const darkBackground=Color(0xFF000000), darkSurface=Color(0xFF0A0E1A), darkCard=Color(0xFF121826), darkBorder=Color(0xFF1A2333);
  static const darkTextPrimary=Color(0xFFFFFFFF), darkTextSecondary=Color(0xFFB0B8C4), darkTextDisabled=Color(0xFF5A6470), darkIconPrimary=cyan, darkIconSecondary=darkTextSecondary, darkDivider=darkBorder;
  static const lightBackground=Color(0xFFF5F7FA), lightSurface=Color(0xFFFFFFFF), lightCard=Color(0xFFFFFFFF), lightBorder=Color(0xFFE0E6ED);
  static const lightTextPrimary=Color(0xFF0A0E1A), lightTextSecondary=Color(0xFF4A5568), lightTextDisabled=Color(0xFFA0AEC0), lightIconPrimary=teal, lightIconSecondary=lightTextSecondary, lightDivider=lightBorder;
  static const attackRed=error, defenseGreen=success, analysisBlue=info, toolsOrange=Color(0xFFFFA502);
  static const appPalette=[cyan,Color(0xFF4CAF50),Color(0xFFFF5722),Color(0xFF9C27B0),info,Color(0xFFFF9800),Color(0xFFE91E63),Color(0xFF3F51B5),Color(0xFF009688),Color(0xFF795548),Color(0xFF607D8B),Color(0xFF673AB7)];
  static const primaryGradient=LinearGradient(colors:[cyan,teal],begin:Alignment.topLeft,end:Alignment.bottomRight);
  static const darkGradient=LinearGradient(colors:[darkSurface,darkBackground],begin:Alignment.topCenter,end:Alignment.bottomCenter);
  static const lightGradient=LinearGradient(colors:[lightBackground,Color(0xFFE8ECF1)],begin:Alignment.topCenter,end:Alignment.bottomCenter);
}
