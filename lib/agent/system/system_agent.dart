import '../core/agent_models.dart';
import '../core/agent_runtime.dart';

enum SystemAgentKind { system, performance, network, security }

class SystemAgentDefinition {
  final SystemAgentKind kind;
  final String id;
  final String name;
  final String description;
  final String action;
  const SystemAgentDefinition(this.kind, this.id, this.name, this.description, this.action);
}

class SystemAgentRegistry {
  static const definitions = <SystemAgentDefinition>[
    SystemAgentDefinition(SystemAgentKind.system, 'system', 'System Agent', 'تشخيص حالة نظام Zion OS محلياً.', 'summary'),
    SystemAgentDefinition(SystemAgentKind.performance, 'performance', 'Performance Agent', 'فحص مؤشرات الذاكرة والمعالج لأغراض التشخيص.', 'memory'),
    SystemAgentDefinition(SystemAgentKind.network, 'network', 'Network Agent', 'عرض واجهات الشبكة المحلية دون فحص أهداف خارجية.', 'network'),
    SystemAgentDefinition(SystemAgentKind.security, 'security', 'Security Agent', 'مراجعة دفاعية لحالة النظام دون استغلال أو تجاوز حماية.', 'summary'),
  ];

  static SystemAgentDefinition? byId(String id) {
    for (final definition in definitions) {
      if (definition.id == id) return definition;
    }
    return null;
  }
}

class SystemAgentCoordinator {
  final AgentRuntime runtime;
  SystemAgentCoordinator({AgentRuntime? runtime}) : runtime = runtime ?? AgentRuntime();

  AgentPlan planFor(String agentId) {
    final definition = SystemAgentRegistry.byId(agentId);
    if (definition == null) return const AgentPlan(task: 'غير معروف', steps: []);
    return AgentPlan(task: definition.name, steps: [
      AgentStep(
        id: '${definition.id}-1',
        description: definition.description,
        tool: 'system_info',
        params: {'action': definition.action},
        requiresEvaluation: true,
      ),
    ]);
  }

  void dispose() => runtime.dispose();
}
