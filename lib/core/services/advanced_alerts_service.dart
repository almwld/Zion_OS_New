import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent application alerts. Alerts are created only by real callers;
/// this service does not manufacture periodic "system checks".
class AdvancedAlertsService extends ChangeNotifier {
  static final AdvancedAlertsService _instance = AdvancedAlertsService._internal();
  factory AdvancedAlertsService() => _instance;
  AdvancedAlertsService._internal();

  List<Map<String, dynamic>> _alerts = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _notifications = <Map<String, dynamic>>[];

  Future<void> init() async {
    await _loadAlerts();
    await _loadNotifications();
  }

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('advanced_alerts');
    if (value == null) return;
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        _alerts = decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {
      _alerts = <Map<String, dynamic>>[];
    }
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('notifications');
    if (value == null) return;
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        _notifications = decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {
      _notifications = <Map<String, dynamic>>[];
    }
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('advanced_alerts', jsonEncode(_alerts));
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', jsonEncode(_notifications));
  }

  Future<void> addCustomAlert(String title, String message, String severity) async {
    _alerts.insert(0, _newItem(title, message, severity));
    if (_alerts.length > 100) _alerts = _alerts.sublist(0, 100);
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> addNotification(String title, String message, String type) async {
    _notifications.insert(0, _newItem(title, message, type));
    if (_notifications.length > 200) _notifications = _notifications.sublist(0, 200);
    await _saveNotifications();
    notifyListeners();
  }

  Map<String, dynamic> _newItem(String title, String message, String type) => <String, dynamic>{
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'title': title,
        'message': message,
        'severity': type,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      };

  Future<void> markAlertAsRead(String id) async {
    final index = _alerts.indexWhere((item) => item['id'] == id);
    if (index < 0) return;
    _alerts[index]['read'] = true;
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> markAllAlertsRead() async {
    for (final alert in _alerts) {
      alert['read'] = true;
    }
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> clearAlerts() async {
    _alerts.clear();
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> deleteAlert(String id) async {
    _alerts.removeWhere((item) => item['id'] == id);
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item['id'] == id);
    if (index < 0) return;
    _notifications[index]['read'] = true;
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    for (final notification in _notifications) {
      notification['read'] = true;
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((item) => item['id'] == id);
    await _saveNotifications();
    notifyListeners();
  }

  List<Map<String, dynamic>> getAlerts({bool unreadOnly = false}) => unreadOnly
      ? _alerts.where((item) => item['read'] != true).map(Map<String, dynamic>.from).toList()
      : _alerts.map(Map<String, dynamic>.from).toList();

  List<Map<String, dynamic>> getNotifications({bool unreadOnly = false}) => unreadOnly
      ? _notifications.where((item) => item['read'] != true).map(Map<String, dynamic>.from).toList()
      : _notifications.map(Map<String, dynamic>.from).toList();

  int getUnreadAlertsCount() => _alerts.where((item) => item['read'] != true).length;
  int getUnreadNotificationsCount() => _notifications.where((item) => item['read'] != true).length;
}
