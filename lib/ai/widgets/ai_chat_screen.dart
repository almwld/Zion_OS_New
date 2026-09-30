import 'package:flutter/material.dart';
import '../ai_agent.dart';
import '../llama_service.dart';

class AIChatScreen extends StatefulWidget {
  final AgentRole role;
  const AIChatScreen({super.key, this.role = AgentRole.terminalAssistant});
  @override State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late final AIAgent _agent;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <AgentMessage>[];
  LlamaModel? _selected;
  bool _loading = true;
  bool _generating = false;
  String? _error;

  @override void initState() { super.initState(); _agent = AIAgent(); _init(); }

  Future<void> _init() async {
    try {
      final models = await _agent.llama.discoverModels();
      if (models.isNotEmpty) {
        _selected = models.firstWhere((m) => m.readable, orElse: () => models.first);
        final ok = await _agent.initialize(modelPath: _selected!.path, role: widget.role);
        if (ok) _messages.add(const AgentMessage(role: 'assistant', content: '🤖 الوكيل المحلي جاهز. يعمل بالكامل دون اتصال بالإنترنت.'));
        else _error = 'تعذر تحميل نموذج GGUF المحلي.';
      } else {
        _error = 'لم يتم العثور على نموذج GGUF. اختره من ذاكرة الهاتف.';
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pick() async {
    final model = await _agent.llama.pickAndImportModel();
    if (model == null) return;
    await _agent.llama.unloadModel();
    final ok = await _agent.initialize(modelPath: model.path, role: widget.role);
    if (mounted) setState(() {
      _selected = model;
      _error = ok ? null : 'فشل تحميل النموذج.';
      if (ok) _messages.add(AgentMessage(role: 'assistant', content: 'تم تحميل ' + model.name + ' محلياً.'));
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _generating || !_agent.isInitialized) return;
    setState(() { _messages.add(AgentMessage(role: 'user', content: text)); _input.clear(); _generating = true; });
    final response = await _agent.chat(text);
    if (mounted) setState(() { _messages.add(AgentMessage(role: 'assistant', content: response)); _generating = false; });
    WidgetsBinding.instance.addPostFrameCallback((_) { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 180), curve: Curves.easeOut); });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zion Offline AI'), actions: [IconButton(onPressed: _pick, icon: const Icon(Icons.folder_open)), IconButton(onPressed: () => setState(() { _messages.clear(); _agent.clearHistory(); }), icon: const Icon(Icons.delete_outline))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        if (_selected != null) ListTile(leading: const Icon(Icons.memory), title: Text(_selected!.name), subtitle: Text(_selected!.path, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: const Chip(label: Text('OFFLINE'))),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
        Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.all(12), itemCount: _messages.length, itemBuilder: (_, i) {
          final m = _messages[i]; final user = m.role == 'user';
          return Align(alignment: user ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .84), decoration: BoxDecoration(color: user ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)), child: Text(m.content)));
        })),
        if (_generating) const LinearProgressIndicator(),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(controller: _input, minLines: 1, maxLines: 5, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder()))), const SizedBox(width: 8), IconButton.filled(onPressed: _generating ? null : _send, icon: const Icon(Icons.send))])))
      ]),
    );
  }

  @override void dispose() { _input.dispose(); _scroll.dispose(); _agent.dispose(); super.dispose(); }
}
