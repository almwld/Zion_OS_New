import '../../../agent/core/agent_models.dart';
import '../../../agent/tools/tool.dart';
import 'github_client.dart';
class GitHubWriteTool extends AgentTool {
 final GitHubClient client;GitHubWriteTool(this.client);
 @override String get name=>'github_write';
 @override String get description=>'تحديث ملف أو إنشاء فرع أو فتح Pull Request. جميع العمليات تتطلب موافقة المستخدم.';
 @override Map<String,dynamic> get parameters=>const {'action':'update_file | create_branch | create_pr','owner':'string','repo':'string','path':'string','content':'string','sha':'string','message':'string','branch':'string','base':'string','title':'string','body':'string','head':'string'};
 @override Set<AgentPermission> get permissions=>const {AgentPermission.network,AgentPermission.externalSideEffect};
 @override bool requiresApproval(Map<String,dynamic> p)=>true;
 @override Future<StepResult> execute(Map<String,dynamic> p)async{
  final owner=p['owner']?.toString()??'',repo=p['repo']?.toString()??'';
  if(owner.isEmpty||repo.isEmpty)return StepResult.failure('owner وrepo مطلوبان');
  try{
   final action=p['action']?.toString()??'';
   final result=switch(action){
    'update_file'=>await client.updateFile(owner,repo,p['path'].toString(),content:p['content'].toString(),sha:p['sha'].toString(),
      message:p['message']?.toString()??'chore: update via Zion Agent',branch:p['branch']?.toString()??'main'),
    'create_branch'=>await client.createBranch(owner,repo,p['branch'].toString(),base:p['base']?.toString()??'main'),
    'create_pr'=>await client.createPullRequest(owner,repo,title:p['title'].toString(),body:p['body']?.toString()??'',
      head:p['head'].toString(),base:p['base']?.toString()??'main'),
    _=>throw ArgumentError('إجراء كتابة غير معروف: $action')
   };
   return StepResult.success('اكتملت عملية GitHub الكتابية: $action',data:result);
  }catch(e){return StepResult.failure('فشل GitHub write: $e');}
 }
}