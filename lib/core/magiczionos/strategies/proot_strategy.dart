import 'dart:io'; import 'strategy.dart'; import '../../userland/zion_proot.dart';
class ProotStrategy extends RootStrategyBase {
  ProotStrategy({this.distroName='ubuntu'}); final String distroName; final ZionProot _proot=const ZionProot();
  String get name=>'proot'; String get displayName=>'PRoot (بدون Root)'; String get description=>'بيئة Linux عبر PRoot الحقيقي داخل Zion Userland'; int get priority=>50; bool get requiresRoot=>false;
  Future<bool> isAvailable() async=>(await _proot.inspect()).status==ProotStatus.available && await _proot.rootfsExists(_distro);
  ZionDistro get _distro=>ZionDistro.values.firstWhere((d)=>d.name==distroName,orElse:()=>ZionDistro.ubuntu);
  Future<StrategyStatus> getStatus() async {final s=await _proot.inspect();if(s.status!=ProotStatus.available)return StrategyStatus.notConfigured;return await _proot.rootfsExists(_distro)?StrategyStatus.available:StrategyStatus.notConfigured;}
  Future<ExecutionResult> execute(String command,{Duration? timeout,String? workingDirectory,Map<String,String>? environment}) async {final t=DateTime.now();if(command.trim().isEmpty)return ExecutionResult.failure('أمر فارغ','proot');try{final p=await _proot.start(_distro,command:['/bin/bash','-lc',command]);final out=await p.stdout.transform(SystemEncoding().decoder).join();final err=await p.stderr.transform(SystemEncoding().decoder).join();final code=await p.exitCode;return ExecutionResult(success:code==0,exitCode:code,stdout:out,stderr:err,duration:DateTime.now().difference(t),strategy:name);}catch(e){return ExecutionResult.failure('خطأ: $e',name);}}
  Future<Process> startInteractiveShell({String? shell,String? workingDirectory,Map<String,String>? environment})=>_proot.start(_distro,command:[shell??'/bin/bash','--login','-i']);
  Future<void> dispose() async {}
}