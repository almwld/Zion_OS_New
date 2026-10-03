import 'package:flutter/material.dart';
class ZionColors {
  ZionColors._();
  static const neonIndigo=Color(0xFF7C4DFF), indigoDeep=Color(0xFF4B2BC7), indigoLight=Color(0xFFB388FF);\n  static const cyan=neonIndigo, teal=indigoDeep, cyanLight=indigoLight;
  static const success=neonIndigo, warning=indigoLight, error=indigoDeep, info=neonIndigo;
  static const darkBackground=Color(0xFF000000), darkSurface=Color(0xFF0A0E1A), darkCard=Color(0xFF121826), darkBorder=Color(0xFF1A2333);
  static const darkTextPrimary=Color(0xFFFFFFFF), darkTextSecondary=Color(0xFFB0B8C4), darkTextDisabled=Color(0xFF5A6470), darkIconPrimary=cyan, darkIconSecondary=darkTextSecondary, darkDivider=darkBorder;
  static const lightBackground=Color(0xFFF5F7FA), lightSurface=Color(0xFFFFFFFF), lightCard=Color(0xFFFFFFFF), lightBorder=Color(0xFFE0E6ED);
  static const lightTextPrimary=Color(0xFF0A0E1A), lightTextSecondary=Color(0xFF4A5568), lightTextDisabled=Color(0xFFA0AEC0), lightIconPrimary=teal, lightIconSecondary=lightTextSecondary, lightDivider=lightBorder;
  static const attackRed=neonIndigo, defenseGreen=neonIndigo, analysisBlue=neonIndigo, toolsOrange=neonIndigo;
  static const appPalette=[neonIndigo,neonIndigo,neonIndigo,neonIndigo,neonIndigo,neonIndigo,neonIndigo,neonIndigo,neonIndigo,neonIndigo,neonIndigo,neonIndigo];
  static const primaryGradient=LinearGradient(colors:[neonIndigo,indigoDeep],begin:Alignment.topLeft,end:Alignment.bottomRight);
  static const darkGradient=LinearGradient(colors:[darkSurface,darkBackground],begin:Alignment.topCenter,end:Alignment.bottomCenter);
  static const lightGradient=LinearGradient(colors:[lightBackground,Color(0xFFE8ECF1)],begin:Alignment.topCenter,end:Alignment.bottomCenter);
}
