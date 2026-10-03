import '../../../core/services/notification_service.dart' as core;

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

  Future<void> initialize() => _delegate.init();

  Future<void> showNotification({
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

  Future<void> showAttackNotification(String target, bool success) async {
    _delegate.addNotification(
      title: 'Attack notification',
      message: '${target} — ${success ? 'completed' : 'failed'}',
      type: success ? core.NotificationType.success : core.NotificationType.error,
    );
  }

  Future<void> showDiscoveryNotification(String target) async {
    _delegate.addNotification(
      title: 'Discovery',
      message: target,
      type: core.NotificationType.info,
    );
  }
}
