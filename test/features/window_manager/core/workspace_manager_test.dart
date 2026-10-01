import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/features/window_manager/core/window_manager.dart';

void main() {
  test('workspace switch isolates visible windows and restores focus', () {
    final wm = WindowManager();
    final w0 = wm.open(title: 'W0', content: const SizedBox());
    final w1 = wm.open(title: 'W1', content: const SizedBox());
    wm.focus(w0);
    expect(wm.activeWorkspace, 0);
    expect(wm.activeWindowId, w0);

    expect(wm.switchWorkspace(1), isTrue);
    expect(wm.activeWorkspace, 1);
    expect(wm.visibleWindows, isEmpty);

    final w2 = wm.open(title: 'W2', content: const SizedBox(), workspace: 1);
    expect(wm.activeWindowId, w2);
    expect(wm.visibleWindows.map((w) => w.id), [w2]);

    expect(wm.switchWorkspace(0), isTrue);
    expect(wm.activeWorkspace, 0);
    expect(wm.activeWindowId, w0);
    expect(wm.visibleWindows.map((w) => w.id), containsAll([w0, w1]));
  });

  test('moving a window between workspaces updates ownership', () {
    final wm = WindowManager();
    final id = wm.open(title: 'Movable', content: const SizedBox());
    expect(wm.moveToWorkspace(id, 2), isTrue);
    expect(wm.find(id)?.workspace, 2);
    expect(wm.visibleWindows, isEmpty);
    expect(wm.switchWorkspace(2), isTrue);
    expect(wm.visibleWindows.map((w) => w.id), [id]);
    expect(wm.activeWindowId, id);
  });

  test('windows opened in another workspace do not steal active focus', () {
    final wm = WindowManager();
    final current = wm.open(title: 'Current', content: const SizedBox());
    final other = wm.open(title: 'Other', content: const SizedBox(), workspace: 3);
    expect(wm.activeWorkspace, 0);
    expect(wm.activeWindowId, current);
    expect(wm.visibleWindows.map((w) => w.id), [current]);
    expect(wm.find(other)?.workspace, 3);
  });
}
