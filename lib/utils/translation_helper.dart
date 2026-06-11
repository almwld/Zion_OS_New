import 'package:easy_localization/easy_localization.dart';

class TranslationHelper {
  static String getAppName(String appKey) {
    // تحويل اسم التطبيق الإنجليزي إلى مفتاح الترجمة
    switch (appKey) {
      case "TERMINAL": return "apps.terminal".tr();
      case "NETWORK": return "apps.network_scanner".tr();
      case "WIFI": return "apps.wifi_scanner".tr();
      case "EXPLOIT": return "apps.exploit_db".tr();
      case "CRYPTO": return "apps.crypto_tool".tr();
      case "STEALTH": return "apps.stealth_mode".tr();
      case "CRACKER": return "apps.password_cracker".tr();
      case "DDOS": return "apps.ddos_attack".tr();
      case "DATABASE": return "apps.database_hacking".tr();
      case "CLOUD": return "apps.cloud_attacks".tr();
      case "SETTINGS": return "apps.settings".tr();
      case "FILE MANAGER": return "apps.file_manager".tr();
      case "BROWSER": return "apps.web_browser".tr();
      case "TEXT ANALYZER": return "apps.text_analyzer".tr();
      case "CALCULATOR": return "apps.calculator".tr();
      case "NOTES": return "apps.notes".tr();
      case "WEATHER": return "apps.weather".tr();
      case "CURRENCY": return "apps.currency_converter".tr();
      case "TRANSLATOR": return "apps.translator".tr();
      case "MAPS": return "apps.maps".tr();
      case "RADIO": return "apps.radio".tr();
      case "SHARE": return "apps.file_sharing".tr();
      case "EMAIL": return "apps.email".tr();
      case "DATE CALC": return "apps.date_calculator".tr();
      case "UNIT CONV": return "apps.unit_converter".tr();
      case "PERCENT": return "apps.percentage_calculator".tr();
      case "BATTERY": return "apps.battery_saver".tr();
      case "BACKUP": return "apps.backup_manager".tr();
      case "CLEANER": return "apps.cleaner".tr();
      case "APP LOCK": return "apps.app_lock".tr();
      case "NOTIFY": return "apps.notification_manager".tr();
      case "GALLERY": return "apps.gallery".tr();
      case "VIDEO": return "apps.video_player".tr();
      case "CLOCK": return "apps.alarms_clock".tr();
      case "CALENDAR": return "apps.calendar".tr();
      case "QR CODE": return "apps.qr_scanner".tr();
      case "DOCUMENTS": return "apps.documents".tr();
      case "SECURITY HUB": return "apps.security_hub".tr();
      case "TOOLS HUB": return "apps.tools_hub".tr();
      case "PERF HUB": return "apps.performance_hub".tr();
      case "DATA HUB": return "apps.data_hub".tr();
      case "NET HUB": return "apps.network_hub".tr();
      case "PRIV HUB": return "apps.privacy_hub".tr();
      case "AUTO HUB": return "apps.automation_hub".tr();
      default: return appKey;
    }
  }
}
