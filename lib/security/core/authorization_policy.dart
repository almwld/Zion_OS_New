enum SecurityMode { defensive, labSimulation }

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
    if (isExpired) return false;
    return allowedActions.isEmpty || allowedActions.contains(action);
  }
}

class AuthorizationPolicy {
  const AuthorizationPolicy();

  bool canExecute({
    required AuthorizationScope scope,
    required String action,
    required bool requiresSimulation,
  }) {
    if (!scope.allows(action)) return false;
    if (requiresSimulation && scope.mode != SecurityMode.labSimulation) return false;
    return true;
  }
}
