enum AgentState { idle, planning, executing, evaluating, completed, failed, cancelled }
enum AgentRisk { safe, review, blocked }
class AgentStep {
  final String id, description, tool; final Map<String,dynamic> params; final bool requiresEvaluation; final AgentRisk risk;
  const AgentStep({required this.id,required this.description,required this.tool,this.params=const {},this.requiresEvaluation=false,this.risk=AgentRisk.safe});
  AgentStep copyWith({AgentRisk? risk})=>AgentStep(id:id,description:description,tool:tool,params:params,requiresEvaluation:requiresEvaluation,risk:risk??this.risk);
}
class AgentPlan { final List<AgentStep> steps; const AgentPlan({required this.steps}); }
class StepResult {
  final bool success; final String summary; final dynamic data; final String? error;
  const StepResult({required this.success,required this.summary,this.data,this.error});
  factory StepResult.success(String summary,{dynamic data})=>StepResult(success:true,summary:summary,data:data);
  factory StepResult.failure(String error)=>StepResult(success:false,summary:'فشل التنفيذ',error:error);
}
class AgentResult {
  final bool success; final String task; final List<StepResult> steps; final String? report; final String? error;
  const AgentResult({required this.success,required this.task,this.steps=const [],this.report,this.error});
  factory AgentResult.error(String task,String error)=>AgentResult(success:false,task:task,error:error);
}
class AgentEvent { final DateTime timestamp; final String message; final AgentState state; const AgentEvent({required this.timestamp,required this.message,required this.state}); }
