import '../../../agent/core/agent_models.dart';
import '../../../agent/tools/tool.dart';
import 'github_client.dart';
class GitHubReadTool extends AgentTool {
 final GitHubClient client;GitHubReadTool(this.client);
 @override String get name=>'github_read';
 @override String get description=>'قراءة ملف أو شجرة المستودع أو فحوص CI أو بيانات تشغيل GitHub Actions.';
 @override Map<String,dynamic> get parameters=>const {'action':'get_file | get_tree | get_check_runs | get_workflow_logs','owner':'string','repo':'string','path':'string','ref':'string','pr':'integer','run_id':'integer'};
 @override Set<AgentPermission> get permissions=>const {AgentPermission.network};
 @override bool get supportsReadOnlyWebRetrieval=>true;
 @override Future<StepResult> execute(Map<String,dynamic> p)async{
  final owner=p['owner']?.toString()??'',repo=p['repo']?.toString()??'';
  if(owner.isEmpty||repo.isEmpty)return StepResult.failure('owner وrepo مطلوبان');
  try{
   final action=p['action']?.toString()??'';
   final data=switch(action){
    'get_file'=>await client.getFile(owner,repo,p['path']?.toString()??'',ref:p['ref']?.toString()),
    'get_tree'=>await client.getTree(owner,repo,p['ref']?.toString()??'main'),
    'get_check_runs'=>await client.getCheckRuns(owner,repo,ref:p['ref']?.toString(),pullNumber:(p['pr'] as num?)?.toInt()),
    'get_workflow_logs'=>{'run_metadata':await client.getWorkflowLogs(owner,repo,(p['run_id'] as num).toInt())},
    _=>throw ArgumentError('إجراء قراءة غير معروف: $action')
   };
   return StepResult.success('اكتملت قراءة GitHub: $action',data:data);
  }catch(e){return StepResult.failure('فشل GitHub read: $e');}
 }
}