import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/agent_models.dart';

/// Read-only observability view for the current Super Agent session.
/// It visualizes real AgentEvents; specialist lanes are orchestration roles,
/// not claims of independently running model processes.
class AgentIntelligenceHub extends StatefulWidget {
  const AgentIntelligenceHub({
    super.key,
    required this.events,
    required this.task,
    required this.result,
    required this.overthinkerEnabled,
    this.eventStream,
    this.resultProvider,
  });

  final List<AgentEvent> events;
  final String task;
  final AgentResult? result;
  final bool overthinkerEnabled;
  final Stream<AgentEvent>? eventStream;
  final AgentResult? Function()? resultProvider;

  @override
  State<AgentIntelligenceHub> createState() => _AgentIntelligenceHubState();
}

class _AgentIntelligenceHubState extends State<AgentIntelligenceHub> {
  late final List<AgentEvent> _liveEvents;
  StreamSubscription<AgentEvent>? _eventSubscription;

  List<AgentEvent> get events => _liveEvents;
  String get task => widget.task;
  AgentResult? get result => widget.resultProvider != null ? widget.resultProvider!() : widget.result;
  bool get overthinkerEnabled => widget.overthinkerEnabled;

  @override
  void initState() {
    super.initState();
    _liveEvents = List<AgentEvent>.of(widget.events);
    _eventSubscription = widget.eventStream?.listen((event) {
      if (!mounted) return;
      setState(() {
        _liveEvents.add(event);
        if (_liveEvents.length > 500) {
          _liveEvents.removeRange(0, _liveEvents.length - 500);
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant AgentIntelligenceHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventStream != widget.eventStream) {
      unawaited(_eventSubscription?.cancel());
      _eventSubscription = widget.eventStream?.listen((event) {
        if (!mounted) return;
        setState(() => _liveEvents.add(event));
      });
    }
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    super.dispose();
  }

  static const _bg = Color(0xFF08111B);
  static const _panel = Color(0xFF111F2C);
  static const _line = Color(0xFF294252);
  static const _cyan = Color(0xFF55D9EA);
  static const _muted = Color(0xFF9BAFBE);

  Future<void> _openObsidian(BuildContext context) async {
    final now = DateTime.now();
    final note = StringBuffer()
      ..writeln('# Zion Super Agent — Session Analysis')
      ..writeln()
      ..writeln('- Captured: ${now.toIso8601String()}')
      ..writeln('- Task: ${task.isEmpty ? 'No task captured' : task}')
      ..writeln('- Overthinker mode: ${overthinkerEnabled ? 'enabled' : 'disabled'}')
      ..writeln('- Outcome: ${result == null ? 'in progress / no result yet' : result!.success ? 'success' : 'needs review'}')
      ..writeln()
      ..writeln('## Event timeline');
    for (final event in events) {
      note.writeln('- ${event.timestamp.toIso8601String()} — ${event.state.name}: ${event.message}');
    }
    if (result != null) {
      note
        ..writeln()
        ..writeln('## Result')
        ..writeln(result!.report ?? result!.error ?? 'Completed without a report.')
        ..writeln()
        ..writeln('## Step outcomes');
      for (var i = 0; i < result!.steps.length; i++) {
        final step = result!.steps[i];
        note.writeln('${i + 1}. ${step.success ? 'PASS' : 'REVIEW'} — ${step.summary} (${step.duration.inMilliseconds} ms)');
      }
    }
    final uri = Uri(
      scheme: 'obsidian',
      host: 'new',
      queryParameters: {
        'name': 'Zion Agent/${now.toIso8601String().replaceAll(':', '-') }',
        'content': note.toString(),
      },
    );
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('Obsidian URI handler unavailable');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: note.toString()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذر فتح Obsidian مباشرة؛ نُسخ التقرير بصيغة Markdown لتلصقه في خزنتك.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _openExpandedMonitor(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E1722),
            title: const Text('مراقبة الأداء المباشرة'),
            leading: IconButton(
              tooltip: 'إغلاق الشاشة الموسعة',
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _SectionTitle(icon: Icons.hub_outlined, title: 'مسار التنفيذ المسجل'),
                const SizedBox(height: 4),
                const Text('يعرض هذا المخطط أحداث الجلسة الحقيقية التي وصلت إلى واجهة المراقبة، وليس قياسات داخلية غير متاحة للنموذج.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
                const SizedBox(height: 8),
                SizedBox(height: 320, width: double.infinity, child: CustomPaint(
                  painter: _NeuralMapPainter(
                    activity: events.isNotEmpty,
                    hasResult: result != null,
                    hasFailure: result?.success == false || (result?.steps.any((step) => !step.success) ?? false),
                    waiting: events.any((event) => event.state == AgentState.waitingApproval),
                  ),
                )),
              ])),
              const SizedBox(height: 12),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionTitle(icon: Icons.timeline_outlined, title: 'سجل الأحداث الفعلي · ${events.length}'),
                const SizedBox(height: 8),
                if (events.isEmpty)
                  const Text('لا توجد أحداث مسجلة بعد.', style: TextStyle(color: _muted))
                else
                  ...events.reversed.map((event) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF0C1823), borderRadius: BorderRadius.circular(10), border: Border.all(color: _line)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: _stateColor(event.state), shape: BoxShape.circle)),
                      const SizedBox(width: 9),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${event.timestamp.toLocal().toString().split('.').first} · ${_stateName(event.state)}', style: const TextStyle(color: _muted, fontSize: 10)),
                        const SizedBox(height: 3),
                        SelectableText(event.message, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
                      ])),
                    ]),
                  )),
              ])),
              const SizedBox(height: 12),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _SectionTitle(icon: Icons.fact_check_outlined, title: 'نتيجة التحقق'),
                const SizedBox(height: 8),
                SelectableText(task.isEmpty ? 'لا توجد مهمة محددة.' : task, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5)),
                const SizedBox(height: 8),
                Text(result == null ? 'الجلسة لم تسجل نتيجة نهائية بعد.' : result!.success ? 'نجاح حسب نتائج الأدوات' : 'تحتاج إلى مراجعة: ${result!.error ?? 'لم يقدم المحرك سبباً محدداً'}', style: TextStyle(color: result == null ? _muted : result!.success ? const Color(0xFF47D6A0) : const Color(0xFFFF7777), fontWeight: FontWeight.w700, fontSize: 12)),
              ])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final success = result?.steps.where((s) => s.success).length ?? 0;
    final failed = result?.steps.where((s) => !s.success).length ?? 0;
    final totalMs = result?.steps.fold<int>(0, (sum, s) => sum + s.duration.inMilliseconds) ?? 0;
    final states = <AgentState, int>{};
    for (final event in events) {
      states[event.state] = (states[event.state] ?? 0) + 1;
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1722),
        title: const Text('Agent Intelligence Lab', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'توسيع مراقبة الأداء',
            onPressed: () => _openExpandedMonitor(context),
            icon: const Icon(Icons.open_in_full_rounded, color: _cyan),
          ),
          IconButton(
            tooltip: 'تصدير إلى Obsidian',
            onPressed: () => _openObsidian(context),
            icon: const Icon(Icons.auto_stories_outlined, color: _cyan),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _SectionTitle(icon: Icons.psychology_alt_outlined, title: 'Overthinker · التحليل متعدد المراحل'),
              const SizedBox(height: 12),
              Text(
                overthinkerEnabled
                  ? 'مفعّل لهذه الجلسة: تُوجَّه الخطة إلى تفكيك المهمة، وفحص المخاطر، والتحقق من النتائج، ثم مراجعة الإخفاقات قبل إعلان الاكتمال.'
                  : 'غير مفعّل. فعّله من أدوات Super Agent لاستخدام تخطيط أعمق والتحقق من النتائج.',
                style: const TextStyle(color: _muted, height: 1.5, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Wrap(spacing: 7, runSpacing: 7, children: [
                _PhaseChip(label: '1 · فهم النطاق'),
                _PhaseChip(label: '2 · تقسيم المهمة'),
                _PhaseChip(label: '3 · المخاطر والتبعيات'),
                _PhaseChip(label: '4 · التنفيذ والتحقق'),
                _PhaseChip(label: '5 · مراجعة النتيجة'),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionTitle(icon: Icons.hub_outlined, title: 'خريطة الشبكة العصبية التشغيلية'),
            const SizedBox(height: 5),
            const Text('رسم للعلاقات بين مراحل العمل والأحداث المسجلة؛ لا يمثل أوزان النموذج الداخلية أو نشاطاً عصبياً غير متاح عبر المحرك.', style: TextStyle(color: _muted, fontSize: 11, height: 1.45)),
            const SizedBox(height: 8),
            SizedBox(height: 245, width: double.infinity, child: CustomPaint(
              painter: _NeuralMapPainter(
                activity: events.isNotEmpty,
                hasResult: result != null,
                hasFailure: failed > 0 || result?.success == false,
                waiting: events.any((e) => e.state == AgentState.waitingApproval),
              ),
            )),
            Wrap(spacing: 12, runSpacing: 8, children: [
              _legend(_cyan, 'تدفق العمل'),
              _legend(const Color(0xFF47D6A0), 'نجاح'),
              _legend(const Color(0xFFFFB454), 'مراجعة/موافقة'),
              _legend(const Color(0xFFFF7777), 'إخفاق'),
            ]),
          ])),
          const SizedBox(height: 12),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionTitle(icon: Icons.groups_2_outlined, title: 'الوكلاء الفرعيون المتخصصون'),
            const SizedBox(height: 5),
            const Text('مسارات تخصصية يوجّه إليها المنسّق الخطة؛ حالتها هنا مستنتجة من سجل الجلسة وليست عمليات مستقلة موازية.', style: TextStyle(color: _muted, fontSize: 11, height: 1.45)),
            const SizedBox(height: 12),
            _role('التخطيط والتحليل', Icons.account_tree_outlined, _cyan, events.any((e) => e.state == AgentState.planning)),
            _role('التنفيذ والأدوات', Icons.terminal_outlined, const Color(0xFF47D6A0), events.any((e) => e.state == AgentState.executing)),
            _role('التحقق وضمان الجودة', Icons.fact_check_outlined, const Color(0xFF8BA9FF), events.any((e) => e.state == AgentState.evaluating) || result != null),
            _role('مراجع المخاطر والصلاحيات', Icons.shield_outlined, const Color(0xFFFFB454), events.any((e) => e.state == AgentState.waitingApproval)),
          ]),
          ),
          const SizedBox(height: 12),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionTitle(icon: Icons.query_stats_outlined, title: 'تحليلات الأداء الفعلية'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _metric('الأحداث', '${events.length}', _cyan)),
              const SizedBox(width: 8),
              Expanded(child: _metric('خطوات ناجحة', '$success', const Color(0xFF47D6A0))),
              const SizedBox(width: 8),
              Expanded(child: _metric('تحتاج مراجعة', '$failed', const Color(0xFFFF7777))),
            ]),
            const SizedBox(height: 10),
            _metricRow('زمن الخطوات المسجل', totalMs > 0 ? '${(totalMs / 1000).toStringAsFixed(2)} ثانية' : 'لا توجد بيانات خطوات بعد'),
            _metricRow('الحالة النهائية', result == null ? 'لم تكتمل بعد' : result!.success ? 'نجاح' : 'فشل / مراجعة'),
            _metricRow('مصدر القياس', 'أحداث AgentRuntime و StepResult'),
          ])),
          const SizedBox(height: 12),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionTitle(icon: Icons.timeline_outlined, title: 'توزيع الأحداث حسب الحالة'),
            const SizedBox(height: 12),
            if (states.isEmpty)
              const Text('ابدأ مهمة لتظهر بيانات القياس.', style: TextStyle(color: _muted))
            else
              ...states.entries.map((entry) {
                final ratio = entry.value / events.length;
                return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(children: [
                  Row(children: [
                    Expanded(child: Text(_stateName(entry.key), style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    Text('${entry.value} · ${(ratio * 100).round()}%', style: const TextStyle(color: _muted, fontSize: 11)),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: ratio, minHeight: 6, backgroundColor: const Color(0xFF233442), color: _stateColor(entry.key))),
                ]));
              }),
          ])),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openObsidian(context),
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text('تصدير تقرير الجلسة إلى Obsidian'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF244858), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 10),
          SelectableText(task.isEmpty ? 'لا توجد مهمة نشطة محددة.' : 'المهمة الحالية: $task', style: const TextStyle(color: _muted, fontSize: 11, height: 1.5)),
        ],
      ),
    );
  }

  static Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
    child: child,
  );

  static Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
  ]);

  static Widget _role(String label, IconData icon, Color color, bool active) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFF0C1823), borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? color.withOpacity(.65) : _line)),
    child: Row(children: [
      Icon(icon, size: 19, color: color),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(8)), child: Text(active ? 'نشط في السجل' : 'بانتظار الحدث', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700))),
    ]),
  );

  static Widget _metric(String title, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(color: const Color(0xFF0C1823), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 10)),
    ]),
  );

  static Widget _metricRow(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(color: _muted, fontSize: 11))),
      const SizedBox(width: 12),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
    ]),
  );

  static String _stateName(AgentState state) => switch (state) {
    AgentState.idle => 'جاهز',
    AgentState.planning => 'تخطيط',
    AgentState.executing => 'تنفيذ',
    AgentState.evaluating => 'تقييم',
    AgentState.waitingApproval => 'بانتظار الموافقة',
    AgentState.completed => 'اكتمل',
    AgentState.failed => 'فشل',
    AgentState.cancelled => 'أُلغي',
  };

  static Color _stateColor(AgentState state) => switch (state) {
    AgentState.idle => _muted,
    AgentState.planning => _cyan,
    AgentState.executing => const Color(0xFF8BA9FF),
    AgentState.evaluating => const Color(0xFFB39DDB),
    AgentState.waitingApproval => const Color(0xFFFFB454),
    AgentState.completed => const Color(0xFF47D6A0),
    AgentState.failed => const Color(0xFFFF7777),
    AgentState.cancelled => const Color(0xFFFFB454),
  };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: _AgentIntelligenceHubState._cyan, size: 19),
    const SizedBox(width: 8),
    Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
  ]);
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.label});
  final String label;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFF0B1A26), borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFF315064))),
    child: Text(label, style: const TextStyle(color: Color(0xFFD3E7F0), fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _NeuralMapPainter extends CustomPainter {
  _NeuralMapPainter({required this.activity, required this.hasResult, required this.hasFailure, required this.waiting});
  final bool activity, hasResult, hasFailure, waiting;
  @override
  void paint(Canvas canvas, Size size) {
    // RTL flow: the session starts on the right and advances leftward.
    final nodes = <Offset>[
      Offset(size.width * .82, size.height * .10),
      Offset(size.width * .62, size.height * .31),
      Offset(size.width * .28, size.height * .31),
      Offset(size.width * .62, size.height * .57),
      Offset(size.width * .28, size.height * .57),
      Offset(size.width * .50, size.height * .83),
    ];
    final edges = <(int, int)>[(0,1),(1,2),(1,3),(2,4),(3,4),(4,5),(3,5)];
    final line = Paint()..color = _NeuralColors.cyan.withOpacity(.55)..strokeWidth = 1.4;
    for (final edge in edges) canvas.drawLine(nodes[edge.$1], nodes[edge.$2], line);
    final labels = ['Super Agent','Planner','Executor','Risk review','Verifier','Result'];
    final colors = <Color>[
      _NeuralColors.cyan,
      _NeuralColors.cyan,
      activity ? const Color(0xFF47D6A0) : _NeuralColors.muted,
      waiting ? const Color(0xFFFFB454) : _NeuralColors.muted,
      hasFailure ? const Color(0xFFFF7777) : hasResult ? const Color(0xFF47D6A0) : _NeuralColors.muted,
      hasFailure ? const Color(0xFFFF7777) : hasResult ? const Color(0xFF47D6A0) : _NeuralColors.cyan,
    ];
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final fill = Paint()..color = colors[i].withOpacity(.14);
      final border = Paint()..color = colors[i]..style = PaintingStyle.stroke..strokeWidth = 1.5;
      canvas.drawCircle(node, 19, fill);
      canvas.drawCircle(node, 19, border);
      final tp = TextPainter(text: TextSpan(text: labels[i], style: TextStyle(color: Colors.white, fontSize: size.width < 350 ? 9 : 10, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout(maxWidth: size.width * .32);
      tp.paint(canvas, Offset((node.dx - tp.width / 2).clamp(0.0, size.width - tp.width).toDouble(), node.dy + 24));
    }
  }
  @override bool shouldRepaint(covariant _NeuralMapPainter old) => activity != old.activity || hasResult != old.hasResult || hasFailure != old.hasFailure || waiting != old.waiting;
}

class _NeuralColors {
  static const cyan = Color(0xFF55D9EA);
  static const muted = Color(0xFF9BAFBE);
}
