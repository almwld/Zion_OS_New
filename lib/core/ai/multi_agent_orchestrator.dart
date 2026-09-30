import 'long_term_memory.dart';
enum AgentRole { orchestrator, terminal, security, network, system, learning, reporter }
enum AgentRisk { safe, review, blocked }
class AgentResult {final AgentRole role;final String summary;final AgentRisk risk;final Map<String,dynamic> data;const AgentResult({required this.role,required this.summary,required this.risk,this.data=const {}});}
class MultiAgentOrchestrator {
 MultiAgentOrchestrator({LongTermAIMemory? memory}):memory=memory??LongTermAIMemory(); final LongTermAIMemory memory;
 Future<List<AgentResult>> analyze(String request) async {await memory.load();final results=<AgentResult>[];final normalized=request.trim();results.add(_route(normalized));if(_looksLikeSecurity(normalized))results.add(_security(normalized));if(_looksLikeNetwork(normalized))results.add(_network(normalized));if(_looksLikeSystem(normalized))results.add(_system(normalized));results.add(AgentResult(role:AgentRole.learning,summary:'تم ربط الطلب بالذاكرة المحلية؛ لا يتم تنفيذ أوامر تلقائية.',risk:AgentRisk.safe,data:{'memoryMatches':memory.search(normalized,limit:5).length}));results.add(AgentResult(role:AgentRole.reporter,summary:'تحليل متعدد الوكلاء مكتمل: \${results.length} وكلاء.',risk:AgentRisk.safe,data:{'roles':results.map((e)=>e.role.name).toList()}));await memory.remember(kind:'agent-analysis',text:normalized,metadata:{'roles':results.map((e)=>e.role.name).toList()});return results;}
 AgentResult _route(String s)=>AgentResult(role:AgentRole.orchestrator,summary:'تم توجيه الطلب إلى الوكلاء المحليين المناسبين.',risk:AgentRisk.safe,data:{'request':s});
 AgentResult _security(String s)=>AgentResult(role:AgentRole.security,summary:'تحليل دفاعي فقط: يمكن فحص مؤشرات الجهاز والصلاحيات والسجلات دون استغلال أو تجاوز حماية.',risk:AgentRisk.review,data:{'request':s});
 AgentResult _network(String s)=>AgentResult(role:AgentRole.network,summary:'يمكن تحليل واجهات واتصال الجهاز والشبكات التي يملكها المستخدم. لا يبدأ فحص أهداف خارجية تلقائياً.',risk:AgentRisk.review,data:{'request':s});
 AgentResult _system(String s)=>AgentResult(role:AgentRole.system,summary:'تحليل محلي لحالة النظام والموارد دون تغيير إعدادات تلقائياً.',risk:AgentRisk.safe,data:{'request':s});
 bool _looksLikeSecurity(String s)=>RegExp(r'أمن|حماية|ثغرة|security|vulner',caseSensitive:false).hasMatch(s);
 bool _looksLikeNetwork(String s)=>RegExp(r'شبك|wifi|network|dns|اتصال',caseSensitive:false).hasMatch(s);
 bool _looksLikeSystem(String s)=>RegExp(r'نظام|cpu|ram|storage|battery|system',caseSensitive:false).hasMatch(s);
}
