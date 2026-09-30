import 'dart:async';
import 'agent_models.dart';
import 'orchestrator.dart';

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
  AgentSession? _active;
  StreamSubscription<AgentEvent>? _subscription;
  final StreamController<AgentEvent> _events = StreamController<AgentEvent>.broadcast();

  AgentRuntime({AgentOrchestrator? orchestrator})
      : orchestrator = orchestrator ?? AgentOrchestrator();

  Stream<AgentEvent> get events => _events.stream;
  AgentSession? get activeSession => _active;

  Future<AgentResult> run(String task, {bool approveReviewed = false}) async {
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
      );
      session.state = result.success ? AgentState.completed : AgentState.failed;
      session.results
        ..clear()
        ..addAll(result.steps);
      session.error = result.error;
      session.touch();
      return result;
    } finally {
      await _subscription?.cancel();
      _subscription = null;
    }
  }

  Future<void> cancel() async {
    // Orchestrator currently runs cooperatively. This preserves the session
    // and exposes a deterministic cancellation state without killing a process.
    final session = _active;
    if (session == null) return;
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
    await _subscription?.cancel();
    await _events.close();
    orchestrator.dispose();
  }
}
