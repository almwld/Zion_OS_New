import 'package:flutter/material.dart';

import 'screens/desktop_home.dart';
import 'screens/lock_screen.dart';

/// Single root-level owner of the lock -> desktop UI lifecycle.
///
/// The root widget is switched in-place after PIN verification instead of
/// pushing a second Navigator route. This prevents the lock screen and desktop
/// from competing for the same navigation stack.
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _authenticated = false;

  void _onAuthenticated() {
    if (!mounted || _authenticated) return;
    setState(() => _authenticated = true);
  }

  @override
  Widget build(BuildContext context) {
    return _authenticated
        ? const ZionDesktop()
        : LockScreen(onAuthenticated: _onAuthenticated);
  }
}
