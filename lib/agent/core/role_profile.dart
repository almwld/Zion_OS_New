import 'agent_models.dart';

enum AgentRole { planner, researcher, analyst, coder, executor, verifier, reporter }

class RoleProfile {
  const RoleProfile({
    required this.role,
    required this.name,
    required this.systemPrompt,
    required this.allowedTools,
    required this.maxSteps,
    this.canModifyFiles = false,
    this.requiresEvidence = true,
  });
  final AgentRole role;
  final String name;
  final String systemPrompt;
  final Set<String> allowedTools;
  final int maxSteps;
  final bool canModifyFiles;
  final bool requiresEvidence;

  bool allowsTool(String tool) {
    if (allowedTools.contains('*') || allowedTools.contains(tool)) return true;
    final name = tool.toLowerCase();
    if (role == AgentRole.researcher) {
      return name == 'browser' || name == 'http' ||
          (name.startsWith('github_') &&
              !RegExp(r'(create|update|write|delete|commit|merge)').hasMatch(name));
    }
    if (role == AgentRole.coder) {
      return name == 'file' || name == 'terminal_run' ||
          (name.startsWith('github_') &&
              RegExp(r'(create|update|write|commit)').hasMatch(name));
    }
    if (role == AgentRole.verifier) {
      return name == 'terminal_run' || name == 'file' ||
          (name.startsWith('github_') &&
              RegExp(r'(get|list|check|status|read|fetch)').hasMatch(name));
    }
    return false;
  }

  static const Map<AgentRole, RoleProfile> defaults = {
    AgentRole.planner: RoleProfile(role: AgentRole.planner, name: 'Planner', systemPrompt: 'حلل الهدف وقسّمه إلى خطوات قابلة للتحقق. لا تنفذ ولا تدّعِ نتائج.', allowedTools: {}, maxSteps: 5),
    AgentRole.researcher: RoleProfile(role: AgentRole.researcher, name: 'Researcher', systemPrompt: 'اجمع الأدلة من أدوات القراءة فقط، وميّز الحقائق عن الافتراضات.', allowedTools: {'browser', 'http', 'github_'}, maxSteps: 8),
    AgentRole.analyst: RoleProfile(role: AgentRole.analyst, name: 'Analyst', systemPrompt: 'حلل النتائج الفعلية وحدد السبب والقيود دون تعديل الملفات.', allowedTools: {'ai', 'data', 'file'}, maxSteps: 5),
    AgentRole.coder: RoleProfile(role: AgentRole.coder, name: 'Coder', systemPrompt: 'اقترح تعديلات محددة متسقة مع السياق. لا تنفذ أي كتابة دون موافقة الأدوات.', allowedTools: {'file', 'terminal_run', 'shell', 'run_command', 'terminal_workflow', 'github_'}, maxSteps: 10, canModifyFiles: true),
    AgentRole.executor: RoleProfile(role: AgentRole.executor, name: 'Executor', systemPrompt: 'نفّذ الخطوات المعتمدة فقط عبر الأدوات المسجلة وسياسات الموافقة.', allowedTools: {'*'}, maxSteps: 32, canModifyFiles: true),
    AgentRole.verifier: RoleProfile(role: AgentRole.verifier, name: 'Verifier', systemPrompt: 'تحقق من النتائج عبر أدلة التنفيذ. لا تعدّل الملفات ولا تفترض النجاح.', allowedTools: {'terminal_run', 'file', 'github_checks', 'github_build_status'}, maxSteps: 8),
    AgentRole.reporter: RoleProfile(role: AgentRole.reporter, name: 'Reporter', systemPrompt: 'اكتب تقريراً موجزاً يفرق بين ما نُفذ وما تم التحقق منه وما بقي.', allowedTools: {}, maxSteps: 2),
  };

  static RoleProfile forRole(AgentRole role) => defaults[role]!;
  static RoleProfile forStep(AgentStep step) {
    final tool = step.tool.toLowerCase();
    if (step.permission == AgentPermission.localWrite ||
        step.permission == AgentPermission.externalSideEffect ||
        RegExp(r'(create|update|write|commit|delete)').hasMatch(tool)) {
      return forRole(AgentRole.coder);
    }
    if (tool.startsWith('github_') || tool == 'browser' || tool == 'http') {
      return forRole(AgentRole.researcher);
    }
    if (tool == 'ai' || tool == 'data') return forRole(AgentRole.analyst);
    if (tool == 'terminal_run' ||
        tool == 'shell' ||
        tool == 'run_command' ||
        tool == 'terminal_workflow' ||
        tool == 'file' ||
        tool == 'python') {
      return forRole(AgentRole.executor);
    }
    return forRole(AgentRole.analyst);
  }
}
