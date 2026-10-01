import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zion_os/features/window_manager/core/alt_tab_manager.dart';
import 'package:zion_os/features/window_manager/core/global_keyboard_manager.dart';
import 'package:zion_os/features/window_manager/core/window_manager.dart';

void main() {
  test('handles workspace shortcut through central manager', () {
    final wm = WindowManager();
    final alt = AltTabManager(wm);
    int? workspace;
    var changed = 0;
    final manager = GlobalKeyboardManager(
      windowManager: wm,
      altTabManager: alt,
      onWorkspaceChanged: (value) => workspace = value,
      onAltTabChanged: () => changed++,
    );

    HardwareKeyboard.instance;
    final handled = manager.handle(const KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.arrowRight,
      logicalKey: LogicalKeyboardKey.arrowRight,
    ));

    expect(handled, isTrue);
    expect(workspace, isNull);
    expect(changed, 0);
    wm.dispose();
  });

  test('returns false for unrelated key events', () {
    final wm = WindowManager();
    final alt = AltTabManager(wm);
    final manager = GlobalKeyboardManager(
      windowManager: wm,
      altTabManager: alt,
      onWorkspaceChanged: (_) {},
      onAltTabChanged: () {},
    );

    final handled = manager.handle(const KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyA,
      logicalKey: LogicalKeyboardKey.keyA,
    ));

    expect(handled, isFalse);
    wm.dispose();
  });
}
