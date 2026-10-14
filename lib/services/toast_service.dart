import 'dart:async';

import 'package:flutter/material.dart';

enum ZionToastTone { info, success, warning, error }

/// App-wide floating toast bar. Unlike ScaffoldMessenger SnackBars, it does
/// not resize the scaffold, queue behind other messages, or block interaction.
class ToastService {
  ToastService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static OverlayEntry? _entry;
  static Timer? _timer;
  static int _sequence = 0;

  static void show(
    String message, {
    ZionToastTone tone = ZionToastTone.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null || message.trim().isEmpty) return;

    _timer?.cancel();
    _entry?.remove();
    _entry = null;
    final id = ++_sequence;
    final color = switch (tone) {
      ZionToastTone.success => const Color(0xFF16A34A),
      ZionToastTone.warning => const Color(0xFFD97706),
      ZionToastTone.error => const Color(0xFFDC2626),
      ZionToastTone.info => const Color(0xFF0D9488),
    };
    final icon = switch (tone) {
      ZionToastTone.success => Icons.check_circle_outline,
      ZionToastTone.warning => Icons.warning_amber_rounded,
      ZionToastTone.error => Icons.error_outline,
      ZionToastTone.info => Icons.info_outline,
    };

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: 28 + MediaQuery.viewInsetsOf(context).bottom,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xF21B252B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.8)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 21),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              message,
                              textDirection: Directionality.of(context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, () {
      if (_sequence != id) return;
      if (identical(_entry, entry)) {
        entry.remove();
        _entry = null;
      }
    });
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
    _sequence++;
  }
}
