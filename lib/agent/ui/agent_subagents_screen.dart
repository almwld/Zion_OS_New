import 'package:flutter/material.dart';
import '../../core/ai/multi_agent_orchestrator.dart';

class AgentSubagentsScreen extends StatefulWidget {
  const AgentSubagentsScreen({super.key});
  @override
  State<AgentSubagentsScreen> createState() => _AgentSubagentsScreenState();
}

class _AgentSubagentsScreenState extends State<AgentSubagentsScreen> {
  final _request = TextEditingController();
  final _orchestrator = MultiAgentOrchestrator();
  List<AgentResult> _results = const [];
  bool _running = false;
  String? _error;

  static const _details = <AgentRole, (String, IconData)>{
    AgentRole.orchestrator: ('منسّق المهمة وتحديد مسار العمل', Icons.hub_outlined),
    AgentRole.terminal: ('مهام الطرفية وبيئة التنفيذ', Icons.terminal),
    AgentRole.security: ('مراجعة أمنية دفاعية وصلاحيات', Icons.shield_outlined),
    AgentRole.network: ('تحليل الشبكة والاتصال', Icons.lan_outlined),
    AgentRole.system: ('حالة النظام والموارد', Icons.memory_outlined),
    AgentRole.learning: ('استرجاع الذاكرة والمعرفة المحلية', Icons.psychology_outlined),
    AgentRole.reporter: ('تجميع النتائج والتقرير', Icons.summarize_outlined),
  };

  Future<void> _analyze() async {
    final request = _request.text.trim();
    if (request.isEmpty || _running) return;
    setState(() { _running = true; _error = null; _results = const []; });
    try {
      final results = await _orchestrator.analyze(request);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحليل المهمة: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  void dispose() {
    _request.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A1018);
    const panel = Color(0xFF121E29);
    const cyan = Color(0xFF35D3E8);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('الوكلاء الفرعيون'), backgroundColor: const Color(0xFF0E1722)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF294252))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.account_tree_outlined, color: cyan, size: 24),
              SizedBox(width: 9),
              Expanded(child: Text('Super Agent · Multi-Agent Routing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
            ]),
            const SizedBox(height: 8),
            const Text('حلّل المهمة ووجّهها إلى التخصصات المحلية المناسبة، ثم اعرض دور كل وكيل ومستوى المخاطر ومطابقات الذاكرة. التحليل لا ينفّذ أوامر النظام تلقائياً.',
              style: TextStyle(color: Color(0xFF9BAFBE), height: 1.5, fontSize: 12)),
            const SizedBox(height: 14),
            TextField(
              controller: _request,
              minLines: 2,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'صف المهمة التي تريد توزيعها على الوكلاء…',
                hintStyle: const TextStyle(color: Color(0xFF728898), fontSize: 12),
                filled: true, fillColor: const Color(0xFF09131D),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFF294252))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFF294252))),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _running ? null : _analyze,
              icon: _running ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
              label: Text(_running ? 'جارٍ تحليل المهمة…' : 'تحليل وتوزيع المهمة'),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        Text('التخصصات المتاحة · ${_results.isEmpty ? _details.length : _results.length}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final entry in _details.entries)
          _agentCard(entry.key, entry.value.$1, entry.value.$2, _results.where((r) => r.role == entry.key).toList()),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Color(0xFFFF8585)))),
      ]),
    );
  }

  Widget _agentCard(AgentRole role, String description, IconData icon, List<AgentResult> results) {
    const panel = Color(0xFF121E29);
    final result = results.isEmpty ? null : results.first;
    final riskColor = result == null ? const Color(0xFF8197A7) : switch (result.risk) {
      AgentRisk.safe => const Color(0xFF45D6A0),
      AgentRisk.review => const Color(0xFFFFB454),
      AgentRisk.blocked => const Color(0xFFFF7474),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: result == null ? const Color(0xFF263B4A) : riskColor.withOpacity(.45))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF173443), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF65D9E9), size: 20)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_roleLabel(role), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 3),
          Text(description, style: const TextStyle(color: Color(0xFF9BAFBE), fontSize: 11)),
          if (result != null) ...[
            const SizedBox(height: 8),
            Text(result.summary, style: const TextStyle(color: Color(0xFFD7E8EF), fontSize: 12, height: 1.45)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              _badge(_riskLabel(result.risk), riskColor),
              if (result.data['memoryMatches'] != null) _badge('مطابقات الذاكرة: ${result.data['memoryMatches']}', const Color(0xFF65D9E9)),
            ]),
          ] else
            const Padding(padding: EdgeInsets.only(top: 5), child: Text('بانتظار توجيه المهمة', style: TextStyle(color: Color(0xFF728898), fontSize: 11))),
        ])),
      ]),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(.28))),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  String _roleLabel(AgentRole role) => switch (role) {
    AgentRole.orchestrator => 'المنسّق الرئيسي',
    AgentRole.terminal => 'وكيل الطرفية',
    AgentRole.security => 'وكيل الأمن',
    AgentRole.network => 'وكيل الشبكات',
    AgentRole.system => 'وكيل النظام',
    AgentRole.learning => 'وكيل الذاكرة والتعلّم',
    AgentRole.reporter => 'وكيل التقارير',
  };

  String _riskLabel(AgentRisk risk) => switch (risk) {
    AgentRisk.safe => 'آمن',
    AgentRisk.review => 'يتطلب مراجعة',
    AgentRisk.blocked => 'محظور',
  };
}
