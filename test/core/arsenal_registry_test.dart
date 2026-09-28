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

  test('tool serialization exposes explicit availability', () {
    final tool = ArsenalRegistry().resolve('terminal.shell')!;
    final json = tool.toJson();
    expect(json['availability'], 'AVAILABLE');
    expect(json['command'], '/system/bin/sh');
  });
}
