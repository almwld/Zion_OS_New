import '../../../agent/core/agent_models.dart';
import '../../../agent/tools/tool.dart';
import '../../environment/agent_environment.dart';
class EnvironmentStatusTool extends AgentTool {
 final AgentEnvironment environment;
 EnvironmentStatusTool(this.environment);
 @override String get name=>'environment_status';
 @override String get description=>'فحص جاهزية مجلد sandbox وZion PTY وPython وGit في Userland.';
 @override Map<String,dynamic> get parameters=>const {};
 @override Set<AgentPermission> get permissions=>const {AgentPermission.readOnly};
 @override Future<StepResult> execute(Map<String,dynamic> params)async{
  try{await environment.prepareSandbox();final status=await environment.inspect();
   return StepResult.success(status.isReady?'بيئة التنفيذ الأساسية جاهزة.':'نتيجة فحص البيئة؛ بعض المكونات غير متاحة.',data:status.toJson());
  }catch(e){return StepResult.failure('فشل فحص البيئة: $e');}
 }
}