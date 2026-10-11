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
    'reopening an app refreshes the rendered floating content',
    (tester) async {
      final manager = WindowManager();
      final key = GlobalKey<FloatingWindowManagerState>();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: FloatingWindowManager(
              key: key,
              windowManager: manager,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      key.currentState!.openWindow(
        'Notes',
        const Text('Old app content'),
        appKey: 'notes',
      );
      await tester.pump();
      expect(find.text('Old app content'), findsOneWidget);

      key.currentState!.openWindow(
        'Notes',
        const Text('Refreshed app content'),
        appKey: 'notes',
      );
      await tester.pump();

      expect(find.text('Old app content'), findsNothing);
      expect(find.text('Refreshed app content'), findsOneWidget);
      manager.dispose();
    },
  );

  testWidgets(
    'floating window lays out a real scaffold app without blank content',
    (tester) async {
      final key = GlobalKey<FloatingWindowManagerState>();
      await tester.binding.setSurfaceSize(const Size(800, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: FloatingWindowManager(
            key: key,
            child: const SizedBox.expand(),
          ),
        ),
      );

      key.currentState!.openWindow(
        'Settings',
        const Scaffold(
          appBar: AppBar(title: Text('Settings screen')),
          body: Center(child: Text('Settings content rendered')),
        ),
        appKey: 'settings',
        size: const Size(380, 520),
        position: const Offset(20, 80),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings screen'), findsOneWidget);
      expect(find.text('Settings content rendered'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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
