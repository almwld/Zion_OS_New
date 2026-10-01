import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/widgets/window_compositor.dart';

void main() {
  testWidgets('compositor renders content and uses repaint boundary', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: WindowCompositor(child: Text('Zion Window')),
    ));
    expect(find.text('Zion Window'), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('Zion Window'), findsOneWidget);
  });
}
