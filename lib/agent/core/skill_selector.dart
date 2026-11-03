import '../skills/agent_skill_library.dart';
import '../skills/agent_knowledge_index.dart';
import 'role_profile.dart';

class SelectedSkills {
  const SelectedSkills({
    required this.role,
    required this.skillContext,
    required this.knowledgeContext,
  });
  final AgentRole role;
  final String skillContext;
  final String knowledgeContext;
}

class SkillSelector {
  SkillSelector({
    AgentSkillLibrary? skills,
    AgentKnowledgeIndex? knowledge,
  }) : _skills = skills ?? AgentSkillLibrary(),
       _knowledge = knowledge ?? AgentKnowledgeIndex();

  final AgentSkillLibrary _skills;
  final AgentKnowledgeIndex _knowledge;

  Future<SelectedSkills> select({
    required RoleProfile role,
    required String task,
    Iterable<String> hints = const [],
    int maxChars = 1000,
  }) async {
    final query = '$task ${hints.join(' ')} ${role.name}';
    final skillContext = await _skills.contextFor(
      query,
      hints: [role.name, role.systemPrompt, ...hints],
      maxSkills: role.role == AgentRole.planner ? 3 : 2,
      maxCharsPerSkill: 360,
      maxTotalChars: (maxChars * 0.7).floor(),
    );
    final knowledgeContext = await _knowledge.contextFor(
      query,
      maxEntries: 2,
      maxTotalChars: (maxChars * 0.3).floor(),
    );
    return SelectedSkills(role: role.role, skillContext: skillContext, knowledgeContext: knowledgeContext);
  }
}
