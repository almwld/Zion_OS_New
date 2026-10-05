import '../tools/tool.dart';
import 'agent_models.dart';
class AgentToolGateway {
 final Map<String,AgentTool> _tools={}; final Set<AgentPermission> granted; final bool requireApprovalForSideEffects;
 AgentToolGateway({this.granted=const {AgentPermission.readOnly},this.requireApprovalForSideEffects=true});
 void register(AgentTool tool)=>_tools[tool.name]=tool;
 AgentTool? get(String name)=>_tools[name];
 List<AgentTool> get tools=>List.unmodifiable(_tools.values);
 String? validate(AgentStep step,{bool approved=false}) {
  final tool=_tools[step.tool]; if(tool==null)return 'الأداة غير مسجلة: '+step.tool;
  for(final p in tool.requiredPermissions(step.params)){if(!granted.contains(p))return 'صلاحية غير ممنوحة: '+p.name;}
  if(requireApprovalForSideEffects&&step.permission==AgentPermission.externalSideEffect&&!approved)return 'هذه الخطوة تتطلب موافقة صريحة';
  if(step.requiresApproval&&!approved)return 'الخطوة تتطلب موافقة صريحة';
  if(!tool.supports(step.params))return 'المعاملات غير مدعومة للأداة';
  return null;
 }
 Future<AgentStepResult> execute(AgentStep step,{bool approved=false})async{
  final error=validate(step,approved:approved); if(error!=null)return AgentStepResult.fail(error);
  final started=DateTime.now();
  try{final result=await _tools[step.tool]!.execute(step.params);return AgentStepResult(success:result.success,summary:result.summary,data:result.data,error:result.error,duration:DateTime.now().difference(started));}
  catch(e){return AgentStepResult.fail('استثناء الأداة: '+e.toString(),duration:DateTime.now().difference(started));}
 }
}