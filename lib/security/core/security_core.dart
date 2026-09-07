import 'audit_logger.dart';
import 'authorization_policy.dart';
import 'event_bus.dart';
import 'risk_engine.dart';
import 'security_capability.dart';
import 'security_event.dart';
import 'security_result.dart';

/// Single composition root for the security domain.
///
/// Feature modules should depend on this facade instead of constructing their
/// own event bus, risk engine, audit logger, or capability registry.
class SecurityCore {
  SecurityCore({
    SecurityEventBus? eventBus,
    RiskEngine? riskEngine,
    AuditLogger? auditLogger,
    AuthorizationPolicy? authorizationPolicy,
    SecurityCapabilityRegistry? capabilities,
  })  : eventBus = eventBus ?? SecurityEventBus(),
        riskEngine = riskEngine ?? const RiskEngine(),
        auditLogger = auditLogger ?? AuditLogger(),
        authorizationPolicy = authorizationPolicy ?? const AuthorizationPolicy(),
        capabilities = capabilities ?? SecurityCapabilityRegistry();

  final SecurityEventBus eventBus;
  final RiskEngine riskEngine;
  final AuditLogger auditLogger;
  final AuthorizationPolicy authorizationPolicy;
  final SecurityCapabilityRegistry capabilities;

  RiskAssessment assess(Iterable<SecurityResult> results) {
    return riskEngine.assess(results);
  }

  SecurityCapability capability(String id) => capabilities.resolve(id);

  bool canExecute({
    required AuthorizationScope scope,
    required String action,
    required bool requiresSimulation,
  }) {
    final allowed = authorizationPolicy.canExecute(
      scope: scope,
      action: action,
      requiresSimulation: requiresSimulation,
    );
    auditLogger.log(
      action: 'security.authorization.check',
      actor: 'security-core',
      outcome: allowed ? 'accepted' : 'denied',
      target: scope.target,
      metadata: <String, Object?>{
        'requestedAction': action,
        'requiresSimulation': requiresSimulation,
        'mode': scope.mode.name,
      },
    );
    return allowed;
  }

  /// Publishes an already normalized event and records its trust source.
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
