import 'dart:async';
import 'dart:convert';
import '../../ai/llama_service.dart';
import '../../core/ai/long_term_memory.dart';
import '../tools/tool_registry.dart';
import 'agent_models.dart';
import 'agent_policy.dart';
import 'cancellation_token.dart';

class AgentOrchestrator {
  late final ToolRegistry tools;
  final AgentPolicy policy;
  final LongTermAIMemory memory;
  final LlamaService ai;
  final StreamController<AgentEvent> _events=StreamController<AgentEvent>.broadcast();
  AgentState _state=AgentState.idle;
  bool _running=false;
  Completer<bool>? _approvalCompleter;
  String? _pendingApprovalStepId;
  static const Duration defaultStepTimeout = Duration(seconds: 90);
  static const int defaultMaxRecoveryAttempts = 2;

  AgentOrchestrator({ToolRegistry? tools,AgentPolicy? policy,LongTermAIMemory? memory,LlamaService? ai})
      :policy=policy??const AgentPolicy(),memory=memory??LongTermAIMemory(),ai=ai??LlamaService() {
    this.tools = tools ?? ToolRegistry(ai: this.ai);
  }

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
    _log('بدء المهمة: $clean');
    final results = <StepResult>[];
    try {
      cancellationToken?.throwIfCancelled();
      final plan = await _createPlan(clean);
      _log('الخطة: ${plan.steps.length} خطوة.');
      if (approveReviewed) {
        _log('لن يتم تجاوز الموافقات؛ كل خطوة حساسة تتطلب موافقة منفصلة.');
      }
      _state = AgentState.executing;

      for (var i = 0; i < plan.steps.length; i++) {
        cancellationToken?.throwIfCancelled();
        final step = plan.steps[i];
        final params = _resolveParams(step.params, results);
        final tool = tools.getTool(step.tool);
        if (tool == null) {
          final r = StepResult.failure('الأداة غير متاحة: ${step.tool}');
          results.add(r);
          return AgentResult(success: false, task: clean, steps: results, error: r.error);
        }
        final policyDecision = policy.evaluate(tool: step.tool, params: params);
        // Never trust the model's declared permission alone: derive the
        // effective permission from the registered tool implementation too.
        final requiredPermissions = tool.requiredPermissions(params);
        final toolRequiresApproval = tool.requiresApproval(params);
        // Read-only web retrieval is a normal agent capability. Mutations and
        // local/process side effects still require explicit approval.
        final isReadOnlyWeb = tool.supportsReadOnlyWebRetrieval &&
            (params['action']?.toString() == 'search' ||
                params['action']?.toString() == 'fetch');
        final requiresSensitiveApproval =
            requiredPermissions.any((permission) =>
                permission == AgentPermission.localWrite ||
                permission == AgentPermission.process ||
                permission == AgentPermission.externalSideEffect ||
                (permission == AgentPermission.network && !isReadOnlyWeb)) ||
            toolRequiresApproval;
        final declaredReview =
            (step.risk == AgentRisk.review && !isReadOnlyWeb) ||
            step.requiresApproval ||
            (step.permission != AgentPermission.readOnly &&
                !(isReadOnlyWeb && step.permission == AgentPermission.network));
        final decision = step.risk == AgentRisk.blocked
            ? const AgentPolicyDecision(risk: AgentRisk.blocked, reason: 'الخطوة مصنفة محظورة من مخطط Zion Agent.', requiresApproval: false)
            : (declaredReview || requiresSensitiveApproval)
                ? AgentPolicyDecision(risk: policyDecision.risk == AgentRisk.blocked ? AgentRisk.blocked : AgentRisk.review, reason: policyDecision.risk == AgentRisk.blocked ? policyDecision.reason : 'الخطوة تتطلب مراجعة صلاحياتها قبل التنفيذ.', requiresApproval: true)
                : policyDecision;
        _log('[ خطوة ${i + 1}/${plan.steps.length}] ${step.description}');

        if (decision.risk == AgentRisk.blocked) {
          final r = StepResult.failure(decision.reason);
          results.add(r);
          _log('محظور: ${decision.reason}');
          return AgentResult(success: false, task: clean, steps: results, error: decision.reason);
        }

        if (decision.requiresApproval) {
          _state = AgentState.waitingApproval;
          _pendingApprovalStepId = step.id;
          _log('بانتظار موافقتك: ${decision.reason}');
          final approved = await _waitForApproval(
            cancellationToken,
            step.description,
          );
          _pendingApprovalStepId = null;
          if (!approved) {
            _state = AgentState.failed;
            final r = StepResult.failure('تم رفض تنفيذ الخطوة: ${step.description}');
            results.add(r);
            _log('تم رفض الخطوة.');
            return AgentResult(
              success: false,
              task: clean,
              steps: results,
              error: 'تم رفض تنفيذ الخطوة: ${step.description}',
            );
          }
          _state = AgentState.executing;
          _log('تمت الموافقة على الخطوة.');
        }

        cancellationToken?.throwIfCancelled();
        final started = DateTime.now();
        StepResult r;
        try {
          r = await tool.executeCancellable(params, cancellationToken).timeout(stepTimeout);
        } on TimeoutException {
          r = StepResult.failure(
            'انتهت مهلة الخطوة بعد ${stepTimeout.inSeconds} ثانية.',
            duration: DateTime.now().difference(started),
          );
        }
        cancellationToken?.throwIfCancelled();
        results.add(r);
        await memory.remember(
          kind: 'agent-step',
          text: '${step.description}\n${r.success ? r.summary : (r.error ?? r.summary)}',
          metadata: {
            'tool': step.tool,
            'success': r.success,
            'stepId': step.id,
            'durationMs': r.duration.inMilliseconds,
          },
        );
        _log(r.success ? 'نجاح: ${r.summary}' : 'فشل: ${r.error ?? r.summary}');

        if (!r.success) {
          _state = AgentState.evaluating;
          var recovered = false;
          var recoveryAttempt = 0;
          while (!recovered && recoveryAttempt < maxRecoveryAttempts) {
            recoveryAttempt++;
            cancellationToken?.throwIfCancelled();
            final alt = await _alternative(step, r.error ?? 'فشل', results);
            if (alt == null) break;
            final altParams = _resolveParams(alt.params, results);
            final t = tools.getTool(alt.tool);
            if (t == null) {
              _log('تعذر تنفيذ البديل: الأداة غير مسجلة.');
              break;
            }
            if (alt.tool == step.tool && jsonEncode(altParams) == jsonEncode(params)) {
              _log('تم تجاهل البديل لأنه يكرر الخطوة الفاشلة نفسها.');
              break;
            }
            final d = policy.evaluate(tool: alt.tool, params: altParams);
            if (d.risk == AgentRisk.blocked || alt.risk == AgentRisk.blocked) {
              _log('تم حظر خطة الاستعادة بواسطة سياسة الأمان.');
              break;
            }
            final altPermissions = t.requiredPermissions(altParams);
            final altNeedsApproval =
                d.requiresApproval ||
                d.risk == AgentRisk.review ||
                altPermissions.any((permission) => permission != AgentPermission.readOnly) ||
                t.requiresApproval(altParams) ||
                alt.permission != AgentPermission.readOnly ||
                alt.requiresApproval ||
                alt.risk == AgentRisk.review;
            if (altNeedsApproval) {
              _state = AgentState.waitingApproval;
              _pendingApprovalStepId = alt.id;
              _log('خطة الاستعادة تتطلب موافقتك: ${alt.description}');
              final approved = await _waitForApproval(cancellationToken, alt.description);
              _pendingApprovalStepId = null;
              if (!approved) {
                _state = AgentState.failed;
                _log('رُفضت خطوة الاستعادة.');
                break;
              }
              _state = AgentState.executing;
              _log('تمت الموافقة على خطوة الاستعادة.');
            }
            cancellationToken?.throwIfCancelled();
            final alternativeStarted = DateTime.now();
            StepResult ar;
            try {
              ar = await t.executeCancellable(altParams, cancellationToken).timeout(stepTimeout);
            } on TimeoutException {
              ar = StepResult.failure(
                'انتهت مهلة الخطوة البديلة بعد ${stepTimeout.inSeconds} ثانية.',
                duration: DateTime.now().difference(alternativeStarted),
              );
            }
            cancellationToken?.throwIfCancelled();
            results.add(ar);
            recovered = ar.success;
            await memory.remember(
              kind: 'agent-recovery',
              text: '${alt.description}\n${ar.success ? ar.summary : (ar.error ?? ar.summary)}',
              metadata: {
                'tool': alt.tool,
                'success': ar.success,
                'stepId': alt.id,
                'durationMs': ar.duration.inMilliseconds,
              },
            );
            _log('المحاولة البديلة $recoveryAttempt/$maxRecoveryAttempts: ${ar.success ? 'نجحت' : 'فشلت'}');
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
      final report = _actualResultsSummary(clean, results);
      await memory.remember(
        kind: 'agent-task',
        text: clean,
        metadata: {
          'success': true,
          'steps': results.length,
          'report': report.length > 1200 ? report.substring(0, 1200) : report,
        },
      );
      _log('اكتملت المهمة.');
      return AgentResult(success: true, task: clean, steps: results, report: report);
    } on AgentCancelledException {
      _state = AgentState.cancelled;
      _log('تم إلغاء المهمة.');
      return AgentResult(success: false, task: clean, steps: results, error: 'تم إلغاء المهمة.');
    } catch (e) {
      _state = AgentState.failed;
      _log('خطأ: ${e.toString()}');
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

  Future<bool> _waitForApproval(
    CancellationToken? cancellationToken,
    String description,
  ) async {
    final completer = Completer<bool>();
    StreamSubscription<void>? cancellationSubscription;
    _approvalCompleter = completer;
    try {
      if (cancellationToken == null) return await completer.future;
      if (cancellationToken.isCancelled) {
        throw const AgentCancelledException();
      }
      final cancelled = Completer<bool>();
      cancellationSubscription = cancellationToken.onCancel.listen((_) {
        if (!cancelled.isCompleted) {
          cancelled.completeError(const AgentCancelledException());
        }
      });
      // Close the small race between the pre-check and stream subscription.
      if (cancellationToken.isCancelled && !cancelled.isCompleted) {
        cancelled.completeError(const AgentCancelledException());
      }
      return await Future.any<bool>([
        completer.future,
        cancelled.future,
      ]);
    } finally {
      await cancellationSubscription?.cancel();
      if (identical(_approvalCompleter, completer)) {
        _approvalCompleter = null;
      }
    }
  }

  void approvePendingStep() {
    final completer = _approvalCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete(true);
  }

  void denyPendingStep() {
    final completer = _approvalCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete(false);
  }

  bool get isWaitingForApproval => _approvalCompleter != null;
  String? get pendingApprovalStepId => _pendingApprovalStepId;

  Future<AgentPlan> _createPlan(String task) async {
    // Model-generated plans are mandatory. Never silently replace a failed or
    // malformed model response with a heuristic plan.
    if (!await _nativeAiAvailable()) {
      throw StateError(
        'النموذج المحلي غير جاهز. حمّل Qwen GGUF وتحقق من ظهور حالة «جاهز» قبل تشغيل الوكيل.',
      );
    }

    final toolCatalog = tools.availableTools.map((name) {
      final tool = tools.getTool(name)!;
      return <String, dynamic>{
        'name': tool.name,
        'description': tool.description.length > 90
            ? tool.description.substring(0, 90)
            : tool.description,
        'parameters': tool.parameters.keys.toList(growable: false),
      };
    }).toList(growable: false);

    // The Android native context is deliberately capped at 512 tokens. Keep
    // planner context compact; the previous full schemas + memory often made
    // planning exceed the context budget or run for too long on small phones.
    final prompt = '''أنت مخطط Zion Super Agent. حوّل المهمة إلى خطة قابلة للتنفيذ باستخدام الأدوات المتاحة فقط.
المهمة: $task
الأدوات ومعاملاتها المسموحة:
${jsonEncode(toolCatalog)}
قواعد: من 1 إلى 4 خطوات. لا تخترع أداة أو معاملًا. استخدم readOnly افتراضيًا. أي كتابة أو تشغيل عملية أو شبكة تتطلب موافقة. لا تنفذ استغلالًا أو تجاوز حماية أو سرقة بيانات.
أعد JSON فقط بهذا الشكل:
{"steps":[{"id":"1","description":"وصف مختصر","tool":"اسم أداة من القائمة","params":{},"requiresEvaluation":true,"requiresApproval":false,"permission":"readOnly","risk":"safe"}]}''';

    final response = await ai
        .generate(prompt, maxTokens: 160, temperature: 0.1)
        .timeout(const Duration(seconds: 90));
    if (response.trim().isEmpty || response.startsWith('ERROR:')) {
      throw StateError('فشل النموذج المحلي في إنشاء الخطة: ${response.trim().isEmpty ? 'استجابة فارغة' : response}');
    }
    final parsed = _parsePlan(response, task: task);
    if (parsed == null || parsed.steps.isEmpty) {
      final excerpt = response.length > 240 ? response.substring(0, 240) : response;
      _log('رفض مخطط النموذج لأن JSON أو أسماء الأدوات غير صالحة: $excerpt');
      throw StateError(
        'لم ينتج النموذج خطة JSON صالحة؛ لم تُنفذ أي خطوة ولم تُستخدم خطة احتياطية. أعد المحاولة بعد التأكد من تحميل نموذج Instruct الصحيح.',
      );
    }
    _log('تم اعتماد خطة النموذج المحلي: ${parsed.steps.length} خطوة.');
    return parsed;
  }

  AgentPlan? _parsePlan(String response, {String task = ''}) {
    try {
      final start = response.indexOf('{');
      final end = response.lastIndexOf('}');
      if (start < 0 || end <= start) return null;
      final decoded = jsonDecode(response.substring(start, end + 1));
      if (decoded is! Map) return null;
      final rawSteps = decoded['steps'];
      if (rawSteps is! List || rawSteps.isEmpty || rawSteps.length > 8) return null;

      final steps = <AgentStep>[];
      final ids = <String>{};
      for (var index = 0; index < rawSteps.length; index++) {
        final raw = rawSteps[index];
        if (raw is! Map) return null;
        final id = (raw['id'] ?? (index + 1)).toString().trim();
        final description = raw['description']?.toString().trim() ?? '';
        final toolName = raw['tool']?.toString().trim() ?? '';
        final tool = tools.getTool(toolName);
        if (id.isEmpty || !ids.add(id) || description.isEmpty || description.length > 240 || tool == null) {
          return null;
        }
        final rawParams = raw['params'];
        if (rawParams != null && rawParams is! Map) return null;
        final params = Map<String, dynamic>.from(rawParams is Map ? rawParams : const {});
        if (!params.keys.every(tool.parameters.containsKey)) return null;
        if (!tool.supports(params)) return null;
        steps.add(AgentStep(
          id: id,
          description: description,
          tool: toolName,
          params: params,
          requiresEvaluation: raw['requiresEvaluation'] == true,
          requiresApproval: raw['requiresApproval'] == true ||
              _permissionFrom(raw['permission']) != AgentPermission.readOnly,
          permission: _permissionFrom(raw['permission']),
          risk: _riskFrom(raw['risk']),
        ));
      }
      return AgentPlan(task: task, steps: steps);
    } catch (_) {
      return null;
    }
  }

  AgentPermission _permissionFrom(dynamic value){switch(value?.toString()){case 'localWrite':return AgentPermission.localWrite;case 'network':return AgentPermission.network;case 'process':return AgentPermission.process;case 'externalSideEffect':return AgentPermission.externalSideEffect;default:return AgentPermission.readOnly;}}
  AgentRisk _riskFrom(dynamic value){switch(value?.toString()){case 'review':return AgentRisk.review;case 'blocked':return AgentRisk.blocked;default:return AgentRisk.safe;}}

  Map<String, dynamic> _resolveParams(Map<String, dynamic> input, List<StepResult> results) {
    final output = <String, dynamic>{};
    for (final entry in input.entries) {
      final value = entry.value;
      if (value is String) {
        var resolved = value.replaceAll('{{previous_result}}',
            results.isEmpty ? '' : _stepOutput(results.last));
        resolved = resolved.replaceAllMapped(RegExp(r'\{\{step_(\d+)\}\}'), (match) {
          final index = int.tryParse(match.group(1) ?? '') ?? 0;
          return index > 0 && index <= results.length ? _stepOutput(results[index - 1]) : '';
        });
        output[entry.key] = resolved;
      } else {
        output[entry.key] = value;
      }
    }
    return output;
  }

  String _stepOutput(StepResult result) {
    final value = result.data ?? result.summary;
    final output = value is String ? value : jsonEncode(value);
    return output.length > 3000 ? '${output.substring(0, 3000)}…[تم اقتطاع المخرجات]' : output;
  }

  Future<bool> _nativeAiAvailable() async {
    // The native llama.cpp model is a process-wide singleton and may have been
    // loaded by the Offline AI screen through another Dart LlamaService object.
    // Synchronize this instance with native state instead of trusting its
    // potentially stale local isLoaded flag.
    try {
      return await ai.refreshLoadedState().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<AgentStep?> _alternative(
    AgentStep failedStep,
    String error,
    List<StepResult> previousResults,
  ) async {
    if (!await _nativeAiAvailable()) return null;
    final toolCatalog = tools.availableTools.map((name) {
      final tool = tools.getTool(name)!;
      return <String, dynamic>{
        'name': tool.name,
        'description': tool.description.length > 90
            ? tool.description.substring(0, 90)
            : tool.description,
        'parameters': tool.parameters.keys.toList(growable: false),
      };
    }).toList(growable: false);
    final context = previousResults.asMap().entries.map((entry) {
      return 'الخطوة ${entry.key + 1}: ${entry.value.success ? 'نجاح' : 'فشل'}؛ ${entry.value.summary}؛ المخرجات: ${_stepOutput(entry.value)}';
    }).join('\n');
    final response = await ai.generate(
      'تعذرت خطوة في مهمة Zion Super Agent. اقترح بديلاً عملياً واحداً لا يعيد الخطوة نفسها دون تغيير. '
      'المهمة الفاشلة: ${failedStep.description}\nالأداة: ${failedStep.tool}\nالخطأ: $error\n'
      'النتائج السابقة الفعلية:\n$context\n'
      'الأدوات ومعاملاتها المتاحة: ${jsonEncode(toolCatalog)}\n'
      'لا تقترح أي إجراء هجومي أو تخطي صلاحيات. استخدم الأدوات الموجودة ومفاتيحها الصحيحة. '
      'إذا تعذر إيجاد بديل آمن فأعد {"steps":[]} . أعد JSON فقط.',
      maxTokens: 160,
      temperature: 0.1,
    ).timeout(const Duration(seconds: 90));
    final plan = _parsePlan(response, task: 'استعادة: ${failedStep.description}');
    return plan?.steps.isNotEmpty == true ? plan!.steps.first : null;
  }

  String _actualResultsSummary(String task, List<StepResult> results) {
    if (results.isEmpty) return 'لم تُنفّذ أي خطوة ولم تُنتج الأدوات مخرجات.';
    final successCount = results.where((result) => result.success).length;
    final lines = results.asMap().entries.map((entry) {
      final result = entry.value;
      final status = result.success ? 'نجاح' : 'فشل';
      final details = result.data == null ? '' : '\nالمخرجات الفعلية: ${_stepOutput(result)}';
      final error = result.error == null ? '' : '\nسبب الفشل: ${result.error}';
      return '${entry.key + 1}. $status — ${result.summary}$error$details\nالمدة: ${result.duration.inMilliseconds} ms';
    }).join('\n\n');
    return 'المهمة: $task\nالخطوات الناجحة: $successCount/${results.length}\n\nنتائج التنفيذ الفعلية:\n$lines';
  }

  void _log(String message)=>_events.add(AgentEvent(timestamp:DateTime.now(),message:message,state:_state));
  void dispose(){
    if (_approvalCompleter != null && !_approvalCompleter!.isCompleted) {
      _approvalCompleter!.complete(false);
    }
    _events.close();
  }
}
