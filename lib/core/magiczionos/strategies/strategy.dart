import 'dart:io';
enum StrategyStatus { available, permissionRequired, notConfigured, unavailable }
class ExecutionResult {
  const ExecutionResult({required this.success,this.exitCode,required this.stdout,required this.stderr,required this.duration,required this.strategy});
  final bool success; final int? exitCode; final String stdout,stderr,strategy; final Duration duration;
  factory ExecutionResult.failure(String error,String strategy)=>ExecutionResult(success:false,stdout:'',stderr:error,duration:Duration.zero,strategy:strategy);
}
abstract class RootStrategyBase {
  String get name; String get displayName; String get description; int get priority; bool get requiresRoot;
  Future<bool> isAvailable(); Future<StrategyStatus> getStatus();
  Future<ExecutionResult> execute(String command,{Duration? timeout,String? workingDirectory,Map<String,String>? environment});
  Future<Process> startInteractiveShell({String? shell,String? workingDirectory,Map<String,String>? environment});
  Future<void> dispose();
}