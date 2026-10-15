import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/ai/multi_agent_orchestrator.dart';

void main() {
  test('routes terminal tasks to the terminal specialist without executing them', () async {
    final results = await MultiAgentOrchestrator().analyze('نفّذ أمر bash لفحص النظام');
    final terminal = results.where((result) => result.role == AgentRole.terminal);
    expect(terminal, isNotEmpty);
    expect(terminal.first.risk, AgentRisk.review);
    expect(terminal.first.data['requiresRuntimeApproval'], isTrue);
    expect(terminal.first.summary, contains('لا ينفذ أوامر'));
  });

  test('reporter count matches the number of specialist results', () async {
    final results = await MultiAgentOrchestrator().analyze('حلل حالة النظام');
    final reporter = results.firstWhere((result) => result.role == AgentRole.reporter);
    expect(reporter.summary, contains('${results.length} وكلاء'));
  });
}
