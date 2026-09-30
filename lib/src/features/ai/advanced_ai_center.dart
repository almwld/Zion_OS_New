
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/ai/ai_knowledge_base.dart';
import '../../../core/ai/adaptive_ai_profile.dart';
import '../../../core/ai/long_term_memory.dart';
import '../../../core/ai/local_ai_capabilities.dart';
import '../../../core/ai/multi_agent_orchestrator.dart';
import '../../../core/ai/smart_ai_controls.dart';

class AdvancedAICenter extends StatefulWidget {
  const AdvancedAICenter({super.key});
  @override State<AdvancedAICenter> createState() => _AdvancedAICenterState();
}
class _AdvancedAICenterState extends State<AdvancedAICenter> {
  final _input = TextEditingController();
  final _memory = LongTermAIMemory();
  late final _orchestrator = MultiAgentOrchestrator(memory: _memory);
  late final _kb = AIKnowledgeBase(_memory);
  final _controls = SmartAIControls();
  final _profile = AdaptiveAIProfile();
  final _speech = stt.SpeechToText();
  bool _listening = false, _busy = false, _speechReady = false;
  List<AgentResult> _results = [];
  List<AIMemoryEntry> _memoryResults = [];
  String _generated = '';

  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    await Future.wait([_memory.load(), _controls.load(), _profile.load()]);
    _speechReady = await _speech.initialize();
    if (mounted) setState(() {});
  }
  @override void dispose() { _input.dispose(); _speech.stop(); super.dispose(); }

  Future<void> _analyze() async {
    final q = _input.text.trim(); if (q.isEmpty) return;
    setState(() => _busy = true);
    _results = await _orchestrator.analyze(q);
    await _profile.recordCommand();
    if (mounted) setState(() => _busy = false);
  }
  Future<void> _listen() async {
    if (!_speechReady) return;
    if (_listening) { await _speech.stop(); setState(() => _listening = false); return; }
    setState(() => _listening = true);
    await _speech.listen(onResult: (r) {
      _input.text = r.recognizedWords;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
      if (r.finalResult && mounted) setState(() => _listening = false);
    }, localeId: 'ar-YE');
  }
  Future<void> _searchMemory() async { _memoryResults = _memory.search(_input.text); setState(() {}); }
  Future<void> _generateUI() async {
    final q = _input.text.trim(); if (q.isEmpty) return;
    setState(() => _generated = 'مخطط واجهة محلي: ' + q + '\n\nالمكونات المقترحة: شاشة رئيسية، حالة تشغيل حقيقية، إجراءات صريحة، سجل، وحالة خطأ. لم يتم توليد أو تنفيذ كود تلقائياً.');
    await _memory.remember(kind: 'ui-generation', text: q);
  }
  Future<void> _saveLesson() async {
    final q = _input.text.trim(); if (q.isEmpty) return;
    await _kb.recordFailure(q, 'ملاحظة يدوية', 'راجع النتيجة قبل التطبيق');
    setState(() {});
  }
  Widget _card(String title, Widget child) => Card(
    color: const Color(0xFF101923),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title, style: const TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)), const SizedBox(height: 10), child],
    )),
  );

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070B10),
    appBar: AppBar(title: const Text('Zion AI Center'), backgroundColor: const Color(0xFF101923)),
    body: ListView(padding: const EdgeInsets.all(12), children: [
      _card('الوضع المحلي', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Offline • GGUF / llama.cpp', style: TextStyle(color: Colors.white)),
        Text('المستوى: ' + _profile.level.name + ' • أوامر: ' + _profile.commands.toString(), style: const TextStyle(color: Colors.white54)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Smart Shield'), subtitle: const Text('مراقبة دفاعية محلية؛ لا إجراءات هجومية تلقائية.'), value: _controls.shieldEnabled, onChanged: (v) async { await _controls.setShield(v); setState(() {}); }),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Privacy Mode'), subtitle: const Text('حالة خصوصية محلية وإعدادات وقائية.'), value: _controls.privacyMode, onChanged: (v) async { await _controls.setPrivacy(v); setState(() {}); }),
      ])),
      _card('Multi-Agent Orchestrator', Column(children: [
        TextField(controller: _input, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'اسأل الوكلاء المحليين...', hintStyle: TextStyle(color: Colors.white38), border: OutlineInputBorder())),
        const SizedBox(height: 8),
        Row(children: [
          FilledButton.icon(onPressed: _busy ? null : _analyze, icon: const Icon(Icons.psychology), label: const Text('تحليل')),
          IconButton(onPressed: _listen, icon: Icon(_listening ? Icons.mic : Icons.mic_none)),
          TextButton(onPressed: _searchMemory, child: const Text('ذاكرة')),
        ]),
        ..._results.map((r) => ListTile(dense: true, leading: Icon(r.risk == AgentRisk.safe ? Icons.check_circle : Icons.policy, color: r.risk == AgentRisk.safe ? Colors.green : Colors.orange), title: Text(r.role.name), subtitle: Text(r.summary))),
      ])),
      _card('Scenario Simulation', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_controls.simulateChange(_input.text.isEmpty ? 'تغيير إعداد محلي' : 'تغيير: ' + _input.text)),
        const SizedBox(height: 6),
        const Text('المحاكاة لا تطبق التغيير ولا تتصل بهدف خارجي.', style: TextStyle(color: Colors.white54)),
      ])),
      _card('Self-Improving Memory', Column(children: [
        Row(children: [Text(_memory.entries.length.toString() + ' سجل محلي', style: const TextStyle(color: Colors.white)), const Spacer(), TextButton(onPressed: _saveLesson, child: const Text('حفظ درس'))]),
        ..._memoryResults.take(5).map((e) => ListTile(dense: true, title: Text(e.kind), subtitle: Text(e.text))),
      ])),
      _card('AI UI Generator', Column(children: [
        FilledButton.icon(onPressed: _generateUI, icon: const Icon(Icons.auto_awesome), label: const Text('توليد مخطط واجهة')),
        if (_generated.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_generated, style: const TextStyle(color: Colors.white))),
      ])),
      _card('Personal Trainer', const Text('التدريب المحلي يشرح الأدوات والمفاهيم ويقيس التقدم. لا يمنح شهادات رسمية ولا ينفذ هجمات.')),
      _card('IoT Manager', const Text('وحدة لإدارة أجهزة يملكها المستخدم: اكتشاف، تعريف، حالة، وإجراءات مصرح بها فقط.')),
      _card('Capabilities', Wrap(spacing: 6, runSpacing: 6, children: LocalAICapabilities.names.map((e) => Chip(label: Text(e))).toList())),
      _card('Memory Search', Column(children: _memory.search(_input.text, limit: 5).map((e) => ListTile(dense: true, title: Text(e.kind), subtitle: Text(e.text))).toList())),
    ]),
  );
}
