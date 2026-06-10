import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'zion_channel',
      'Zion Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    await _notifications.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details, payload: payload);
  }

  Future<void> showAttackNotification(String target, bool success) async {
    await showNotification(
      title: success ? '✅ Attack Successful' : '❌ Attack Failed',
      body: success ? 'Successfully compromised $target' : 'Failed to attack $target',
    );
  }

  Future<void> showDiscoveryNotification(String target) async {
    await showNotification(
      title: '🔍 New Target Discovered',
      body: 'Found device: $target',
    );
  }
}
