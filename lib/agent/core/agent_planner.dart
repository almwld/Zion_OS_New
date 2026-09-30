import 'dart:convert';
import '../../ai/llama_service.dart';
import 'agent_models.dart';
class AgentPlanner {
 final LlamaService service;
 AgentPlanner({LlamaService? service}):service=service??LlamaService();
 Future<AgentPlan> create(String task)async{
  final prompt='حوّل المهمة إلى خطة JSON. المهمة: '+task+'\\nاستخدم read-only افتراضياً. أي كتابة أو عملية أو شبكة يجب وسم صلاحيتها. لا تولد استغلالاً أو تجاوز حماية أو سرقة بيانات اعتماد. JSON فقط.';
  try{
   final response=await service.generate(prompt,maxTokens:900,temperature:0.2);
   final start=response.indexOf('{'),end=response.lastIndexOf('}');
   if(start>=0&&end>start){
    final decoded=Map<String,dynamic>.from(jsonDecode(response.substring(start,end+1)) as Map);
    final raw=decoded['steps']; if(raw is List){
     final steps=<AgentStep>[];
     for(var i=0;i<raw.length;i++){final m=Map<String,dynamic>.from(raw[i] as Map);final p=_permission(m['permission']);steps.add(AgentStep(id:(m['id']??i+1).toString(),description:(m['description']??'خطوة').toString(),tool:(m['tool']??'ai').toString(),params:Map<String,dynamic>.from(m['params']??{}),permission:p,requiresApproval:m['requiresApproval']==true||p!=AgentPermission.readOnly));}
     if(steps.isNotEmpty)return AgentPlan(task:task,steps:steps);
    }
   }
  }catch(_){}
  return AgentPlan(task:task,steps:[AgentStep(id:'1',description:'تحليل المهمة محلياً',tool:'ai',params:{'prompt':task})]);
 }
 AgentPermission _permission(dynamic v){switch(v.toString()){case 'localWrite':return AgentPermission.localWrite;case 'network':return AgentPermission.network;case 'process':return AgentPermission.process;case 'externalSideEffect':return AgentPermission.externalSideEffect;default:return AgentPermission.readOnly;}}
}