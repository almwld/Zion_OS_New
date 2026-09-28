import 'dart:io'; import 'magiczionos_config.dart'; import 'strategies/strategy.dart'; import 'strategies/magiczionos_strategy.dart'; import 'strategies/proot_strategy.dart'; import 'strategies/chroot_strategy.dart';
class Magiczionos {
  Magiczionos._(); static final Magiczionos instance=Magiczionos._();
  MagiczionosConfig _config=const MagiczionosConfig(); RootStrategyBase? _active; final Map<String,RootStrategyBase> _strategies={};
  MagiczionosConfig get config=>_config; RootStrategyBase? get activeStrategy=>_active;
  Future<void> initialize([MagiczionosConfig? config]) async {_config=config??_config;_strategies..clear()..addAll({'magiczionos':MagiczionosStrategy(),'chroot':ChrootStrategy(),'proot':ProotStrategy(distroName:_config.defaultDistro)});await _select();}
  Future<RootStrategyBase?> _select() async {if(_config.preferredStrategy!=RootStrategy.auto){final s=_strategies[_config.preferredStrategy.name];if(s!=null&&await s.getStatus()==StrategyStatus.available){_active=s;return s;}if(!_config.autoFallback)return null;}final list=_strategies.values.toList()..sort((a,b)=>b.priority.compareTo(a.priority));for(final s in list){if(await s.getStatus()==StrategyStatus.available){_active=s;return s;}}_active=null;return null;}
  Future<Map<String,StrategyStatus>> getAllStatuses() async=>{for(final e in _strategies.entries)e.key:await e.value.getStatus()};
  Future<ExecutionResult> execute(String command,{Duration? timeout,String? workingDirectory}) async=>_active?.execute(command,timeout:timeout??Duration(seconds:_config.commandTimeoutSeconds),workingDirectory:workingDirectory)??ExecutionResult.failure('لا توجد استراتيجية متاحة','none');
  Future<Process> startShell({String? shell}) async=>_active?.startInteractiveShell(shell:shell??_config.defaultShell)??(throw StateError('لا توجد استراتيجية متاحة'));
  Future<bool> switchStrategy(RootStrategy target) async {final s=_strategies[target.name];if(s==null||await s.getStatus()!=StrategyStatus.available)return false;_active=s;_config=_config.copyWith(preferredStrategy:target);return true;}
  Future<void> dispose() async {for(final s in _strategies.values)await s.dispose();}
}