import 'dart:io';
import '../../../agent/core/agent_models.dart';
import '../../../agent/core/cancellation_token.dart';
import '../../../agent/tools/tool.dart';
import '../../environment/agent_environment.dart';
class PythonTool extends AgentTool {
 final AgentEnvironment environment;PythonTool(this.environment);
 @override String get name=>'run_python';
 @override String get description=>'تشغيل سكربت Python داخل مساحة Zion sandbox بمهلة محددة وموافقة صريحة.';
 @override Map<String,dynamic> get parameters=>const {'code':{'type':'string','required':true},'timeout_seconds':{'type':'integer','required':false}};
 @override Set<AgentPermission> get permissions=>const {AgentPermission.process,AgentPermission.localWrite};
 @override bool requiresApproval(Map<String,dynamic> p)=>true;
 String _quote(String v) => "'" + v.replaceAll("'", "'\\''") + "'";
 @override Future<StepResult> executeCancellable(Map<String,dynamic> p,CancellationToken? token)async{
  if(token==null)return execute(p);token.throwIfCancelled();
  final service=environment.terminal;if(service==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final subscription=token.onCancel.listen((_)=>service.interruptInteractive());
  try{return await execute(p);}finally{await subscription.cancel();}
 }
 @override Future<StepResult> execute(Map<String,dynamic> p)async{
  final terminal=environment.terminal;if(terminal==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final code=p['code']?.toString();if(code==null||code.trim().isEmpty||code.length>100000)return StepResult.failure('كود Python فارغ أو يتجاوز 100KB.');
  final seconds=(p['timeout_seconds'] as num?)?.toInt()??30;if(seconds<1||seconds>300)return StepResult.failure('مهلة Python يجب أن تكون بين 1 و300 ثانية.');
  final file=File('${environment.tempDirectory.path}/agent_${DateTime.now().microsecondsSinceEpoch}.py');
  try{await environment.prepareSandbox();await file.writeAsString(code,flush:true);
   final r=await terminal.executeInInteractive('${environment.pythonCommand} -I ${_quote(file.path)}',timeout:Duration(seconds:seconds));
   final data={'stdout':r.stdout,'stderr':r.stderr,'exit_code':r.exitCode,'duration_ms':r.duration.inMilliseconds};
   return r.exitCode==0?StepResult.success('Python اكتمل (exit 0).',data:data,duration:r.duration):StepResult.failure('فشل Python (exit ${r.exitCode}): ${r.stderr.isEmpty?r.stdout:r.stderr}',duration:r.duration);
  }catch(e){return StepResult.failure('تعذر تشغيل Python: $e');}finally{try{if(await file.exists())await file.delete();}catch(_){}}
 }
}