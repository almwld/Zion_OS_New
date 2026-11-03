import 'agent_models.dart';
import 'role_profile.dart';

class RoleHandoff {
  RoleHandoff({
    required this.from,
    required this.to,
    required Map<String, dynamic> context,
    required this.reason,
    DateTime? createdAt,
  }) : context = Map<String, dynamic>.unmodifiable(context),
       createdAt = createdAt ?? DateTime.now();

  final RoleProfile from;
  final RoleProfile to;
  final Map<String, dynamic> context;
  final String reason;
  final DateTime createdAt;

  factory RoleHandoff.forPlan({
    required RoleProfile from,
    required RoleProfile to,
    required AgentPlan plan,
    required String reason,
  }) => RoleHandoff(
    from: from,
    to: to,
    reason: reason,
    context: {
      'task': plan.task,
      'stepCount': plan.steps.length,
      'steps': plan.steps.take(32).map((step) => {
        'id': step.id,
        'description': step.description,
        'tool': step.tool,
        'permission': step.permission.name,
        'requiresApproval': step.requiresApproval,
      }).toList(growable: false),
    },
  );

  factory RoleHandoff.forStep({
    required RoleProfile from,
    required RoleProfile to,
    required AgentStep step,
    required StepResult result,
    required String reason,
  }) => RoleHandoff(
    from: from,
    to: to,
    reason: reason,
    context: {
      'stepId': step.id,
      'description': step.description,
      'tool': step.tool,
      'success': result.success,
      'summary': result.summary,
      if (result.error != null) 'error': result.error,
      'durationMs': result.duration.inMilliseconds,
    },
  );
}
