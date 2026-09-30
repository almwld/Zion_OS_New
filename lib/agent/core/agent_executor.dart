import 'agent_models.dart';
import 'agent_tool_gateway.dart';
import 'execution_policy.dart';
typedef AgentEventSink=void Function(String message);
class AgentExecutor {
 final AgentToolGateway gateway; final AgentExecutionPolicy policy; final AgentEventSink? onEvent;
 AgentExecutor({required this.gateway,required this.policy,this.onEvent});
 Future<AgentTaskResult> execute(AgentPlan plan,{Set<String> approvedSteps=const {}})async{
  if(plan.steps.length>policy.maxSteps)return AgentTaskResult.failure(plan.task,'الخطة تتجاوز الحد المسموح للخطوات.',plan:plan);
  final results=<AgentStepResult>[];
  for(final step in plan.steps){
   onEvent?.call('تنفيذ: '+step.description);
   final approved=approvedSteps.contains(step.id);
   final result=await gateway.execute(step,approved:approved);
   results.add(result);
   onEvent?.call(result.success?'نجح: '+result.summary:'فشل: '+(result.error??result.summary));
   if(!result.success)return AgentTaskResult.failure(plan.task,'توقفت المهمة عند الخطوة '+step.id+': '+(result.error??result.summary),plan:plan,results:results);
  }
  return AgentTaskResult(success:true,task:plan.task,state:AgentState.completed,plan:plan,results:results,report:results.map((r)=>r.summary).join('\\n'));
 }
}