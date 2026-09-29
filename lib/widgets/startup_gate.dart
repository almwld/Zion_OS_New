import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../adaptive/adaptive_interface.dart';
import '../app_router.dart';

/// Shows the branded startup screen only once per 12-hour window.
/// The lock/desktop session remains owned by AppRouter.
class ZionStartupGate extends StatefulWidget {
  const ZionStartupGate({super.key});

  @override
  State<ZionStartupGate> createState() => _ZionStartupGateState();
}

class _ZionStartupGateState extends State<ZionStartupGate>
    with SingleTickerProviderStateMixin {
  static const _lastSplashKey = 'zion.last_splash_at';
  static const _interval = Duration(hours: 12);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _decide();
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_lastSplashKey);
    final now = DateTime.now().millisecondsSinceEpoch;
    final shouldShow = raw == null ||
        now - raw >= _interval.inMilliseconds;

    if (!shouldShow) {
      if (mounted) setState(() => _showSplash = false);
      return;
    }

    await prefs.setInt(_lastSplashKey, now);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) {
      return const AdaptiveInterface(child: AppRouter());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BCD4).withOpacity(0.42),
                      blurRadius: 34,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Z',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 58,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ZION OS',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SECURE • FAST • PERSISTENT',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00BCD4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
