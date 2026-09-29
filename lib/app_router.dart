import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'zion_desktop.dart';
import 'screens/lock_screen.dart';

/// Single root-level owner of the lock -> desktop UI lifecycle.
///
/// A successful unlock is retained for a short inactivity grace period so
/// leaving/reopening the app does not unexpectedly discard the current session.
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  static const _sessionKey = 'zion.authenticated_at';
  static const _sessionGrace = Duration(minutes: 15);

  bool _authenticated = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final stamp = prefs.getInt(_sessionKey);
    final valid = stamp != null &&
        DateTime.now().millisecondsSinceEpoch - stamp <=
            _sessionGrace.inMilliseconds;

    if (!mounted) return;
    setState(() {
      _authenticated = valid;
      _loaded = true;
    });

    if (!valid && stamp != null) {
      await prefs.remove(_sessionKey);
    }
  }

  Future<void> _onAuthenticated() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _sessionKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (!mounted || _authenticated) return;
    setState(() => _authenticated = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00BCD4),
            ),
          ),
        ),
      );
    }

    return _authenticated
        ? const DesktopHome()
        : LockScreen(onAuthenticated: _onAuthenticated);
  }
}
