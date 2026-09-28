import 'dart:async'; import 'dart:io'; import 'strategy.dart';
class MagiczionosStrategy extends RootStrategyBase {
  static const _suCandidates=['/system/bin/su','/system/xbin/su','/sbin/su','su'];
  String get name=>'magiczionos'; String get displayName=>'#magiczionos (Magisk)'; String get description=>'Root عبر SU حقيقي عند منحه من مدير الصلاحيات'; int get priority=>100; bool get requiresRoot=>true;
  Future<String?> _su() async { for(final p in _suCandidates){try{final r=await Process.run(p,['-c','id'],runInShell:false).timeout(const Duration(seconds:3));if(r.exitCode==0&&r.stdout.toString().contains('uid=0'))return p;}catch(_){}} return null; }
  Future<bool> isAvailable() async=>await _su()!=null;
  Future<StrategyStatus> getStatus() async { final su=await _su(); return su==null?StrategyStatus.permissionRequired:StrategyStatus.available; }
  bool _blocked(String c)=>RegExp(r'(^|[;&|])\s*(rm\s+-rf|mkfs|dd\s+if=|reboot|poweroff|shutdown|:(){|fork\s*\()|\b(wipe|format)\b)',caseSensitive:false).hasMatch(c);
  Future<ExecutionResult> execute(String command,{Duration? timeout,String? workingDirectory,Map<String,String>? environment}) async {
    if(_blocked(command)) return ExecutionResult.failure('تم حظر الأمر عالي الخطورة بواسطة سياسة Zion.','magiczionos');
    final su=await _su(); if(su==null)return ExecutionResult.failure('SU غير متاح أو لم يُمنح الإذن.','magiczionos'); final t=DateTime.now();
    try{final r=await Process.run(su,['-c',command],workingDirectory:workingDirectory,environment:environment,runInShell:false).timeout(timeout??const Duration(seconds:60));return ExecutionResult(success:r.exitCode==0,exitCode:r.exitCode,stdout:r.stdout.toString(),stderr:r.stderr.toString(),duration:DateTime.now().difference(t),strategy:name);}on TimeoutException{return ExecutionResult.failure('انتهت المهلة','magiczionos');}catch(e){return ExecutionResult.failure('خطأ: $e',name);}
  }
  Future<Process> startInteractiveShell({String? shell,String? workingDirectory,Map<String,String>? environment}) async {final su=await _su();if(su==null)throw StateError('SU غير متاح.');final selected=shell??'/system/bin/sh';if(!RegExp(r'^/(system|data/data/com\.zion\.os/files)/').hasMatch(selected))throw ArgumentError('مسار shell غير موثوق.');return Process.start(su,['-c','exec "$selected"'],workingDirectory:workingDirectory,environment:environment,runInShell:false);}
  Future<ExecutionResult> magiskCommand(String args)=>execute('magisk $args');
  @override Future<void> dispose() async {}
}