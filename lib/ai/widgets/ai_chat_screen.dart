import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF38BDF8);
    return SizedBox(
      width: 34,
      height: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List<Widget>.generate(3, (index) {
            final phase = (_controller.value * 2 * math.pi) -
                (index * 2 * math.pi / 3);
            final scale = 0.65 + (0.55 * ((math.sin(phase) + 1) / 2));
            const glowColor = Color(0xFF38BDF8);
            final dotScale = scale.clamp(0.65, 1.2);
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: Transform.scale(
                scale: dotScale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: glowColor.withValues(
                      alpha: 0.65 + (dotScale - 0.65) * 0.7,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: 0.20 + (dotScale - 0.65) * 0.28,
                        ),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AIChatScreen extends StatefulWidget {
  final AgentRole role;
  const AIChatScreen({super.key, this.role = AgentRole.terminalAssistant});
  @override State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late final AIAgent _agent;
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
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
          .where((m) => m.readable && m.path.isNotEmpty && m.sizeBytes > 0 && m.sizeBytes <= 4 * 1024 * 1024 * 1024)
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
            : 'لم يُعثر على نموذج GGUF قابل للقراءة ضمن حد الاكتشاف 4 GiB. يمكنك استيراد نموذج يدوياً.';
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
    if (model.sizeBytes <= 0) {
      setState(() => _error = 'تعذر قراءة حجم ملف النموذج. أعد استيراد GGUF.');
      return;
    }
    setState(() {
      _loadingModel = true;
      _status = 'جارٍ تحميل النموذج محلياً؛ قد يستغرق تحميل النماذج الكبيرة بضع دقائق.';
      _error = null;
    });
    try {
      final ok = await _agent.initialize(
        modelPath: model.path,
        role: widget.role,
        nThreads: 4,
      );
      if (!mounted) return;
      setState(() {
        _error = ok
            ? null
            : 'تعذر تحميل GGUF عبر محرك llama.cpp. تحقق من سلامة الملف وتوافق صيغة النموذج، ثم راجع سجل ZionLLM.';
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
      if (model.sizeBytes <= 0) {
        setState(() => _error = 'تعذر قراءة حجم ملف النموذج. أعد استيراد GGUF.');
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

    // The native request may still be queued behind the readiness check on the
    // single AI executor. Retry briefly until JNI reports an active generation
    // or this send operation finishes; a single early cancel can otherwise be
    // lost just before native inference starts.
    for (var attempt = 0; attempt < 20; attempt++) {
      final cancelled = await _agent.llama.cancelGeneration();
      if (cancelled || !mounted || !_generating) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isReady = _agent.isInitialized;
    final hasMessages = _messages.isNotEmpty;
    final modelName = _selected?.name ?? 'لا يوجد نموذج محدد';
    Widget actionButton(IconData icon, String tooltip, VoidCallback? onPressed) =>
      IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon, size: 21), visualDensity: VisualDensity.compact);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68, titleSpacing: 16,
        title: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(13)), child: Icon(Icons.auto_awesome, color: colors.onPrimaryContainer, size: 22)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Zion Offline AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: isReady ? const Color(0xFF20B486) : colors.outline)),
              const SizedBox(width: 6),
              Flexible(child: Text(isReady ? 'يعمل محلياً · دون اتصال' : 'مساعد ذكي على جهازك', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant))),
            ]),
          ])),
        ]),
        actions: [
          actionButton(Icons.add_comment_outlined, 'محادثة جديدة', _generating || _loadingModel ? null : _newChat),
          actionButton(Icons.history_rounded, 'المحادثات المحفوظة', _generating || _loadingModel ? null : _showSessions),
          actionButton(Icons.tune_rounded, 'إعدادات التوليد', _showGenerationSettings),
          PopupMenuButton<String>(
            tooltip: 'أدوات النموذج', icon: const Icon(Icons.more_vert),
            onSelected: (value) { if (value == 'load') _loadSelected(); if (value == 'import') _pick(); if (value == 'unload') _unloadModel(); if (value == 'clear') _clearConversation(); },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'load', enabled: !_loading && !_loadingModel && _selected != null, child: const ListTile(dense: true, leading: Icon(Icons.memory), title: Text('تحميل النموذج'))),
              PopupMenuItem(value: 'import', enabled: !_loading && !_loadingModel, child: const ListTile(dense: true, leading: Icon(Icons.folder_open), title: Text('استيراد نموذج GGUF'))),
              if (isReady) PopupMenuItem(value: 'unload', enabled: !_loadingModel && !_generating, child: const ListTile(dense: true, leading: Icon(Icons.eject), title: Text('تحرير ذاكرة النموذج'))),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'clear', enabled: !_generating && !_loadingModel, child: const ListTile(dense: true, leading: Icon(Icons.delete_outline), title: Text('مسح المحادثة'))),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(top: false, child: Column(children: [
        if (_loadingModel) const LinearProgressIndicator(minHeight: 2),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else ...[
          Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 6), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: colors.surfaceContainerLow, border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)), borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.memory_rounded, color: colors.primary, size: 21)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('النموذج المحلي', style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 2),
                if (_availableModels.length > 1)
                  DropdownButtonHideUnderline(child: DropdownButton<LlamaModel>(
                    isExpanded: true, isDense: true, value: _selected, hint: const Text('اختر نموذج GGUF'),
                    items: _availableModels.map((m) => DropdownMenuItem(value: m, child: Text('${m.name} · ${(m.sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB', overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: _loadingModel || _generating ? null : (m) async {
                      if (m == null) return;
                      setState(() { _selected = m; _preferredModelPath = m.path; _error = null; });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(_modelPathKey, m.path);
                    },
                  ))
                else Text(modelName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ])),
              const SizedBox(width: 8),
              if (isReady)
                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF20B486).withValues(alpha: .13), borderRadius: BorderRadius.circular(10)), child: const Text('جاهز', style: TextStyle(color: Color(0xFF168765), fontWeight: FontWeight.w700, fontSize: 11)))
              else FilledButton.tonal(onPressed: _loadingModel || _selected == null ? null : _loadSelected, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 38)), child: Text(_loadingModel ? 'تحميل...' : 'تحميل')),
            ]),
          )),
          if (_status != null)
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 6), child: Row(children: [
              if (_loadingModel) const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2)) else Icon(Icons.info_outline, size: 15, color: colors.secondary),
              const SizedBox(width: 7), Expanded(child: Text(_status!, style: theme.textTheme.bodySmall?.copyWith(color: colors.secondary))),
            ])),
          if (_error != null)
            Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 6), child: Material(
              color: colors.errorContainer.withValues(alpha: .65), borderRadius: BorderRadius.circular(12),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, size: 18, color: colors.onErrorContainer), const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: colors.onErrorContainer))),
                IconButton(visualDensity: VisualDensity.compact, constraints: const BoxConstraints(minWidth: 28, minHeight: 28), tooltip: 'إخفاء التنبيه', onPressed: () => setState(() => _error = null), icon: Icon(Icons.close, size: 16, color: colors.onErrorContainer)),
              ])),
            )),
          Expanded(child: hasMessages
            ? ListView.builder(controller: _scroll, padding: const EdgeInsets.fromLTRB(14, 10, 14, 18), itemCount: _messages.length, itemBuilder: (context, i) {
                final message = _messages[i]; final user = message.role == 'user';
                final bubbleColor = user ? colors.primaryContainer : colors.surfaceContainerLow;
                final foreground = user ? colors.onPrimaryContainer : colors.onSurface;
                return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!user) ...[
                    Container(width: 31, height: 31, decoration: BoxDecoration(color: colors.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.auto_awesome, size: 17, color: colors.primary)),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .82),
                    padding: const EdgeInsets.fromLTRB(14, 11, 10, 5),
                    decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(user ? 18 : 5), bottomRight: Radius.circular(user ? 5 : 18)), border: Border.all(color: colors.outlineVariant.withValues(alpha: .45))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SelectableText(message.content, style: TextStyle(height: 1.55, fontSize: 14.5, color: foreground)),
                      const SizedBox(height: 4),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(visualDensity: VisualDensity.compact, constraints: const BoxConstraints(minWidth: 32, minHeight: 30), tooltip: 'نسخ النص', icon: Icon(Icons.content_copy_rounded, size: 15, color: colors.onSurfaceVariant), onPressed: () => Clipboard.setData(ClipboardData(text: message.content))),
                        if (user) IconButton(visualDensity: VisualDensity.compact, constraints: const BoxConstraints(minWidth: 32, minHeight: 30), tooltip: 'تعديل وإعادة إرسال المدخل', icon: Icon(Icons.edit_outlined, size: 15, color: colors.onSurfaceVariant), onPressed: _generating ? null : () {
                          _input.value = TextEditingValue(text: message.content, selection: TextSelection.collapsed(offset: message.content.length));
                          FocusScope.of(context).requestFocus(_inputFocus);
                        }),
                      ]),
                    ]),
                  )),
                ]));
              })
            : ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 24), children: [
                const SizedBox(height: 16),
                Center(child: Container(width: 78, height: 78, decoration: BoxDecoration(color: colors.primary.withValues(alpha: .11), borderRadius: BorderRadius.circular(26), border: Border.all(color: colors.primary.withValues(alpha: .16))), child: Icon(Icons.psychology_alt_rounded, size: 40, color: colors.primary))),
                const SizedBox(height: 20),
                Text('ماذا تريد أن تنجز؟', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.4)),
                const SizedBox(height: 8),
                Text(isReady ? 'اكتب طلبك وسأعالجه محلياً على جهازك.' : 'مساعدك المحلي جاهز للإعداد. اختر نموذج GGUF وحمّله لبدء الاستدلال.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, height: 1.5)),
                const SizedBox(height: 25),
                Text('ابدأ بأحد هذه الطلبات', style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 10),
                ...[
                  (Icons.terminal_rounded, 'شرح أمر طرفية', 'اشرح هذا الأمر في الطرفية خطوة بخطوة'),
                  (Icons.code_rounded, 'مساعدة برمجية', 'راجع هذا الكود واقترح إصلاحاً آمناً'),
                  (Icons.menu_book_rounded, 'تلخيص وشرح', 'لخّص هذا الموضوع في نقاط واضحة'),
                ].map((item) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Material(
                  color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(15),
                  child: InkWell(borderRadius: BorderRadius.circular(15), onTap: () {
                    _input.text = item.$3;
                    _input.selection = TextSelection.collapsed(offset: _input.text.length);
                    FocusScope.of(context).requestFocus(_inputFocus);
                  }, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), child: Row(children: [
                    Icon(item.$1, color: colors.primary, size: 21), const SizedBox(width: 12),
                    Expanded(child: Text(item.$2, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                    Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: colors.onSurfaceVariant),
                  ]))),
                ))),
                if (!isReady && _availableModels.isEmpty)
                  Padding(padding: const EdgeInsets.only(top: 8), child: OutlinedButton.icon(onPressed: _loadingModel ? null : _pick, icon: const Icon(Icons.file_open_outlined), label: const Text('استيراد نموذج GGUF من الهاتف'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
              ]),
          ),
          if (_generating)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(Icons.auto_awesome_rounded, size: 18, color: colors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _cancelRequested ? 'جارٍ إيقاف التوليد' : 'Zion AI يكتب الآن',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (_cancelRequested)
                                SizedBox(
                                  width: 13,
                                  height: 13,
                                  child: CircularProgressIndicator(strokeWidth: 1.8, color: colors.primary),
                                )
                              else
                                const _TypingDots(),
                              const SizedBox(width: 8),
                              Text(
                                _cancelRequested ? 'لحظة من فضلك...' : 'يعالج طلبك محلياً',
                                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: _cancelGeneration, child: const Text('إيقاف')),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)))),
            child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                IconButton(tooltip: 'استيراد نموذج GGUF', onPressed: _loading || _loadingModel ? null : _pick, icon: const Icon(Icons.add_circle_outline_rounded)),
                Expanded(child: TextField(
                  focusNode: _inputFocus, controller: _input, minLines: 1, maxLines: 5, maxLength: 700, textInputAction: TextInputAction.newline,
                  onSubmitted: (_) { if (!_generating) _send(); },
                  decoration: InputDecoration(
                    hintText: _generating ? 'انتظر اكتمال الاستدلال...' : 'اكتب رسالتك إلى Zion AI...', counterText: '', filled: true, fillColor: colors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: .5))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: colors.primary, width: 1.4)),
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 48, height: 48, child: IconButton.filled(onPressed: _loadingModel ? null : (_generating ? _cancelGeneration : _send), tooltip: _generating ? 'إيقاف التوليد' : 'إرسال الرسالة', style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: Icon(_generating ? Icons.stop_rounded : Icons.arrow_upward_rounded))),
              ]),
              const SizedBox(height: 5),
              Text(isReady ? 'المحادثة والاستدلال محليان · قد تختلف السرعة حسب النموذج والجهاز' : 'تُحفظ المحادثات على الجهاز · حمّل نموذجاً لبدء العمل', textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: .8), fontSize: 10.5)),
            ])),
          ),
        ],
      ])),
    );
  }

  @override void dispose() {
    if (_generating) unawaited(_agent.llama.cancelGeneration());
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    unawaited(_agent.dispose());
    super.dispose();
  }
}
