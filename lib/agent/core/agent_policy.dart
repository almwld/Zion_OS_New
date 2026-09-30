import 'agent_models.dart';
class AgentPolicyDecision { final AgentRisk risk; final String reason; final bool requiresApproval; const AgentPolicyDecision({required this.risk,required this.reason,required this.requiresApproval}); }
class AgentPolicy {
  const AgentPolicy();
  AgentPolicyDecision evaluate({required String tool,required Map<String,dynamic> params}) {
    if(tool=='shell'){
      final command=(params['command']??'').toString().trim();
      if(command.isEmpty)return const AgentPolicyDecision(risk:AgentRisk.blocked,reason:'أمر shell فارغ.',requiresApproval:false);
      if(_blockedShell(command))return const AgentPolicyDecision(risk:AgentRisk.blocked,reason:'الأمر محظور من سياسة Zion Agent.',requiresApproval:false);
      if(!_safeShell(command))return const AgentPolicyDecision(risk:AgentRisk.review,reason:'الأمر خارج قائمة التنفيذ التلقائي.',requiresApproval:true);
    }
    if(tool=='http'&&(params['method']??'GET').toString().toUpperCase()!='GET')return const AgentPolicyDecision(risk:AgentRisk.review,reason:'HTTP الذي يغيّر بيانات يحتاج موافقة.',requiresApproval:true);
    if(tool=='file'){
      final action=(params['action']??'read').toString();
      if(action!='read'&&action!='list')return const AgentPolicyDecision(risk:AgentRisk.review,reason:'تعديل الملفات يحتاج موافقة.',requiresApproval:true);
    }
    if(tool=='python')return const AgentPolicyDecision(risk:AgentRisk.review,reason:'Python يعمل في مساحة المهمة وليس sandbox نظام تشغيل حقيقياً.',requiresApproval:true);
    return const AgentPolicyDecision(risk:AgentRisk.safe,reason:'الأداة مسموحة.',requiresApproval:false);
  }
  bool _blockedShell(String command){
    final c=command.toLowerCase(); const blocked=['rm -rf /','mkfs','dd if=','shutdown','reboot','su -c','chmod 777 /','mount ','iptables -f','nmap ','masscan ','metasploit','sqlmap','hydra ','john ','aircrack'];
    return blocked.any(c.contains);
  }
  bool _safeShell(String command){
    final c=command.trim().toLowerCase();
    if(c.contains('&&')||c.contains('||')||c.contains(';')||c.contains('|'))return false;
    return RegExp(r'^(pwd|ls(\s+-[a-z-]+)?(\s+[^\s]+)?|cat\s+[^\s]+|echo\s+.+|whoami|id|uname(\s+-[a-z]+)?|date|df(\s+-[a-z]+)?|du(\s+-[a-z]+)?|ps(\s+-[a-z]+)?)$').hasMatch(c);
  }
}
