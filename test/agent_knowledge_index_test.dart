import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/skills/agent_knowledge_index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline knowledge index loads unique, categorized entries', () async {
    final index = AgentKnowledgeIndex();
    final entries = await index.entries();
    expect(entries.length, greaterThanOrEqualTo(30));
    expect(entries.map((entry) => entry.id).toSet(), hasLength(entries.length));
    expect(entries.map((entry) => entry.domain).toSet(), containsAll([
      'linux-runtime',
      'linux-packages',
      'terminal',
      'android',
      'flutter',
      'github-ci',
      'local-ai',
    ]));
  });

  test('ranking prioritizes local Kali/rootfs discovery', () async {
    final ranked = await AgentKnowledgeIndex().rank(
      'discover Kali rootfs and verify bin/bash shell',
    );
    expect(ranked, isNotEmpty);
    expect(ranked.first.id, anyOf('kali-detection', 'rootfs-shell'));
  });

  test('Arabic queries retrieve local Kali knowledge', () async {
    final ranked = await AgentKnowledgeIndex().rank('استكشف كالي لينكس والتوزيعة المحلية');
    expect(ranked, isNotEmpty);
    expect(ranked.first.id, 'kali-detection');
  });

  test('ranking prioritizes Flutter diagnostics for build failures', () async {
    final ranked = await AgentKnowledgeIndex().rank('flutter build apk failure');
    expect(ranked.first.id, 'flutter-diagnostics');
  });

  test('knowledge context is bounded and labels itself as reference', () async {
    final context = await AgentKnowledgeIndex().contextFor(
      'Kali packages and local rootfs',
      maxEntries: 5,
      maxTotalChars: 1000,
    );
    expect(context, contains('\n'));
    expect(context.length, lessThanOrEqualTo(1000));
    expect(context, contains('Kali'));
    expect(context, isNot(contains(r'\n')));
  });

  test('empty tasks do not load or emit knowledge context', () async {
    final index = AgentKnowledgeIndex();
    expect(await index.rank('   '), isEmpty);
    expect(await index.contextFor('  '), isEmpty);
  });
}
