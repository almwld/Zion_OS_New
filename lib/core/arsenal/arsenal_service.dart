import '../../security/core/authorization_policy.dart';
import '../../security/core/security_core.dart';
import '../userland/userland_registry.dart';
import 'arsenal_executor.dart';
import 'arsenal_registry.dart';

/// Composition facade used by the UI and other subsystems.
///
/// It keeps the static Arsenal catalogue and the runtime Userland catalogue
/// synchronized, then exposes one authorized execution boundary.
class ArsenalService {
  ArsenalService({
    SecurityCore? securityCore,
    UserlandRegistry? userlandRegistry,
  }) : securityCore = securityCore ?? SecurityCore(),
       userlandRegistry = userlandRegistry ?? const UserlandRegistry();

  final SecurityCore securityCore;
  final UserlandRegistry userlandRegistry;

  ArsenalRegistry _registry = ArsenalRegistry();

  ArsenalRegistry get registry => _registry;

  Future<ArsenalRegistry> refresh() async {
    final base = ArsenalRegistry().tools;
    final userland = await userlandRegistry.snapshot();
    final overrides = <String, ArsenalTool>{for (final tool in userland) tool.id: tool};
    final merged = <ArsenalTool>[
      for (final tool in base) overrides[tool.id] ?? tool,
      for (final tool in userland)
        if (!base.any((candidate) => candidate.id == tool.id)) tool,
    ];
    _registry = ArsenalRegistry(tools: merged);
    _registry = await const ArsenalRuntimeResolver().resolve(_registry);
    return _registry;
  }

  ArsenalExecutor executor() => ArsenalExecutor(
        registry: _registry,
        resolver: const ArsenalRuntimeResolver(),
        securityCore: securityCore,
      );

  Future<ArsenalExecutionResult> execute({
    required String toolId,
    List<String> arguments = const <String>[],
    required AuthorizationScope scope,
    String actor = 'arsenal',
  }) async {
    if (!_registry.tools.any((tool) => tool.id == toolId)) {
      await refresh();
    }
    return executor().execute(
      toolId: toolId,
      arguments: arguments,
      scope: scope,
      actor: actor,
    );
  }
}
