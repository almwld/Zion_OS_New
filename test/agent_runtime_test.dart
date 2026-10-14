import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/core/agent_runtime.dart';
import 'package:project_zion/agent/core/agent_models.dart';
import 'package:project_zion/agent/core/orchestrator.dart';
import 'package:project_zion/agent/tools/tool_registry.dart';
import 'package:project_zion/agent/tools/tool.dart';
import 'package:project_zion/ai/llama_service.dart';

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
  test('AgentRuntime exposes a cancellable busy state before async setup finishes', () async {
    final runtime = AgentRuntime(
      orchestrator: AgentOrchestrator(
        tools: ToolRegistry(customTools: [_BlockingAiTool()]),
        ai: LlamaService(),
      ),
    );
    final pending = runtime.run('حلل هذه المهمة');
    expect(runtime.canCancel, isTrue);
    await runtime.cancel();
    final result = await pending;
    expect(result.success, isFalse);
    expect(runtime.canCancel, isFalse);
    await runtime.dispose();
  });
}

class _BlockingAiTool extends AgentTool {
  @override
  String get name => 'ai';
  @override
  String get description => 'أداة اختبار بطيئة';
  @override
  Map<String, dynamic> get parameters => const {'prompt': 'string'};
  @override
  Future<StepResult> execute(Map<String, dynamic> params) => Completer<StepResult>().future;
}

extension on DateTime {
  bool isAtLeast(DateTime other) => !isBefore(other);
}
