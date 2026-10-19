import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../core/orchestrator.dart';
import '../tools/tool_registry.dart';
import '../tools/terminal_pty_tool.dart';
import '../../features/terminal/terminal_service.dart';
import '../../security/core/security_core.dart';
import '../core/agent_models.dart';
import '../core/agent_runtime.dart';
import '../../ai/llama_service.dart';
import 'kali_agent_loop_screen.dart';
import 'agent_lab_screen.dart';
import 'agent_subagents_screen.dart';
import 'obsidian_vault_screen.dart';
import 'agent_intelligence_hub.dart';

class _SuperAgentTypingDots extends StatefulWidget {
  const _SuperAgentTypingDots();

  @override
  State<_SuperAgentTypingDots> createState() => _SuperAgentTypingDotsState();
}

class _SuperAgentTypingDotsState extends State<_SuperAgentTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 32,
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
              final dotScale = scale.clamp(0.65, 1.2);
              const cyan = Color(0xFF38BDF8);
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Transform.scale(
                  scale: dotScale,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: cyan.withValues(alpha: 0.65 + (dotScale - 0.65) * 0.7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cyan.withValues(alpha: 0.20 + (dotScale - 0.65) * 0.28),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});
  @override State<AgentScreen> createState()=>_AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  // Keep execution alive across route changes; this widget is only a view.
  static AgentRuntime? _persistentRuntime;
  static TerminalService? _persistentTerminal;
  static LlamaService? _persistentAi;
  static final StringBuffer _persistentPtyConsole = StringBuffer();

  late final AgentRuntime _runtime;
  late final TerminalService _agentTerminal;
  late final bool _ownsAgentTerminal;
  late final bool _usingSharedTerminal;
  StreamSubscription<String>? _ptySubscription;
  final StringBuffer _ptyConsole = _persistentPtyConsole;
  int _ptyOutputVersion = 0;
  final _input=TextEditingController();
  final _scroll=ScrollController();
  final _messages=<Map<String,String>>[];
  final _events=<AgentEvent>[];
  StreamSubscription<AgentEvent>? _sub;
  AgentResult? _result;
  bool _modelLoading=false;
  bool _modelReady=false;
  bool _submitting=false;
  bool _historyReady=false;
  bool _workspaceDetailsExpanded=false;
  bool _overthinkerEnabled = false;
  int _workspaceTab = 0;
  int _activityFilter = 0;
  static const String _historyKey='zion_super_agent_messages_v1';
  String _modelStatus='جارٍ البحث عن نموذج GGUF محلي…';
  String? _modelName;
  LlamaModel? _candidateModel;
  List<LlamaModel> _availableModels = <LlamaModel>[];
  final Set<String> _collaborationModels = <String>{};

  @override void initState(){
    super.initState();
    final ai = _persistentAi ??= LlamaService();
    final activeTerminal = _persistentTerminal ?? TerminalService.activeInteractiveService;
    _usingSharedTerminal = activeTerminal != null;
    _ownsAgentTerminal = activeTerminal == null;
    _agentTerminal = activeTerminal ?? TerminalService(context.read<SecurityCore>());
    final isFirstRuntime = _persistentRuntime == null;
    _persistentTerminal ??= _agentTerminal;
    if (isFirstRuntime && !_ownsAgentTerminal) _agentTerminal.retainForAgent();
    _ptySubscription = _agentTerminal.output.listen((chunk) {
      _ptyConsole.write(chunk);
      if (_ptyConsole.length > 18000) {
        final current = _ptyConsole.toString();
        _ptyConsole
          ..clear()
          ..write(current.substring(current.length - 18000));
      }
      if (!mounted) return;
      setState(() => _ptyOutputVersion++);
      _scrollEnd();
    });
    if (isFirstRuntime) {
      final tools = ToolRegistry(ai: ai, customTools: [TerminalPtyTool(_agentTerminal)]);
      _persistentRuntime = AgentRuntime(orchestrator: AgentOrchestrator(ai: ai, tools: tools));
    }
    _runtime = _persistentRuntime!;
    // Let the agent window render before requesting native model discovery.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_discoverModel());
    });
    _messages.add(const {'role':'assistant','text':'مرحباً. أنا Zion Super Agent المحلي. صف لي ما تريد إنجازه بلغة طبيعية، وسأخطط للخطوات وأعرض التنفيذ والنتائج أمامك.'});
    _sub=_runtime.events.listen((e){
      if(!mounted)return;
      setState(() {
        _events.add(e);
        if (_events.length > 150) {
          _events.removeRange(0, _events.length - 150);
        }
      });
      _scrollEnd();
    });
    unawaited(_restoreMessages());
  }


  Future<void> _restoreMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) {
        await _persistMessages();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = decoded.whereType<Map>().take(100).map((item) {
        final role = item['role']?.toString();
        final text = item['text']?.toString() ?? '';
        if ((role != 'user' && role != 'assistant') || text.trim().isEmpty) return null;
        return <String, String>{'role': role!, 'text': text};
      }).whereType<Map<String, String>>().toList(growable: false);
      if (!mounted || restored.isEmpty) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(restored);
      });
      _scrollEnd();
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_historyKey);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _historyReady = true);
    }
  }

  Future<void> _persistMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = _messages.length > 100
          ? _messages.sublist(_messages.length - 100)
          : _messages;
      await prefs.setString(_historyKey, jsonEncode(recent));
    } catch (_) {
      // The agent remains usable when local history persistence is unavailable.
    }
  }

  void _appendMessage(Map<String, String> message) {
    _messages.add(message);
    if (_messages.length > 100) {
      _messages.removeRange(0, _messages.length - 100);
    }
  }

  Future<void> _discoverModel() async {
    if (mounted) setState(() {
      _modelLoading = true;
      _modelStatus = 'جارٍ البحث عن ملفات GGUF في الخلفية…';
    });
    try {
      final models = await _runtime.orchestrator.ai.discoverModels();
      final candidates = models
          .where((m) => m.readable && m.path.isNotEmpty && m.sizeBytes > 0 && m.sizeBytes <= 4 * 1024 * 1024 * 1024)
          .toList()
        ..sort((a, b) {
          int score(LlamaModel model) {
            final name = model.name.toLowerCase();
            var value = 0;
            if (name.contains('instruct')) value += 100;
            if (name.contains('chat')) value += 90;
            if (name.contains('assistant')) value += 70;
            if (name.contains('qwen')) value += 55;
            if (name.contains('llama')) value += 45;
            if (name.contains('base')) value -= 25;
            return value;
          }
          final byQuality = score(b).compareTo(score(a));
          if (byQuality != 0) return byQuality;
          return b.sizeBytes.compareTo(a.sizeBytes);
        });
      final nativeReady = await _runtime.orchestrator.ai.refreshLoadedState();
      if (mounted) setState(() {
        _availableModels = candidates;
        _collaborationModels.removeWhere((path) => !candidates.any((model) => model.path == path));
        _candidateModel = candidates.isEmpty ? null : candidates.first;
        _modelReady = nativeReady;
        _modelName = nativeReady
            ? (_runtime.orchestrator.ai.currentModel?.split('/').last ?? 'Local AI')
            : _candidateModel?.name;
        _modelStatus = nativeReady
            ? 'النموذج المحلي جاهز'
            : _candidateModel == null
                ? (models.isEmpty
                    ? 'لا يوجد نموذج GGUF قابل للتحميل. استورد نموذجاً للبدء.'
                    : 'لم يُعثر على نموذج GGUF ضمن الحد الافتراضي 4 GiB. يمكنك استيراد النموذج يدوياً.')
                : 'تم العثور على ${_candidateModel!.name}. اضغط تحميل النموذج عند الاستعداد.';
      });
    } catch (e) {
      if (mounted) setState(() {
        _modelReady = false;
        _modelStatus = 'تعذر فحص نماذج GGUF: $e';
      });
    } finally {
      if (mounted) setState(() => _modelLoading = false);
    }
  }

  Future<void> _initializeModel({bool pick = false}) async {
    if (_modelLoading) return;
    if (mounted) setState(() {
      _modelLoading = true;
      _modelStatus = pick ? 'اختر ملف نموذج GGUF…' : 'جارٍ تحميل النموذج المحلي…';
    });
    try {
      LlamaModel? model = _candidateModel;
      if (pick) {
        model = await _runtime.orchestrator.ai.pickAndImportModel();
        if (model == null) {
          if (mounted) setState(() => _modelStatus = 'لم يتم اختيار نموذج.');
          return;
        }
        _candidateModel = model;
      }
      if (model == null) {
        if (mounted) setState(() => _modelStatus = 'لم يتم العثور على نموذج. استخدم استيراد GGUF.');
        return;
      }
      if (model.sizeBytes <= 0) {
        if (mounted) setState(() => _modelStatus = 'تعذر قراءة حجم ملف GGUF. أعد استيراد النموذج.');
        return;
      }
      final ok = await _runtime.orchestrator.ai.loadModel(model.path, threads: 4);
      if (mounted) setState(() {
        _modelReady = ok;
        _modelName = ok ? model!.name : null;
        _modelStatus = ok
            ? 'النموذج المحلي جاهز'
            : 'تعذر تحميل GGUF عبر محرك llama.cpp. تحقق من سلامة الملف وتوافق صيغة النموذج، ثم راجع سجل ZionLLM.';
      });
    } catch (e) {
      if (mounted) setState(() {
        _modelReady = false;
        _modelStatus = 'تعذر تهيئة محرك الذكاء المحلي: $e';
      });
    } finally {
      if (mounted) setState(() => _modelLoading = false);
    }
  }

  Future<void> _run() async {
    final rawTask = _input.text.trim();
    final task = _overthinkerEnabled
      ? '''[OVERTHINKER MODE — Zion Super Agent]
Original task: $rawTask

Engineering loop:
1. Define the requested outcome and scope; do not invent missing facts.
2. Organize the plan through specialist perspectives: planner, executor, risk reviewer, and verifier. Do not claim separate agents ran unless they actually did.
3. Identify dependencies and risks before side effects; require approval for sensitive actions.
4. Execute one verifiable step at a time and inspect real tool output.
5. Verify the final state against the original task; diagnose and recover from failures within the granted scope.
6. Report evidence, uncertainty, and remaining work honestly.
''' : rawTask;
    if (rawTask.isEmpty || !_historyReady || _runtime.canCancel || _submitting) return;
    // Deterministic tool tasks can run without a loaded model. Complex planning
    // uses the local GGUF model when it is available.
    setState(() {
      _submitting = true;
      _input.clear();
      _appendMessage({'role': 'user', 'text': rawTask});
      _result = null;
    });
    await _persistMessages();
    _scrollEnd();
    try {
      var executionTask = task;
      final selectedModels = _availableModels
          .where((model) => _collaborationModels.contains(model.path))
          .toList(growable: false);
      if (selectedModels.length > 1) {
        final sharedNotes = <String>[];
        for (var i = 0; i < selectedModels.length; i++) {
          final model = selectedModels[i];
          if (mounted) setState(() {
            _modelLoading = true;
            _modelStatus = 'تعاون النماذج ${i + 1}/${selectedModels.length}: ${model.name}';
          });
          final loaded = await _runtime.orchestrator.ai.loadModel(model.path, threads: 2);
          if (!loaded) {
            throw StateError('تعذر تحميل نموذج التعاون: ${model.name}. تحقق من الملف أو الذاكرة المتاحة.');
          }
          final prompt = '''أنت مشارك في جلسة متعددة النماذج تعمل محلياً على Zion OS.
المهمة الأصلية: $rawTask
ملخصات النماذج السابقة:
${sharedNotes.isEmpty ? 'لا توجد مساهمات سابقة؛ قدّم تحليلك المستقل.' : sharedNotes.join('\n\n')}
اسم نموذجك: ${model.name}
قدّم تحليلاً عملياً موجزاً، وحدد الافتراضات والمخاطر وخطوة التحقق. لا تدّع تنفيذ أوامر أو تغييرات لم تنفذها فعلياً.''';
          final contribution = (await _runtime.orchestrator.ai.generate(
            prompt,
            maxTokens: 512,
            temperature: 0.25,
          )).trim();
          if (contribution.isEmpty || contribution.startsWith('ERROR:')) {
            throw StateError('فشل إخراج نموذج ${model.name}: ${contribution.isEmpty ? 'رد فارغ' : contribution}');
          }
          sharedNotes.add('مساهمة ${model.name}:\n$contribution');
        }
        executionTask = '''المهمة الأصلية المطلوب تنفيذها: $rawTask

مراجعة تعاونية فعلية من النماذج المحلية المختارة (تم تشغيل كل نموذج بالتتابع، وليس بالتوازي):
${sharedNotes.join('\n\n')}

استخدم هذه المساهمات كسياق مساعد لا كحقائق مؤكدة. نفّذ المهمة بالأدوات المسجلة، وافحص المخرجات الحقيقية، وبيّن أي تعارض أو إخفاق. لا تعتبر التحليل السابق دليلاً على تنفيذ المهمة.''';
        if (mounted) setState(() {
          _modelName = selectedModels.last.name;
          _modelReady = true;
          _modelStatus = 'اكتمل تحليل ${selectedModels.length} نماذج محلية بالتتابع؛ يجري التنفيذ والتحقق الآن.';
        });
      }
      final result = await _runtime.run(
        executionTask,
        approveReviewed: false,
        stepTimeout: const Duration(minutes: 16),
        maxRecoveryAttempts: 8,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _appendMessage({
          'role': 'assistant',
          'text': _visibleResultSummary(result),
        });
      });
      await _persistMessages();
      _scrollEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _appendMessage({'role': 'assistant', 'text': 'تعذر إكمال المهمة: $error'});
      });
      await _persistMessages();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<String> _runLabPrompt(String prompt) async {
    if (!mounted || _runtime.canCancel || _submitting) {
      throw StateError('Zion Super Agent مشغول بمهمة أخرى.');
    }
    setState(() => _submitting = true);
    try {
      final ai = _runtime.orchestrator.ai;
      if (!await ai.refreshLoadedState()) {
        throw StateError('النموذج المحلي غير محمّل؛ حمّل GGUF أولاً ثم أعد المحاولة.');
      }
      // Collaboration roles are model prompts, not system/tool tasks. Routing
      // them through AgentRuntime caused its task verifier to reject ordinary
      // analysis text and mark the whole collaboration as failed.
      final response = await ai.generate(
        prompt,
        maxTokens: 768,
        temperature: 0.25,
      ).timeout(const Duration(minutes: 8));
      final text = response.trim();
      if (text.isEmpty) throw StateError('عاد النموذج برد فارغ لهذا الدور.');
      if (text.startsWith('ERROR:')) throw StateError(text);
      return text;
    } on TimeoutException {
      await _runtime.orchestrator.ai.cancelGeneration();
      throw StateError('انتهت مهلة استجابة النموذج بعد 8 دقائق؛ تم طلب إيقاف التوليد.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _scrollEnd()=>WidgetsBinding.instance.addPostFrameCallback((_){
    if(_scroll.hasClients)_scroll.animateTo(_scroll.position.maxScrollExtent,duration:const Duration(milliseconds:180),curve:Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1018),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0E1722),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF123744),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF35D3E8).withOpacity(.32)),
            ),
            child: const Icon(Icons.hub_outlined, color: Color(0xFF35D3E8), size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Zion Super Agent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 2),
              Text('مساحة العمل الذكية', style: TextStyle(fontSize: 11, color: Color(0xFF9BAFBE))),
            ],
          )),
        ]),
        actions: [
          IconButton(
            tooltip: 'محادثة جديدة',
            onPressed: (!_historyReady || _runtime.canCancel || _submitting) ? null : () {
              setState(() {
                _messages..clear()..add(const {'role': 'assistant', 'text': 'محادثة جديدة جاهزة. ما المهمة التي تريد إنجازها؟'});
                _events.clear();
                _result = null;
              });
              unawaited(_persistMessages());
            },
            icon: const Icon(Icons.add_comment_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'أدوات الوكيل',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'hub') {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => AgentIntelligenceHub(
                    events: List<AgentEvent>.unmodifiable(_events),
                    task: _runtime.activeSession?.task ?? _input.text.trim(),
                    result: _result,
                    overthinkerEnabled: _overthinkerEnabled,
                  ),
                ));
              } else if (value == 'overthinker') {
                setState(() => _overthinkerEnabled = !_overthinkerEnabled);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_overthinkerEnabled
                    ? 'تم تفعيل Overthinker: تخطيط أعمق ومراجعة للنتائج.'
                    : 'تم إيقاف نمط Overthinker.'),
                  behavior: SnackBarBehavior.floating,
                ));
              } else if (value == 'loop') {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => KaliAgentLoopScreen(ai: _runtime.orchestrator.ai),
                ));
              } else if (value == 'subagents') {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AgentSubagentsScreen()));
              } else if (value == 'obsidian') {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ObsidianVaultScreen(initialMarkdown: _buildSessionMarkdown())));
              } else if (value == 'lab') {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => AgentLabScreen(
                    runPrompt: _runLabPrompt,
                    cancelRun: _runtime.cancel,
                    isCancelled: () => _runtime.snapshot?.state == AgentState.cancelled,
                  ),
                ));
              } else if (value == 'refresh') {
                unawaited(_discoverModel());
              } else if (value == 'clear') {
                setState(() { _events.clear(); _result = null; });
              } else if (value == 'export') {
                unawaited(_exportSession());
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'hub', child: ListTile(leading: const Icon(Icons.hub_outlined), title: const Text('مركز الذكاء والتحليلات'), contentPadding: EdgeInsets.zero)),
              PopupMenuItem(value: 'overthinker', child: ListTile(leading: Icon(_overthinkerEnabled ? Icons.psychology_alt : Icons.psychology_alt_outlined), title: Text(_overthinkerEnabled ? 'إيقاف Overthinker' : 'تفعيل Overthinker'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'loop', child: ListTile(leading: Icon(Icons.account_tree_outlined), title: Text('Agent Loop · Kali'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'subagents', child: ListTile(leading: Icon(Icons.groups_2_outlined), title: Text('الوكلاء الفرعيون'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'obsidian', child: ListTile(leading: Icon(Icons.auto_stories_outlined), title: Text('Obsidian · قاعدة المعرفة'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'lab', child: ListTile(leading: Icon(Icons.hub_outlined), title: Text('مختبر الوكلاء وLoop Engineering'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'refresh', child: ListTile(leading: Icon(Icons.refresh), title: Text('فحص النموذج مجدداً'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'clear', child: ListTile(leading: Icon(Icons.cleaning_services_outlined), title: Text('مسح النشاط الظاهر'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'export', child: ListTile(leading: Icon(Icons.ios_share_outlined), title: Text('نسخ تقرير الجلسة'), contentPadding: EdgeInsets.zero)),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        _workspaceOverview(),
        _workspaceTabs(),
        Expanded(child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          children: [
            if (_workspaceTab == 0) ...[
              if (_messages.length <= 1) _quickActions(),
              for (var i = 0; i < _messages.length; i++)
                _message(i, _messages[i]['role']!, _messages[i]['text']!),
              if (_submitting && !_runtime.canCancel)
                _workingBanner('يتم تجهيز المهمة', 'جارٍ إرسال المهمة إلى منسق الوكيل…'),
              if (_runtime.canCancel)
                _workingBanner(
                  _runtime.canApprove ? 'بانتظار موافقتك' : 'الوكيل يعمل',
                  _runtime.canApprove ? 'راجع تفاصيل الخطوة قبل السماح بتنفيذها.' : 'تُعرض الخطوات والنتائج هنا فور وصولها.',
                ),
              _ptyConsoleCard(),
            ],
            if (_workspaceTab == 0 || _workspaceTab == 1)
              if (_events.isNotEmpty) _activity()
              else if (_workspaceTab == 1)
                _emptyWorkspace('لا توجد أحداث بعد', 'عند بدء المهمة ستظهر هنا خطوات التخطيط والتنفيذ والحالة الفعلية لكل حدث.', Icons.timeline_outlined),
            if (_workspaceTab == 0 || _workspaceTab == 2)
              if (_result != null) _resultCard()
              else if (_workspaceTab == 2)
                _emptyWorkspace('لا توجد نتائج بعد', 'ستظهر هنا خلاصة المهمة ومخرجات الأدوات وأزمنة التنفيذ بعد انتهاء المهمة.', Icons.fact_check_outlined),
          ],
        )),
        _composer(),
      ]),
    );
  }


  Widget _ptyConsoleCard() {
    final output = _ptyConsole.toString().trimRight();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF080D12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A4858)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(children: [
              const Icon(Icons.terminal, size: 17, color: Color(0xFF48D9C0)),
              const SizedBox(width: 7),
              const Expanded(child: Text(
                'مخرجات Zion PTY الحية',
                style: TextStyle(color: Color(0xFFE4F1F5), fontSize: 12, fontWeight: FontWeight.w700),
              )),
              Text(
                _usingSharedTerminal ? 'جلسة الطرفية المحددة' : 'جلسة PTY للوكيل',
                style: const TextStyle(color: Color(0xFF8BA7B7), fontSize: 9),
              ),
              IconButton(
                tooltip: 'مسح العرض فقط',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _ptyConsole.clear();
                  _ptyOutputVersion++;
                }),
                icon: const Icon(Icons.clear_all, size: 17, color: Color(0xFF8BA7B7)),
              ),
            ]),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 64, maxHeight: 230),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              reverse: true,
              child: SelectableText(
                output.isEmpty
                    ? 'بانتظار مخرجات الطرفية… ستظهر الأوامر والنتائج هنا أثناء التنفيذ.'
                    : output,
                key: ValueKey<int>(_ptyOutputVersion),
                style: const TextStyle(
                  color: Color(0xFFB7D8C9),
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspaceTabs() {
    const labels = ['المحادثة', 'النشاط والخطة', 'النتائج'];
    const icons = [Icons.forum_outlined, Icons.account_tree_outlined, Icons.fact_check_outlined];
    return Container(
      color: const Color(0xFF0E1722),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF09131D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF223847)),
        ),
        child: Row(children: List.generate(labels.length, (i) {
          final selected = _workspaceTab == i;
          return Expanded(child: Semantics(
            selected: selected,
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _workspaceTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF173847) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? const Color(0xFF2D7187) : Colors.transparent),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icons[i], size: 15, color: selected ? const Color(0xFF65D9E9) : const Color(0xFF8197A7)),
                  const SizedBox(width: 5),
                  Flexible(child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? const Color(0xFFE2F8FC) : const Color(0xFF9BAFBE)))),
                ]),
              ),
            ),
          ));
        })),
      ),
    );
  }

  Widget _emptyWorkspace(String title, String detail, IconData icon) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFF111D29),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF263B4A)),
    ),
    child: Column(children: [
      Container(width: 54, height: 54,
        decoration: BoxDecoration(color: const Color(0xFF173443), borderRadius: BorderRadius.circular(17)),
        child: Icon(icon, size: 27, color: const Color(0xFF35D3E8))),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 6),
      Text(detail, textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF9BAFBE), fontSize: 12, height: 1.55)),
      if (_workspaceTab != 0) ...[
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => setState(() => _workspaceTab = 0),
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('العودة إلى المحادثة'),
        ),
      ],
    ]),
  );

  String _buildSessionMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Zion Super Agent — تقرير الجلسة')
      ..writeln()
      ..writeln('## حالة النموذج')
      ..writeln('- النموذج: ${_modelName ?? 'غير محدد'}')
      ..writeln('- الحالة: $_modelStatus')
      ..writeln()
      ..writeln('## المحادثة');
    for (final message in _messages) {
      buffer.writeln();
      buffer.writeln(message['role'] == 'user' ? '**المستخدم:**' : '**Zion Agent:**');
      buffer.writeln(message['text'] ?? '');
    }
    buffer.writeln();
    buffer.writeln('## سجل النشاط');
    for (final event in _events) {
      buffer.writeln('- [${_stateLabel(event.state)}] ${event.message}');
    }
    if (_result != null) {
      buffer.writeln();
      buffer.writeln('## النتيجة');
      buffer.writeln(_visibleResultSummary(_result!));
    }
    return buffer.toString();
  }

  Future<void> _exportSession() async {
    await Clipboard.setData(ClipboardData(text: _buildSessionMarkdown()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('تم نسخ تقرير الجلسة بالمحادثة والنشاط والنتائج'),
        duration: Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Widget _workspaceOverview() {
    final running = _runtime.canCancel && !_runtime.canApprove;
    final statusColor = _runtime.canApprove
        ? const Color(0xFFFFB454)
        : running
            ? const Color(0xFF35D3E8)
            : _result == null || _result!.success
                ? const Color(0xFF45D6A0)
                : const Color(0xFFFF7474);
    final status = _runtime.canApprove
        ? 'بانتظار الموافقة'
        : running
            ? 'ينفذ الآن'
            : _submitting
                ? 'يجهز المهمة'
                : _result == null
                    ? 'جاهز للعمل'
                    : _result!.success ? 'اكتملت المهمة' : 'تحتاج إلى مراجعة';
    return Container(
      color: const Color(0xFF0E1722),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF142231),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF294252)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12))),
              if (_runtime.canCancel)
                TextButton.icon(
                  onPressed: _runtime.cancel,
                  icon: const Icon(Icons.stop_circle_outlined, size: 17),
                  label: const Text('إيقاف'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8585), visualDensity: VisualDensity.compact),
                ),
              IconButton(
                tooltip: _workspaceDetailsExpanded ? 'إخفاء تفاصيل النموذج' : 'عرض تفاصيل النموذج',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _workspaceDetailsExpanded = !_workspaceDetailsExpanded),
                icon: Icon(
                  _workspaceDetailsExpanded ? Icons.expand_less_rounded : Icons.tune_rounded,
                  color: const Color(0xFF91A7B7),
                  size: 20,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.memory_outlined, size: 20, color: Color(0xFF35D3E8)),
              const SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_modelLoading ? 'جارٍ تهيئة النموذج المحلي' : (_modelName ?? 'الذكاء الاصطناعي المحلي'),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(_modelStatus, style: const TextStyle(color: Color(0xFF9BAFBE), fontSize: 11, height: 1.4)),
              ])),
              if (_modelLoading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(_modelReady ? Icons.check_circle : Icons.info_outline,
                  color: _modelReady ? const Color(0xFF45D6A0) : const Color(0xFFFFB454), size: 20),
            ]),
            if (_workspaceDetailsExpanded) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (!_modelReady && !_modelLoading && _candidateModel != null)
                  _outlineAction(Icons.play_circle_outline, 'تحميل النموذج', _runtime.canCancel ? null : () => unawaited(_initializeModel())),
                if (!_modelReady && !_modelLoading)
                  _outlineAction(Icons.file_open_outlined, 'استيراد GGUF', _runtime.canCancel ? null : () => unawaited(_initializeModel(pick: true))),
                _outlineAction(Icons.refresh, 'فحص النموذج', (_modelLoading || _runtime.canCancel) ? null : () => unawaited(_discoverModel())),
                _statusTag(Icons.lock_outline, 'موافقة للخطوات الحساسة', const Color(0xFFFFB454)),
              ]),
              if (_availableModels.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('نماذج التعاون في الجلسة', style: TextStyle(color: Color(0xFFD9EAF2), fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 3),
                const Text('اختر نموذجين أو أكثر. سيعملون بالتتابع ويتبادلون ملخصات التحليل؛ يُحمّل نموذج واحد فقط في كل مرة لتقليل ضغط الذاكرة.', style: TextStyle(color: Color(0xFF9BAFBE), fontSize: 10, height: 1.4)),
                const SizedBox(height: 5),
                ..._availableModels.map((model) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: const Color(0xFF35D3E8),
                  checkColor: const Color(0xFF07131B),
                  value: _collaborationModels.contains(model.path),
                  onChanged: (_modelLoading || _submitting || _runtime.canCancel) ? null : (selected) => setState(() {
                    if (selected == true) {
                      _collaborationModels.add(model.path);
                    } else {
                      _collaborationModels.remove(model.path);
                    }
                  }),
                  title: Text(model.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  subtitle: Text('${(model.sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MiB${_modelName == model.name ? ' · النموذج الحالي' : ''}', style: const TextStyle(color: Color(0xFF8197A7), fontSize: 9)),
                )),
              ],
            ],
          ]),
        ),
        if (_runtime.canApprove) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF332719),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFB454).withOpacity(.55)),
            ),
            child: Row(children: [
              const Icon(Icons.policy_outlined, color: Color(0xFFFFB454), size: 22),
              const SizedBox(width: 9),
              const Expanded(child: Text('تتطلب الخطوة الحالية موافقتك قبل التنفيذ.', style: TextStyle(color: Colors.white, fontSize: 11))),
              TextButton(onPressed: _runtime.deny, child: const Text('رفض', style: TextStyle(color: Color(0xFFFF8585)))),
              FilledButton(onPressed: _runtime.approve, child: const Text('موافقة')),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        if (_workspaceDetailsExpanded) ...[
          Row(children: [
            Expanded(child: _metricCard('الأنشطة', '${_events.length}', Icons.timeline_outlined)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('خطوات النتيجة', '${_result?.steps.length ?? 0}', Icons.checklist_rtl_outlined)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('المحادثة', '${_messages.length}', Icons.forum_outlined)),
          ]),
        ],
      ]),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFF111D29), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFF233746))),
    child: Row(children: [
      Icon(icon, size: 17, color: const Color(0xFF35D3E8)),
      const SizedBox(width: 7),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9BAFBE), fontSize: 10)),
      ])),
    ]),
  );

  Widget _statusTag(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: color.withOpacity(.09), borderRadius: BorderRadius.circular(11), border: Border.all(color: color.withOpacity(.28))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color), const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _outlineAction(IconData icon, String label, VoidCallback? onPressed) => OutlinedButton.icon(
    onPressed: onPressed, icon: Icon(icon, size: 16), label: Text(label, style: const TextStyle(fontSize: 11)),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFB8D9E4), side: const BorderSide(color: Color(0xFF345363)),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9), visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    ),
  );

  Widget _quickActions() => Container(
    margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: const Color(0xFF111D29), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF233746))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ابدأ بمهمة', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      const Text('اكتب هدفك بلغتك الطبيعية، وسيعرض الوكيل خطته وخطوات التنفيذ والنتائج الفعلية.',
        style: TextStyle(color: Color(0xFF9BAFBE), fontSize: 12, height: 1.5)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _quickPrompt('فحص البيئة', 'نفّذ الأمر pwd ثم اشرح النتيجة'),
        _quickPrompt('تحليل مهمة', 'حلّل هذه المهمة محلياً واشرح خطوات تنفيذها'),
        _quickPrompt('عرض المخرجات', 'ماهي مخرجاتك؟ اشرح الأدوات والنتائج المتاحة'),
      ]),
    ]),
  );

  Widget _quickPrompt(String label, String prompt) => ActionChip(
    avatar: const Icon(Icons.arrow_back, size: 15, color: Color(0xFF35D3E8)),
    label: Text(label),
    onPressed: (_runtime.canCancel || _submitting) ? null : () => setState(() => _input.text = prompt),
    backgroundColor: const Color(0xFF182B39),
    side: const BorderSide(color: Color(0xFF294858)),
    labelStyle: const TextStyle(color: Color(0xFFD7E8EF), fontSize: 11),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
  );

  Widget _workingBanner(String title, String detail) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFF38BDF8).withValues(alpha: .30),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF38BDF8).withValues(alpha: .06),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 21),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title == 'الوكيل يعمل' ? 'Zion Super Agent يعمل الآن' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _SuperAgentTypingDots(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(color: Color(0xFF9BAFBE), fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _copyMessage(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('تم نسخ النص'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _editMessage(int index) {
    if (_runtime.canCancel || _submitting || index < 0 || index >= _messages.length) return;
    final message = _messages[index];
    if (message['role'] != 'user') return;
    setState(() {
      _input.text = message['text'] ?? '';
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
      _messages.removeRange(index, _messages.length);
      _events.clear();
      _result = null;
    });
    unawaited(_persistMessages());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('عدّل الطلب ثم أرسله من جديد'),
        duration: Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Widget _message(int index, String role, String text) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760), margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF164354) : const Color(0xFF121E29),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 5), bottomRight: Radius.circular(isUser ? 5 : 16),
          ),
          border: Border.all(color: isUser ? const Color(0xFF2D7187) : const Color(0xFF263B4A)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isUser ? Icons.person_outline : Icons.hub_outlined, size: 15, color: isUser ? const Color(0xFF8EDCF0) : const Color(0xFF45D6C0)),
            const SizedBox(width: 6),
            Expanded(child: Text(isUser ? 'أنت' : 'Zion Agent', style: const TextStyle(color: Color(0xFFB8CAD5), fontSize: 10, fontWeight: FontWeight.w700))),
            IconButton(
              tooltip: 'نسخ الرسالة',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              padding: EdgeInsets.zero,
              onPressed: () => unawaited(_copyMessage(text)),
              icon: const Icon(Icons.content_copy_rounded, size: 15, color: Color(0xFF91A7B7)),
            ),
            if (isUser)
              IconButton(
                tooltip: 'تعديل الطلب',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                padding: EdgeInsets.zero,
                onPressed: (_runtime.canCancel || _submitting) ? null : () => _editMessage(index),
                icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF8EDCF0)),
              ),
          ]),
          const SizedBox(height: 7),
          SelectableText(text, style: const TextStyle(color: Color(0xFFE5EDF2), height: 1.55, fontSize: 13)),
        ]),
      ),
    );
  }

  List<AgentEvent> _visibleEvents() => _events.where((event) {
    if (_activityFilter == 1) return event.state == AgentState.failed;
    if (_activityFilter == 2) return event.state == AgentState.waitingApproval;
    return true;
  }).toList(growable: false);

  Widget _activityFilterChip(String label, int value) => FilterChip(
    label: Text(label),
    selected: _activityFilter == value,
    onSelected: (_) => setState(() => _activityFilter = value),
    showCheckmark: false,
    visualDensity: VisualDensity.compact,
    backgroundColor: const Color(0xFF162633),
    selectedColor: const Color(0xFF174452),
    side: BorderSide(color: _activityFilter == value ? const Color(0xFF35D3E8) : const Color(0xFF2B4657)),
    labelStyle: TextStyle(
      color: _activityFilter == value ? const Color(0xFFBDF5FC) : const Color(0xFF9BAFBE),
      fontSize: 11,
      fontWeight: _activityFilter == value ? FontWeight.w700 : FontWeight.w500,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  Widget _activity() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: const Color(0xFF111D29), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF263B4A))),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFF173443), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.timeline_outlined, color: Color(0xFF35D3E8), size: 19)),
        title: const Text('سجل نشاط الوكيل', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        subtitle: Text('${_events.length} حدث مسجل · يعرض أحدث 12 حدثاً', style: const TextStyle(color: Color(0xFF91A7B7), fontSize: 10)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Wrap(spacing: 7, runSpacing: 7, children: [
              _activityFilterChip('الكل', 0),
              _activityFilterChip('الإخفاقات', 1),
              _activityFilterChip('الموافقات', 2),
            ]),
          ),
          if (_visibleEvents().isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
              child: Text(
                _activityFilter == 1 ? 'لا توجد إخفاقات مسجلة.' : _activityFilter == 2 ? 'لا توجد خطوات تنتظر الموافقة.' : 'لا توجد أحداث مسجلة بعد.',
                style: const TextStyle(color: Color(0xFF91A7B7), fontSize: 12),
              ),
            ),
          for (final e in _visibleEvents().reversed.take(12).toList().reversed)
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 29, height: 29, decoration: BoxDecoration(color: _eventColor(e).withOpacity(.10), borderRadius: BorderRadius.circular(9)),
                child: Icon(_eventIcon(e), size: 16, color: _eventColor(e))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.message, style: const TextStyle(color: Color(0xFFE1EAF0), fontSize: 12, height: 1.4)),
                const SizedBox(height: 3),
                Text(_stateLabel(e.state), style: TextStyle(color: _eventColor(e), fontSize: 10)),
              ])),
            ])),
        ],
      ),
    ),
  );

  Widget _resultCard() {
    final result = _result!;
    final actual = _visibleResultSummary(result);
    return Card(
      color: const Color(0xFF101812),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(result.success ? Icons.task_alt : Icons.error_outline,
                  color: result.success ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(width: 8),
              const Expanded(child: Text('نتائج التنفيذ الفعلية')),
              IconButton(
                tooltip: 'نسخ النتائج',
                onPressed: () => Clipboard.setData(ClipboardData(text: actual)),
                icon: const Icon(Icons.copy, size: 18),
              ),
            ]),
            const SizedBox(height: 8),
            SelectableText(actual, style: const TextStyle(color: Colors.white70, height: 1.45)),
            if (result.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              for (var i = 0; i < result.steps.length; i++) _stepResultTile(i + 1, result.steps[i]),
            ],
            if (!result.success) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  onPressed: (_runtime.canCancel || _submitting) ? null : () {
                    _input.text = result.task;
                    _run();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepResultTile(int index, StepResult step) {
    final detail = _formatActualData(step.data);
    final text = [
      '$index. ${step.success ? 'نجاح' : 'فشل'} — ${step.summary}',
      if (step.error != null && step.error!.trim().isNotEmpty) 'الخطأ: ${step.error}',
      if (detail.isNotEmpty) 'المخرجات الفعلية:\n$detail',
      'المدة: ${step.duration.inMilliseconds} ms',
    ].join('\n');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (step.success ? Colors.greenAccent : Colors.redAccent).withOpacity(.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(step.success ? Icons.check_circle_outline : Icons.error_outline,
                  size: 17, color: step.success ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(width: 7),
              Expanded(child: Text('الخطوة $index', style: const TextStyle(fontWeight: FontWeight.w600))),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'نسخ نتيجة الخطوة',
                onPressed: () => Clipboard.setData(ClipboardData(text: text)),
                icon: const Icon(Icons.copy, size: 16),
              ),
            ]),
            SelectableText(text, style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _visibleResultSummary(AgentResult result) {
    if (result.steps.isEmpty) {
      return result.success
          ? 'اكتملت المهمة، لكن لم تُرجع الأدوات مخرجات تفصيلية.'
          : 'لم تكتمل المهمة. السبب: ${result.error ?? 'لم يقدّم المحرك سبباً محدداً.'}';
    }
    final lines = result.steps.asMap().entries.map((entry) {
      final step = entry.value;
      final output = _formatActualData(step.data);
      return [
        '${entry.key + 1}. ${step.success ? 'نجاح' : 'فشل'} — ${step.summary}',
        if (step.error != null && step.error!.trim().isNotEmpty) 'الخطأ: ${step.error}',
        if (output.isNotEmpty) 'المخرجات الفعلية: $output',
      ].join('\n');
    }).join('\n\n');
    return '${result.success ? 'اكتملت المهمة حسب نتائج الأدوات.' : 'لم تكتمل المهمة بنجاح.'}\nالمهمة: ${result.task}\n$lines${result.error == null ? '' : '\nالسبب النهائي: ${result.error}'}';
  }

  String _formatActualData(dynamic data) {
    if (data == null) return '';
    String value;
    try {
      if (data is String) {
        value = data
            .replaceAll(RegExp(r'\x1B\\[[0-?]*[ -/]*[@-~]'), '')
            .replaceAll('\u0000', '')
            .replaceAll('\r\n', '\n')
            .replaceAll('\r', '\n')
            .trim();
        // Normalize JSON-encoded tool output so every tool uses one readable
        // presentation instead of leaking escaped maps or quoted JSON strings.
        if ((value.startsWith('{') && value.endsWith('}')) ||
            (value.startsWith('[') && value.endsWith(']'))) {
          try {
            final decoded = jsonDecode(value);
            value = const JsonEncoder.withIndent('  ').convert(decoded);
          } catch (_) {}
        }
      } else {
        value = const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {
      value = data.toString();
    }
    const maxLength = 5000;
    return value.length <= maxLength
        ? value
        : '${value.substring(0, maxLength)}\n… تم اختصار المخرجات المعروضة؛ انسخ النتيجة الكاملة من مصدر الأداة.';
  }

  Widget _composer() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(color: Color(0xFF0E1722), border: Border(top: BorderSide(color: Color(0xFF243744)))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Icon(Icons.shield_outlined, size: 15, color: Color(0xFF45D6A0)),
          const SizedBox(width: 6),
          const Expanded(child: Text('محلي أولاً · موافقة قبل الخطوات الحساسة', style: TextStyle(color: Color(0xFF91A7B7), fontSize: 10))),
          if (_historyReady) Text('${_messages.length} رسالة', style: const TextStyle(color: Color(0xFF71899A), fontSize: 10)),
        ]),
        const SizedBox(height: 9),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Container(
            decoration: BoxDecoration(color: const Color(0xFF14212D), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF2B4657))),
            child: TextField(
              enabled: _historyReady && !_runtime.canCancel && !_submitting,
              controller: _input, minLines: 1, maxLines: 5,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _run(),
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              decoration: const InputDecoration(
                hintText: 'صف المهمة للوكيل… مثال: نفّذ الأمر pwd ثم اشرح النتيجة',
                hintStyle: TextStyle(color: Color(0xFF7F94A4), fontSize: 11),
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                border: InputBorder.none,
              ),
            ),
          )),
          const SizedBox(width: 8),
          SizedBox(width: 48, height: 48, child: FilledButton(
            onPressed: (!_historyReady || _runtime.canCancel || _submitting) ? null : _run,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF35BFD4), foregroundColor: const Color(0xFF07131B),
              disabledBackgroundColor: const Color(0xFF273945), padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Icon(Icons.arrow_upward_rounded, size: 22),
          )),
        ]),
      ]),
    ),
  );

  IconData _eventIcon(AgentEvent e)=>switch(e.state){
    AgentState.waitingApproval=>Icons.lock_outline,
    AgentState.completed=>Icons.check_circle_outline,
    AgentState.failed=>Icons.error_outline,
    AgentState.cancelled=>Icons.stop_circle_outlined,
    AgentState.planning=>Icons.account_tree_outlined,
    AgentState.executing=>Icons.play_circle_outline,
    AgentState.evaluating=>Icons.fact_check_outlined,
    AgentState.idle=>Icons.info_outline,
  };

  Color _eventColor(AgentEvent e)=>switch(e.state){
    AgentState.waitingApproval=>Colors.orangeAccent,
    AgentState.completed=>Colors.greenAccent,
    AgentState.failed=>Colors.redAccent,
    AgentState.cancelled=>Colors.orangeAccent,
    AgentState.planning=>Colors.cyanAccent,
    AgentState.executing=>Colors.white70,
    AgentState.evaluating=>Colors.cyanAccent,
    AgentState.idle=>Colors.white54,
  };

  String _stateLabel(AgentState s)=>switch(s){
    AgentState.idle=>'جاهز',AgentState.planning=>'تخطيط',AgentState.executing=>'تنفيذ',
    AgentState.evaluating=>'تقييم',AgentState.waitingApproval=>'بانتظار الموافقة',
    AgentState.completed=>'اكتمل',AgentState.failed=>'فشل',AgentState.cancelled=>'أُلغي',
  };

  @override void dispose(){
    // Detach route listeners only. Do not cancel the active session or close
    // its PTY when the user navigates to another screen.
    unawaited(_sub?.cancel());
    unawaited(_ptySubscription?.cancel());
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }
}
