import 'package:flutter/foundation.dart';

import '../../security/core/audit_logger.dart';
import 'installers/unified_installer.dart';
import 'magiczionos_config.dart';
import 'magiczionos_core.dart';
import 'strategies/strategy.dart';

class MagiczionosProvider extends ChangeNotifier {
  MagiczionosProvider({Magiczionos? core, AuditLogger? auditLogger}) : core = core ?? Magiczionos.instance, auditLogger = auditLogger ?? AuditLogger();
  final Magiczionos core;
  final AuditLogger auditLogger;
  final UnifiedInstaller installer = UnifiedInstaller();
  Map<String, StrategyStatus> statuses = const <String, StrategyStatus>{};
  bool initializing = false;
  bool installing = false;
  double installProgress = 0;
  String? error;

  RootStrategy get selectedStrategy => core.config.preferredStrategy;
  RootStrategyBase? get activeStrategy => core.activeStrategy;

  Future<void> initialize([MagiczionosConfig? config]) async {
    initializing = true; error = null; notifyListeners();
    try { await core.initialize(config, auditLogger); await refresh(); } catch (e) { error = e.toString(); auditLogger.log(action: 'magiczionos.initialize', actor: 'provider', outcome: 'failed', metadata: {'error': e.toString()}); }
    initializing = false; notifyListeners();
  }

  Future<void> refresh() async { statuses = await core.getAllStatuses(); notifyListeners(); }

  Future<bool> switchStrategy(RootStrategy strategy) async {
    final ok = await core.switchStrategy(strategy);
    await refresh();
    return ok;
  }

  Future<ExecutionResult> execute(String command) => core.execute(command);
  Future<ProcessResult> install(String distro) async {
    installing = true; installProgress = 0; error = null; notifyListeners();
    try {
      final result = await installer.install(RootStrategy.proot, distro: distro, onProgress: (value) { installProgress = value; notifyListeners(); });
      auditLogger.log(action: 'magiczionos.install', actor: 'provider', outcome: result.success ? 'success' : 'failed', target: distro, metadata: {'message': result.message});
      if (!result.success) error = result.message;
      return ProcessResult(result.success, result.message);
    } finally { installing = false; notifyListeners(); }
  }
}

class ProcessResult {
  const ProcessResult(this.success, this.message);
  final bool success;
  final String message;
}