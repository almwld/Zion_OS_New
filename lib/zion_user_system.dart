import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

class ZionUser {
  final String username;
  final String passwordHash;
  final String role;
  final DateTime createdAt;
  final Map<String, dynamic> settings;

  ZionUser({
    required this.username,
    required this.passwordHash,
    this.role = 'user',
    DateTime? createdAt,
    Map<String, dynamic>? settings,
  })  : createdAt = createdAt ?? DateTime.now(),
        settings = settings ?? {
          'theme': 'matrix',
          'language': 'ar',
          'autolock': true,
        };

  bool verifyPassword(String password) {
    if (password.isEmpty || passwordHash.isEmpty) return false;
    final digest = sha256.convert(utf8.encode(password)).toString();
    return digest == passwordHash;
  }

  static String hashPassword(String password) {
    if (password.isEmpty) throw ArgumentError.value(password, 'password');
    return sha256.convert(utf8.encode(password)).toString();
  }
}

class ZionUserManager extends ChangeNotifier {
  final List<ZionUser> _users = [];

  ZionUser? _currentUser;
  bool _isLoggedIn = false;

  List<ZionUser> get users => List.unmodifiable(_users);
  ZionUser? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  bool login(String username, String password) {
    final user = _findUser(username);
    if (user != null && user.verifyPassword(password)) {
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

  bool addUser(String username, String password, {String role = 'user'}) {
    final normalized = username.trim();
    if (normalized.isEmpty || password.isEmpty || _findUser(normalized) != null) {
      return false;
    }
    _users.add(ZionUser(
      username: normalized,
      passwordHash: ZionUser.hashPassword(password),
      role: role,
    ));
    notifyListeners();
    return true;
  }

  void removeUser(String username) {
    _users.removeWhere((u) => u.username == username);
    if (_currentUser?.username == username) logout();
    notifyListeners();
  }

  void updateUserSetting(String key, dynamic value) {
    if (_currentUser != null) {
      _currentUser!.settings[key] = value;
      notifyListeners();
    }
  }

  ZionUser? _findUser(String username) {
    for (final user in _users) {
      if (user.username == username) return user;
    }
    return null;
  }
}
