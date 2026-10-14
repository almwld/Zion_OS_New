import 'dart:async';

import 'package:flutter/material.dart';

/// A lightweight overlay notification styled as a compact toast bar.
/// It accepts SnackBar configuration for migration compatibility, but does
/// not enqueue or render a ScaffoldMessenger SnackBar.
class ToastBar {
  ToastBar._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(BuildContext context, SnackBar config) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final media = MediaQuery.maybeOf(context);
    final bottomInset = (media?.padding.bottom ?? 0) +
        (media?.viewInsets.bottom ?? 0) +
        16;
    final theme = Theme.of(context);
    final background = config.backgroundColor ?? theme.colorScheme.inverseSurface;
    final foreground = theme.colorScheme.onInverseSurface;
    final action = config.action;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: 16,
        right: 16,
        bottom: bottomInset,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 180),
                builder: (context, opacity, child) => Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, (1 - opacity) * 10),
                    child: child,
                  ),
                ),
                child: Material(
                  color: background,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: DefaultTextStyle.merge(
                            style: TextStyle(color: foreground),
                            child: IconTheme.merge(
                              data: IconThemeData(color: foreground, size: 20),
                              child: config.content,
                            ),
                          ),
                        ),
                        if (action != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: action.onPressed,
                            child: Text(
                              action.label,
                              style: TextStyle(
                                color: action.textColor ?? foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
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
    _timer = Timer(config.duration, () {
      if (identical(_entry, entry)) {
        entry.remove();
        _entry = null;
        _timer = null;
      }
    });
  }
}
