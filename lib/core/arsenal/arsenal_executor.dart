import '../../features/terminal/terminal_service.dart';
import '../../security/core/authorization_policy.dart';
import '../../security/core/security_core.dart';
import 'arsenal_registry.dart';

class ArsenalExecutionResult {
  const ArsenalExecutionResult({required this.success, required this.status, required this.toolId, this.exitCode, this.stdout = '', this.stderr = '', this.reason});
  final bool success;
  final String status;
  final String toolId;
  final int? exitCode;
  final String stdout;
  final String stderr;
  final String? reason;
}

class ArsenalExecutor {
  ArsenalExecutor({ArsenalRegistry? registry, ArsenalRuntimeResolver? resolver, SecurityCore? securityCore, TerminalService? terminalService})
      : registry = registry ?? ArsenalRegistry(),
        resolver = resolver ?? const ArsenalRuntimeResolver(),
        securityCore = securityCore ?? SecurityCore(),
        _terminalService = terminalService;

  final TerminalService? _terminalService;

  final ArsenalRegistry registry;
  final ArsenalRuntimeResolver resolver;
  final SecurityCore securityCore;
  late final TerminalService terminal = _terminalService ?? TerminalService(securityCore);

  Future<ArsenalRegistry> refreshAvailability() => resolver.resolve(registry);

  Future<ArsenalExecutionResult> execute({
    required String toolId,
    List<String> arguments = const <String>[],
    required AuthorizationScope scope,
    String actor = 'arsenal',
  }) async {
    final runtime = await resolver.resolve(registry);
    final tool = runtime.resolve(toolId);
    if (tool == null) return _fail(toolId, 'NOT_FOUND', 'Tool is not registered.');
    if (tool.availability != ArsenalAvailability.available) {
      return _fail(toolId, tool.availability.name.toUpperCase(), tool.reason ?? 'Tool is unavailable.');
    }
    final command = tool.command;
    if (command == null || command.isEmpty) return _fail(toolId, 'UNSUPPORTED', 'Tool has no executable command.');
    if (arguments.any((value) => value.contains('\u0000') || value.contains('\n') || value.contains('\r'))) {
      return _fail(toolId, 'INVALID_ARGUMENTS', 'Arguments contain prohibited control characters.');
    }
    final decision = securityCore.gateway.authorize(
      scope: scope,
      action: tool.id,
      capabilityId: _capabilityFor(tool),
      actor: actor,
      requiresSimulation: tool.category == ArsenalCategory.attack,
    );
    if (!decision.allowed) return _fail(toolId, decision.status, decision.reason);

    final commandLine = [command, ...arguments.map(_quote)].join(' ');
    final result = await terminal.execute(commandLine);
    securityCore.auditLogger.log(
      action: 'arsenal.execute',
      actor: actor,
      outcome: result.succeeded ? 'success' : 'failed',
      target: scope.target,
      metadata: <String, Object?>{
        'toolId': tool.id,
        'exitCode': result.exitCode,
        'source': 'TerminalService',
      },
    );
    return ArsenalExecutionResult(
      success: result.succeeded,
      status: result.succeeded ? 'SUCCESS' : 'EXIT_${result.exitCode}',
      toolId: tool.id,
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }

  String _capabilityFor(ArsenalTool tool) {
    switch (tool.category) {
      case ArsenalCategory.network:
        return 'network.diagnostics';
      case ArsenalCategory.defense:
      case ArsenalCategory.analysis:
      case ArsenalCategory.forensics:
        return 'security.audit';
      default:
        return 'terminal.execute';
    }
  }

  String _quote(String value) => "'${value.replaceAll("'", "'\\''")}'";
  ArsenalExecutionResult _fail(String id, String status, String reason) => ArsenalExecutionResult(success: false, status: status, toolId: id, reason: reason);
}
