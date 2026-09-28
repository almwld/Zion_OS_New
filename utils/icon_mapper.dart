import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconMapper {
  static Widget getIcon(String appName, {double size = 28}) {
    final path = _getIconPath(appName);
    if (path != null) {
      return SvgPicture.asset(path, width: size, height: size, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn));
    }
    return Icon(_getFallbackIcon(appName), size: size, color: const Color(0xFF00BCD4));
  }

  static String? _getIconPath(String appName) {
    final icons = {
      "CALCULATOR": "assets/icons/svg_colors/calculator.svg",
      "NOTES": "assets/icons/svg_colors/notes.svg",
      "TERMINAL": "assets/icons/svg_colors/terminal.svg",
      "WIFI": "assets/icons/svg_colors/wifi.svg",
      "CRYPTO": "assets/icons/svg_colors/crypto.svg",
      "STEALTH": "assets/icons/svg_colors/stealth.svg",
    };
    return icons[appName];
  }

  static IconData _getFallbackIcon(String appName) {
    switch (appName) {
      case "CALCULATOR": return Icons.calculate;
      case "NOTES": return Icons.note;
      case "TERMINAL": return Icons.terminal;
      case "WIFI": return Icons.wifi;
      default: return Icons.apps;
    }
  }
}
