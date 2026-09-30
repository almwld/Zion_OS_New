import 'dart:async';
import 'agent_models.dart';
import 'orchestrator.dart';
import 'cancellation_token.dart';

class AgentSessionSnapshot {
  final String id;
  final String task;
  final AgentState state;
  final AgentPlan? plan;
  final List<StepResult> results;
  final DateTime updatedAt;
  final String? error;
  const AgentSessionSnapshot({required this.id,required this.task,required this.state,this.plan,this.results=const [],required this.updatedAt,this.error});
}

class AgentSession {
  final String id;
  final String task;
  AgentState state;
  AgentPlan? plan;
  final List<StepResult> results;
  final DateTime createdAt;
  DateTime updatedAt;
  String? error;

  AgentSession({
    required this.id,
    required this.task,
    this.state = AgentState.idle,
    this.plan,
    List<StepResult>? results,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.error,
  }) : results = results ?? <StepResult>[],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  void touch() => updatedAt = DateTime.now();
}

class AgentRuntime {
  final AgentOrchestrator orchestrator;
  CancellationToken? _token;
  AgentSession? _active;
  StreamSubscription<AgentEvent>? _subscription;
  final StreamController<AgentEvent> _events = StreamController<AgentEvent>.broadcast();

  AgentRuntime({AgentOrchestrator? orchestrator})
      : orchestrator = orchestrator ?? AgentOrchestrator();

  Stream<AgentEvent> get events => _events.stream;
  AgentSession? get activeSession => _active;
  bool get canCancel => _active != null && orchestrator.isRunning;
  AgentSessionSnapshot? get snapshot {
    final s = _active;
    if (s == null) return null;
    return AgentSessionSnapshot(id:s.id,task:s.task,state:s.state,plan:s.plan,results:List<StepResult>.unmodifiable(s.results),updatedAt:s.updatedAt,error:s.error);
  }

  Future<AgentResult> run(
    String task, {
    bool approveReviewed = false,
    Duration stepTimeout = AgentOrchestrator.defaultStepTimeout,
    int maxRecoveryAttempts = AgentOrchestrator.defaultMaxRecoveryAttempts,
  }) async {
    final clean = task.trim();
    if (clean.isEmpty) return AgentResult.error(clean, 'المهمة فارغة.');
    if (_active != null && orchestrator.isRunning) {
      return AgentResult.error(clean, 'هناك مهمة قيد التنفيذ.');
    }

    final session = AgentSession(
      id: 'agent-${DateTime.now().microsecondsSinceEpoch}',
      task: clean,
      state: AgentState.planning,
    );
    _active = session;
    final token = CancellationToken();
    _token = token;

    await _subscription?.cancel();
    _subscription = orchestrator.events.listen((event) {
      session.state = event.state;
      session.touch();
      _events.add(event);
    });

    try {
      final result = await orchestrator.executeTask(
        clean,
        approveReviewed: approveReviewed,
        cancellationToken: token,
        stepTimeout: stepTimeout,
        maxRecoveryAttempts: maxRecoveryAttempts,
      );
      session.state = result.success
          ? AgentState.completed
          : (token.isCancelled ? AgentState.cancelled : AgentState.failed);
      session.results
        ..clear()
        ..addAll(result.steps);
      session.error = result.error;
      session.touch();
      return result;
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      await token.dispose();
      if (identical(_token, token)) _token = null;
    }
  }

  bool get canApprove => _active != null && orchestrator.isWaitingForApproval;

  void approve() {
    if (!canApprove) return;
    orchestrator.approvePendingStep();
  }

  void deny() {
    if (!canApprove) return;
    orchestrator.denyPendingStep();
  }

  Future<void> cancel() async {
    final session = _active;
    if (session == null) return;
    _token?.cancel();
    session.state = AgentState.cancelled;
    session.touch();
    _events.add(AgentEvent(
      timestamp: DateTime.now(),
      message: 'تم إلغاء المهمة الحالية.',
      state: AgentState.cancelled,
    ));
  }

  void clearSession() {
    _active = null;
  }

  Future<void> dispose() async {
    _token?.cancel();
    await _subscription?.cancel();
    await _events.close();
    orchestrator.dispose();
  }
}
