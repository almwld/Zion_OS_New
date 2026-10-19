import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_zion/core/ai/long_term_memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('bounds large records and reloads persisted memory', () async {
    final memory = LongTermAIMemory();
    await memory.remember(
      kind: 'agent-step',
      text: List<String>.filled(600, 'تحليل طويل ').join(),
      metadata: <String, dynamic>{
        'tool': 'shell',
        'success': true,
        'details': List<String>.filled(200, 'معلومات تفصيلية ').join(),
      },
    );

    expect(memory.entries, hasLength(1));
    expect(memory.entries.single.text.length,
        lessThanOrEqualTo(LongTermAIMemory.maxTextChars + 1));
    expect(memory.entries.single.metadata.toString().length, lessThan(1800));

    final reloaded = LongTermAIMemory();
    await reloaded.load();
    expect(reloaded.entries, hasLength(1));
    expect(reloaded.entries.single.kind, 'agent-step');
    expect(reloaded.search('shell').single.text, memory.entries.single.text);
  });

  test('memory search prioritizes relevant and recent entries', () async {
    final memory = LongTermAIMemory();
    await memory.remember(kind: 'preference', text: 'تفضيل واجهة زيون');
    await memory.remember(kind: 'agent-step', text: 'نتيجة بناء زيون');

    final matches = memory.search('زيون');
    expect(matches, hasLength(2));
    expect(matches.first.text, 'نتيجة بناء زيون');
  });

  test('identical retry entries are deduplicated within the short window', () async {
    final memory = LongTermAIMemory();
    await memory.remember(
      kind: 'agent-step',
      text: 'تم فحص المخرجات',
      metadata: const {'tool': 'shell', 'success': true},
    );
    await memory.remember(
      kind: 'agent-step',
      text: 'تم فحص المخرجات',
      metadata: const {'tool': 'shell', 'success': true},
    );

    expect(memory.entries, hasLength(1));
  });
}
