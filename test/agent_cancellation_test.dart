import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/core/agent_runtime.dart';
import 'package:project_zion/agent/core/cancellation_token.dart';

void main() {
  test('CancellationToken is idempotent and observable', () async {
    final token = CancellationToken();
    var events = 0;
    final sub = token.onCancel.listen((_) => events++);
    expect(token.isCancelled, isFalse);
    token.cancel();
    token.cancel();
    expect(token.isCancelled, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(events, 1);
    await sub.cancel();
    await token.dispose();
  });

  test('AgentRuntime rejects empty task without creating a session', () async {
    final runtime = AgentRuntime();
    final result = await runtime.run('   ');
    expect(result.success, isFalse);
    expect(runtime.activeSession, isNull);
    await runtime.dispose();
  });

  test('AgentRuntime exposes a cancellable active session', () async {
    final runtime = AgentRuntime();
    expect(runtime.canCancel, isFalse);
    await runtime.dispose();
  });
}
