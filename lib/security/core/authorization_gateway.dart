import 'authorization_policy.dart';
import 'audit_logger.dart';
import 'security_capability.dart';

/// Result of an authorization decision. No operation is executed by this
/// class; callers must only execute after an `allowed` decision.
class AuthorizationDecision {
  const AuthorizationDecision({
    required this.allowed,
    required this.status,
    required this.reason,
    required this.target,
    required this.action,
  });

  final bool allowed;
  final String status;
  final String reason;
  final String target;
  final String action;
}

/// Enforcement boundary between security UI/modules and operational actions.
///
/// The gateway validates scope, expiration, capability availability and the
/// central deny-list before an operation can proceed. Every decision is
/// recorded in the shared AuditLogger.
class AuthorizationGateway {
  AuthorizationGateway({
    required this.policy,
    required this.capabilities,
    required this.auditLogger,
  });

  final AuthorizationPolicy policy;
  final SecurityCapabilityRegistry capabilities;
  final AuditLogger auditLogger;

  AuthorizationDecision authorize({
    required AuthorizationScope scope,
    required String action,
    required String capabilityId,
    String actor = 'operator',
    bool requiresSimulation = false,
  }) {
    final normalizedAction = action.trim().toLowerCase();
    final capability = capabilities.resolve(capabilityId);

    if (AuthorizationPolicy.blockedActions.contains(normalizedAction)) {
      return _deny(
        actor: actor,
        scope: scope,
        action: normalizedAction,
        reason: 'Action is permanently blocked by security policy.',
        status: 'BLOCKED',
      );
    }

    if (scope.isExpired) {
      return _deny(
        actor: actor,
        scope: scope,
        action: normalizedAction,
        reason: 'Authorization scope has expired.',
        status: 'EXPIRED',
      );
    }

    if (capability.isUnavailable) {
      return _deny(
        actor: actor,
        scope: scope,
        action: normalizedAction,
        reason: capability.reason ?? 'Capability is unavailable.',
        status: 'UNAVAILABLE',
      );
    }

    if (requiresSimulation && !capability.isSimulation) {
      return _deny(
        actor: actor,
        scope: scope,
        action: normalizedAction,
        reason: 'Operation requires an explicitly simulated capability.',
        status: 'DENIED',
      );
    }

    if (!policy.canExecute(
      scope: scope,
      action: normalizedAction,
      requiresSimulation: requiresSimulation,
    )) {
      return _deny(
        actor: actor,
        scope: scope,
        action: normalizedAction,
        reason: 'Action is outside the authorized scope.',
        status: 'DENIED',
      );
    }

    auditLogger.log(
      action: 'security.authorization.grant',
      actor: actor,
      outcome: 'accepted',
      target: scope.target,
      metadata: <String, Object?>{
        'requestedAction': normalizedAction,
        'capabilityId': capabilityId,
        'mode': scope.mode.name,
        'expiresAt': scope.expiresAt.toUtc().toIso8601String(),
      },
    );

    return AuthorizationDecision(
      allowed: true,
      status: 'AUTHORIZED',
      reason: 'Operation is authorized within the current scope.',
      target: scope.target,
      action: normalizedAction,
    );
  }

  AuthorizationDecision _deny({
    required String actor,
    required AuthorizationScope scope,
    required String action,
    required String reason,
    required String status,
  }) {
    auditLogger.log(
      action: 'security.authorization.deny',
      actor: actor,
      outcome: status.toLowerCase(),
      target: scope.target,
      metadata: <String, Object?>{
        'requestedAction': action,
        'reason': reason,
        'mode': scope.mode.name,
        'expiresAt': scope.expiresAt.toUtc().toIso8601String(),
      },
    );

    return AuthorizationDecision(
      allowed: false,
      status: status,
      reason: reason,
      target: scope.target,
      action: action,
    );
  }
}
