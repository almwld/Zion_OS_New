import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/arsenal/arsenal_registry.dart';
import 'package:project_zion/core/userland/userland_registry.dart';

void main() {
  test('registry exposes only explicit Userland availability', () async {
    const registry = UserlandRegistry();
    final tools = registry.tools();
    expect(tools.map((e) => e.id), containsAll(UserlandRegistry.toolIds));
    expect(
      tools.every(
        (e) => e.availability == ArsenalAvailability.notConfigured,
      ),
      isTrue,
    );
  });

  test('unknown Userland tool is unavailable', () async {
    const registry = UserlandRegistry();
    expect(
      await registry.availability('unknown'),
      ArsenalAvailability.unavailable,
    );
  });
}
