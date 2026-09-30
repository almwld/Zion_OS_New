import 'dart:convert';
enum AgentState { idle, planning, executing, evaluating, waitingApproval, completed, failed, cancelled }
enum AgentRisk { safe, review, blocked }
enum AgentPermission { readOnly, localWrite, network, process, externalSideEffect }
class AgentStep {
 final String id,description,tool; final Map<String,dynamic> params; final bool requiresEvaluation,requiresApproval; final AgentRisk risk; final AgentPermission permission;
 const AgentStep({required this.id,required this.description,required this.tool,this.params=const {},this.requiresEvaluation=false,this.risk=AgentRisk.safe,this.requiresApproval=false,this.permission=AgentPermission.readOnly});
 AgentStep copyWith({AgentRisk? risk})=>AgentStep(id:id,description:description,tool:tool,params:params,requiresEvaluation:requiresEvaluation,risk:risk??this.risk,requiresApproval:requiresApproval,permission:permission);
 Map<String,dynamic> toJson()=>{'id':id,'description':description,'tool':tool,'params':params,'requiresEvaluation':requiresEvaluation,'requiresApproval':requiresApproval,'risk':risk.name,'permission':permission.name};
}
class AgentPlan {
 final String task; final List<AgentStep> steps; const AgentPlan({this.task='',required this.steps});
 String toJsonString()=>jsonEncode({'task':task,'steps':steps.map((e)=>e.toJson()).toList()});
}
class StepResult {
 final bool success; final String summary; final dynamic data; final String? error; final Duration duration;
 const StepResult({required this.success,required this.summary,this.data,this.error,this.duration=Duration.zero});
 factory StepResult.success(String summary,{dynamic data,Duration duration=Duration.zero})=>StepResult(success:true,summary:summary,data:data,duration:duration);
 factory StepResult.failure(String error,{Duration duration=Duration.zero})=>StepResult(success:false,summary:'فشل التنفيذ',error:error,duration:duration);
}
class AgentResult {
 final bool success; final String task; final List<StepResult> steps; final String? report; final String? error;
 const AgentResult({required this.success,required this.task,this.steps=const [],this.report,this.error});
 factory AgentResult.error(String task,String error)=>AgentResult(success:false,task:task,error:error);
}
class AgentEvent { final DateTime timestamp; final String message; final AgentState state; const AgentEvent({required this.timestamp,required this.message,required this.state}); }
class AgentStepResult {
 final bool success; final String summary; final dynamic data; final String? error; final Duration duration;
 const AgentStepResult({required this.success,required this.summary,this.data,this.error,this.duration=Duration.zero});
 factory AgentStepResult.ok(String summary,{dynamic data,Duration duration=Duration.zero})=>AgentStepResult(success:true,summary:summary,data:data,duration:duration);
 factory AgentStepResult.fail(String error,{Duration duration=Duration.zero})=>AgentStepResult(success:false,summary:'فشل التنفيذ',error:error,duration:duration);
}
class AgentTaskResult {
 final bool success; final String task; final AgentState state; final AgentPlan? plan; final List<AgentStepResult> results; final String report;
 const AgentTaskResult({required this.success,required this.task,required this.state,this.plan,this.results=const [],this.report=''});
 factory AgentTaskResult.failure(String task,String report,{AgentPlan? plan,List<AgentStepResult> results=const []})=>AgentTaskResult(success:false,task:task,state:AgentState.failed,plan:plan,results:results,report:report);
}