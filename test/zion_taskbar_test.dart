import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_zion/features/window_manager/core/window_manager.dart';
import 'package:project_zion/zion_taskbar.dart';

void main() {
  testWidgets('desktop taskbar uses a single compact row with named workspaces', (tester) async {
    final manager = WindowManager();
    await tester.pumpWidget(
      ChangeNotifierProvider<WindowManager>.value(
        value: manager,
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          home: const Scaffold(
            body: SizedBox.expand(),
            bottomNavigationBar: ZionTaskbar(
              categories: [
                {'nameAr': 'النظام', 'icon': Icons.settings},
                {'nameAr': 'الأدوات', 'icon': Icons.build},
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('النظام'), findsOneWidget);
    expect(find.text('الأدوات'), findsOneWidget);
    expect(find.text('مساحة 1'), findsOneWidget);
    expect(find.text('مساحة 4'), findsOneWidget);
    expect(find.text('W1'), findsNothing);
    expect(find.text('W4'), findsNothing);

    final taskbar = tester.widget<ZionTaskbar>(find.byType(ZionTaskbar));
    expect(taskbar.categories, hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
    manager.dispose();
  });
}
