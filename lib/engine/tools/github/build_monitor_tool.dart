import '../../../agent/core/agent_models.dart';
import '../../../agent/tools/tool.dart';
import 'build_monitor.dart';
class BuildMonitorTool extends AgentTool {
 final BuildMonitor monitor;BuildMonitorTool(this.monitor);
 @override String get name=>'wait_build';
 @override String get description=>'مراقبة GitHub Check Runs حتى اكتمال البناء أو انتهاء المهلة.';
 @override Map<String,dynamic> get parameters=>const {'owner':'string','repo':'string','ref':'string'};
 @override Set<AgentPermission> get permissions=>const {AgentPermission.network};
 @override bool get supportsReadOnlyWebRetrieval=>true;
 @override Future<StepResult> execute(Map<String,dynamic> p)async{
  try{
   final s=await monitor.waitForBuild(owner:p['owner'].toString(),repo:p['repo'].toString(),ref:p['ref'].toString());
   return s.success?StepResult.success(s.summary,data:s.details):StepResult.failure(s.summary);
  }catch(e){return StepResult.failure('تعذرت مراقبة البناء: $e');}
 }
}