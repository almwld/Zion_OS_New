import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType { info, success, warning, error, system, security, update }

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  List<Map<String, dynamic>> _notifications = [];
  
  Future<void> init() async {
    await _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString('notifications');
    if (notificationsJson != null && notificationsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = List.from(jsonDecode(notificationsJson));
        _notifications = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }
  }
  
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', jsonEncode(_notifications));
  }
  
  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    Duration? autoDismiss,
  }) {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    };
    _notifications.insert(0, notification);
    if (_notifications.length > 100) _notifications = _notifications.sublist(0, 100);
    _saveNotifications();
    notifyListeners();
    
    if (autoDismiss != null) {
      Future.delayed(autoDismiss, () {
        _notifications.removeWhere((n) => n['id'] == notification['id']);
        _saveNotifications();
        notifyListeners();
      });
    }
  }
  
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['read'] = true;
      _saveNotifications();
      notifyListeners();
    }
  }
  
  void markAllAsRead() {
    for (var n in _notifications) n['read'] = true;
    _saveNotifications();
    notifyListeners();
  }
  
  void clearAll() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }
  
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n['id'] == id);
    _saveNotifications();
    notifyListeners();
  }
  
  List<Map<String, dynamic>> getNotifications({bool unreadOnly = false}) {
    if (unreadOnly) return _notifications.where((n) => !n['read']).toList();
    return List.from(_notifications);
  }
  
  int getUnreadCount() => _notifications.where((n) => !n['read']).length;
  
  Color getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.info: return const Color(0xFF00BCD4);
      case NotificationType.success: return Colors.green;
      case NotificationType.warning: return Colors.orange;
      case NotificationType.error: return Colors.red;
      case NotificationType.system: return Colors.purple;
      case NotificationType.security: return Colors.amber;
      case NotificationType.update: return Colors.blue;
    }
  }
  
  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info: return Icons.info_outline;
      case NotificationType.success: return Icons.check_circle_outline;
      case NotificationType.warning: return Icons.warning_amber_outlined;
      case NotificationType.error: return Icons.error_outline;
      case NotificationType.system: return Icons.computer;
      case NotificationType.security: return Icons.security;
      case NotificationType.update: return Icons.system_update;
    }
  }
}

// Helper functions
String jsonEncode(List<Map<String, dynamic>> data) {
  return data.toString();
}
List<Map<String, dynamic>> jsonDecode(String data) {
  return [];
}
