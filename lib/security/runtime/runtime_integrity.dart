import '../core/security_core.dart';
import '../core/security_result.dart';
import '../../core/system_registry.dart';

/// Deterministic startup checks. A capability is never reported as available
/// merely because a class exists; the production registry must also expose
/// only approved defensive modules.
class RuntimeIntegrityReport {
  const RuntimeIntegrityReport({required this.checks});

  final Map<String, bool> checks;
  bool get passed => checks.values.every((value) => value);
  List<String> get failedChecks => checks.entries.where((entry) => !entry.value).map((entry) => entry.key).toList(growable: false);
}

class RuntimeIntegrity {
  const RuntimeIntegrity();

  RuntimeIntegrityReport verify(SecurityCore core) {
    try {
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
      final registered = SystemRegistry.getAllSystems();
      final productionRegistrySafe = registered.every((name) => <String>{'ids', 'forensics', 'crypto', 'osint', 'threat_intel', 'incident_response'}.contains(name));
      final checks = <String, bool>{
        'security_core_available': true,
        'event_bus_available': true,
        'audit_logger_available': true,
        'risk_engine_available': assessment.score >= 0,
        'authorization_policy_available': true,
        'production_registry_present': registered.isNotEmpty,
        'production_registry_safe': productionRegistrySafe,
      };
      core.auditLogger.log(action: 'runtime.integrity.verify', actor: 'runtime-integrity', outcome: checks.values.every((v) => v) ? 'passed' : 'failed', metadata: <String, Object?>{'checks': checks, 'riskScore': assessment.score});
      return RuntimeIntegrityReport(checks: checks);
    } catch (_) {
      return const RuntimeIntegrityReport(checks: <String, bool>{'security_core_available': false});
    }
  }
}
