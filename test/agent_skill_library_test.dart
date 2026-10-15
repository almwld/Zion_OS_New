import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/skills/agent_skill_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('skill catalog contains the six bundled workflow skills', () {
    expect(AgentSkillLibrary.definitions, hasLength(6));
    expect(
      AgentSkillLibrary.definitions.map((skill) => skill.name),
      containsAll([
        'systematic-debugging',
        'test-driven-development',
        'verification-before-completion',
        'writing-plans',
        'brainstorming',
        'executing-plans',
      ]),
    );
  });

  test('ranking prioritizes debugging for build failures', () {
    final ranked = AgentSkillLibrary().rank('debug a flutter build failure');
    expect(ranked.first.name, 'systematic-debugging');
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
