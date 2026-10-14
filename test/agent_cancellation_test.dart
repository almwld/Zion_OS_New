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

class SlowBrowserTool extends AgentTool {
  final Duration delay;
  SlowBrowserTool(this.delay);

  @override
  String get name => 'ai';

  @override
  String get description => 'Deterministic delayed test tool.';

  @override
  Map<String, dynamic> get parameters => const {};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async {
    await Future<void>.delayed(delay);
    return StepResult.success('slow tool completed');
  }
}

class NetworkBrowserTool extends AgentTool {
  Map<String, dynamic>? lastParams;

  @override
  String get name => 'browser';

  @override
  String get description => 'Deterministic read-only web permission test tool.';

  @override
  Map<String, dynamic> get parameters => const {};

  @override
  Set<AgentPermission> requiredPermissions(Map<String, dynamic> params) =>
      const {AgentPermission.network};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async {
    lastParams = Map<String, dynamic>.from(params);
    return StepResult.success('network tool completed');
  }
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

  test('read-only web retrieval respects the registered tool permission contract', () async {
    final browser = NetworkBrowserTool();
    final orchestrator = AgentOrchestrator(
      tools: ToolRegistry(customTools: [browser]),
      policy: const AgentPolicy(),
    );
    final future = orchestrator.executeTask('ابحث عن معلومات');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(orchestrator.state, AgentState.waitingApproval);
    orchestrator.approvePendingStep();
    final result = await future;
    expect(result.success, isTrue);
    expect(result.steps, hasLength(1));
    expect(result.steps.single.summary, 'network tool completed');
    expect(browser.lastParams?['action'], 'search');
    expect(browser.lastParams?['query'], 'معلومات');
    expect(orchestrator.state, AgentState.completed);
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
    orchestrator.dispose();
  });

  test('cancellation while waiting for approval releases the pending wait', () async {
    final token = CancellationToken();
    final orchestrator = AgentOrchestrator(
      tools: ToolRegistry(customTools: [ReviewTool()]),
      policy: ReviewPolicy(),
    );
    final future = orchestrator.executeTask(
      'حلل المهمة',
      cancellationToken: token,
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(orchestrator.state, AgentState.waitingApproval);
    token.cancel();
    final result = await future;
    expect(result.success, isFalse);
    expect(result.error, 'تم إلغاء المهمة.');
    expect(orchestrator.state, AgentState.cancelled);
    orchestrator.dispose();
    await token.dispose();
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
    final tools = ToolRegistry(customTools: [SlowBrowserTool(const Duration(milliseconds: 250))]);
    final orchestrator = AgentOrchestrator(
      tools: tools,
      policy: const AgentPolicy(),
    );
    final result = await orchestrator.executeTask(
      'حلل مهمة timeout test',
      stepTimeout: const Duration(milliseconds: 25),
    );
    expect(result.success, isFalse);
    expect(result.steps, isNotEmpty);
    expect(result.steps.first.success, isFalse);
    expect(result.steps.first.error, contains('انتهت مهلة الخطوة'));
    orchestrator.dispose();
  });

  test('AgentRuntime cancellation interrupts an active orchestration', () async {
    final tools = ToolRegistry(customTools: [SlowBrowserTool(const Duration(milliseconds: 500))]);
    final runtime = AgentRuntime(
      orchestrator: AgentOrchestrator(tools: tools),
    );

    final future = runtime.run(
      'حلل مهمة cancellation test',
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

