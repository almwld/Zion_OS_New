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
  List<LlamaModel> _availableModels = <LlamaModel>[];
  LlamaModel? _selected;
  bool _loading = true;
  bool _loadingModel = false;
  bool _generating = false;
  String? _error;

  @override void initState() { super.initState(); _agent = AIAgent(); _init(); }

  Future<void> _init() async {
    try {
      // Opening the app only discovers models. Native GGUF loading can consume
      // substantial RAM, so it must be an explicit user action.
      final models = await _agent.llama.discoverModels();
      _availableModels = models
          .where((m) => m.readable && m.path.isNotEmpty)
          .toList()
        ..sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
      if (_availableModels.isNotEmpty) {
        _selected = _availableModels.first;
        _error = 'تم العثور على نموذج محلي. اضغط زر تحميل النموذج لبدء المحرك.';
      } else {
        _error = 'لم يتم العثور على نموذج GGUF. استخدم زر الاستيراد لاختيار نموذج من الهاتف.';
      }
    } catch (e) {
      _error = 'تعذر فحص نماذج الذكاء المحلي: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadSelected() async {
    final model = _selected;
    if (model == null || _loading || _loadingModel) return;
    setState(() {
      _loadingModel = true;
      _error = 'جارٍ تحميل النموذج محلياً؛ قد يستغرق ذلك وقتاً حسب حجمه وذاكرة الجهاز.';
    });
    try {
      final ok = await _agent.initialize(
        modelPath: model.path,
        role: widget.role,
        nThreads: 2,
      );
      if (!mounted) return;
      setState(() {
        _error = ok
            ? null
            : 'تعذر تحميل النموذج. اختر نموذج GGUF أصغر أو متوافقاً مع الجهاز.';
        if (ok) {
          _messages.add(AgentMessage(
            role: 'assistant',
            content: 'تم تحميل ${model.name}. المعالجة محلية دون اتصال.',
          ));
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحميل النموذج: $e');
    } finally {
      if (mounted) setState(() => _loadingModel = false);
    }
  }

  Future<void> _pick() async {
    try {
      final model = await _agent.llama.pickAndImportModel();
      if (model == null || !mounted) return;
      setState(() {
        _availableModels = [model, ..._availableModels.where((m) => m.path != model.path)];
        _selected = model;
        _error = 'تم استيراد النموذج. اضغط زر تحميل النموذج لبدء المحرك.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر استيراد النموذج: $e');
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _generating) return;
    if (!_agent.isInitialized) {
      setState(() => _messages.add(const AgentMessage(
        role: 'assistant',
        content: 'حمّل نموذج GGUF أولاً باستخدام زر الذاكرة بالأعلى.',
      )));
      return;
    }
    setState(() { _messages.add(AgentMessage(role: 'user', content: text)); _input.clear(); _generating = true; });
    try {
      final response = await _agent.chat(text);
      if (mounted) setState(() => _messages.add(AgentMessage(role: 'assistant', content: response)));
    } catch (e) {
      if (mounted) setState(() => _messages.add(AgentMessage(
        role: 'assistant',
        content: 'فشل الاستدلال المحلي: ' + e.toString(),
      )));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 180), curve: Curves.easeOut); });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zion Offline AI'), actions: [IconButton(onPressed: _loading || _loadingModel || _selected == null ? null : _loadSelected, tooltip: 'تحميل النموذج', icon: const Icon(Icons.memory)), IconButton(onPressed: _loading || _loadingModel ? null : _pick, tooltip: 'استيراد نموذج GGUF', icon: const Icon(Icons.folder_open)), IconButton(onPressed: () => setState(() { _messages.clear(); _agent.clearHistory(); }), icon: const Icon(Icons.delete_outline))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        if (_loadingModel) const LinearProgressIndicator(),
        if (_selected != null) ListTile(leading: const Icon(Icons.memory), title: Text(_selected!.name), subtitle: Text(_selected!.path, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Chip(label: Text(_agent.isInitialized ? 'OFFLINE' : 'غير محمل'))),
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
