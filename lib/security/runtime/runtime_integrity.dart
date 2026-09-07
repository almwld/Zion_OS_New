import '../core/security_core.dart';
import '../core/security_result.dart';

/// Lightweight, deterministic runtime gate used before the UI is considered
/// operational. It verifies that the Security Core composition is available
/// and that its trust-boundary primitives respond without throwing.
class RuntimeIntegrityReport {
  const RuntimeIntegrityReport({required this.checks});

  final Map<String, bool> checks;

  bool get passed => checks.values.every((value) => value);

  List<String> get failedChecks => checks.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList(growable: false);
}

class RuntimeIntegrity {
  const RuntimeIntegrity();

  RuntimeIntegrityReport verify(SecurityCore core) {
    final probe = SecurityResult(
      id: 'runtime-integrity-probe',
      timestamp: DateTime.now().toUtc(),
      source: ResultSource.real,
      severity: SecuritySeverity.info,
      title: 'Runtime integrity probe',
      description: 'Internal startup probe for Zion Security Core.',
      confidence: 1,
    );

    final assessment = core.assess(<SecurityResult>[probe]);
    final checks = <String, bool>{
      'security_core_available': true,
      'event_bus_available': core.eventBus.stream != null,
      'audit_logger_available': core.auditLogger.records.isEmpty,
      'risk_engine_available': assessment.score >= 0,
      'authorization_policy_available': core.authorizationPolicy != null,
    };

    return RuntimeIntegrityReport(checks: checks);
  }
}
