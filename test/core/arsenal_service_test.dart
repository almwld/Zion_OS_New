import 'package:flutter_test/flutter_test.dart';

import 'package:project_zion/core/arsenal/arsenal_service.dart';
import 'package:project_zion/security/core/authorization_policy.dart';

void main() {
  test('ArsenalService merges userland runtime entries', () async {
    final service = ArsenalService();
    final registry = await service.refresh();
    expect(registry.resolve('packages.zion-pkg'), isNotNull);
    expect(registry.resolve('runtime.zion-proot'), isNotNull);
    expect(registry.resolve('terminal.shell'), isNotNull);
  });

  test('ArsenalService refuses unknown tool execution', () async {
    final service = ArsenalService();
    final result = await service.execute(
      toolId: 'unknown.tool',
      scope: AuthorizationScope(
        target: 'local-device',
        mode: SecurityMode.defensive,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      ),
    );
    expect(result.status, anyOf('NOT_FOUND', 'NOT_CONFIGURED'));
    expect(result.success, isFalse);
  });
}
