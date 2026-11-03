import 'dart:async';
import 'github_client.dart';
class BuildStatus {
 final bool completed,success;final String summary;final Map<String,dynamic> details;
 const BuildStatus({required this.completed,required this.success,required this.summary,this.details=const {}});
}
class BuildMonitor {
 final GitHubClient github;final Duration interval,timeout;
 BuildMonitor({required this.github,this.interval=const Duration(seconds:30),this.timeout=const Duration(minutes:30)});
 Future<BuildStatus> waitForBuild({required String owner,required String repo,required String ref})async{
  final deadline=DateTime.now().add(timeout);
  while(DateTime.now().isBefore(deadline)){
   final data=await github.getCheckRuns(owner,repo,ref:ref);
   final runs=(data['check_runs'] as List? ??const []).whereType<Map>().toList();
   if(runs.isNotEmpty&&runs.every((r)=>r['status']=='completed')){
    final failed=runs.where((r)=>r['conclusion']!='success').toList();
    if(failed.isEmpty)return BuildStatus(completed:true,success:true,summary:'نجحت جميع فحوص CI',details:data);
    return BuildStatus(completed:true,success:false,summary:failed.map((r)=>'${r['name']}: ${r['conclusion']}').join('\n'),details:{'checks':data,'failed':failed});
   }
   await Future<void>.delayed(interval);
  }
  return const BuildStatus(completed:true,success:false,summary:'انتهت مهلة مراقبة البناء دون نتيجة نهائية');
 }
 String extractFailureReason(String logs,{int maxLines=50}){
  final lines=logs.split(RegExp(r'\r?\n')).where((e)=>e.trim().isNotEmpty).toList();
  return (lines.length<=maxLines?lines:lines.sublist(lines.length-maxLines)).join('\n');
 }
}