import 'package:flutter/services.dart';

import 'alt_tab_manager.dart';
import 'window_manager.dart';

typedef KeyboardAction = void Function();

/// Central dispatcher for desktop-wide keyboard shortcuts.
class GlobalKeyboardManager {
  GlobalKeyboardManager({
    required this.windowManager,
    required this.altTabManager,
    required this.onWorkspaceChanged,
    required this.onAltTabChanged,
  });

  final WindowManager windowManager;
  final AltTabManager altTabManager;
  final void Function(int workspace) onWorkspaceChanged;
  final KeyboardAction onAltTabChanged;

  bool handle(KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;

    if (event.logicalKey == LogicalKeyboardKey.tab &&
        keyboard.isAltPressed &&
        (event is KeyDownEvent || event is KeyRepeatEvent)) {
      if (!altTabManager.isActive) {
        altTabManager.begin();
      }
      if (altTabManager.isActive) {
        altTabManager.cycle(reverse: keyboard.isShiftPressed);
        onAltTabChanged();
      }
      return true;
    }

    if (event is KeyDownEvent &&
        keyboard.isControlPressed &&
        keyboard.isAltPressed &&
        (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight)) {
      final delta =
          event.logicalKey == LogicalKeyboardKey.arrowLeft ? -1 : 1;
      final next = windowManager.activeWorkspace + delta;
      if (windowManager.switchWorkspace(next)) {
        onWorkspaceChanged(next);
      }
      return true;
    }

    if (event is KeyUpEvent &&
        (event.logicalKey == LogicalKeyboardKey.altLeft ||
            event.logicalKey == LogicalKeyboardKey.altRight ||
            event.logicalKey == LogicalKeyboardKey.alt)) {
      if (altTabManager.isActive) {
        altTabManager.end();
        onAltTabChanged();
      }
      return true;
    }

    return false;
  }

  void cancelAltTab() {
    if (!altTabManager.isActive) return;
    altTabManager.cancel();
    onAltTabChanged();
  }
}
