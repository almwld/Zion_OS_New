import '../arsenal/arsenal_executor.dart';
import '../arsenal/arsenal_service.dart';
import '../../security/core/authorization_policy.dart';

class ArsenalRuntimeController {
  ArsenalRuntimeController(this.arsenal);

  final ArsenalService arsenal;
  bool _loaded = false;

  Future<void> initialize() async {
    await arsenal.refresh();
    _loaded = true;
  }

  bool get isInitialized => _loaded;

  Future<ArsenalExecutionResult> run(
    String toolId, {
    List<String> arguments = const <String>[],
    String actor = 'arsenal-ui',
  }) {
    if (!_loaded) {
      return _initializeAndRun(toolId, arguments, actor);
    }
    return arsenal.execute(
      toolId: toolId,
      arguments: arguments,
      actor: actor,
      scope: AuthorizationScope(
        target: 'local-device',
        mode: SecurityMode.defensive,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
        allowedActions: <String>{toolId},
      ),
    );
  }

  Future<ArsenalExecutionResult> _initializeAndRun(
    String toolId,
    List<String> arguments,
    String actor,
  ) async {
    await initialize();
    return run(toolId, arguments: arguments, actor: actor);
  }
}
