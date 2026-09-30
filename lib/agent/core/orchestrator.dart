import 'dart:async';
import 'dart:convert';
import '../../ai/llama_service.dart';
import '../../core/ai/long_term_memory.dart';
import '../tools/tool_registry.dart';
import 'agent_models.dart';
import 'agent_policy.dart';
import 'cancellation_token.dart';

class AgentOrchestrator {
  final ToolRegistry tools;
  final AgentPolicy policy;
  final LongTermAIMemory memory;
  final LlamaService ai;
  final StreamController<AgentEvent> _events=StreamController<AgentEvent>.broadcast();
  AgentState _state=AgentState.idle;
  bool _running=false;
  static const Duration defaultStepTimeout = Duration(seconds: 30);
  static const int defaultMaxRecoveryAttempts = 2;

  AgentOrchestrator({ToolRegistry? tools,AgentPolicy? policy,LongTermAIMemory? memory,LlamaService? ai})
      :tools=tools??ToolRegistry(),policy=policy??const AgentPolicy(),memory=memory??LongTermAIMemory(),ai=ai??LlamaService();

  Stream<AgentEvent> get events=>_events.stream;
  AgentState get state=>_state;
  bool get isRunning=>_running;

  Future<AgentResult> executeTask(
    String task, {
    bool approveReviewed = false,
    CancellationToken? cancellationToken,
    Duration stepTimeout = defaultStepTimeout,
    int maxRecoveryAttempts = defaultMaxRecoveryAttempts,
  }) async {
    final clean = task.trim();
    if (clean.isEmpty) return AgentResult.error(clean, 'المهمة فارغة.');
    if (_running) return AgentResult.error(clean, 'Zion Agent مشغول بمهمة أخرى.');
    _running = true;
    _state = AgentState.planning;
    _log('🎯 بدء المهمة: $clean');
    final results = <StepResult>[];
    try {
      final plan = await _createPlan(clean);
      _log('📋 الخطة: ${plan.steps.length} خطوة.');
      _state = AgentState.executing;

      for (var i = 0; i < plan.steps.length; i++) {
        cancellationToken?.throwIfCancelled();
        final step = plan.steps[i];
        final decision = policy.evaluate(tool: step.tool, params: step.params);
        _log('▶️ [${i + 1}/${plan.steps.length}] ${step.description}');

        if (decision.risk == AgentRisk.blocked) {
          final r = StepResult.failure(decision.reason);
          results.add(r);
          _log('⛔ ${decision.reason}');
          return AgentResult(success: false, task: clean, steps: results, error: decision.reason);
        }

        if (decision.requiresApproval && !approveReviewed) {
          _state = AgentState.waitingApproval;
          final r = StepResult.failure('تحتاج هذه الخطوة موافقة: ${decision.reason}');
          results.add(r);
          _log('🔐 ${decision.reason}');
          return AgentResult(
            success: false,
            task: clean,
            steps: results,
            error: 'موافقة مطلوبة للخطوة: ${step.description}',
          );
        }

        final tool = tools.getTool(step.tool);
        if (tool == null) {
          final r = StepResult.failure('الأداة غير متاحة: ${step.tool}');
          results.add(r);
          return AgentResult(success: false, task: clean, steps: results, error: r.error);
        }

        cancellationToken?.throwIfCancelled();
        final started = DateTime.now();
        StepResult r;
        try {
          r = await tool.execute(step.params).timeout(stepTimeout);
        } on TimeoutException {
          r = StepResult.failure(
            'انتهت مهلة الخطوة بعد ${stepTimeout.inSeconds} ثانية.',
            duration: DateTime.now().difference(started),
          );
        }
        results.add(r);
        await memory.remember(
          kind: 'agent-step',
          text: step.description,
          metadata: {'tool': step.tool, 'success': r.success},
        );
        _log(r.success ? '  ✅ ${r.summary}' : '  ❌ ${r.error ?? r.summary}');

        if (!r.success) {
          _state = AgentState.evaluating;
          var recovered = false;
          var recoveryAttempt = 0;
          while (!recovered && recoveryAttempt < maxRecoveryAttempts) {
            recoveryAttempt++;
            cancellationToken?.throwIfCancelled();
            final alt = await _alternative(step, r.error ?? 'فشل');
            if (alt == null) break;
            final d = policy.evaluate(tool: alt.tool, params: alt.params);
            if (d.risk != AgentRisk.safe && !(approveReviewed && !d.requiresApproval)) {
              _log('🔐 البديل يحتاج موافقة أو محظور.');
              break;
            }
            final t = tools.getTool(alt.tool);
            if (t == null) break;
            cancellationToken?.throwIfCancelled();
            final alternativeStarted = DateTime.now();
            StepResult ar;
            try {
              ar = await t.execute(alt.params).timeout(stepTimeout);
            } on TimeoutException {
              ar = StepResult.failure(
                'انتهت مهلة الخطوة البديلة بعد ${stepTimeout.inSeconds} ثانية.',
                duration: DateTime.now().difference(alternativeStarted),
              );
            }
            results.add(ar);
            recovered = ar.success;
            _log('🔄 المحاولة البديلة $recoveryAttempt/$maxRecoveryAttempts: ${ar.success ? 'نجحت' : 'فشلت'}');
          }
          if (!recovered) {
            _state = AgentState.failed;
            return AgentResult(
              success: false,
              task: clean,
              steps: results,
              error: 'فشلت الخطوة: ${step.description}',
            );
          }
        }
        _state = AgentState.executing;
      }

      _state = AgentState.completed;
      final report = await _report(clean, results);
      _log('✅ اكتملت المهمة.');
      return AgentResult(success: true, task: clean, steps: results, report: report);
    } on AgentCancelledException {
      _state = AgentState.cancelled;
      _log('⏹️ تم إلغاء المهمة.');
      return AgentResult(success: false, task: clean, steps: results, error: 'تم إلغاء المهمة.');
    } catch (e) {
      _state = AgentState.failed;
      _log('❌ ${e.toString()}');
      return AgentResult(success: false, task: clean, steps: results, error: e.toString());
    } finally {
      _running = false;
      if (_state != AgentState.completed &&
          _state != AgentState.failed &&
          _state != AgentState.cancelled &&
          _state != AgentState.waitingApproval) {
        _state = AgentState.idle;
      }
    }
  }

  Future<AgentPlan> _createPlan(String task) async {
    await memory.load();
    if(await ai.nativeLoaded){
      final prompt='''أنت مخطط Zion Agent. المهمة: $task
أنشئ خطوات عملية باستخدام الأدوات: ai,data,file,http,shell,python.
لا تستخدم أدوات هجومية أو استغلال أو تجاوز حماية.
أعد JSON فقط بالشكل {"steps":[{"id":"1","description":"...","tool":"...","params":{},"requiresEvaluation":false}]}''';
      final response=await ai.generate(prompt,maxTokens:900,temperature:0.2);
      final parsed=_parsePlan(response);if(parsed!=null&&parsed.steps.isNotEmpty)return parsed;
    }
    return _heuristicPlan(task);
  }

  AgentPlan? _parsePlan(String response){
    try{final s=response.indexOf('{'),e=response.lastIndexOf('}');if(s<0||e<=s)return null;final j=jsonDecode(response.substring(s,e+1));final list=j['steps'];if(list is! List)return null;
      return AgentPlan(steps:list.whereType<Map>().map((x)=>AgentStep(id:x['id']?.toString()??DateTime.now().microsecondsSinceEpoch.toString(),description:x['description']?.toString()??'خطوة',tool:x['tool']?.toString()??'ai',params:Map<String,dynamic>.from(x['params'] is Map?x['params']:{},),requiresEvaluation:x['requiresEvaluation']==true)).toList());
    }catch(_){return null;}
  }

  AgentPlan _heuristicPlan(String task){
    final lower=task.toLowerCase();
    if(lower.contains('ابحث')||lower.contains('search'))return AgentPlan(steps:[AgentStep(id:'1',description:'البحث عن المعلومات',tool:'http',params:{'method':'GET','url':'https://html.duckduckgo.com/html/?q='+Uri.encodeComponent(task)}) ,AgentStep(id:'2',description:'تلخيص النتائج',tool:'ai',params:{'prompt':'لخّص نتائج البحث التالية للمهمة: '+task},requiresEvaluation:true)]);
    if(lower.contains('حلل')||lower.contains('analy'))return AgentPlan(steps:[AgentStep(id:'1',description:'تحليل المهمة محلياً',tool:'ai',params:{'prompt':task},requiresEvaluation:true)]);
    return AgentPlan(steps:[AgentStep(id:'1',description:'تحليل المهمة محلياً',tool:'ai',params:{'prompt':task},requiresEvaluation:true)]);
  }

  Future<AgentStep?> _alternative(AgentStep step,String error) async {
    if(!await ai.nativeLoaded)return null;
    final response=await ai.generate('الخطوة الفاشلة: '+step.description+'\nالأداة: '+step.tool+'\nالخطأ: '+error+'\nاقترح خطوة دفاعية بديلة JSON فقط.',maxTokens:500,temperature:0.1);
    final p=_parsePlan(response);return p?.steps.isNotEmpty==true?p!.steps.first:null;
  }

  Future<String> _report(String task,List<StepResult> results) async {
    final summary=results.map((r)=>r.success?'نجاح: '+r.summary:'فشل: '+(r.error??r.summary)).join('\n');
    if(await ai.nativeLoaded){final r=await ai.generate('المهمة: '+task+'\nالنتائج:\n'+summary+'\nاكتب تقريراً مختصراً.',maxTokens:700,temperature:0.2);if(!r.startsWith('ERROR:'))return r;}
    return summary;
  }

  void _log(String message)=>_events.add(AgentEvent(timestamp:DateTime.now(),message:message,state:_state));
  void dispose(){_events.close();}
}
