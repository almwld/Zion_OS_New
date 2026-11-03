import 'dart:convert';
import '../providers/ai_provider.dart';
class RecoverySuggestion {
 final String diagnosis,repairPrompt;final List<String> actions;
 const RecoverySuggestion({required this.diagnosis,required this.repairPrompt,this.actions=const []});
}
class RecoveryEngine {
 final AIProvider Function() provider;
 final void Function(String taskId,String prompt,String output,AIProvider active)? onUsage;
 RecoveryEngine(this.provider,{this.onUsage});
 Future<RecoverySuggestion> suggest({required String taskId,required String goal,required String failure,required String logs,Map<String,dynamic> context=const {}})async{
  final bounded=logs.length>18000?logs.substring(logs.length-18000):logs;
  final prompt='حلل سبب فشل المهمة واقترح خطة إصلاح فقط. أخرج JSON بالمفاتيح diagnosis وrepairPrompt وactions. لا تدّعِ إجراء أي تعديل.\nالهدف: $goal\nالفشل: $failure\nالسجلات:\n$bounded\nالسياق: $context';
  final active=provider();
  final raw=await active.generate(prompt:prompt,systemPrompt:'أنت مهندس إصلاح برمجي. لا تختلق نتائج أو سجلات.',maxTokens:1200,temperature:0.1);
  onUsage?.call(taskId,prompt,raw,active);
  try{
   final a=raw.indexOf('{'),b=raw.lastIndexOf('}');if(a<0||b<=a)throw const FormatException();
   final map=jsonDecode(raw.substring(a,b+1)) as Map<String,dynamic>;
   return RecoverySuggestion(diagnosis:map['diagnosis']?.toString()??'سبب غير محدد',
    repairPrompt:map['repairPrompt']?.toString()??raw,actions:(map['actions'] as List? ??const []).map((e)=>e.toString()).toList());
  }catch(_){return RecoverySuggestion(diagnosis:'تعذر تحليل التشخيص المنظم',repairPrompt:raw);}
 }
}