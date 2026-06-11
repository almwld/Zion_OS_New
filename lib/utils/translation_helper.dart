import 'package:easy_localization/easy_localization.dart';

class TranslationHelper {
  static String getAppName(String appKey) {
    final key = _getTranslationKey(appKey);
    return key.tr();
  }

  static String _getTranslationKey(String appName) {
    switch (appName) {
      case "TERMINAL": return "apps.terminal";
      case "NETWORK": return "apps.network_scanner";
      case "WIFI": return "apps.wifi_scanner";
      case "EXPLOIT": return "apps.exploit_db";
      case "CRYPTO": return "apps.crypto_tool";
      case "STEALTH": return "apps.stealth_mode";
      case "CRACKER": return "apps.password_cracker";
      case "DDOS": return "apps.ddos_attack";
      case "DATABASE": return "apps.database_hacking";
      case "CLOUD": return "apps.cloud_attacks";
      case "SETTINGS": return "apps.settings";
      case "FILE MANAGER": return "apps.file_manager";
      case "BROWSER": return "apps.web_browser";
      case "TEXT ANALYZER": return "apps.text_analyzer";
      case "CALCULATOR": return "apps.calculator";
      case "NOTES": return "apps.notes";
      case "WEATHER": return "apps.weather";
      case "CURRENCY": return "apps.currency_converter";
      case "TRANSLATOR": return "apps.translator";
      case "MAPS": return "apps.maps";
      case "RADIO": return "apps.radio";
      case "SHARE": return "apps.file_sharing";
      case "EMAIL": return "apps.email";
      case "DATE CALC": return "apps.date_calculator";
      case "UNIT CONV": return "apps.unit_converter";
      case "PERCENT": return "apps.percentage_calculator";
      case "BATTERY": return "apps.battery_saver";
      case "BACKUP": return "apps.backup_manager";
      case "CLEANER": return "apps.cleaner";
      case "APP LOCK": return "apps.app_lock";
      case "NOTIFY": return "apps.notification_manager";
      case "GALLERY": return "apps.gallery";
      case "VIDEO": return "apps.video_player";
      case "CLOCK": return "apps.alarms_clock";
      case "CALENDAR": return "apps.calendar";
      case "QR CODE": return "apps.qr_scanner";
      case "DOCUMENTS": return "apps.documents";
      case "SECURITY HUB": return "apps.security_hub";
      case "TOOLS HUB": return "apps.tools_hub";
      case "PERF HUB": return "apps.performance_hub";
      case "DATA HUB": return "apps.data_hub";
      case "NET HUB": return "apps.network_hub";
      case "PRIV HUB": return "apps.privacy_hub";
      case "AUTO HUB": return "apps.automation_hub";
      case "ROOT TERM": return "apps.root_terminal";
      default: return appName;
    }
  }
}
