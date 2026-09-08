import 'package:flutter/foundation.dart';

/// Native notifications are intentionally disabled for the initial build.
/// The public API is preserved so existing callers remain source-compatible.
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {}

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {}

  Future<void> showAttackNotification(String target, bool success) async {}

  Future<void> showDiscoveryNotification(String target) async {}
}
