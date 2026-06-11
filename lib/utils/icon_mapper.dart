import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconMapper {
  static Widget getIcon(String appName, {double size = 28}) {
    final iconPath = _getSvgPath(appName);
    if (iconPath != null) {
      return SvgPicture.asset(
        iconPath,
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(Color(0xFF00BCD4), BlendMode.srcIn),
      );
    }
    return Icon(_getMaterialIcon(appName), size: size, color: const Color(0xFF00BCD4));
  }

  static String? _getSvgPath(String appName) {
    switch (appName) {
      case "TERMINAL": return "assets/icons/svg_colors/terminal.svg";
      case "NETWORK": return "assets/icons/svg_colors/network.svg";
      case "WIFI": return "assets/icons/svg_colors/wifi.svg";
      case "CRYPTO": return "assets/icons/svg_colors/crypto.svg";
      case "STEALTH": return "assets/icons/svg_colors/stealth.svg";
      case "CRACKER": return "assets/icons/svg_colors/cracker.svg";
      case "DDOS": return "assets/icons/svg_colors/ddos.svg";
      case "DATABASE": return "assets/icons/svg_colors/database.svg";
      case "CLOUD": return "assets/icons/svg_colors/cloud.svg";
      case "FORENSICS": return "assets/icons/svg_colors/forensics.svg";
      case "TEXT ANALYZER": return "assets/icons/svg_colors/text_analyzer.svg";
      case "SETTINGS": return "assets/icons/svg_colors/settings.svg";
      case "FILE MANAGER": return "assets/icons/svg_colors/file_manager.svg";
      case "BROWSER": return "assets/icons/svg_colors/browser.svg";
      case "WEATHER": return "assets/icons/svg_colors/weather.svg";
      case "CURRENCY": return "assets/icons/svg_colors/currency.svg";
      case "TRANSLATOR": return "assets/icons/svg_colors/translator.svg";
      case "MAPS": return "assets/icons/svg_colors/maps.svg";
      case "RADIO": return "assets/icons/svg_colors/radio.svg";
      case "SHARE": return "assets/icons/svg_colors/share.svg";
      case "EMAIL": return "assets/icons/svg_colors/email.svg";
      case "NOTES": return "assets/icons/svg_colors/notes.svg";
      case "CLOCK": return "assets/icons/svg_colors/alarm.svg";
      case "CALCULATOR": return "assets/icons/svg_colors/calculator.svg";
      case "BATTERY": return "assets/icons/svg_colors/battery.svg";
      default: return null;
    }
  }

  static IconData _getMaterialIcon(String appName) {
    switch (appName) {
      case "SECURITY HUB": return Icons.security;
      case "TOOLS HUB": return Icons.build;
      case "PERF HUB": return Icons.speed;
      case "DATA HUB": return Icons.storage;
      case "NET HUB": return Icons.network_check;
      case "PRIV HUB": return Icons.privacy_tip;
      case "AUTO HUB": return Icons.settings_applications;
      case "ROOT TERM": return Icons.terminal;
      default: return Icons.apps;
    }
  }
}

  // أيقونات Bath Style (الحمام/الاستحمام)
  static Widget getBathIcon(String appName, {double size = 28}) {
    String? path;
    switch (appName) {
      case "TERMINAL": path = "assets/icons/bath/terminal.svg"; break;
      case "NETWORK": path = "assets/icons/bath/network.svg"; break;
      case "WIFI": path = "assets/icons/bath/wifi.svg"; break;
      case "SECURITY": path = "assets/icons/bath/shield.svg"; break;
      case "CRYPTO": path = "assets/icons/bath/lock.svg"; break;
      case "DDOS": path = "assets/icons/bath/speed.svg"; break;
      case "DATABASE": path = "assets/icons/bath/database.svg"; break;
      case "CLOUD": path = "assets/icons/bath/cloud.svg"; break;
      case "FORENSICS": path = "assets/icons/bath/search.svg"; break;
      case "SETTINGS": path = "assets/icons/bath/settings.svg"; break;
      default: return null;
    }
    if (path != null) {
      return SvgPicture.asset(path, width: size, height: size);
    }
    return null;
  }
