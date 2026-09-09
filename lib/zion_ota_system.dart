import 'package:flutter/foundation.dart';

class OTAUpdate {
  final String version;
  final int buildNumber;
  final String description;
  final int size;
  final bool isCritical;

  const OTAUpdate({
    required this.version,
    required this.buildNumber,
    required this.description,
    required this.size,
    this.isCritical = false,
  });
}

/// OTA coordinator with an honest state model.
///
/// The APK cannot invent an update or pretend to install one. A real OTA
/// backend/update manifest must be configured before check/download/install can
/// report success. This keeps the UI truthful until the AOSP OTA pipeline is
/// connected.
class ZionOTASystem extends ChangeNotifier {
  OTAUpdate? _availableUpdate;
  bool _isChecking = false;
  bool _isDownloading = false;
  bool _isInstalling = false;
  int _downloadProgress = 0;
  int _installProgress = 0;
  String? _error;

  OTAUpdate? get availableUpdate => _availableUpdate;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  bool get isInstalling => _isInstalling;
  int get downloadProgress => _downloadProgress;
  int get installProgress => _installProgress;
  String? get error => _error;
  bool get isConfigured => false;

  Future<OTAUpdate?> checkForUpdates() async {
    _isChecking = true;
    _error = null;
    notifyListeners();
    try {
      _availableUpdate = null;
      _error = 'خدمة تحديث Zion OS غير مهيأة: يلزم مصدر OTA موثوق ومانيفست موقّع.';
      return null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> downloadUpdate() async {
    if (_availableUpdate == null) {
      _error = 'لا يوجد تحديث موثوق متاح للتنزيل.';
      notifyListeners();
      return;
    }
    _error = 'تنزيل OTA غير متاح قبل ربط خدمة التحديث الموثوقة.';
    notifyListeners();
  }

  Future<void> installUpdate() async {
    _error = 'تثبيت OTA غير متاح من داخل APK عادي. يلزم مسار AOSP/Recovery أو آلية تحديث نظام موثوقة.';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
