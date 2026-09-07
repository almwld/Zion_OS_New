enum SecurityMode { defensive, labSimulation }

/// A bounded authorization scope for one assessment operation.
class AuthorizationScope {
  const AuthorizationScope({
    required this.target,
    required this.mode,
    required this.expiresAt,
    this.allowedActions = const <String>{},
  });

  final String target;
  final SecurityMode mode;
  final DateTime expiresAt;
  final Set<String> allowedActions;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  bool allows(String action) {
    if (isExpired || action.trim().isEmpty) return false;
    return allowedActions.isEmpty || allowedActions.contains(action);
  }
}

/// Central policy for executable security capabilities.
///
/// Dangerous offensive capabilities are denied regardless of scope mode. A
/// scope is not a mechanism for bypassing a platform safety restriction.
class AuthorizationPolicy {
  const AuthorizationPolicy();

  static const Set<String> blockedActions = <String>{
    'wifi.wps.bruteforce',
    'wifi.deauth.emit',
    'wifi.evil_twin.capture',
    'wifi.credential_capture',
    'credential.theft',
    'password.cracking',
    'handshake.cracking',
    'pmkid.cracking',
    'sql.exploitation',
    'sql.data_extraction',
  };

  bool canExecute({
    required AuthorizationScope scope,
    required String action,
    required bool requiresSimulation,
  }) {
    final normalizedAction = action.trim().toLowerCase();
    if (blockedActions.contains(normalizedAction)) return false;
    if (!scope.allows(normalizedAction)) return false;
    if (requiresSimulation && scope.mode != SecurityMode.labSimulation) {
      return false;
    }
    return true;
  }
}
