import 'package:flutter/material.dart';

class ZionToast {
  ZionToast._();

  static void show(
    BuildContext context,
    String message, {
    Color? accent,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    final color = accent ?? const Color(0xFF00BCD4);
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 20,
        right: 20,
        bottom: 28,
        child: _ToastCard(
          message: message,
          accent: color,
          onDismiss: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(duration, () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _ToastCard extends StatelessWidget {
  final String message;
  final Color accent;
  final VoidCallback onDismiss;

  const _ToastCard({
    required this.message,
    required this.accent,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xE60A0E1A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.45)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: accent, size: 19),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, color: Colors.white54, size: 17),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
