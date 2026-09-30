import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_zion/features/window_manager/core/window_manager.dart';
import 'package:project_zion/features/window_manager/providers/window_provider.dart';
void main(){testWidgets('provider exposes manager', (tester) async {final m=WindowManager();await tester.pumpWidget(WindowManagerProvider(manager:m,child:Builder(builder:(context)=>Text('${context.watch<WindowManager>().windows.length}'))));expect(find.text('0'),findsOneWidget);});}