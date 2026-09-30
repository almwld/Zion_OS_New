import '../../ai/llama_service.dart'; import '../core/agent_models.dart'; import 'tool.dart';
class AITool extends AgentTool {
  final LlamaService service; AITool({LlamaService? service}):service=service??LlamaService();
  String get name=>'ai'; String get description=>'تحليل أو توليد نص باستخدام GGUF المحلي المحمل.';
  Map<String,dynamic> get parameters=>const {'prompt':'string','maxTokens':'int','temperature':'double'};
  Future<StepResult> execute(Map<String,dynamic> p) async {final prompt=p['prompt']?.toString().trim();if(prompt==null||prompt.isEmpty)return StepResult.failure('prompt مطلوب.');final r=await service.generate(prompt,maxTokens:(p['maxTokens'] as num?)?.toInt()??512,temperature:(p['temperature'] as num?)?.toDouble()??0.7);if(r.startsWith('ERROR:'))return StepResult.failure(r);return StepResult.success('اكتمل التحليل المحلي.',data:r);}
}
