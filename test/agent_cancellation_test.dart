import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/agent/core/agent_models.dart';
import 'package:project_zion/agent/core/agent_runtime.dart';
import 'package:project_zion/agent/core/agent_policy.dart';
import 'package:project_zion/agent/core/cancellation_token.dart';
import 'package:project_zion/agent/core/orchestrator.dart';
import 'package:project_zion/agent/tools/tool.dart';
import 'package:project_zion/agent/tools/tool_registry.dart';

class ReviewTool extends AgentTool {
  @override
  String get name => 'ai';

  @override
  String get description => 'Deterministic approval test tool.';

  @override
  Map<String, dynamic> get parameters => const {};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async =>
      StepResult.success('approved tool completed');
}

class ReviewPolicy extends AgentPolicy {
  @override
  AgentPolicyDecision evaluate({
    required String tool,
    required Map<String, dynamic> params,
  }) => const AgentPolicyDecision(
        risk: AgentRisk.review,
        reason: 'approval test',
        requiresApproval: true,
      );
}

class SlowHttpTool extends AgentTool {
  final Duration delay;
  SlowHttpTool(this.delay);

  @override
  String get name => 'http';

  @override
  String get description => 'Deterministic slow HTTP test tool.';

  @override
  Map<String, dynamic> get parameters => const {};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async {
    await Future<void>.delayed(delay);
    return StepResult.success('slow tool completed');
  }
}

class NetworkHttpTool extends AgentTool {
  @override
  String get name => 'http';

  @override
  String get description => 'Deterministic network permission test tool.';

  @override
  Map<String, dynamic> get parameters => const {};

  @override
  Set<AgentPermission> requiredPermissions(Map<String, dynamic> params) =>
      const {AgentPermission.network};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async =>
      StepResult.success('network tool completed');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Orchestrator pauses for approval and resumes after approval', () async {
    final orchestrator = AgentOrchestrator(
      tools: ToolRegistry(customTools: [ReviewTool()]),
      policy: ReviewPolicy(),
    );
    final future = orchestrator.executeTask('حلل المهمة');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(orchestrator.state, AgentState.waitingApproval);
    expect(orchestrator.isWaitingForApproval, isTrue);
    orchestrator.approvePendingStep();
    final result = await future;
    expect(result.success, isTrue);
    expect(orchestrator.state, AgentState.completed);
    orchestrator.dispose();
  });

  test('Tool-declared network permission requires approval even for a read-only plan', () async {
    final orchestrator = AgentOrchestrator(
      tools: ToolRegistry(customTools: [NetworkHttpTool()]),
      policy: const AgentPolicy(),
    );
    final future = orchestrator.executeTask('ابحث عن معلومات');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(orchestrator.state, AgentState.waitingApproval);
    expect(orchestrator.isWaitingForApproval, isTrue);
    orchestrator.denyPendingStep();
    final result = await future;
    expect(result.success, isFalse);
    expect(result.error, contains('تم رفض تنفيذ الخطوة'));
    orchestrator.dispose();
  });

  test('Global approval override cannot bypass per-step confirmation', () async {
    final orchestrator = AgentOrchestrator(
      tools: ToolRegistry(customTools: [ReviewTool()]),
      policy: ReviewPolicy(),
    );
    final future = orchestrator.executeTask('حلل المهمة', approveReviewed: true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(orchestrator.state, AgentState.waitingApproval);
    orchestrator.denyPendingStep();
    final result = await future;
    expect(result.success, isFalse);
    expect(result.error, contains('تم رفض تنفيذ الخطوة'));
    await orchestrator.dispose();
  });

  test('Orchestrator denies a pending reviewed step', () async {
    final orchestrator = AgentOrchestrator(
      tools: ToolRegistry(customTools: [ReviewTool()]),
      policy: ReviewPolicy(),
    );
    final future = orchestrator.executeTask('حلل المهمة');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(orchestrator.isWaitingForApproval, isTrue);
    orchestrator.denyPendingStep();
    final result = await future;
    expect(result.success, isFalse);
    expect(result.error, contains('تم رفض تنفيذ الخطوة'));
    expect(orchestrator.state, AgentState.failed);
    orchestrator.dispose();
  });

  test('CancellationToken is idempotent and observable', () async {
    final token = CancellationToken();
    var events = 0;
    final sub = token.onCancel.listen((_) => events++);
    expect(token.isCancelled, isFalse);
    token.cancel();
    token.cancel();
    expect(token.isCancelled, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(events, 1);
    await sub.cancel();
    await token.dispose();
  });

  test('AgentRuntime rejects empty task without creating a session', () async {
    final runtime = AgentRuntime();
    final result = await runtime.run('   ');
    expect(result.success, isFalse);
    expect(runtime.activeSession, isNull);
    await runtime.dispose();
  });

  test('AgentRuntime exposes a cancellable active session', () async {
    final runtime = AgentRuntime();
    expect(runtime.canCancel, isFalse);
    await runtime.dispose();
  });

  test('Orchestrator preserves cancelled state when token is already cancelled', () async {
    final token = CancellationToken()..cancel();
    final orchestrator = AgentOrchestrator();
    final result = await orchestrator.executeTask(
      'حلل المهمة',
      cancellationToken: token,
    );
    expect(result.success, isFalse);
    expect(result.error, 'تم إلغاء المهمة.');
    expect(orchestrator.state, AgentState.cancelled);
    orchestrator.dispose();
    await token.dispose();
  });

  test('Orchestrator enforces the central step timeout', () async {
    final tools = ToolRegistry(customTools: [SlowHttpTool(const Duration(milliseconds: 250))]);
    final orchestrator = AgentOrchestrator(
      tools: tools,
      policy: const AgentPolicy(),
    );
    final result = await orchestrator.executeTask(
      'search timeout test',
      stepTimeout: const Duration(milliseconds: 25),
    );
    expect(result.success, isFalse);
    expect(result.steps, isNotEmpty);
    expect(result.steps.first.success, isFalse);
    expect(result.steps.first.error, contains('انتهت مهلة الخطوة'));
    orchestrator.dispose();
  });

  test('AgentRuntime cancellation interrupts an active orchestration', () async {
    final tools = ToolRegistry(customTools: [SlowHttpTool(const Duration(milliseconds: 500))]);
    final runtime = AgentRuntime(
      orchestrator: AgentOrchestrator(tools: tools),
    );

    final future = runtime.run(
      'search cancellation test',
      stepTimeout: const Duration(seconds: 2),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(runtime.canCancel, isTrue);
    await runtime.cancel();

    final result = await future;
    expect(result.success, isFalse);
    expect(result.error, 'تم إلغاء المهمة.');
    expect(runtime.activeSession?.state, AgentState.cancelled);
    await runtime.dispose();
  });
}

