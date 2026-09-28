import 'dart:io';

import '../../security/core/audit_logger.dart';
import 'magiczionos_config.dart';
import 'strategies/chroot_strategy.dart';
import 'strategies/magiczionos_strategy.dart';
import 'strategies/proot_strategy.dart';
import 'strategies/strategy.dart';

class Magiczionos {
  Magiczionos._();
  static final Magiczionos instance = Magiczionos._();
  MagiczionosConfig _config = const MagiczionosConfig();
  RootStrategyBase? _active;
  final Map<String, RootStrategyBase> _strategies = <String, RootStrategyBase>{};
  AuditLogger? _audit;

  MagiczionosConfig get config => _config;
  RootStrategyBase? get activeStrategy => _active;

  Future<void> initialize([MagiczionosConfig? config, AuditLogger? auditLogger]) async {
    _config = config ?? _config;
    _audit = auditLogger ?? _audit;
    _strategies..clear()..addAll({
      'magiczionos': MagiczionosStrategy(),
      'chroot': ChrootStrategy(),
      'proot': ProotStrategy(distroName: _config.defaultDistro),
    });
    await _select();
    _audit?.log(action: 'magiczionos.initialize', actor: 'magiczionos', outcome: _active == null ? 'no-strategy' : 'ready', target: _active?.name, metadata: {'preferred': _config.preferredStrategy.name});
  }

  Future<RootStrategyBase?> _select() async {
    if (_config.preferredStrategy != RootStrategy.auto) {
      final selected = _strategies[_config.preferredStrategy.name];
      if (selected != null && await selected.getStatus() == StrategyStatus.available) { _active = selected; return selected; }
      if (!_config.autoFallback) { _active = null; return null; }
    }
    final list = _strategies.values.toList()..sort((a, b) => b.priority.compareTo(a.priority));
    for (final strategy in list) {
      if (await strategy.getStatus() == StrategyStatus.available) { _active = strategy; return strategy; }
    }
    _active = null;
    return null;
  }

  Future<Map<String, StrategyStatus>> getAllStatuses() async => {for (final e in _strategies.entries) e.key: await e.value.getStatus()};

  Future<ExecutionResult> execute(String command, {Duration? timeout, String? workingDirectory}) async {
    final strategy = _active;
    if (strategy == null) {
      final result = ExecutionResult.failure('لا توجد استراتيجية متاحة', 'none');
      _audit?.log(action: 'magiczionos.execute', actor: 'magiczionos', outcome: 'unavailable', target: 'none');
      return result;
    }
    final result = await strategy.execute(command, timeout: timeout ?? Duration(seconds: _config.commandTimeoutSeconds), workingDirectory: workingDirectory);
    _audit?.log(action: 'magiczionos.execute', actor: 'magiczionos', outcome: result.success ? 'success' : 'failed', target: strategy.name, metadata: {'exitCode': result.exitCode, 'command': command});
    return result;
  }

  Future<Process> startShell({String? shell}) async {
    final strategy = _active;
    if (strategy == null) { _audit?.log(action: 'magiczionos.shell.start', actor: 'magiczionos', outcome: 'unavailable'); throw StateError('لا توجد استراتيجية متاحة'); }
    try {
      final process = await strategy.startInteractiveShell(shell: shell ?? _config.defaultShell);
      _audit?.log(action: 'magiczionos.shell.start', actor: 'magiczionos', outcome: 'success', target: strategy.name);
      return process;
    } catch (e) {
      _audit?.log(action: 'magiczionos.shell.start', actor: 'magiczionos', outcome: 'failed', target: strategy.name, metadata: {'error': e.toString()});
      rethrow;
    }
  }

  Future<bool> switchStrategy(RootStrategy target) async {
    final strategy = _strategies[target.name];
    if (strategy == null || await strategy.getStatus() != StrategyStatus.available) {
      _audit?.log(action: 'magiczionos.strategy.switch', actor: 'magiczionos', outcome: 'unavailable', target: target.name);
      return false;
    }
    _active = strategy;
    _config = _config.copyWith(preferredStrategy: target);
    _audit?.log(action: 'magiczionos.strategy.switch', actor: 'magiczionos', outcome: 'success', target: target.name);
    return true;
  }

  Future<void> dispose() async { for (final strategy in _strategies.values) { await strategy.dispose(); } }
}