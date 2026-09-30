import 'package:flutter_test/flutter_test.dart';
import 'package:zion_os/agent/core/agent_runtime.dart';
import 'package:zion_os/agent/core/agent_models.dart';

void main() {
  test('AgentSession preserves task lifecycle metadata', () {
    final session = AgentSession(id: 'test-1', task: 'تحليل النظام');
    expect(session.state, AgentState.idle);
    expect(session.task, 'تحليل النظام');
    expect(session.results, isEmpty);
    final before = session.updatedAt;
    session.state = AgentState.executing;
    session.touch();
    expect(session.state, AgentState.executing);
    expect(session.updatedAt.isAtLeast(before), isTrue);
  });

  test('AgentRuntime exposes deterministic empty-task failure', () async {
    final runtime = AgentRuntime();
    final result = await runtime.run('   ');
    expect(result.success, isFalse);
    expect(result.error, 'المهمة فارغة.');
    await runtime.dispose();
  });
}

extension on DateTime {
  bool isAtLeast(DateTime other) => !isBefore(other);
}
