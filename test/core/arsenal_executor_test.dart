import 'package:flutter_test/flutter_test.dart';

import 'package:project_zion/core/arsenal/arsenal_executor.dart';
import 'package:project_zion/core/arsenal/arsenal_registry.dart';
import 'package:project_zion/security/core/authorization_policy.dart';

void main() {
  test('Arsenal executor rejects unregistered tools before execution', () async {
    final executor = ArsenalExecutor();
    final result = await executor.execute(
      toolId: 'missing.tool',
      scope: AuthorizationScope(
        target: 'local-device',
        mode: SecurityMode.defensive,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      ),
    );
    expect(result.success, isFalse);
    expect(result.status, 'NOT_FOUND');
  });

  test('Arsenal executor resolves the native shell through TerminalService', () async {
    final executor = ArsenalExecutor();
    final result = await executor.execute(
      toolId: 'terminal.shell',
      arguments: <String>['-c', 'printf zion-arsenal-test'],
      scope: AuthorizationScope(
        target: 'local-device',
        mode: SecurityMode.defensive,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      ),
    );
    expect(result.status, anyOf('SUCCESS', startsWith('EXIT_'), 'UNAVAILABLE'));
    if (result.status == 'SUCCESS') {
      expect(result.stdout, contains('zion-arsenal-test'));
    }
  });
}
