import 'package:flutter/material.dart';
import 'core/services/real_attack_core.dart';

class ZionAttackPanel extends StatefulWidget {
  const ZionAttackPanel({super.key});

  @override
  State<ZionAttackPanel> createState() => _ZionAttackPanelState();
}

class _ZionAttackPanelState extends State<ZionAttackPanel> {
  final TextEditingController _targetCtrl = TextEditingController(text: '192.168.1.1');
  final TextEditingController _customCmdCtrl = TextEditingController();
  String _output = 'جاهز للهجوم. حدد الهدف والأداة.\n';
  bool _isAttacking = false;

  Future<void> _executeAttack(String type) async {
    setState(() { _isAttacking = true; _output = 'جاري الهجوم...\n'; });

    String result = '';
    final target = _targetCtrl.text;

    switch (type) {
      case 'nmap': result = await RealAttackCore.nmapScan(target); break;
      case 'sqlmap': result = await RealAttackCore.sqlmapAttack(target.startsWith('http') ? target : 'http://$target'); break;
      case 'nikto': result = await RealAttackCore.niktoScan(target); break;
      case 'dirb': result = await RealAttackCore.dirbScan(target.startsWith('http') ? target : 'http://$target'); break;
      case 'wpscan': result = await RealAttackCore.wpscanAudit(target.startsWith('http') ? target : 'http://$target'); break;
      case 'gobuster': result = await RealAttackCore.gobusterScan(target.startsWith('http') ? target : 'http://$target'); break;
      case 'ffuf': result = await RealAttackCore.ffufFuzz(target.startsWith('http') ? target : 'http://$target'); break;
      case 'dnsenum': result = await RealAttackCore.dnsEnum(target); break;
      case 'searchsploit': result = await RealAttackCore.searchsploit(target); break;
      case 'custom': result = await RealAttackCore.customCommand(_customCmdCtrl.text); break;
      default: result = 'نوع هجوم غير معروف';
    }

    setState(() { _output += '$result\n\n─── انتهى الهجوم ───\n'; _isAttacking = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _targetCtrl, style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace'), decoration: const InputDecoration(labelText: 'الهدف (IP/URL)', labelStyle: TextStyle(color: Color(0xFF00FF41)), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          if (_isAttacking) const LinearProgressIndicator(color: Colors.red),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _attackBtn('Nmap', 'nmap', Colors.blue),
            _attackBtn('SQLmap', 'sqlmap', Colors.purple),
            _attackBtn('Nikto', 'nikto', Colors.orange),
            _attackBtn('Dirb', 'dirb', Colors.teal),
            _attackBtn('WPScan', 'wpscan', Colors.indigo),
            _attackBtn('Gobuster', 'gobuster', Colors.cyan),
            _attackBtn('FFUF', 'ffuf', Colors.amber),
            _attackBtn('DNS Enum', 'dnsenum', Colors.green),
            _attackBtn('SearchSploit', 'searchsploit', Colors.red),
          ]),
          const SizedBox(height: 16),
          TextField(controller: _customCmdCtrl, style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace'), decoration: const InputDecoration(labelText: 'أمر Kali مخصص', labelStyle: TextStyle(color: Color(0xFF00FF41)), border: OutlineInputBorder())),
          const SizedBox(height: 8),
          _attackBtn('تنفيذ الأمر المخصص', 'custom', Colors.red),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0A0E0A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1A3A1A))), child: Text(_output, style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace', fontSize: 12))),
        ],
      ),
    );
  }

  Widget _attackBtn(String label, String type, Color color) => ElevatedButton(
    style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    onPressed: _isAttacking ? null : () => _executeAttack(type),
    child: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 13)),
  );
}
