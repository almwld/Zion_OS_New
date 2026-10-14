import 'dart:async';

import '../core/agent_models.dart';
import '../core/cancellation_token.dart';

abstract class AgentTool {
  String get name;
  String get description;
  Map<String, dynamic> get parameters;

  Set<AgentPermission> get permissions => const {AgentPermission.readOnly};
  Set<AgentPermission> requiredPermissions(Map<String, dynamic> params) => permissions;
  bool requiresApproval(Map<String, dynamic> params) => false;

  /// Opt in only for tools whose network actions are strictly read-only GETs.
  bool get supportsReadOnlyWebRetrieval => false;
  bool supports(Map<String, dynamic> params) => true;

  Future<StepResult> execute(Map<String, dynamic> params);

  /// Default cancellation races a tool's result against the session token.
  /// Long-running process tools should override this to terminate their process.
  Future<StepResult> executeCancellable(
    Map<String, dynamic> params,
    CancellationToken? cancellationToken,
  ) async {
    if (cancellationToken == null) return execute(params);
    cancellationToken.throwIfCancelled();

    final cancelled = Completer<StepResult>();
    final subscription = cancellationToken.onCancel.listen((_) {
      if (!cancelled.isCompleted) {
        cancelled.completeError(const AgentCancelledException());
      }
    });
    try {
      return await Future.any<StepResult>([
        execute(params),
        cancelled.future,
      ]);
    } finally {
      await subscription.cancel();
    }
  }
}
