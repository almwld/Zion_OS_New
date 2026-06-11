import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconMapper {
  static Widget getIcon(String appName, {double size = 28}) {
    final iconPath = _getIconPath(appName);
    if (iconPath != null) {
      return SvgPicture.asset(
        iconPath,
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
    }
    return Icon(_getFallbackIcon(appName), size: size, color: const Color(0xFF00BCD4));
  }

  static String? _getIconPath(String appName) {
    switch (appName) {
      case "TERMINAL":
        return "assets/icons/svg_colors/terminal.svg";
      case "NETWORK":
      case "NETWORK SCANNER":
        return "assets/icons/svg_colors/network.svg";
      case "WIFI":
        return "assets/icons/svg_colors/wifi.svg";
      case "CRYPTO":
        return "assets/icons/svg_colors/crypto.svg";
      case "STEALTH":
        return "assets/icons/svg_colors/stealth.svg";
      case "CRACKER":
      case "PASSWORD CRACKER":
        return "assets/icons/svg_colors/cracker.svg";
      case "DDOS":
        return "assets/icons/svg_colors/ddos.svg";
      case "DATABASE":
        return "assets/icons/svg_colors/database.svg";
      case "CLOUD":
        return "assets/icons/svg_colors/cloud.svg";
      case "NETWORK TOOLS":
        return "assets/icons/svg_colors/network_tools.svg";
      case "FORENSICS":
        return "assets/icons/svg_colors/forensics.svg";
      case "TEXT ANALYZER":
        return "assets/icons/svg_colors/text_analyzer.svg";
      case "SETTINGS":
        return "assets/icons/svg_colors/settings.svg";
      case "FILE MANAGER":
        return "assets/icons/svg_colors/file_manager.svg";
      case "BROWSER":
        return "assets/icons/svg_colors/browser.svg";
      case "WEATHER":
        return "assets/icons/svg_colors/weather.svg";
      case "CURRENCY":
        return "assets/icons/svg_colors/currency.svg";
      case "TRANSLATOR":
        return "assets/icons/svg_colors/translator.svg";
      case "MAPS":
        return "assets/icons/svg_colors/maps.svg";
      case "RADIO":
        return "assets/icons/svg_colors/radio.svg";
      case "SHARE":
        return "assets/icons/svg_colors/share.svg";
      case "EMAIL":
        return "assets/icons/svg_colors/email.svg";
      case "NOTES":
        return "assets/icons/svg_colors/notes.svg";
      case "CLOCK":
      case "ALARMS & CLOCK":
        return "assets/icons/svg_colors/alarm.svg";
      case "CALCULATOR":
        return "assets/icons/svg_colors/calculator.svg";
      // أيقونات جديدة
      case "BACKUP":
      case "BACKUP MANAGER":
        return "assets/icons/svg_colors/backup.svg";
      case "CLEANER":
        return "assets/icons/svg_colors/cleaner.svg";
      case "APP LOCK":
        return "assets/icons/svg_colors/app_lock.svg";
      case "NOTIFY":
      case "NOTIFICATION MANAGER":
        return "assets/icons/svg_colors/notify.svg";
      case "GALLERY":
        return "assets/icons/svg_colors/gallery.svg";
      case "VIDEO":
      case "VIDEO PLAYER":
        return "assets/icons/svg_colors/video.svg";
      case "CALENDAR":
        return "assets/icons/svg_colors/calendar.svg";
      case "QR CODE":
      case "QR SCANNER":
        return "assets/icons/svg_colors/qr.svg";
      case "DOCUMENTS":
        return "assets/icons/svg_colors/documents.svg";
      case "BATTERY":
      case "BATTERY SAVER":
        return "assets/icons/svg_colors/battery.svg";
      default:
        return null;
    }
  }

  static IconData _getFallbackIcon(String appName) {
    switch (appName) {
      case "TERMINAL":
        return Icons.terminal;
      case "NETWORK SCANNER":
        return Icons.network_wifi;
      case "WIFI":
        return Icons.wifi;
      case "CRYPTO":
        return Icons.lock;
      case "STEALTH":
        return Icons.visibility_off;
      case "CRACKER":
        return Icons.vpn_key;
      case "DDOS":
        return Icons.speed;
      case "DATABASE":
        return Icons.storage;
      case "CLOUD":
        return Icons.cloud;
      case "FORENSICS":
        return Icons.search;
      case "TEXT ANALYZER":
        return Icons.analytics;
      case "SETTINGS":
        return Icons.settings;
      case "FILE MANAGER":
        return Icons.folder;
      case "BROWSER":
        return Icons.public;
      case "WEATHER":
        return Icons.wb_sunny;
      case "CURRENCY":
        return Icons.attach_money;
      case "TRANSLATOR":
        return Icons.translate;
      case "MAPS":
        return Icons.map;
      case "RADIO":
        return Icons.radio;
      case "SHARE":
        return Icons.share;
      case "EMAIL":
        return Icons.email;
      case "NOTES":
        return Icons.note;
      case "CLOCK":
        return Icons.access_time;
      case "CALCULATOR":
        return Icons.calculate;
      case "BACKUP":
        return Icons.backup;
      case "CLEANER":
        return Icons.cleaning_services;
      case "APP LOCK":
        return Icons.lock;
      case "NOTIFY":
        return Icons.notifications;
      case "GALLERY":
        return Icons.photo_library;
      case "VIDEO":
        return Icons.play_circle_filled;
      case "CALENDAR":
        return Icons.calendar_today;
      case "QR CODE":
        return Icons.qr_code_scanner;
      case "DOCUMENTS":
        return Icons.description;
      case "BATTERY":
        return Icons.battery_charging_full;
      default:
        return Icons.apps;
    }
  }
}
