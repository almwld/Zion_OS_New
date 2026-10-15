import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/skills/agent_skill_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('skill catalog contains the six bundled workflow skills', () {
    expect(AgentSkillLibrary.definitions, hasLength(24));
    expect(
      AgentSkillLibrary.definitions.map((skill) => skill.name),
      containsAll([
        'systematic-debugging',
        'test-driven-development',
        'verification-before-completion',
        'writing-plans',
        'brainstorming',
        'executing-plans',
        'diagnosing-superpowers',
        'dispatching-parallel-agents',
        'finishing-a-development-branch',
        'receiving-code-review',
        'requesting-code-review',
        'subagent-driven-development',
        'using-git-worktrees',
        'using-superpowers',
        'writing-skills',
        'local-runtime-discovery',
        'linux-package-inventory',
        'pty-evidence-debugging',
        'flutter-ci-repair',
        'local-model-planning',
        'android-storage-inventory',
        'evidence-driven-recovery',
        'defensive-network-inventory',
        'git-safe-recovery',
      ]),
    );
  });

  test('ranking prioritizes debugging for build failures', () {
    final ranked = AgentSkillLibrary().rank('debug a flutter build failure');
    expect(ranked.first.name, 'systematic-debugging');
  });

  test('Arabic tasks rank Zion-native runtime skills', () {
    final ranked = AgentSkillLibrary().rank('استكشف كالي لينكس والروتفس المحلي');
    expect(ranked.first.name, 'local-runtime-discovery');
  });

  test('context loads a relevant bundled skill within configured budget', () async {
    final context = await AgentSkillLibrary().contextFor(
      'debug a build failure',
      maxSkills: 2,
      maxCharsPerSkill: 900,
      maxTotalChars: 2200,
    );
    expect(context, contains('systematic-debugging'));
    expect(context, contains('Relevant Agent Skills'));
    expect(context.length, lessThanOrEqualTo(2200));
    expect(context, isNot(contains('name: systematic-debugging')));
  });

  test('empty task yields no skill context', () async {
    expect(await AgentSkillLibrary().contextFor('   '), isEmpty);
  });
}
