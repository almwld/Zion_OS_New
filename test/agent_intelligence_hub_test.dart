import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/core/agent_models.dart';
import 'package:project_zion/agent/ui/agent_intelligence_hub.dart';

void main() {
  testWidgets('intelligence hub renders overthinker and telemetry views', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AgentIntelligenceHub(
        events: [
          AgentEvent(timestamp: DateTime(2026, 10, 15), message: 'بدأ التخطيط', state: AgentState.planning),
          AgentEvent(timestamp: DateTime(2026, 10, 15, 0, 1), message: 'تم التحقق', state: AgentState.evaluating),
        ],
        task: 'تحقق من حالة النظام',
        result: AgentResult(
          success: true,
          task: 'تحقق من حالة النظام',
          steps: [StepResult.success('اكتملت خطوة التحقق', duration: const Duration(milliseconds: 125))],
          report: 'تم التحقق',
        ),
        overthinkerEnabled: true,
      ),
    ));
    await tester.pump();

    expect(find.text('Agent Intelligence Lab'), findsOneWidget);
    expect(find.textContaining('Overthinker'), findsWidgets);
    expect(find.text('خريطة الشبكة العصبية التشغيلية'), findsOneWidget);
    expect(find.text('الوكلاء الفرعيون المتخصصون'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('تصدير تقرير الجلسة إلى Obsidian'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('تصدير تقرير الجلسة إلى Obsidian'), findsOneWidget);
  });
}
