import '../core/agent_models.dart';
import '../environments/environment_manager.dart';
import 'tool.dart';

class PythonTool extends AgentTool {
  String get name=>'python';
  String get description=>'تشغيل Python داخل مساحة عمل المهمة. هذه ليست عزلة kernel حقيقية.';
  Map<String,dynamic> get parameters=>const {'code':'string','environment':'string','timeout':'int'};
  Future<StepResult> execute(Map<String,dynamic> p) async {
    final code=p['code']?.toString();
    if(code==null||code.trim().isEmpty)return StepResult.failure('code مطلوب.');
    final env=await EnvironmentManager.getOrCreate(p['environment']?.toString()??'default');
    try{
      final script=env.filesDir.path+'/main.py'; await scriptFile(env,script,code);
      final r=await env.runProcess('python3',[script],timeout:Duration(seconds:(p['timeout'] as num?)?.toInt()??60));
      if(r.exitCode==0)return StepResult.success('اكتمل Python.',data:{'stdout':r.stdout,'stderr':r.stderr,'exitCode':r.exitCode,'environment':env.name});
      return StepResult.failure(r.stderr.isEmpty?r.stdout:r.stderr);
    }catch(e){return StepResult.failure('Python غير متاح أو فشل التنفيذ: '+e.toString());}
  }
  Future<void> scriptFile(AgentEnvironment env,String path,String code) async {
    final f=File(path); await f.parent.create(recursive:true); await f.writeAsString(code);
  }
}
