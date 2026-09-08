/// Native notifications are intentionally disabled for the initial build.
/// The public API is kept as a no-op so existing callers remain compatible.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {}

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  Future<void> showBatteryAlert(int level) async {}
}
