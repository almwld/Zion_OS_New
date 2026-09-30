import 'package:http/http.dart' as http;
import '../core/agent_models.dart';
import 'tool.dart';

class BrowserTool extends AgentTool {
  String get name=>'browser';
  String get description=>'جلب صفحات ويب والبحث النصي عبر HTTP؛ لا ينفذ JavaScript أو يسجل دخولاً تلقائياً.';
  Map<String,dynamic> get parameters=>const {'action':'fetch | search','url':'string','query':'string'};
  Future<StepResult> execute(Map<String,dynamic> p) async {
    final action=p['action']?.toString()??'fetch';
    final target=action=='search'
      ? 'https://html.duckduckgo.com/html/?q='+Uri.encodeComponent(p['query']?.toString()??'')
      : p['url']?.toString()??'';
    final uri=Uri.tryParse(target);
    if(uri==null||!{'http','https'}.contains(uri.scheme))return StepResult.failure('رابط غير صالح.');
    try{
      final r=await http.get(uri,headers:{'User-Agent':'Zion-Agent/1.0'});
      if(r.statusCode<200||r.statusCode>=400)return StepResult.failure('HTTP '+r.statusCode.toString());
      return StepResult.success('تم جلب '+r.body.length.toString()+' حرف.',data:{'url':uri.toString(),'status':r.statusCode,'content':r.body});
    }catch(e){return StepResult.failure('فشل جلب الصفحة: '+e.toString());}
  }
}
