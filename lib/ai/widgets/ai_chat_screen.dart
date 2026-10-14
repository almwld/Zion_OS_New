import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../ai_agent.dart';
import '../llama_service.dart';

class _LocalChatSession {
  final String id;
  String title;
  DateTime updatedAt;
  final List<AgentMessage> messages;

  _LocalChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    List<AgentMessage>? messages,
  }) : messages = messages ?? <AgentMessage>[];

  factory _LocalChatSession.fromJson(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Invalid local chat session');
    }
    final rawMessages = value['messages'];
    final parsed = rawMessages is List
        ? rawMessages.whereType<Map>().map((item) => AgentMessage(
            role: item['role'] == 'user' ? 'user' : 'assistant',
            content: (item['content'] ?? '').toString(),
          )).where((m) => m.content.isNotEmpty).toList()
        : <AgentMessage>[];
    return _LocalChatSession(
      id: (value['id'] ?? '').toString(),
      title: (value['title'] ?? 'محادثة جديدة').toString(),
      updatedAt: DateTime.tryParse((value['updatedAt'] ?? '').toString()) ?? DateTime.now(),
      messages: parsed.length > 40 ? parsed.sublist(parsed.length - 40) : parsed,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
  };
}

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
  final List<_LocalChatSession> _sessions = <_LocalChatSession>[];
  String? _activeSessionId;
  List<LlamaModel> _availableModels = <LlamaModel>[];
  LlamaModel? _selected;
  bool _loading = true;
  bool _loadingModel = false;
  bool _generating = false;
  bool _cancelRequested = false;
  String? _error;
  String? _status;
  double _temperature = 0.25;
  int _maxTokens = 128;
  static const _historyKey = 'zion_offline_ai_messages_v1';
  static const _sessionsKey = 'zion_offline_ai_sessions_v1';
  static const _activeSessionKey = 'zion_offline_ai_active_session_v1';
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

    final sessionsRaw = prefs.getString(_sessionsKey);
    if (sessionsRaw != null && sessionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(sessionsRaw);
        if (decoded is List) {
          _sessions
            ..clear()
            ..addAll(decoded.map(_LocalChatSession.fromJson)
                .where((session) => session.id.isNotEmpty));
        }
      } catch (_) {
        _sessions.clear();
        await prefs.remove(_sessionsKey);
      }
    }

    final preferredId = prefs.getString(_activeSessionKey);
    _LocalChatSession? active;
    for (final session in _sessions) {
      if (session.id == preferredId) {
        active = session;
        break;
      }
    }
    if (active == null && _sessions.isNotEmpty) {
      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      active = _sessions.first;
    }

    if (active != null) {
      _activeSessionId = active.id;
      _messages.addAll(active.messages);
      _agent.restoreHistory(_messages);
      return;
    }

    // Migrate the previous single-conversation format without losing messages.
    final raw = prefs.getString(_historyKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _messages.addAll(decoded.whereType<Map>().take(100).map((item) => AgentMessage(
            role: item['role'] == 'user' ? 'user' : 'assistant',
            content: (item['content'] ?? '').toString(),
          )).where((m) => m.content.isNotEmpty));
        }
      } catch (_) {
        await prefs.remove(_historyKey);
      }
    }
    _agent.restoreHistory(_messages);
    _activeSessionId = 'chat-${DateTime.now().microsecondsSinceEpoch}';
    _sessions.add(_LocalChatSession(
      id: _activeSessionId!,
      title: _titleForMessages(_messages),
      updatedAt: DateTime.now(),
      messages: List<AgentMessage>.of(_messages),
    ));
  }

  String _titleForMessages(List<AgentMessage> messages) {
    final userMessages = messages.where((m) => m.role == 'user');
    if (userMessages.isEmpty) return 'محادثة جديدة';
    final first = userMessages.first;
    final text = first.content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length > 34 ? '${text.substring(0, 34)}…' : text;
  }

  Future<void> _persistConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = _messages.length > 40 ? _messages.sublist(_messages.length - 40) : _messages;
      final id = _activeSessionId ?? 'chat-${DateTime.now().microsecondsSinceEpoch}';
      _activeSessionId = id;
      final index = _sessions.indexWhere((session) => session.id == id);
      final session = _LocalChatSession(
        id: id,
        title: _titleForMessages(_messages),
        updatedAt: DateTime.now(),
        messages: List<AgentMessage>.of(recent),
      );
      if (index >= 0) {
        _sessions[index] = session;
      } else {
        _sessions.add(session);
      }
      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (_sessions.length > 12) {
        _sessions.removeRange(12, _sessions.length);
      }
      await prefs.setString(_sessionsKey, jsonEncode(_sessions.map((s) => s.toJson()).toList()));
      await prefs.setString(_activeSessionKey, id);
      // Keep the legacy key in sync for downgrade compatibility.
      await prefs.setString(_historyKey, jsonEncode(
        recent.map((m) => {'role': m.role, 'content': m.content}).toList(),
      ));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر حفظ سجل المحادثة على الجهاز.');
    }
  }

  Future<void> _newChat() async {
    if (_generating || _loadingModel) return;
    await _persistConversation();
    final id = 'chat-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _activeSessionId = id;
      _messages.clear();
      _agent.clearHistory();
      _error = null;
    });
    await _persistConversation();
  }

  Future<void> _showSessions() async {
    if (_generating || _loadingModel) return;
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.65,
          child: Column(children: [
            const ListTile(title: Text('المحادثات المحفوظة')),
            Expanded(
              child: ListView(
                children: _sessions.map((session) => ListTile(
                  leading: Icon(session.id == _activeSessionId ? Icons.chat_bubble : Icons.chat_bubble_outline),
                  title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${session.messages.length} رسالة'),
                  selected: session.id == _activeSessionId,
                  onTap: () => Navigator.pop(sheetContext, session.id),
                )).toList(),
              ),
            ),
          ]),
        ),
      ),
    );
    if (selectedId == null || selectedId == _activeSessionId || !mounted) return;
    await _persistConversation();
    final matchingSessions = _sessions.where((s) => s.id == selectedId);
    if (matchingSessions.isEmpty) return;
    final session = matchingSessions.first;
    setState(() {
      _activeSessionId = session.id;
      _messages
        ..clear()
        ..addAll(session.messages);
      _agent.restoreHistory(_messages);
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSessionKey, session.id);
    await _persistConversation();
    _scrollToEnd();
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
    _activeSessionId = _activeSessionId ?? 'chat-${DateTime.now().microsecondsSinceEpoch}';
    await _persistConversation();
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
      _status = 'جارٍ تحميل النموذج محلياً؛ قد يستغرق ذلك وقتاً حسب حجمه وذاكرة الجهاز.';
      _error = null;
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
        _status = ok ? 'النموذج محمل محلياً دون اتصال.' : null;
        if (ok) {
          _preferredModelPath = model.path;
          _agent.restoreHistory(_messages);
        }
      });
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_modelPathKey, model.path);
        await _persistConversation();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'تعذر تحميل النموذج: $e'; _status = null; });
    } finally {
      if (mounted) setState(() => _loadingModel = false);
    }
  }

  Future<void> _unloadModel() async {
    if (_generating || _loadingModel || !_agent.isInitialized) return;
    setState(() {
      _loadingModel = true;
      _status = 'جارٍ تحرير ذاكرة النموذج...';
      _error = null;
    });
    try {
      await _agent.unload();
      if (mounted) setState(() => _status = 'تم تفريغ النموذج وتحرير الذاكرة.');
    } catch (e) {
      if (mounted) setState(() { _error = 'تعذر تفريغ النموذج: $e'; _status = null; });
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

  Future<void> _cancelGeneration() async {
    if (!_generating || _cancelRequested) return;
    setState(() {
      _cancelRequested = true;
      _status = 'جارٍ إيقاف التوليد المحلي...';
    });
    await _agent.llama.cancelGeneration();
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
    setState(() {
      _messages.add(AgentMessage(role: 'user', content: text));
      _input.clear();
      _generating = true;
      _cancelRequested = false;
      _status = null;
    });
    await _persistConversation();
    _scrollToEnd();
    try {
      if (_cancelRequested) {
        if (mounted) setState(() => _messages.add(const AgentMessage(
          role: 'assistant',
          content: 'تم إيقاف التوليد قبل بدء الاستدلال.',
        )));
      } else {
        final response = await _agent.chat(text, maxTokens: _maxTokens, temperature: _temperature);
        final shownResponse = _cancelRequested
            ? (response.startsWith('ERROR:')
                ? 'تم إيقاف التوليد.'
                : 'تم إيقاف التوليد.\n$response')
            : response;
        if (mounted) setState(() => _messages.add(AgentMessage(role: 'assistant', content: shownResponse)));
      }
    } catch (e) {
      if (mounted) setState(() => _messages.add(AgentMessage(
        role: 'assistant',
        content: 'فشل الاستدلال المحلي: ' + e.toString(),
      )));
    } finally {
      if (mounted) setState(() {
        _generating = false;
        _cancelRequested = false;
        if (_status == 'جارٍ إيقاف التوليد المحلي...') _status = null;
      });
      await _persistConversation();
      _scrollToEnd();
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zion Offline AI'), actions: [IconButton(onPressed: _newChat, tooltip: 'محادثة جديدة', icon: const Icon(Icons.add_comment_outlined)), IconButton(onPressed: _showSessions, tooltip: 'المحادثات المحفوظة', icon: const Icon(Icons.history)), IconButton(onPressed: _showGenerationSettings, tooltip: 'إعدادات التوليد', icon: const Icon(Icons.tune)), IconButton(onPressed: _loading || _loadingModel || _selected == null ? null : _loadSelected, tooltip: 'تحميل النموذج', icon: const Icon(Icons.memory)), if (_agent.isInitialized) IconButton(onPressed: _loadingModel || _generating ? null : _unloadModel, tooltip: 'تفريغ النموذج وتحرير الذاكرة', icon: const Icon(Icons.eject)), IconButton(onPressed: _loading || _loadingModel ? null : _pick, tooltip: 'استيراد نموذج GGUF', icon: const Icon(Icons.folder_open)), IconButton(onPressed: _clearConversation, tooltip: 'مسح المحادثة', icon: const Icon(Icons.delete_outline))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        if (_loadingModel) const LinearProgressIndicator(),
        if (_availableModels.length > 1) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: DropdownButton<LlamaModel>(isExpanded: true, value: _selected, items: _availableModels.map((m) => DropdownMenuItem(value: m, child: Text('${m.name} · ${(m.sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB', overflow: TextOverflow.ellipsis))).toList(), onChanged: _loadingModel || _generating ? null : (m) async {
          if (m == null) return;
          setState(() { _selected = m; _preferredModelPath = m.path; _error = null; });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_modelPathKey, m.path);
        })),
        if (_selected != null) ListTile(leading: const Icon(Icons.memory), title: Text(_selected!.name), subtitle: Text(_selected!.path, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Chip(label: Text(_agent.isInitialized ? 'OFFLINE' : 'غير محمل'))),
        if (_status != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Align(alignment: AlignmentDirectional.centerStart, child: Text(_status!, style: TextStyle(color: Theme.of(context).colorScheme.secondary)))),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
        Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.all(12), itemCount: _messages.length, itemBuilder: (_, i) {
          final m = _messages[i]; final user = m.role == 'user';
          return Align(alignment: user ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .84), decoration: BoxDecoration(color: user ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SelectableText(m.content), if (!user) Align(alignment: AlignmentDirectional.centerEnd, child: IconButton(visualDensity: VisualDensity.compact, tooltip: 'نسخ الرد', icon: const Icon(Icons.copy, size: 16), onPressed: () => Clipboard.setData(ClipboardData(text: m.content))))])));
        })),
        if (_generating) const LinearProgressIndicator(),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(controller: _input, minLines: 1, maxLines: 5, maxLength: 2000, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder(), counterText: ''))), const SizedBox(width: 8), IconButton.filled(
          onPressed: _loadingModel ? null : (_generating ? _cancelGeneration : _send),
          tooltip: _generating ? 'إيقاف التوليد' : 'إرسال الرسالة',
          icon: Icon(_generating ? Icons.stop : Icons.send),
        )])))
      ]),
    );
  }

  @override void dispose() { _input.dispose(); _scroll.dispose(); _agent.dispose(); super.dispose(); }
}
