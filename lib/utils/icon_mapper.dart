import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconMapper {
  static Widget getIcon(String appName, {double size = 28}) {
    final path = _getIconPath(appName);
    if (path != null) {
      return SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn));
    }
    return Icon(_getFallbackIcon(appName), size: size, color: const Color(0xFF00BCD4));
  }

  static String? _getIconPath(String appName) {
    const icons = <String, String>{
      "CALCULATOR": "assets/icons/svg_colors/calculator.svg",
      "NOTES": "assets/icons/svg_colors/notes.svg",
      "TERMINAL": "assets/icons/svg_colors/terminal.svg",
      "WIFI": "assets/icons/svg_colors/wifi.svg",
      "CRYPTO": "assets/icons/svg_colors/crypto.svg",
      "STEALTH": "assets/icons/svg_colors/stealth.svg",
      "CRACKER": "assets/icons/svg_colors/cracker.svg",
      "FORENSICS": "assets/icons/svg_colors/forensics.svg",
      "NETWORK": "assets/icons/svg_colors/network.svg",
      "SETTINGS": "assets/icons/svg_colors/settings.svg",
      "DATABASE": "assets/icons/svg_colors/database.svg",
      "SECURITY": "assets/icons/svg_colors/security_hub.svg",
      "FILE MANAGER": "assets/icons/svg_colors/file_manager.svg",
      "BROWSER": "assets/icons/svg_colors/browser.svg",
      "CALENDAR": "assets/icons/svg_colors/calendar.svg",
      "CAMERA": "assets/icons/svg_colors/gallery.svg",
      "MEDIA PLAYER": "assets/icons/svg_colors/video.svg",
    };
    return icons[appName];
  }

  static IconData _getFallbackIcon(String appName) {
    switch (appName) {
      case "CALCULATOR": return Icons.calculate;
      case "NOTES": return Icons.note;
      case "TERMINAL": return Icons.terminal;
      case "WIFI": return Icons.wifi;
      case "EXPLOIT": return Icons.bug_report;
      case "PROCESS": return Icons.memory;
      case "FIREWALL": return Icons.security;
      case "ANALYTICS": return Icons.analytics;
      case "SYSTEM AI": return Icons.psychology;
      case "APP STORE": return Icons.store;
      case "MESSAGES": return Icons.message;
      case "PROFILE": return Icons.person;
      case "LOGS": return Icons.receipt_long;
      case "STORAGE": return Icons.storage;
      default: return Icons.apps;
    }
  }
}
