import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/agent_models.dart';
import '../core/agent_runtime.dart';
import '../../ai/llama_service.dart';
import 'kali_agent_loop_screen.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});
  @override State<AgentScreen> createState()=>_AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  late final AgentRuntime _runtime;
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
  static const String _historyKey='zion_super_agent_messages_v1';
  String _modelStatus='جارٍ البحث عن نموذج GGUF محلي…';
  String? _modelName;
  LlamaModel? _candidateModel;

  @override void initState(){
    super.initState();
    _runtime=AgentRuntime();
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
          .where((m) => m.readable && m.path.isNotEmpty && m.sizeBytes > 0 && m.sizeBytes <= 2 * 1024 * 1024 * 1024)
          .toList()
        ..sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
      final nativeReady = await _runtime.orchestrator.ai.refreshLoadedState();
      if (mounted) setState(() {
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
                    : 'النماذج الموجودة أكبر من حد الذاكرة الآمن (2 GiB). اختر نموذجاً أصغر.')
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
      if (model.sizeBytes <= 0 || model.sizeBytes > 2 * 1024 * 1024 * 1024) {
        if (mounted) setState(() => _modelStatus = 'حجم النموذج يتجاوز حد الذاكرة الآمن (2 GiB). اختر نموذجاً أصغر.');
        return;
      }
      final ok = await _runtime.orchestrator.ai.loadModel(model.path, threads: 2);
      if (mounted) setState(() {
        _modelReady = ok;
        _modelName = ok ? model!.name : null;
        _modelStatus = ok
            ? 'النموذج المحلي جاهز'
            : 'تعذر تحميل النموذج. جرّب ملف GGUF أصغر ومتوافقاً مع ذاكرة الجهاز.';
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
    final task = _input.text.trim();
    if (task.isEmpty || !_historyReady || _runtime.canCancel || _submitting) return;
    // Deterministic tool tasks can run without a loaded model. Complex planning
    // uses the local GGUF model when it is available.
    setState(() {
      _submitting = true;
      _input.clear();
      _appendMessage({'role': 'user', 'text': task});
      _result = null;
    });
    await _persistMessages();
    _scrollEnd();
    try {
      final result = await _runtime.run(task, approveReviewed: false);
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

  void _scrollEnd()=>WidgetsBinding.instance.addPostFrameCallback((_){
    if(_scroll.hasClients)_scroll.animateTo(_scroll.position.maxScrollExtent,duration:const Duration(milliseconds:180),curve:Curves.easeOut);
  });

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFF070B08),
    appBar:AppBar(
      backgroundColor:const Color(0xFF0B120E),
      title:const Row(children:[Icon(Icons.auto_awesome,color:Color(0xFF00FF41)),SizedBox(width:8),Text('Zion Super Agent')]),
      actions:[
        IconButton(
          onPressed: (!_historyReady || _runtime.canCancel || _submitting) ? null : () {
            setState(() {
              _messages
                ..clear()
                ..add(const {'role':'assistant','text':'محادثة جديدة جاهزة. ما الذي تريد إنجازه؟'});
              _events.clear();
              _result = null;
            });
            unawaited(_persistMessages());
          },
          icon: const Icon(Icons.add_comment_outlined),
          tooltip: 'محادثة جديدة',
        ),
        IconButton(
          onPressed: _runtime.canCancel ? null : () {
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => KaliAgentLoopScreen(ai: _runtime.orchestrator.ai),
            ));
          },
          icon: const Icon(Icons.loop),
          tooltip: 'Agent Loop · Kali',
        ),
      ],
    ),
    body:Column(children:[
      _statusBar(),
      Expanded(child:ListView(
        controller:_scroll,
        padding:const EdgeInsets.fromLTRB(14,14,14,8),
        children:[
          for(final m in _messages)_message(m['role']!,m['text']!),
          if(_events.isNotEmpty)_activity(),
          if(_result!=null)_resultCard(),
          if(_runtime.canCancel)const LinearProgressIndicator(minHeight:2),
        ],
      )),
      _composer(),
    ]),
  );

  Widget _statusBar()=>Container(
    width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),color:const Color(0xFF0B120E),
    child:Wrap(spacing:8,runSpacing:6,children:[
      Chip(label:Text(_runtime.canApprove?'بانتظار الموافقة':_runtime.canCancel?'ينفذ الآن':'جاهز')),
      Chip(
        avatar: Icon(_modelReady ? Icons.memory : _modelLoading ? Icons.hourglass_top : Icons.warning_amber_rounded, size: 16),
        label: Text(_modelLoading ? 'تحميل النموذج…' : _modelReady ? (_modelName ?? 'Local AI') : 'النموذج غير جاهز'),
      ),
      if (_modelLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      if (!_modelReady && !_modelLoading && _candidateModel != null)
        TextButton.icon(
          onPressed: _runtime.canCancel ? null : () => unawaited(_initializeModel()),
          icon: const Icon(Icons.memory, size: 17),
          label: const Text('تحميل النموذج'),
        ),
      if (!_modelReady && !_modelLoading)
        TextButton.icon(
          onPressed: _runtime.canCancel ? null : () => unawaited(_initializeModel(pick: true)),
          icon: const Icon(Icons.file_open, size: 17),
          label: const Text('استيراد GGUF'),
        ),
      const Chip(label:Text('موافقة لكل خطوة حساسة')),
      if(_runtime.canApprove)...[
        IconButton.filled(onPressed:_runtime.approve,icon:const Icon(Icons.check,size:18),tooltip:'موافقة'),
        IconButton(onPressed:_runtime.deny,icon:const Icon(Icons.close,color:Colors.orangeAccent),tooltip:'رفض'),
      ],
      if(_runtime.canCancel)IconButton(onPressed:()=>_runtime.cancel(),icon:const Icon(Icons.stop_circle_outlined,color:Colors.redAccent),tooltip:'إلغاء'),
    ]),
  );

  Widget _message(String role,String text)=>Align(
    alignment:role=='user'?Alignment.centerRight:Alignment.centerLeft,
    child:Container(
      constraints:const BoxConstraints(maxWidth:760),
      margin:const EdgeInsets.only(bottom:10),
      padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(
        color:role=='user'?const Color(0xFF103D2A):const Color(0xFF101812),
        borderRadius:BorderRadius.circular(16),
        border:Border.all(color:const Color(0xFF00FF41).withOpacity(.12)),
      ),
      child:Text(text,style:const TextStyle(color:Colors.white70,height:1.45)),
    ),
  );

  Widget _activity()=>Card(
    color:const Color(0xFF0B120E),
    child:ExpansionTile(
      initiallyExpanded:true,
      leading:const Icon(Icons.timeline,color:Color(0xFF00FF41)),
      title:Text('نشاط الوكيل ('+_events.length.toString()+')'),
      children:[for(final e in _events)ListTile(
        dense:true,
        leading:Icon(_eventIcon(e),size:17,color:_eventColor(e)),
        title:Text(e.message,style:const TextStyle(fontSize:12,color:Colors.white70)),
        subtitle:Text(_stateLabel(e.state),style:const TextStyle(fontSize:10,color:Colors.white38)),
      )],
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
      value = data is String ? data : const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      value = data.toString();
    }
    const maxLength = 5000;
    return value.length <= maxLength
        ? value
        : '${value.substring(0, maxLength)}\n… تم اختصار المخرجات المعروضة؛ انسخ النتيجة الكاملة من مصدر الأداة.';
  }

  Widget _composer()=>SafeArea(
    child:Padding(
      padding:const EdgeInsets.fromLTRB(10,8,10,10),
      child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
        Expanded(child:TextField(
          enabled:_historyReady && !_runtime.canCancel && !_submitting,
          controller:_input,
          minLines:1,maxLines:5,
          onSubmitted:(_)=>_run(),
          style:const TextStyle(color:Colors.white),
          decoration:InputDecoration(
            hintText:'صف المهمة للوكيل… مثال: نفّذ الأمر pwd ثم اشرح النتيجة',
            hintStyle:const TextStyle(color:Colors.white38,fontSize:12),
            filled:true,fillColor:const Color(0xFF101812),
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),
          ),
        )),
        const SizedBox(width:8),
        IconButton.filled(onPressed:(!_historyReady || _runtime.canCancel || _submitting)?null:_run,icon:const Icon(Icons.arrow_upward),tooltip:'إرسال'),
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

  @override void dispose(){_sub?.cancel();_runtime.dispose();_input.dispose();_scroll.dispose();super.dispose();}
}
