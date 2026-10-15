import 'package:flutter/services.dart';

/// Loads bundled Agent Skills as bounded prompt context. Skill files are
/// documentation only; they are never executed and cannot grant permissions.
class AgentSkillDefinition {
  final String name;
  final String asset;
  final String description;
  final List<String> keywords;

  const AgentSkillDefinition({
    required this.name,
    required this.asset,
    required this.description,
    required this.keywords,
  });
}

class AgentSkillLibrary {
  AgentSkillLibrary({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const List<AgentSkillDefinition> definitions = [
    AgentSkillDefinition(
      name: 'systematic-debugging',
      asset: 'assets/agent_skills/systematic-debugging.md',
      description: 'Evidence-first root-cause investigation and repair.',
      keywords: ['bug', 'debug', 'error', 'failure', 'crash', 'broken', 'diagnos', 'timeout', 'exception', 'build'],
    ),
    AgentSkillDefinition(
      name: 'test-driven-development',
      asset: 'assets/agent_skills/test-driven-development.md',
      description: 'Test-first feature implementation and regression coverage.',
      keywords: ['test', 'regression', 'feature', 'implement', 'fix', 'refactor', 'assertion'],
    ),
    AgentSkillDefinition(
      name: 'verification-before-completion',
      asset: 'assets/agent_skills/verification-before-completion.md',
      description: 'Verify claims with fresh test and build evidence.',
      keywords: ['verify', 'verification', 'complete', 'finish', 'release', 'ci', 'apk', 'success', 'device'],
    ),
    AgentSkillDefinition(
      name: 'writing-plans',
      asset: 'assets/agent_skills/writing-plans.md',
      description: 'Break complex requests into executable, verifiable steps.',
      keywords: ['plan', 'multi-step', 'architecture', 'design', 'task', 'workflow', 'roadmap'],
    ),
    AgentSkillDefinition(
      name: 'brainstorming',
      asset: 'assets/agent_skills/brainstorming.md',
      description: 'Compare designs and clarify constraints before large changes.',
      keywords: ['brainstorm', 'design', 'approach', 'options', 'architecture', 'new system'],
    ),
    AgentSkillDefinition(
      name: 'executing-plans',
      asset: 'assets/agent_skills/executing-plans.md',
      description: 'Execute incrementally with observed outputs and model-led recovery.',
      keywords: ['execute', 'execution', 'recover', 'retry', 'terminal', 'shell', 'runtime', 'kali', 'userland', 'rootfs'],
    ),
  ];

  List<AgentSkillDefinition> rank(String task) {
    final normalized = task.toLowerCase();
    final ranked = definitions.map((skill) {
      var score = 0;
      for (final keyword in skill.keywords) {
        if (normalized.contains(keyword)) score += keyword.contains(' ') ? 3 : 2;
      }
      return (skill: skill, score: score);
    }).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return definitions.indexOf(a.skill).compareTo(definitions.indexOf(b.skill));
      });

    final relevant = ranked.where((entry) => entry.score > 0).map((entry) => entry.skill).toList();
    if (relevant.isNotEmpty) return relevant;
    return ranked.take(3).map((entry) => entry.skill).toList();
  }

  Future<String> contextFor(
    String task, {
    int maxSkills = 3,
    int maxCharsPerSkill = 2400,
    int maxTotalChars = 6000,
  }) async {
    if (task.trim().isEmpty || maxSkills < 1 || maxCharsPerSkill < 1 || maxTotalChars < 1) {
      return '';
    }

    final output = StringBuffer(
      'Relevant Agent Skills (guidance only; actual tool outputs and runtime policy are authoritative):\n',
    );
    var added = 0;
    for (final skill in rank(task).take(maxSkills)) {
      String source;
      try {
        source = await _bundle.loadString(skill.asset);
      } catch (_) {
        continue;
      }
      source = source.replaceFirst(RegExp(r'^---\s*[\s\S]*?---\s*'), '').trim();
      if (source.isEmpty) continue;
      if (source.length > maxCharsPerSkill) {
        final cut = source.lastIndexOf('\n', maxCharsPerSkill);
        source = source.substring(0, cut > 0 ? cut : maxCharsPerSkill) +
            '\n[Skill excerpt shortened to fit the local model context.]';
      }
      final section = '\n### ${skill.name}: ${skill.description}\n$source\n';
      if (output.length + section.length > maxTotalChars) break;
      output.write(section);
      added++;
    }
    return added == 0 ? '' : output.toString();
  }
}
