import 'package:flutter_test/flutter_test.dart';

import 'package:project_zion/security/core/security_core.dart';
import 'package:project_zion/security/runtime/runtime_integrity.dart';

void main() {
  group('RuntimeIntegrity', () {
    test('passes with a healthy Security Core', () {
      final core = SecurityCore();
      final report = const RuntimeIntegrity().verify(core);

      expect(report.passed, isTrue);
      expect(report.failedChecks, isEmpty);
      expect(core.auditLogger.records, isNotEmpty);

      core.dispose();
    });

    test('does not expose simulated data as part of the runtime probe', () {
      final core = SecurityCore();
      final report = const RuntimeIntegrity().verify(core);

      expect(report.checks['security_core_available'], isTrue);
      expect(report.checks['risk_engine_available'], isTrue);
      expect(
        core.auditLogger.records.every(
          (record) => record.metadata['source'] != 'simulated',
        ),
        isTrue,
      );

      core.dispose();
    });
  });
}
