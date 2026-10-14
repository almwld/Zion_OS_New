import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
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
  double _temperature = 0.25;
  int _maxTokens = 128;
  static const _historyKey = 'zion_offline_ai_messages_v1';
  static const _temperatureKey = 'zion_offline_ai_temperature_v1';
  static const _maxTokensKey = 'zion_offline_ai_max_tokens_v1';
  static const _modelPathKey = 'zion_offline_ai_model_path_v1';
  String? _preferredModelPath;

  @override void initState() {
    super.initState();
    _agent = AIAgent();
    // Paint the window before invoking Android model discovery.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_init());
    });
  }

  Future<void> _init() async {
    try {
      await _restoreConversation();
      // Opening the app only discovers models. Native GGUF loading can consume
      // substantial RAM, so it must be an explicit user action.
      final models = await _agent.llama.discoverModels();
      _availableModels = models
          .where((m) => m.readable && m.path.isNotEmpty && m.sizeBytes > 0 && m.sizeBytes <= 2 * 1024 * 1024 * 1024)
          .toList()
        ..sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
      _selected = _availableModels.cast<LlamaModel?>().firstWhere(
        (m) => m?.path == _preferredModelPath,
        orElse: () => _availableModels.isEmpty ? null : _availableModels.first,
      );
      if (_availableModels.isNotEmpty) {
        _error = 'تم العثور على نموذج محلي. اضغط زر تحميل النموذج لبدء المحرك.';
      } else {
        _error = models.isEmpty
            ? 'لم يتم العثور على نموذج GGUF. استخدم زر الاستيراد لاختيار نموذج من الهاتف.'
            : 'النماذج المتاحة أكبر من حد الذاكرة الآمن (2 GiB). اختر نموذجاً أصغر لتجنب إغلاق التطبيق.';
      }
    } catch (e) {
      _error = 'تعذر فحص نماذج الذكاء المحلي: $e';
    }
    if (mounted) setState(() => _loading = false);
    _scrollToEnd();
  }

  Future<void> _restoreConversation() async {
    final prefs = await SharedPreferences.getInstance();
    _temperature = (prefs.getDouble(_temperatureKey) ?? 0.25).clamp(0.0, 1.2).toDouble();
    _maxTokens = (prefs.getInt(_maxTokensKey) ?? 128).clamp(32, 256).toInt();
    _preferredModelPath = prefs.getString(_modelPathKey);
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _messages.addAll(decoded.whereType<Map>().take(100).map((item) => AgentMessage(
        role: item['role'] == 'user' ? 'user' : 'assistant',
        content: (item['content'] ?? '').toString(),
      )).where((m) => m.content.isNotEmpty));
      _agent.restoreHistory(_messages);
    } catch (_) {
      await prefs.remove(_historyKey);
    }
  }

  Future<void> _persistConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = _messages.length > 100 ? _messages.sublist(_messages.length - 100) : _messages;
      await prefs.setString(_historyKey, jsonEncode(
        recent.map((m) => {'role': m.role, 'content': m.content}).toList(),
      ));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر حفظ سجل المحادثة على الجهاز.');
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _clearConversation() async {
    if (_generating || _loadingModel) return;
    setState(() {
      _messages.clear();
      _agent.clearHistory();
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> _loadSelected() async {
    final model = _selected;
    if (model == null || _loading || _loadingModel) return;
    if (model.sizeBytes <= 0 || model.sizeBytes > 2 * 1024 * 1024 * 1024) {
      setState(() => _error = 'حجم النموذج يتجاوز حد الذاكرة الآمن (2 GiB). اختر نموذج GGUF أصغر.');
      return;
    }
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
          _preferredModelPath = model.path;
        }
      });
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_modelPathKey, model.path);
        await _persistConversation();
      }
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
      if (model.sizeBytes <= 0 || model.sizeBytes > 2 * 1024 * 1024 * 1024) {
        setState(() => _error = 'تم اختيار النموذج لكن حجمه خارج الحد الآمن (2 GiB). اختر نموذجاً أصغر.');
        return;
      }
      setState(() {
        _availableModels = [model, ..._availableModels.where((m) => m.path != model.path)];
        _selected = model;
        _preferredModelPath = model.path;
        _error = 'تم استيراد النموذج. اضغط زر تحميل النموذج لبدء المحرك.';
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modelPathKey, model.path);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر استيراد النموذج: $e');
    }
  }

  Future<void> _showGenerationSettings() async {
    var temperature = _temperature;
    var tokens = _maxTokens;
    final result = await showModalBottomSheet<Map<String, Object>>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('إعدادات التوليد المحلي', style: Theme.of(context).textTheme.titleLarge),
              Row(children: [const Expanded(child: Text('طول الإجابة')), Text('$tokens رمزاً')]),
              Slider(value: tokens.toDouble(), min: 32, max: 256, divisions: 7, onChanged: (v) => setSheetState(() => tokens = v.round())),
              Row(children: [const Expanded(child: Text('تنوع الإجابة')), Text(temperature.toStringAsFixed(2))]),
              Slider(value: temperature, min: 0, max: 1.2, divisions: 24, onChanged: (v) => setSheetState(() => temperature = v)),
              FilledButton(onPressed: () => Navigator.pop(sheetContext, {'tokens': tokens, 'temperature': temperature}), child: const Text('حفظ الإعدادات')),
            ]),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _maxTokens = result['tokens']! as int;
      _temperature = result['temperature']! as double;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxTokensKey, _maxTokens);
    await prefs.setDouble(_temperatureKey, _temperature);
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
    await _persistConversation();
    _scrollToEnd();
    try {
      final response = await _agent.chat(text, maxTokens: _maxTokens, temperature: _temperature);
      if (mounted) { setState(() => _messages.add(AgentMessage(role: 'assistant', content: response))); await _persistConversation(); }
    } catch (e) {
      if (mounted) setState(() => _messages.add(AgentMessage(
        role: 'assistant',
        content: 'فشل الاستدلال المحلي: ' + e.toString(),
      )));
    } finally {
      if (mounted) setState(() => _generating = false);
      _scrollToEnd();
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zion Offline AI'), actions: [IconButton(onPressed: _showGenerationSettings, tooltip: 'إعدادات التوليد', icon: const Icon(Icons.tune)), IconButton(onPressed: _loading || _loadingModel || _selected == null ? null : _loadSelected, tooltip: 'تحميل النموذج', icon: const Icon(Icons.memory)), IconButton(onPressed: _loading || _loadingModel ? null : _pick, tooltip: 'استيراد نموذج GGUF', icon: const Icon(Icons.folder_open)), IconButton(onPressed: _clearConversation, tooltip: 'مسح المحادثة', icon: const Icon(Icons.delete_outline))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        if (_loadingModel) const LinearProgressIndicator(),
        if (_availableModels.length > 1) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: DropdownButton<LlamaModel>(isExpanded: true, value: _selected, items: _availableModels.map((m) => DropdownMenuItem(value: m, child: Text('${m.name} · ${(m.sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB', overflow: TextOverflow.ellipsis))).toList(), onChanged: _loadingModel || _generating ? null : (m) async {
          if (m == null) return;
          setState(() { _selected = m; _preferredModelPath = m.path; _error = null; });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_modelPathKey, m.path);
        })),
        if (_selected != null) ListTile(leading: const Icon(Icons.memory), title: Text(_selected!.name), subtitle: Text(_selected!.path, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Chip(label: Text(_agent.isInitialized ? 'OFFLINE' : 'غير محمل'))),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
        Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.all(12), itemCount: _messages.length, itemBuilder: (_, i) {
          final m = _messages[i]; final user = m.role == 'user';
          return Align(alignment: user ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .84), decoration: BoxDecoration(color: user ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SelectableText(m.content), if (!user) Align(alignment: AlignmentDirectional.centerEnd, child: IconButton(visualDensity: VisualDensity.compact, tooltip: 'نسخ الرد', icon: const Icon(Icons.copy, size: 16), onPressed: () => Clipboard.setData(ClipboardData(text: m.content))))])));
        })),
        if (_generating) const LinearProgressIndicator(),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(controller: _input, minLines: 1, maxLines: 5, maxLength: 2000, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder(), counterText: ''))), const SizedBox(width: 8), IconButton.filled(onPressed: _generating || _loadingModel ? null : _send, icon: const Icon(Icons.send))])))
      ]),
    );
  }

  @override void dispose() { _input.dispose(); _scroll.dispose(); _agent.dispose(); super.dispose(); }
}
