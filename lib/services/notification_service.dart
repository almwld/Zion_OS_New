import '../core/services/notification_service.dart' as core;

/// Compatibility wrapper. Use core.NotificationService for new code.
///
/// @deprecated Migrate callers to core.NotificationService, which is backed by
/// the real local NotificationDaemon.
@Deprecated('Use core.NotificationService instead.')
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final core.NotificationService _delegate = core.NotificationService();

  Future<void> init() => _delegate.init();

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    _delegate.addNotification(
      title: title,
      message: body,
      type: core.NotificationType.info,
    );
  }

  Future<void> showBatteryAlert(int level) async {
    _delegate.addNotification(
      title: 'Battery alert',
      message: 'Battery level: $level%',
      type: core.NotificationType.warning,
    );
  }
}
