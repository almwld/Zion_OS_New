import 'package:flutter/material.dart';

class ZionUser {
  final String username;
  final String passwordHash;
  final String role; // admin, user, guest
  final DateTime createdAt;
  final Map<String, dynamic> settings;

  ZionUser({
    required this.username,
    required this.passwordHash,
    this.role = 'user',
    DateTime? createdAt,
    Map<String, dynamic>? settings,
  })  : createdAt = createdAt ?? DateTime.now(),
        settings = settings ?? {'theme': 'matrix', 'language': 'ar', 'autolock': true};

  bool verifyPassword(String password) {
    // محاكاة التحقق من كلمة المرور
    return password == 'zion' || password == 'root' || password == 'admin' || password == username;
  }
}

class ZionUserManager extends ChangeNotifier {
  final List<ZionUser> _users = [
    ZionUser(username: 'root', passwordHash: 'hash_root', role: 'admin'),
    ZionUser(username: 'zion', passwordHash: 'hash_zion', role: 'admin'),
    ZionUser(username: 'guest', passwordHash: 'hash_guest', role: 'guest'),
  ];

  ZionUser? _currentUser;
  bool _isLoggedIn = false;

  List<ZionUser> get users => _users;
  ZionUser? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  bool login(String username, String password) {
    final user = _users.firstWhere((u) => u.username == username, orElse: () => ZionUser(username: '', passwordHash: ''));
    if (user.username.isNotEmpty && user.verifyPassword(password)) {
      _currentUser = user;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void addUser(String username, String password, {String role = 'user'}) {
    if (_users.any((u) => u.username == username)) return;
    _users.add(ZionUser(username: username, passwordHash: 'hash_$username', role: role));
    notifyListeners();
  }

  void removeUser(String username) {
    _users.removeWhere((u) => u.username == username);
    notifyListeners();
  }

  void updateUserSetting(String key, dynamic value) {
    if (_currentUser != null) {
      _currentUser!.settings[key] = value;
      notifyListeners();
    }
  }
}
