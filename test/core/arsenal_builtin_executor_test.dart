import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/arsenal/arsenal_builtin_executor.dart';
import 'package:project_zion/security/core/authorization_policy.dart';
import 'package:project_zion/security/core/security_core.dart';

void main() {
  AuthorizationScope scope() => AuthorizationScope(
        target: 'local-device',
        mode: SecurityMode.defensive,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
        allowedActions: const <String>{
          'forensics.hash',
          'crypto.hash',
          'ai.analysis',
          'defense.audit',
          'analysis.logs',
          'utility.system-info',
          'web.inspect',
        },
      );

  test('hash builtin produces a real SHA-256', () async {
    final file = File('${Directory.systemTemp.path}/zion-arsenal-hash.txt');
    await file.writeAsString('zion');
    final security = SecurityCore();
    final result = await ArsenalBuiltinExecutor(security).execute(
      toolId: 'forensics.hash',
      arguments: <String>[file.path, 'sha256'],
      actor: 'test',
      scope: scope(),
    );
    expect(result?.success, isTrue);
    expect(result?.stdout, contains('SHA256'));
    await file.delete();
  });

  test('AI builtin returns local model output', () async {
    final result = await ArsenalBuiltinExecutor(SecurityCore()).execute(
      toolId: 'ai.analysis',
      arguments: const <String>['security', '0.1', '0.2', '0.1', '0.9'],
      actor: 'test',
      scope: scope(),
    );
    expect(result?.success, isTrue);
    expect(result?.stdout, contains('local-mlp'));
  });

  test('system info builtin returns bounded metrics', () async {
    final result = await ArsenalBuiltinExecutor(SecurityCore()).execute(
      toolId: 'utility.system-info',
      arguments: const <String>[],
      actor: 'test',
      scope: scope(),
    );
    expect(result?.success, isTrue);
    expect(result?.stdout, contains('cpuPercent'));
  });
}
