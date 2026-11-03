import 'dart:async';
import '../../../agent/core/agent_models.dart';
import '../../../agent/core/cancellation_token.dart';
import '../../../agent/tools/tool.dart';
import '../../environment/agent_environment.dart';
import '../../terminal/command_registry.dart';
import '../../terminal/environment_detector.dart';
import '../../terminal/environment_router.dart';
import '../../terminal/path_policy.dart';

class TerminalTool extends AgentTool {
 final AgentEnvironment environment;
 TerminalTool(this.environment,{EnvironmentRouter? router}) : router=router??EnvironmentRouter(
  detector:EnvironmentDetector(environment:environment,terminal:environment.terminal),
  registry:CommandRegistry(),
 ),pathPolicy=PathPolicy(allowedRoots:[environment.sandboxRoot.path]);
 final EnvironmentRouter router;
 final PathPolicy pathPolicy;
 @override String get name=>'run_command';
 @override String get description=>'تشغيل أمر محدود داخل مجلد مشروع sandbox عبر Zion native PTY وبعد موافقة المستخدم.';
 @override Map<String,dynamic> get parameters=>const {
  'command':{'type':'string','required':true},
  'timeout_seconds':{'type':'integer','required':false},
  'working_directory':{'type':'string','required':false,'description':'مجلد نسبي داخل sandbox/projects'},
 };
 @override Set<AgentPermission> get permissions=>const {AgentPermission.process};
 @override bool requiresApproval(Map<String,dynamic> p)=>true;

 bool _allowed(String command){
  final value=command.trim();
  if(value.isEmpty||value.length>2000)return false;
  const forbidden=['|','>','<','&',';','\,'\\','\n','\r','\u0000'];
  if(forbidden.any(value.contains))return false;
  final args=value.split(RegExp(r'\s+'));
  final executable=args.first;
  final rest=args.skip(1).toList();
  if(rest.any((arg)=>!RegExp(r'^[A-Za-z0-9_./-]+$').hasMatch(arg)||arg.contains('..')||arg.startsWith('-')||arg.startsWith('/')))return false;
  if(const {'ls','cat','grep','find','wc','head','tail'}.contains(executable))return true;
  if(executable=='git'&&rest.isNotEmpty)return const {'status','diff','log'}.contains(rest.first)&&rest.skip(1).every((arg)=>!arg.startsWith('!'));
  if(executable=='npm'&&rest.length==1)return rest.first=='test';
  if(executable=='npm'&&rest.length==2)return rest[0]=='run'&&rest[1]=='build';
  if(executable=='flutter'&&rest.length==1)return const {'analyze','test'}.contains(rest.first);
  if(executable=='dart'&&rest.length==1)return const {'analyze','format'}.contains(rest.first);
  return false;
 }

 String _quote(String value)=>"'"+value.replaceAll("'","'\\''")+"'";

 @override Future<StepResult> execute(Map<String,dynamic> params)async{
  final service=environment.terminal;
  if(service==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final raw=params['command']?.toString()??'';
  if(!_allowed(raw))return StepResult.failure('الأمر خارج القائمة البيضاء أو يحتوي معاملات shell محظورة.');
  final directory=await environment.resolveWorkspaceDirectory(params['working_directory']?.toString()??'.');
  if(directory==null)return StepResult.failure('مجلد العمل غير موجود أو خارج sandbox/projects.');
  final seconds=(params['timeout_seconds'] as num?)?.toInt()??60;
  if(seconds<1||seconds>1800)return StepResult.failure('المهلة يجب أن تكون بين 1 و1800 ثانية.');
  final pathCheck=await pathPolicy.checkAsync(raw,workingDirectory:directory.path);
  if(!pathCheck.allowed)return StepResult.failure('رفض فحص المسار: ${pathCheck.reason}');
  final execution=await router.route(raw);
  final command='cd ${_quote(directory.path)} && $raw';
  final result=await service.executeInInteractive(command,timeout:execution.timeout.inSeconds>seconds?Duration(seconds:seconds):execution.timeout,runtime:execution.runtimeName);
  final data={'stdout':result.stdout,'stderr':result.stderr,'exit_code':result.exitCode,
   'duration_ms':result.duration.inMilliseconds,'shell':result.shell,'working_directory':directory.path};
  return result.exitCode==0
   ?StepResult.success('اكتمل الأمر (exit 0).',data:data,duration:result.duration)
   :StepResult.failure('فشل الأمر (exit ${result.exitCode}): ${result.stderr.isEmpty?result.stdout:result.stderr}',duration:result.duration);
 }

 @override Future<StepResult> executeCancellable(Map<String,dynamic> params,CancellationToken? token)async{
  if(token==null)return execute(params);
  token.throwIfCancelled();
  final service=environment.terminal;
  if(service==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final subscription=token.onCancel.listen((_)=>unawaited(service.interruptInteractive()));
  try{return await execute(params);}finally{await subscription.cancel();}
 }
},'(',')','`','\\','\n','\r','\u0000'];
  if(forbidden.any(value.contains))return false;
  final args=value.split(RegExp(r'\s+'));
  final executable=args.first;
  final rest=args.skip(1).toList();
  if(rest.any((arg)=>!RegExp(r'^[A-Za-z0-9_./-]+$').hasMatch(arg)||arg.contains('..')||arg.startsWith('-')||arg.startsWith('/')))return false;
  if(const {'ls','cat','grep','find','wc','head','tail'}.contains(executable))return true;
  if(executable=='git'&&rest.isNotEmpty)return const {'status','diff','log'}.contains(rest.first)&&rest.skip(1).every((arg)=>!arg.startsWith('!'));
  if(executable=='npm'&&rest.length==1)return rest.first=='test';
  if(executable=='npm'&&rest.length==2)return rest[0]=='run'&&rest[1]=='build';
  if(executable=='flutter'&&rest.length==1)return const {'analyze','test'}.contains(rest.first);
  if(executable=='dart'&&rest.length==1)return const {'analyze','format'}.contains(rest.first);
  return false;
 }

 String _quote(String value)=>"'"+value.replaceAll("'","'\\''")+"'";

 @override Future<StepResult> execute(Map<String,dynamic> params)async{
  final service=environment.terminal;
  if(service==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final raw=params['command']?.toString()??'';
  if(!_allowed(raw))return StepResult.failure('الأمر خارج القائمة البيضاء أو يحتوي معاملات shell محظورة.');
  final directory=await environment.resolveWorkspaceDirectory(params['working_directory']?.toString()??'.');
  if(directory==null)return StepResult.failure('مجلد العمل غير موجود أو خارج sandbox/projects.');
  final seconds=(params['timeout_seconds'] as num?)?.toInt()??60;
  if(seconds<1||seconds>1800)return StepResult.failure('المهلة يجب أن تكون بين 1 و1800 ثانية.');
  final pathCheck=await pathPolicy.checkAsync(raw,workingDirectory:directory.path);
  if(!pathCheck.allowed)return StepResult.failure('رفض فحص المسار: ${pathCheck.reason}');
  final execution=await router.route(raw);
  final command='cd ${_quote(directory.path)} && $raw';
  final result=await service.executeInInteractive(command,timeout:execution.timeout.inSeconds>seconds?Duration(seconds:seconds):execution.timeout,runtime:execution.runtimeName);
  final data={'stdout':result.stdout,'stderr':result.stderr,'exit_code':result.exitCode,
   'duration_ms':result.duration.inMilliseconds,'shell':result.shell,'working_directory':directory.path};
  return result.exitCode==0
   ?StepResult.success('اكتمل الأمر (exit 0).',data:data,duration:result.duration)
   :StepResult.failure('فشل الأمر (exit ${result.exitCode}): ${result.stderr.isEmpty?result.stdout:result.stderr}',duration:result.duration);
 }

 @override Future<StepResult> executeCancellable(Map<String,dynamic> params,CancellationToken? token)async{
  if(token==null)return execute(params);
  token.throwIfCancelled();
  final service=environment.terminal;
  if(service==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final subscription=token.onCancel.listen((_)=>unawaited(service.interruptInteractive()));
  try{return await execute(params);}finally{await subscription.cancel();}
 }
}