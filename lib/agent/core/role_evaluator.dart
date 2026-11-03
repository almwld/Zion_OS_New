import 'agent_models.dart';
import 'role_profile.dart';

class RoleEvaluation {
  const RoleEvaluation({
    required this.accepted,
    required this.score,
    required this.feedback,
    this.requiresRetry = false,
  });
  final bool accepted;
  final int score;
  final String feedback;
  final bool requiresRetry;
}

class RoleEvaluator {
  const RoleEvaluator();

  RoleEvaluation evaluatePlan(AgentPlan plan, {required int maxSteps}) {
    if (plan.task.trim().isEmpty) {
      return const RoleEvaluation(accepted: false, score: 0, feedback: 'الخطة لا تحتوي على هدف واضح.');
    }
    if (plan.steps.isEmpty || plan.steps.length > maxSteps) {
      return RoleEvaluation(accepted: false, score: 0, feedback: 'عدد الخطوات يجب أن يكون بين 1 و$maxSteps.');
    }
    final ids = <String>{};
    for (final step in plan.steps) {
      if (step.id.trim().isEmpty || !ids.add(step.id) || step.description.trim().isEmpty || step.tool.trim().isEmpty) {
        return const RoleEvaluation(accepted: false, score: 0, feedback: 'تحتوي الخطة على خطوة ناقصة أو معرف مكرر.');
      }
    }
    return const RoleEvaluation(accepted: true, score: 100, feedback: 'بنية الخطة صالحة؛ صلاحيات الأدوات ستُفحص وقت التنفيذ.');
  }

  RoleEvaluation evaluateStep({
    required RoleProfile role,
    required AgentStep step,
    required StepResult result,
  }) {
    if (!role.allowsTool(step.tool)) {
      return RoleEvaluation(accepted: false, score: 0, feedback: 'الأداة ' + step.tool + ' خارج صلاحيات دور ' + role.name + '.');
    }
    if (!result.success) {
      return RoleEvaluation(accepted: false, score: 0, feedback: result.error ?? result.summary, requiresRetry: true);
    }
    if (role.requiresEvidence && result.summary.trim().isEmpty && result.data == null) {
      return const RoleEvaluation(accepted: false, score: 20, feedback: 'نجاح الأداة دون مخرجات قابلة للفحص لا يكفي لإثبات النتيجة.', requiresRetry: true);
    }
    return const RoleEvaluation(accepted: true, score: 100, feedback: 'اجتازت الخطوة فحص الدور؛ هذا لا يتجاوز تحقق الأداة وسياساتها.');
  }
}
