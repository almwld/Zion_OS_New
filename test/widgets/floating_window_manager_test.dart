import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/features/window_manager/core/window_manager.dart';
import 'package:project_zion/widgets/floating_window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'reopening an app synchronizes native and floating workspaces',
    (tester) async {
      final manager = WindowManager();
      final key = GlobalKey<FloatingWindowManagerState>();
      final nativeId = manager.open(
        title: 'Notes',
        content: const SizedBox(),
        workspace: 0,
        appKey: 'notes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FloatingWindowManager(
            key: key,
            windowManager: manager,
            child: const SizedBox.expand(),
          ),
        ),
      );

      key.currentState!.openWindow(
        'Notes',
        const SizedBox(),
        appKey: 'notes',
        windowId: nativeId,
      );
      await tester.pump();

      key.currentState!.switchWorkspace(1);
      await tester.pump();
      expect(manager.activeWorkspace, 1);

      // Reproduce the split-brain state: the native manager's idempotent
      // open path moves the existing window to the active workspace before
      // the floating layer gets a chance to restore its remembered workspace.
      manager.open(
        title: 'Notes',
        content: const SizedBox(),
        workspace: 1,
        appKey: 'notes',
      );
      expect(manager.find(nativeId)?.workspace, 1);

      key.currentState!.openWindow(
        'Notes',
        const SizedBox(),
        appKey: 'notes',
      );
      await tester.pump();

      expect(manager.activeWorkspace, 0);
      expect(key.currentState!.activeWorkspace, 0);
      expect(manager.find(nativeId)?.workspace, 0);
      expect(
        key.currentState!.widget.windowManager!.windows
            .where((window) => window.appKey == 'notes'),
        hasLength(1),
      );
    },
  );
}
