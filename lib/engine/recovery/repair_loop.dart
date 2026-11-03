import 'dart:convert';
import '../approval/approval_gate.dart';
import '../config/engine_config.dart';
import '../providers/ai_provider.dart';
import '../tools/github/github_client.dart';
import '../tools/github/build_monitor.dart';
import 'recovery_engine.dart';
class RepairOutcome {
 final bool success;final int cycles;final String report;
 const RepairOutcome({required this.success,required this.cycles,required this.report});
}
class RepairLoop {
 final EngineConfig config;final RecoveryEngine recovery;final ApprovalGate approvals;
 final GitHubClient github;final BuildMonitor monitor;final AIProvider Function() provider;
 RepairLoop({required this.config,required this.recovery,required this.approvals,required this.github,required this.monitor,required this.provider});
 Future<RepairOutcome> run({required String taskId,required String owner,required String repo,required String branch,required String goal,required String failure,required String logs})async{
  var reason=failure;var currentLogs=logs;final max=config.maxRepairCycles.clamp(0,5).toInt();
  for(var cycle=1;cycle<=max;cycle++){
   try{final fetched=await github.getLatestFailedWorkflowLogs(owner,repo,branch);if(fetched!=null&&fetched.isNotEmpty)currentLogs=fetched;}catch(_){}\n   final failureLogs=monitor.extractFailureReason(currentLogs);\n   final suggestion=await recovery.suggest(goal:goal,failure:reason,logs:failureLogs,context:{'owner':owner,'repo':repo,'branch':branch,'cycle':cycle});
   final raw=await provider().generate(systemPrompt:'أخرج JSON فقط بالمفاتيح filePath وcontent وcommitMessage. تعديل ملف واحد فقط.',
    prompt:'أصلح المشكلة دون تغيير غير ذي صلة. الهدف: $goal\nالتشخيص: ${suggestion.diagnosis}\nالخطة: ${suggestion.repairPrompt}\nالسجلات: $failureLogs',
    maxTokens:config.maxTokensPerStep,temperature:0.1);
   Map<String,dynamic> change;
   try{final a=raw.indexOf('{'),b=raw.lastIndexOf('}');change=jsonDecode(raw.substring(a,b+1)) as Map<String,dynamic>;}
   catch(_){return RepairOutcome(success:false,cycles:cycle,report:'تعذر قراءة JSON الخاص بالتعديل');}
   final path=change['filePath']?.toString()??'',content=change['content']?.toString();
   if(path.isEmpty||content==null)return RepairOutcome(success:false,cycles:cycle,report:'مسار الملف أو محتواه مفقود');
   final approval=await approvals.request(ApprovalRequest(id:'$taskId-repair-$cycle',taskId:taskId,
    action:'تعديل الملف $path: ${suggestion.diagnosis}',risk:'مرتفع',
    details:{'filePath':path,'content':content,
      'commitMessage':change['commitMessage']?.toString()??'fix: repair build failure','branch':branch},
    createdAt:DateTime.now()));
   if(!approval.approved)return RepairOutcome(success:false,cycles:cycle,report:'رُفض الإصلاح: ${approval.reason??''}');
   final current=await github.getFile(owner,repo,path,ref:branch);
   final sha=current['sha']?.toString();if(sha==null)return RepairOutcome(success:false,cycles:cycle,report:'تعذر الحصول على SHA للملف');
   await github.updateFile(owner,repo,path,content:content,sha:sha,branch:branch,message:change['commitMessage']?.toString()??'fix: repair build failure');
   final result=await monitor.waitForBuild(owner:owner,repo:repo,ref:branch);
   if(result.success)return RepairOutcome(success:true,cycles:cycle,report:'نجح البناء بعد دورة الإصلاح $cycle');
   reason=result.summary;currentLogs=reason;
  }
  return RepairOutcome(success:false,cycles:max,report:'انتهت دورات الإصلاح دون نجاح البناء');
 }
}