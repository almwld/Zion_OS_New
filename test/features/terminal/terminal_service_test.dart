import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/features/terminal/terminal_service.dart';
import '../../../lib/security/core/security_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('built-in help is handled without spawning a shell', () async {
    final service = TerminalService(SecurityCore());
    addTearDown(service.dispose);

    final result = await service.execute('help');

    expect(result.succeeded, isTrue);
    expect(result.shell, 'builtin');
    expect(result.stdout, contains('history'));
    expect(result.stdout, contains('shell-status'));
  });

  test('real shell command returns process output and exit code', () async {
    final service = TerminalService(SecurityCore());
    addTearDown(service.dispose);

    final result = await service.execute('printf ZionTerminalTest');

    expect(result.command, 'printf ZionTerminalTest');
    expect(result.shell, isNot('unavailable'));
    expect(result.exitCode, 0);
    expect(result.stdout, contains('ZionTerminalTest'));
    expect(result.duration, greaterThanOrEqualTo(Duration.zero));
  });

  test('failed real command exposes a non-zero exit code', () async {
    final service = TerminalService(SecurityCore());
    addTearDown(service.dispose);

    final result = await service.execute('command_that_should_not_exist_zion');

    expect(result.shell, isNot('unavailable'));
    expect(result.exitCode, isNot(0));
  });

  test('history is persisted and returned in newest-first order', () async {
    final service = TerminalService(SecurityCore());
    addTearDown(service.dispose);

    await service.execute('printf one');
    await service.execute('printf two');
    await Future<void>.delayed(Duration.zero);

    final result = await service.execute('history');

    expect(service.history.take(2), <String>['printf two', 'printf one']);
    expect(result.stdout, contains('printf two'));
    expect(result.stdout, contains('printf one'));
  });

  test('interactive shell starts, streams output, and stops', () async {
    final service = TerminalService(SecurityCore());
    addTearDown(service.dispose);
    final output = <String>[];
    final subscription = service.output.listen(output.add);
    addTearDown(subscription.cancel);

    await service.startInteractive();

    if (!service.isInteractiveRunning) {
      expect(output.join(), contains('No POSIX shell'));
      return;
    }

    service.write('printf InteractiveZion\n');
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(output.join(), contains('InteractiveZion'));

    await service.stopInteractive();
    expect(service.isInteractiveRunning, isFalse);
  });

  test('clearHistory removes all saved commands', () async {
    final service = TerminalService(SecurityCore());
    addTearDown(service.dispose);

    await service.execute('printf clear-me');
    await Future<void>.delayed(Duration.zero);
    await service.clearHistory();

    expect(service.history, isEmpty);
    final result = await service.execute('history');
    expect(result.stdout, isEmpty);
  });
}
