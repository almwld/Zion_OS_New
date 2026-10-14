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
  testWidgets('saved user prompts can be copied and edited back into the composer', (tester) async {
    SharedPreferences.setMockInitialValues({
      'zion_offline_ai_sessions_v1': '[{"id":"saved-1","title":"سؤال محفوظ","updatedAt":"2026-10-14T00:00:00.000","messages":[{"role":"user","content":"اشرح الطرفية"},{"role":"assistant","content":"الطرفية تنفذ الأوامر."}]}]',
      'zion_offline_ai_active_session_v1': 'saved-1',
    });

    await tester.pumpWidget(const MaterialApp(home: AIChatScreen()));
    await tester.pumpAndSettle();

    expect(find.text('اشرح الطرفية'), findsOneWidget);
    expect(find.text('الطرفية تنفذ الأوامر.'), findsOneWidget);
    expect(find.byTooltip('نسخ النص'), findsNWidgets(2));
    await tester.tap(find.byTooltip('تعديل وإعادة إرسال المدخل'));
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.controller!.text, 'اشرح الطرفية');
  });

}
