import 'package:flutter_test/flutter_test.dart';

import 'package:project_zion/core/services/unified_core_service.dart';
import 'package:project_zion/features/terminal/native_pty_adapter.dart';
import 'package:project_zion/features/terminal/terminal_service.dart';
import 'package:project_zion/screens/lock_screen.dart';
import 'package:project_zion/security/core/security_core.dart';
import 'package:project_zion/security/runtime/runtime_integrity.dart';

void main() {
  testWidgets('Lock Screen is constructible', (tester) async {
    await tester.pumpWidget(const LockScreen());
    expect(find.byType(LockScreen), findsOneWidget);
  });

  test('Runtime integrity passes with a fresh SecurityCore', () {
    final report = const RuntimeIntegrity().verify(SecurityCore());
    expect(report.passed, isTrue);
    expect(report.failedChecks, isEmpty);
  });

  test('Unified core exposes only defensive diagnostics', () async {
    final service = UnifiedCoreService();
    expect(await service.execute('help'), contains('DEFENSIVE DIAGNOSTICS'));
    expect(await service.execute('msfconsole'), contains('unavailable'));
    expect(await service.execute('sqlmap'), contains('unavailable'));
  });

  test('Terminal service reports its shell capability without faking PTY success', () async {
    final service = TerminalService(SecurityCore());
    final result = await service.execute('shell-status');
    expect(result.exitCode == 0 || result.exitCode == 127, isTrue);
    await service.dispose();
  });

  test('Native PTY adapter fails closed when no platform channel is available', () async {
    final adapter = NativePtyAdapter();
    expect(await adapter.isAvailable(), isFalse);
    await adapter.dispose();
  });
}
