import 'package:http/http.dart' as http;
import '../core/agent_models.dart';
import 'tool.dart';

class BrowserTool extends AgentTool {
  String get name=>'browser';
  Set<AgentPermission> get permissions => const {AgentPermission.network};
  String get description=>'جلب صفحات ويب والبحث النصي عبر HTTP؛ لا ينفذ JavaScript أو يسجل دخولاً تلقائياً.';
  Map<String,dynamic> get parameters=>const {'action':'fetch | search','url':'string','query':'string'};
  Future<StepResult> execute(Map<String,dynamic> p) async {
    final action=p['action']?.toString()??'fetch';
    final target=action=='search'
      ? 'https://html.duckduckgo.com/html/?q='+Uri.encodeComponent(p['query']?.toString()??'')
      : p['url']?.toString()??'';
    final uri=Uri.tryParse(target);
    if(uri==null||!{'http','https'}.contains(uri.scheme))return StepResult.failure('رابط غير صالح.');
    if (uri.userInfo.isNotEmpty || _isPrivateOrLocalHost(uri.host)) {
      return StepResult.failure('تم رفض عنوان محلي أو خاص لحماية بيانات الجهاز.');
    }
    try{
      final r=await http.get(uri,headers:{'User-Agent':'Zion-Agent/1.0'});
      if(r.statusCode<200||r.statusCode>=400)return StepResult.failure('HTTP '+r.statusCode.toString());
      return StepResult.success('تم جلب '+r.body.length.toString()+' حرف.',data:{'url':uri.toString(),'status':r.statusCode,'content':r.body});
    }catch(e){return StepResult.failure('فشل جلب الصفحة: '+e.toString());}
  }

  bool _isPrivateOrLocalHost(String rawHost) {
    final host = rawHost.toLowerCase().replaceFirst(RegExp(r'\\.$'), '');
    if (host == 'localhost' || host.endsWith('.localhost') ||
        host.endsWith('.local') || host == '::1' || host == '[::1]') {
      return true;
    }
    final parts = host.split('.');
    if (parts.length == 4) {
      final octets = parts.map(int.tryParse).toList();
      if (octets.every((value) => value != null && value >= 0 && value <= 255)) {
        final a = octets[0]!, c = octets[1]!;
        return a == 0 || a == 10 || a == 127 ||
            (a == 169 && c == 254) ||
            (a == 172 && c >= 16 && c <= 31) ||
            (a == 192 && c == 168) || a >= 224;
      }
    }
    return false;
  }
}
