import 'dart:async';

typedef AgentPromptRunner = Future<String> Function(String prompt);

class AgentCollaborationCancelled implements Exception {
  const AgentCollaborationCancelled();
  @override
  String toString() => 'تم إيقاف دورة الوكلاء بناءً على طلب المستخدم.';
}

void _ensureCollaborationActive(bool Function()? isCancelled) {
  if (isCancelled?.call() ?? false) throw const AgentCollaborationCancelled();
}

enum SpecialistRole { planner, researcher, engineer, reviewer, verifier }
enum CollaborationStatus { queued, running, completed, failed, skipped }

class CollaborationEvent {
  final String id;
  final String runId;
  final String actor;
  final String action;
  final CollaborationStatus status;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String detail;

  const CollaborationEvent({
    required this.id,
    required this.runId,
    required this.actor,
    required this.action,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.detail,
  });

  Duration get duration => finishedAt.difference(startedAt);

  Map<String, Object?> toJson() => {
    'id': id, 'runId': runId, 'actor': actor, 'action': action,
    'status': status.name, 'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(), 'detail': detail,
  };

  factory CollaborationEvent.fromJson(Map<String, dynamic> json) =>
      CollaborationEvent(
        id: json['id']?.toString() ?? '',
        runId: json['runId']?.toString() ?? '',
        actor: json['actor']?.toString() ?? 'Agent',
        action: json['action']?.toString() ?? '',
        status: CollaborationStatus.values.firstWhere(
          (v) => v.name == json['status'], orElse: () => CollaborationStatus.failed),
        startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ?? DateTime.now(),
        finishedAt: DateTime.tryParse(json['finishedAt']?.toString() ?? '') ?? DateTime.now(),
        detail: json['detail']?.toString() ?? '',
      );
}

class CollaborationResult {
  final String runId;
  final String title;
  final String output;
  final List<CollaborationEvent> events;
  final bool success;

  const CollaborationResult({
    required this.runId, required this.title, required this.output,
    required this.events, required this.success,
  });
}

/// Coordinates role-specialized prompts over one shared local-model runner.
/// Calls are intentionally serialized because the local inference runtime is
/// single-session; this avoids overlapping generations and memory spikes.
class AgentCollaborationEngine {
  static const int maxTeamAgents = 5;
  static const int maxReviewPasses = 3;
  static const int maxEngineeringIterations = 3;

  Future<CollaborationResult> runTeam({
    required String task,
    required AgentPromptRunner runPrompt,
    List<SpecialistRole> roles = const [
      SpecialistRole.planner, SpecialistRole.researcher,
      SpecialistRole.engineer, SpecialistRole.reviewer,
      SpecialistRole.verifier,
    ],
    bool Function()? isCancelled,
  }) async {
    final runId = _newId();
    final events = <CollaborationEvent>[];
    final findings = <String>[];
    final boundedRoles = roles.take(maxTeamAgents).toList(growable: false);
    for (final role in boundedRoles) {
      _ensureCollaborationActive(isCancelled);
      final prompt = _rolePrompt(role, task, findings);
      final started = DateTime.now();
      try {
        final output = await runPrompt(prompt);
        _ensureCollaborationActive(isCancelled);
        final finished = DateTime.now();
        final normalized = output.trim();
        findings.add('## ${_roleName(role)}\n${normalized.isEmpty ? 'لم يُرجع الوكيل نتيجة نصية.' : normalized}');
        events.add(CollaborationEvent(
          id: _newId(), runId: runId, actor: _roleName(role),
          action: 'تحليل المهمة من منظور متخصص', status: normalized.isEmpty ? CollaborationStatus.failed : CollaborationStatus.completed,
          startedAt: started, finishedAt: finished, detail: _excerpt(normalized),
        ));
      } catch (error) {
        if (isCancelled?.call() ?? false) throw const AgentCollaborationCancelled();
        final finished = DateTime.now();
        events.add(CollaborationEvent(
          id: _newId(), runId: runId, actor: _roleName(role),
          action: 'تحليل المهمة من منظور متخصص', status: CollaborationStatus.failed,
          startedAt: started, finishedAt: finished, detail: error.toString(),
        ));
        findings.add('## ${_roleName(role)}\nتعذر إكمال الدور: $error');
      }
    }
    _ensureCollaborationActive(isCancelled);
    final synthesisStart = DateTime.now();
    String output;
    var success = false;
    try {
      output = await runPrompt(
        'أنت المنسق الرئيسي في Zion Super Agent. اجمع مخرجات الوكلاء التالية في جواب نهائي عملي. '
        'افصل الحقائق عن الافتراضات، اذكر التعارضات والفجوات، ولا تدّع تنفيذ أي شيء لم يثبت. '
        'المهمة: $task\n\n${findings.join('\n\n')}',
      );
      _ensureCollaborationActive(isCancelled);
      success = output.trim().isNotEmpty;
    } catch (error) {
      if (isCancelled?.call() ?? false) throw const AgentCollaborationCancelled();
      output = 'تعذر تركيب النتائج تلقائياً: $error\n\n${findings.join('\n\n')}';
    }
    events.add(CollaborationEvent(
      id: _newId(), runId: runId, actor: 'Super Agent',
      action: 'تركيب النتائج والتحقق من التعارضات',
      status: success ? CollaborationStatus.completed : CollaborationStatus.failed,
      startedAt: synthesisStart, finishedAt: DateTime.now(), detail: _excerpt(output),
    ));
    return CollaborationResult(runId: runId, title: 'فريق الوكلاء: $task',
      output: output, events: List.unmodifiable(events), success: success);
  }

  Future<CollaborationResult> runOverthinker({
    required String task, required AgentPromptRunner runPrompt,
    int passes = maxReviewPasses,
    bool Function()? isCancelled,
  }) async {
    final runId = _newId();
    final events = <CollaborationEvent>[];
    var working = '';
    final count = passes.clamp(1, maxReviewPasses);
    for (var pass = 1; pass <= count; pass++) {
      _ensureCollaborationActive(isCancelled);
      final started = DateTime.now();
      final mode = switch (pass) {
        1 => 'حل أولي: قدّم أفضل إجابة مباشرة مع الافتراضات.',
        2 => 'مراجعة نقدية: ابحث عن أخطاء منطقية وثغرات وحالات حدية، ثم صحح الحل.',
        _ => 'تحقق نهائي: اختبر الاتساق، الأدلة، السلامة، وما لا يمكن إثباته. أعط النسخة النهائية الموجزة.',
      };
      try {
        working = await runPrompt(
          'وضع Overthinker المنضبط، الجولة $pass من $count. $mode\n'
          'المهمة الأصلية: $task\n'
          '${working.isEmpty ? '' : 'المخرجات السابقة التي يجب نقدها لا تكرارها:\n$working'}\n'
          'لا تكشف سلسلة التفكير الداخلية أو المداولات الخاصة. اعرض خلاصة التحقق، الأسباب القابلة للفحص، '
          'الافتراضات، المخاطر، والنتيجة المحسنة فقط.',
        );
        _ensureCollaborationActive(isCancelled);
        events.add(CollaborationEvent(id: _newId(), runId: runId,
          actor: 'Overthinker · الجولة $pass', action: mode,
          status: working.trim().isEmpty ? CollaborationStatus.failed : CollaborationStatus.completed,
          startedAt: started, finishedAt: DateTime.now(), detail: _excerpt(working)));
      } catch (error) {
        if (isCancelled?.call() ?? false) throw const AgentCollaborationCancelled();
        events.add(CollaborationEvent(id: _newId(), runId: runId,
          actor: 'Overthinker · الجولة $pass', action: mode,
          status: CollaborationStatus.failed, startedAt: started,
          finishedAt: DateTime.now(), detail: error.toString()));
        if (working.isEmpty) working = 'تعذر إكمال المراجعة: $error';
        break;
      }
    }
    return CollaborationResult(runId: runId, title: 'Overthinker: $task',
      output: working, events: List.unmodifiable(events),
      success: events.any((e) => e.status == CollaborationStatus.completed));
  }

  Future<CollaborationResult> runEngineeringLoop({
    required String task, required AgentPromptRunner runPrompt,
    int iterations = maxEngineeringIterations,
    bool Function()? isCancelled,
  }) async {
    final runId = _newId();
    final events = <CollaborationEvent>[];
    final count = iterations.clamp(1, maxEngineeringIterations);
    var evidence = '';
    for (var i = 1; i <= count; i++) {
      _ensureCollaborationActive(isCancelled);
      String? verificationOutput;
      final phases = <({String name, String instruction})>[
        (name: 'Engineer · دورة $i', instruction: 'صمم أو نفذ الحل المطلوب ضمن الأدوات المتاحة. لا تدّع تنفيذ أو اختبار شيء لم يحدث.'),
        (name: 'Reviewer · دورة $i', instruction: 'راجع الحل السابق بحثاً عن عيوب، حالات حدية، آثار جانبية، ومخاطر. أعط قائمة إصلاحات مرتبة واختبارات تحقق.'),
        (name: 'Verifier · دورة $i', instruction: 'تحقق من الأدلة والنتائج المتاحة. صنّف كل نقطة: مثبتة، غير مثبتة، أو فاشلة. اقترح الخطوة التالية.'),
      ];
      for (final phase in phases) {
        _ensureCollaborationActive(isCancelled);
        final started = DateTime.now();
        try {
          final output = await runPrompt(
            'Loop Engineering — ${phase.name}.\nالمهمة: $task\n'
            '${phase.instruction}\n'
            '${evidence.isEmpty ? '' : 'سجل الدورة السابق:\n$evidence'}\n'
            'اكتب تقريراً عملياً قصيراً يتضمن النتائج القابلة للتحقق والخطوة التالية. '
            'في دور Verifier أضف سطراً أخيراً LOOP_STATUS: COMPLETE فقط إذا كانت معايير القبول متحققة ولا توجد فجوة جوهرية؛ وإلا LOOP_STATUS: CONTINUE.',
          );
          _ensureCollaborationActive(isCancelled);
          if (phase.name.startsWith('Verifier')) verificationOutput = output;
          evidence += '\n\n### ${phase.name}\n$output';
          events.add(CollaborationEvent(id: _newId(), runId: runId,
            actor: phase.name, action: phase.instruction,
            status: output.trim().isEmpty ? CollaborationStatus.failed : CollaborationStatus.completed,
            startedAt: started, finishedAt: DateTime.now(), detail: _excerpt(output)));
        } catch (error) {
          if (isCancelled?.call() ?? false) throw const AgentCollaborationCancelled();
          events.add(CollaborationEvent(id: _newId(), runId: runId,
            actor: phase.name, action: phase.instruction, status: CollaborationStatus.failed,
            startedAt: started, finishedAt: DateTime.now(), detail: error.toString()));
          evidence += '\n\n### ${phase.name}\nفشل الدور: $error';
        }
      }
      final verifiedComplete = verificationOutput != null &&
          RegExp(r'LOOP_STATUS\s*:\s*COMPLETE', caseSensitive: false)
              .hasMatch(verificationOutput!);
      if (verifiedComplete) break;
    }
    return CollaborationResult(runId: runId, title: 'Loop Engineering: $task',
      output: evidence.trim(), events: List.unmodifiable(events),
      success: events.any((e) => e.status == CollaborationStatus.completed));
  }

  String _rolePrompt(SpecialistRole role, String task, List<String> prior) {
    final priorText = prior.isEmpty ? '' : '\nمخرجات الأدوار السابقة:\n${prior.join('\n\n')}';
    final instruction = switch (role) {
      SpecialistRole.planner => 'حلل الهدف إلى مراحل صغيرة قابلة للتحقق، وحدد الاعتماديات والمخاطر.',
      SpecialistRole.researcher => 'استخرج ما يلزم معرفته، وافصل الحقائق المتاحة عن الفجوات والافتراضات.',
      SpecialistRole.engineer => 'اقترح التنفيذ العملي الأدنى مع مراعاة التكامل مع النظام الحالي.',
      SpecialistRole.reviewer => 'انتقد الخطة والتنفيذ المقترح وابحث عن أخطاء وحالات حدية.',
      SpecialistRole.verifier => 'ضع معايير قبول واختبارات قابلة للتحقق، وحدد ما لا يمكن إثباته.',
    };
    return 'أنت وكيل فرعي متخصص في Zion Super Agent: ${_roleName(role)}. '
      'نفذ دورك فقط، لا تدّع استخدام أدوات غير متاحة، ولا تتجاوز الصلاحيات.\n'
      'المهمة: $task\nالدور: $instruction$priorText';
  }

  String _roleName(SpecialistRole role) => switch (role) {
    SpecialistRole.planner => 'Planner',
    SpecialistRole.researcher => 'Researcher',
    SpecialistRole.engineer => 'Engineer',
    SpecialistRole.reviewer => 'Reviewer',
    SpecialistRole.verifier => 'Verifier',
  };

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
  static String _excerpt(String text) => text.trim().length <= 180 ? text.trim() : '${text.trim().substring(0, 177)}…';
}
