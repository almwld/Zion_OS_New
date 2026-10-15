import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_zion/agent/core/agent_collaboration.dart';
import 'package:project_zion/agent/knowledge/obsidian_vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('specialist team is bounded, sequential, and records each role', () async {
    var active = 0;
    var maxActive = 0;
    final result = await AgentCollaborationEngine().runTeam(
      task: 'اختبر المهمة',
      roles: SpecialistRole.values,
      runPrompt: (prompt) async {
        active++;
        if (active > maxActive) maxActive = active;
        await Future<void>.delayed(const Duration(milliseconds: 1));
        active--;
        return 'نتيجة قابلة للفحص';
      },
    );
    expect(maxActive, 1);
    expect(result.events.length, 6);
    expect(result.events.where((e) => e.actor == 'Verifier').length, 1);
    expect(result.success, isTrue);
  });

  test('overthinker never exceeds three passes', () async {
    var calls = 0;
    final result = await AgentCollaborationEngine().runOverthinker(
      task: 'راجع النتيجة',
      passes: 99,
      runPrompt: (_) async => 'مراجعة ${++calls}',
    );
    expect(calls, 3);
    expect(result.events.length, 3);
  });

  test('engineering loop records bounded engineer-review-verifier cycles', () async {
    var calls = 0;
    final result = await AgentCollaborationEngine().runEngineeringLoop(
      task: 'إصلاح اختبار',
      iterations: 99,
      runPrompt: (_) async => 'مرحلة ${++calls}',
    );
    expect(calls, 9);
    expect(result.events.length, 9);
    expect(result.events.first.actor, 'Engineer · دورة 1');
    expect(result.events.last.actor, 'Verifier · دورة 3');
  });

  test('Obsidian vault persists notes, wikilinks, tags and graph edges locally', () async {
    SharedPreferences.setMockInitialValues({});
    final vault = ObsidianVault();
    final first = await vault.save(title: 'خطة الوكيل', body: 'راجع [[نتائج الاختبار]]', tags: ['#agent', 'engineering']);
    final second = await vault.save(title: 'نتائج الاختبار', body: 'كل شيء جاهز');
    expect(first.tags, ['agent', 'engineering']);
    expect(first.links, ['نتائج الاختبار']);
    final graph = await vault.graph();
    expect(graph.notes, hasLength(2));
    expect(graph.edges[first.id], [second.id]);
    expect((await vault.search('خطة الوكيل')), hasLength(1));
    await vault.delete(second.id);
    expect((await vault.allNotes()), hasLength(1));
  });
}
