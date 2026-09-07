import 'audit_logger.dart';
import 'authorization_policy.dart';
import 'event_bus.dart';
import 'risk_engine.dart';
import 'security_event.dart';
import 'security_result.dart';

/// Single composition root for the security domain.
///
/// Feature modules should depend on this facade instead of constructing their
/// own event bus, risk engine, or audit logger. This is the first consolidation
/// boundary for Zion OS 2.0.
class SecurityCore {
  SecurityCore({
    SecurityEventBus? eventBus,
    RiskEngine? riskEngine,
    AuditLogger? auditLogger,
    AuthorizationPolicy? authorizationPolicy,
  })  : eventBus = eventBus ?? SecurityEventBus(),
        riskEngine = riskEngine ?? const RiskEngine(),
        auditLogger = auditLogger ?? AuditLogger(),
        authorizationPolicy = authorizationPolicy ?? const AuthorizationPolicy();

  final SecurityEventBus eventBus;
  final RiskEngine riskEngine;
  final AuditLogger auditLogger;
  final AuthorizationPolicy authorizationPolicy;

  RiskAssessment assess(Iterable<SecurityResult> results) {
    return riskEngine.assess(results);
  }

  void publish(SecurityEvent event) {
    eventBus.publish(event);
    auditLogger.log(
      action: 'security.event.publish',
      actor: 'security-core',
      outcome: 'accepted',
      target: event.assetId,
      metadata: <String, Object?>{
        'eventId': event.id,
        'type': event.type,
        'source': event.source.name,
        'severity': event.severity.name,
      },
    );
  }

  Future<void> dispose() async {
    await eventBus.dispose();
    await auditLogger.dispose();
  }
}
