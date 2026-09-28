import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;
  
  static double getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 0.8;      // هاتف
    if (width < 900) return 0.9;      // تابلت صغير
    if (width < 1200) return 1.0;     // تابلت كبير
    return 1.2;                        // سطح مكتب / VM
  }
  
  static double getIconSize(BuildContext context) {
    final scale = getScaleFactor(context);
    return 48 * scale;
  }
  
  static double getFontSize(BuildContext context, double baseSize) {
    final scale = getScaleFactor(context);
    return baseSize * scale;
  }
  
  static double getWindowWidth(BuildContext context, double baseWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.85;
    final minWidth = screenWidth * 0.4;
    return baseWidth.clamp(minWidth, maxWidth);
  }
  
  static double getWindowHeight(BuildContext context, double baseHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8;
    final minHeight = screenHeight * 0.3;
    return baseHeight.clamp(minHeight, maxHeight);
  }
  
  static EdgeInsets getDesktopPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(24);
    }
    if (isTablet(context)) {
      return const EdgeInsets.all(16);
    }
    return const EdgeInsets.all(12);
  }
  
  static int getDesktopGridColumns(BuildContext context) {
    if (isDesktop(context)) return 5;
    if (isTablet(context)) return 4;
    return 3;
  }
}
