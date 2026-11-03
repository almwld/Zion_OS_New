import 'dart:async';
import '../../../agent/core/agent_models.dart';
import '../../../agent/core/cancellation_token.dart';
import '../../../agent/tools/tool.dart';
import '../../environment/agent_environment.dart';
class TerminalTool extends AgentTool {
 final AgentEnvironment environment;TerminalTool(this.environment);
 @override String get name=>'run_command';
 @override String get description=>'تنفيذ أمر محدود داخل جلسة Zion native PTY بعد موافقة المستخدم.';
 @override Map<String,dynamic> get parameters=>const {'command':{'type':'string','required':true},'timeout_seconds':{'type':'integer','required':false},'working_directory':{'type':'string','required':false,'description':'مسار نسبي داخل sandbox/projects'}};
 @override Set<AgentPermission> get permissions=>const {AgentPermission.process};
 @override bool requiresApproval(Map<String,dynamic> p)=>true;
 bool _allowed(String command){
  final v=command.trim();if(v.isEmpty||v.length>2000||RegExp(r'[|><&;\$()\x60\\\r\n\x00]').hasMatch(v))return false;
  final a=v.split(RegExp(r'\s+'));final exe=a.first;
  final safeArgs=a.skip(1).toList();
  if(safeArgs.any((x)=>!RegExp(r'^[A-Za-z0-9_./-]+
  if(exe=='npm'&&a.length==2)return a[1]=='test';
  if(exe=='npm'&&a.length==3)return a[1]=='run'&&a[2]=='build';
  if(exe=='flutter'&&a.length==2)return const {'analyze','test'}.contains(a[1]);
  if(exe=='dart'&&a.length==2)return const {'analyze','format'}.contains(a[1]);
  if(exe=='python3'&&a.length==2){final f=a[1];return f.endsWith('.py')&&!f.contains('..')&&(f.startsWith(environment.tempDirectory.path+'/')||f.startsWith(environment.projectsDirectory.path+'/'));}
  return false;
 }
 @override Future<StepResult> execute(Map<String,dynamic> p)async{
  final s=environment.terminal;if(s==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final rawCommand=p['command']?.toString()??'';if(!_allowed(rawCommand))return StepResult.failure('الأمر خارج القائمة البيضاء أو يحتوي معاملات shell محظورة.');
  final directory=await environment.resolveWorkspaceDirectory(p['working_directory']?.toString()??'.');
  if(directory==null)return StepResult.failure('مجلد العمل غير موجود أو خارج sandbox/projects.');
  final command="cd '${directory.path.replaceAll("'","'\\''")}' && $rawCommand";
  final seconds=(p['timeout_seconds'] as num?)?.toInt()??60;if(seconds<1||seconds>1800)return StepResult.failure('المهلة يجب أن تكون بين 1 و1800 ثانية.');
  final r=await s.executeInInteractive(command,timeout:Duration(seconds:seconds));
  final data={'stdout':r.stdout,'stderr':r.stderr,'exit_code':r.exitCode,'duration_ms':r.duration.inMilliseconds,'shell':r.shell};
  return r.exitCode==0?StepResult.success('اكتمل الأمر (exit 0).',data:data,duration:r.duration):StepResult.failure('فشل الأمر (exit ${r.exitCode}): ${r.stderr.isEmpty?r.stdout:r.stderr}',duration:r.duration);
 }
 @override Future<StepResult> executeCancellable(Map<String,dynamic> p,CancellationToken? token)async{
  if(token==null)return execute(p);token.throwIfCancelled();final s=environment.terminal;if(s==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final rawCommand=p['command']?.toString()??'';if(!_allowed(rawCommand))return StepResult.failure('الأمر خارج القائمة البيضاء.');
  final directory=await environment.resolveWorkspaceDirectory(p['working_directory']?.toString()??'.');
  if(directory==null)return StepResult.failure('مجلد العمل غير موجود أو خارج sandbox/projects.');
  final command="cd '${directory.path.replaceAll("'","'\\''")}' && $rawCommand";
  final seconds=(p['timeout_seconds'] as num?)?.toInt()??60;if(seconds<1||seconds>1800)return StepResult.failure('مهلة غير صالحة.');
  final sub=token.onCancel.listen((_)=>unawaited(s.interruptInteractive()));try{return await execute(p);}finally{await sub.cancel();}
 }
}).hasMatch(x)||x.contains('..')||x.startsWith('-')))return false;
  if(const {'ls','cat','grep','find','wc','head','tail'}.contains(exe))return true;
  if(exe=='git'&&a.length>=2)return const {'status','diff','log'}.contains(a[1])&&safeArgs.skip(1).every((x)=>!x.startsWith('!'));
  if(exe=='npm'&&a.length==2)return a[1]=='test';
  if(exe=='npm'&&a.length==3)return a[1]=='run'&&a[2]=='build';
  if(exe=='flutter'&&a.length==2)return const {'analyze','test'}.contains(a[1]);
  if(exe=='dart'&&a.length==2)return const {'analyze','format'}.contains(a[1]);
  if(exe=='python3'&&a.length==2){final f=a[1];return f.endsWith('.py')&&!f.contains('..')&&(f.startsWith(environment.tempDirectory.path+'/')||f.startsWith(environment.projectsDirectory.path+'/'));}
  return false;
 }
 @override Future<StepResult> execute(Map<String,dynamic> p)async{
  final s=environment.terminal;if(s==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final command=p['command']?.toString()??'';if(!_allowed(command))return StepResult.failure('الأمر خارج القائمة البيضاء أو يحتوي معاملات shell محظورة.');
  final seconds=(p['timeout_seconds'] as num?)?.toInt()??60;if(seconds<1||seconds>1800)return StepResult.failure('المهلة يجب أن تكون بين 1 و1800 ثانية.');
  final r=await s.executeInInteractive(command,timeout:Duration(seconds:seconds));
  final data={'stdout':r.stdout,'stderr':r.stderr,'exit_code':r.exitCode,'duration_ms':r.duration.inMilliseconds,'shell':r.shell};
  return r.exitCode==0?StepResult.success('اكتمل الأمر (exit 0).',data:data,duration:r.duration):StepResult.failure('فشل الأمر (exit ${r.exitCode}): ${r.stderr.isEmpty?r.stdout:r.stderr}',duration:r.duration);
 }
 @override Future<StepResult> executeCancellable(Map<String,dynamic> p,CancellationToken? token)async{
  if(token==null)return execute(p);token.throwIfCancelled();final s=environment.terminal;if(s==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final command=p['command']?.toString()??'';if(!_allowed(command))return StepResult.failure('الأمر خارج القائمة البيضاء.');
  final seconds=(p['timeout_seconds'] as num?)?.toInt()??60;if(seconds<1||seconds>1800)return StepResult.failure('مهلة غير صالحة.');
  final sub=token.onCancel.listen((_)=>unawaited(s.interruptInteractive()));try{return await execute(p);}finally{await sub.cancel();}
 }
}