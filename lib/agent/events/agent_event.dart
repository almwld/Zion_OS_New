import 'dart:collection';

/// أحداث تنفيذ قابلة للعرض للمستخدم؛ لا تحتوي على سلسلة التفكير الداخلية.
sealed class AgentEvent {
  final String taskId;
  final DateTime timestamp;
  final String summary;

  const AgentEvent({
    required this.taskId,
    required this.timestamp,
    required this.summary,
  });
}

class AnalysisEvent extends AgentEvent {
  final String userGoal;

  const AnalysisEvent({
    required super.taskId,
    required super.timestamp,
    required this.userGoal,
    required super.summary,
  });
}

class PlanEvent extends AgentEvent {
  final List<String> steps;

  PlanEvent({
    required super.taskId,
    required super.timestamp,
    required List<String> steps,
    required super.summary,
  }) : steps = List<String>.unmodifiable(steps);
}

class ToolCallEvent extends AgentEvent {
  final String toolName;
  final Map<String, dynamic> params;

  ToolCallEvent({
    required super.taskId,
    required super.timestamp,
    required this.toolName,
    required Map<String, dynamic> params,
    required super.summary,
  }) : params = UnmodifiableMapView<String, dynamic>(
          Map<String, dynamic>.from(params),
        );
}

class ObservationEvent extends AgentEvent {
  final String toolName;
  final bool success;
  final String resultPreview;

  ObservationEvent({
    required super.taskId,
    required super.timestamp,
    required this.toolName,
    required this.success,
    required String resultPreview,
    required super.summary,
  }) : resultPreview = resultPreview.length <= 200
            ? resultPreview
            : resultPreview.substring(0, 200);
}

class VerificationEvent extends AgentEvent {
  final bool passed;
  final String verifierName;
  final String details;

  const VerificationEvent({
    required super.taskId,
    required super.timestamp,
    required this.passed,
    required this.verifierName,
    required this.details,
    required super.summary,
  });
}

class ApprovalRequestEvent extends AgentEvent {
  final String action;
  final String risk;
  final String diff;

  const ApprovalRequestEvent({
    required super.taskId,
    required super.timestamp,
    required this.action,
    required this.risk,
    required this.diff,
    required super.summary,
  });
}

class CompletionEvent extends AgentEvent {
  final bool success;
  final String finalReport;

  const CompletionEvent({
    required super.taskId,
    required super.timestamp,
    required this.success,
    required this.finalReport,
    required super.summary,
  });
}

class ErrorEvent extends AgentEvent {
  final String errorType;
  final String errorMessage;

  const ErrorEvent({
    required super.taskId,
    required super.timestamp,
    required this.errorType,
    required this.errorMessage,
    required super.summary,
  });
}
