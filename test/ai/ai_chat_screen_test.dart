import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_zion/ai/widgets/ai_chat_screen.dart';

const _aiChannel = MethodChannel('zion.os/ai');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_aiChannel, (call) async {
      switch (call.method) {
        case 'discoverModels':
          return <dynamic>[];
        case 'isLoaded':
          return false;
        case 'cancelGeneration':
          return false;
        case 'freeModel':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_aiChannel, null);
  });

  testWidgets('local AI exposes new chat and saved chat history', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AIChatScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Zion Offline AI'), findsOneWidget);
    expect(find.byTooltip('محادثة جديدة'), findsOneWidget);
    expect(find.byTooltip('المحادثات المحفوظة'), findsOneWidget);

    await tester.tap(find.byTooltip('محادثة جديدة'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('المحادثات المحفوظة'));
    await tester.pumpAndSettle();

    expect(find.text('المحادثات المحفوظة'), findsOneWidget);
    expect(find.text('محادثة جديدة'), findsWidgets);
  });
}
