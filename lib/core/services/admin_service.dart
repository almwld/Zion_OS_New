import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService extends ChangeNotifier {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _permissions = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _systemLogs = <Map<String, dynamic>>[];
  bool _maintenanceMode = false;

  Future<void> init() async {
    await _loadUsers();
    await _loadPermissions();
    await _loadSystemLogs();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('admin_users');
    if (value != null) _users = _decodeList(value);
    if (_users.isEmpty) {
      _users = <Map<String, dynamic>>[
        {'id': '1', 'username': 'admin', 'role': 'Administrator', 'permissions': 'full', 'active': true},
        {'id': '2', 'username': 'operator', 'role': 'Operator', 'permissions': 'limited', 'active': true},
        {'id': '3', 'username': 'viewer', 'role': 'Viewer', 'permissions': 'readonly', 'active': false},
      ];
      await _saveUsers();
    }
  }

  Future<void> _loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('admin_permissions');
    if (value != null) _permissions = _decodeList(value);
    if (_permissions.isEmpty) {
      _permissions = <Map<String, dynamic>>[
        {'id': '1', 'name': 'Full Access', 'level': 100, 'description': 'Complete system access'},
        {'id': '2', 'name': 'Limited Access', 'level': 50, 'description': 'Limited functionality access'},
        {'id': '3', 'name': 'Read Only', 'level': 10, 'description': 'View only access'},
      ];
      await _savePermissions();
    }
  }

  Future<void> _loadSystemLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('system_logs');
    if (value != null) _systemLogs = _decodeList(value);
  }

  List<Map<String, dynamic>> _decodeList(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_users', jsonEncode(_users));
  }

  Future<void> _savePermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_permissions', jsonEncode(_permissions));
  }

  Future<void> _saveSystemLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('system_logs', jsonEncode(_systemLogs));
  }

  Future<void> addSystemLog(String action, String user, String details) async {
    _systemLogs.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'action': action,
      'user': user,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (_systemLogs.length > 500) _systemLogs = _systemLogs.sublist(0, 500);
    await _saveSystemLogs();
    notifyListeners();
  }

  Future<void> addUser(String username, String role, String permissions, bool active) async {
    _users.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'username': username,
      'role': role,
      'permissions': permissions,
      'active': active,
    });
    await _saveUsers();
    await addSystemLog('User Added', 'admin', 'Added user: $username');
  }

  Future<void> updateUser(String id, bool active) async {
    final index = _users.indexWhere((u) => u['id'] == id);
    if (index == -1) return;
    _users[index]['active'] = active;
    await _saveUsers();
    await addSystemLog('User Updated', 'admin', 'Updated user: ${_users[index]['username']}');
  }

  Future<void> deleteUser(String id) async {
    final index = _users.indexWhere((u) => u['id'] == id);
    if (index == -1) return;
    final user = _users[index];
    _users.removeAt(index);
    await _saveUsers();
    await addSystemLog('User Deleted', 'admin', 'Deleted user: ${user['username']}');
  }

  Future<void> setMaintenanceMode(bool enabled) async {
    _maintenanceMode = enabled;
    await addSystemLog('Maintenance Mode', 'admin', enabled ? 'Enabled' : 'Disabled');
  }

  Future<void> clearSystemLogs() async {
    _systemLogs.clear();
    await _saveSystemLogs();
    notifyListeners();
  }

  List<Map<String, dynamic>> getUsers() => List<Map<String, dynamic>>.from(_users);
  List<Map<String, dynamic>> getPermissions() => List<Map<String, dynamic>>.from(_permissions);
  List<Map<String, dynamic>> getSystemLogs({int? limit}) => limit == null ? List<Map<String, dynamic>>.from(_systemLogs) : _systemLogs.take(limit).toList();
  bool get maintenanceMode => _maintenanceMode;

  Map<String, dynamic> getSystemStats() => {
    'total_users': _users.length,
    'active_users': _users.where((u) => u['active'] == true).length,
    'total_logs': _systemLogs.length,
    'maintenance_mode': _maintenanceMode,
  };
}
