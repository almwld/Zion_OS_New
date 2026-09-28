import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/arsenal/arsenal_registry.dart';

void main() {
  test('registry exposes all twelve Arsenal categories', () {
    expect(ArsenalCategory.values, hasLength(12));
    expect(ArsenalCategory.values.map((e) => e.name).toSet(), containsAll(<String>[
      'attack', 'defense', 'analysis', 'tools', 'network', 'crypto',
      'ai', 'forensics', 'wireless', 'web', 'system', 'utility',
    ]));
  });

  test('unconfigured capabilities are never reported as available', () {
    final registry = ArsenalRegistry();
    final package = registry.resolve('packages.zion-pkg');
    expect(package, isNotNull);
    expect(package!.availability, ArsenalAvailability.notConfigured);
    expect(package.command, 'zion-pkg');
  });

  test('grouping includes every category', () {
    final grouped = ArsenalRegistry().grouped();
    expect(grouped.keys, hasLength(12));
    for (final category in ArsenalCategory.values) {
      expect(grouped, contains(category.name));
    }
  });

  test('runtime resolver marks missing absolute executables as not configured', () async {
    const registry = ArsenalRegistry(tools: <ArsenalTool>[
      ArsenalTool(
        id: 'test.missing',
        name: 'Missing',
        category: ArsenalCategory.tools,
        availability: ArsenalAvailability.available,
        command: '/definitely/missing/zion-tool',
      ),
    ]);
    final resolved = await const ArsenalRuntimeResolver().resolve(registry);
    final tool = resolved.resolve('test.missing')!;
    expect(tool.availability, ArsenalAvailability.notConfigured);
    expect(tool.reason, contains('not present'));
  });

  test('tool copyWith preserves immutable registry metadata', () {
    final original = ArsenalRegistry().resolve('terminal.shell')!;
    final changed = original.copyWith(availability: ArsenalAvailability.notConfigured, reason: 'runtime check');
    expect(changed.id, original.id);
    expect(changed.command, original.command);
    expect(changed.availability, ArsenalAvailability.notConfigured);
    expect(changed.reason, 'runtime check');
  });

  test('tool serialization exposes explicit availability', () {
    final tool = ArsenalRegistry().resolve('terminal.shell')!;
    final json = tool.toJson();
    expect(json['availability'], 'AVAILABLE');
    expect(json['command'], '/system/bin/sh');
  });
}
