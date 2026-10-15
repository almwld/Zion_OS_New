import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/agent_collaboration.dart';
import '../knowledge/obsidian_vault.dart';

class AgentLabScreen extends StatefulWidget {
  final AgentPromptRunner runPrompt;
  final Future<void> Function()? cancelRun;
  final bool Function()? isCancelled;
  const AgentLabScreen({super.key, required this.runPrompt, this.cancelRun, this.isCancelled});

  @override
  State<AgentLabScreen> createState() => _AgentLabScreenState();
}

class _AgentLabScreenState extends State<AgentLabScreen> with SingleTickerProviderStateMixin {
  final _engine = AgentCollaborationEngine();
  final _vault = ObsidianVault();
  final _task = TextEditingController();
  final _search = TextEditingController();
  final _notes = <ObsidianNote>[];
  final _events = <CollaborationEvent>[];
  final _output = <String>[];
  late final TabController _tabs;
  bool _busy = false;
  bool _loadingNotes = true;
  String? _error;
  static const _telemetryKey = 'zion_agent_collaboration_events_v1';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() { if (mounted) setState(() {}); });
    _refreshNotes();
    _restoreTelemetry();
  }

  Future<void> _restoreTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_telemetryKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      if (!mounted) return;
      setState(() => _events.addAll(decoded.whereType<Map>().map((e) =>
        CollaborationEvent.fromJson(Map<String, dynamic>.from(e))).take(400)));
    } catch (_) {}
  }

  Future<void> _persistTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = _events.length > 400 ? _events.sublist(_events.length - 400) : _events;
      await prefs.setString(_telemetryKey, jsonEncode(events.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _refreshNotes([String query = '']) async {
    setState(() => _loadingNotes = true);
    final result = query.trim().isEmpty ? await _vault.allNotes() : await _vault.search(query);
    if (!mounted) return;
    setState(() { _notes..clear()..addAll(result); _loadingNotes = false; });
  }

  Future<void> _run(String mode) async {
    final task = _task.text.trim();
    if (task.isEmpty || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      late final CollaborationResult result;
      if (mode == 'team') {
        result = await _engine.runTeam(task: task + String.fromCharCode(10) + String.fromCharCode(10) + await _vault.contextFor(task), runPrompt: widget.runPrompt, isCancelled: widget.isCancelled);
      } else if (mode == 'loop') {
        result = await _engine.runEngineeringLoop(task: task + String.fromCharCode(10) + String.fromCharCode(10) + await _vault.contextFor(task), runPrompt: widget.runPrompt, isCancelled: widget.isCancelled);
      } else {
        result = await _engine.runOverthinker(task: task + String.fromCharCode(10) + String.fromCharCode(10) + await _vault.contextFor(task), runPrompt: widget.runPrompt, isCancelled: widget.isCancelled);
      }
      if (!mounted) return;
      setState(() {
        _output.insert(0, result.output);
        _events.addAll(result.events);
        if (_events.length > 400) _events.removeRange(0, _events.length - 400);
      });
      await _persistTelemetry();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editNote([ObsidianNote? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    final tags = TextEditingController(text: existing?.tags.join(', ') ?? '');
    final result = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(existing == null ? 'ملاحظة جديدة' : 'تحرير الملاحظة'),
      content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')),
        const SizedBox(height: 8),
        TextField(controller: body, minLines: 7, maxLines: 14, decoration: const InputDecoration(labelText: 'محتوى Markdown', hintText: 'استخدم [[اسم الملاحظة]] لإنشاء رابط داخلي')),
        const SizedBox(height: 8),
        TextField(controller: tags, decoration: const InputDecoration(labelText: 'وسوم', hintText: 'agent, linux, idea')),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
      ],
    ));
    if (result == true) {
      await _vault.save(id: existing?.id, title: title.text, body: body.text,
        tags: tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList());
      await _refreshNotes(_search.text);
    }
    title.dispose(); body.dispose(); tags.dispose();
  }

  Future<void> _saveResult(String text) async {
    final title = 'نتيجة وكيل ' + DateTime.now().toIso8601String().replaceAll(':', '-');
    await _vault.save(title: title, body: text, tags: const ['agent', 'result']);
    await _refreshNotes(_search.text);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حُفظت النتيجة في دفتر Obsidian المحلي.')));
  }
  Future<void> _exportVault() async {
    final markdown = await _vault.exportMarkdown();
    await Clipboard.setData(ClipboardData(text: markdown));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نُسخت الملاحظات بصيغة Markdown إلى الحافظة.')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Agent · مختبر الوكلاء'),
        actions: [
          if (_busy) IconButton(tooltip: 'إيقاف التنفيذ', onPressed: widget.cancelRun == null ? null : () => widget.cancelRun!(), icon: const Icon(Icons.stop_circle_outlined)),
          IconButton(tooltip: 'تصدير دفتر المعرفة', onPressed: _exportVault, icon: const Icon(Icons.ios_share_rounded)),
        ],
        bottom: TabBar(controller: _tabs, isScrollable: true, tabs: const [
          Tab(icon: Icon(Icons.groups_2_outlined), text: 'الوكلاء'),
          Tab(icon: Icon(Icons.loop_rounded), text: 'Loop Engineering'),
          Tab(icon: Icon(Icons.auto_awesome_outlined), text: 'Overthinker'),
          Tab(icon: Icon(Icons.hub_outlined), text: 'Obsidian / الشبكة'),
        ]),
      ),
      body: TabBarView(controller: _tabs, children: [
        _agentTab(colors),
        _activityTab(colors),
        _overthinkerTab(colors),
        _vaultGraphTab(colors),
      ]),
    );
  }

  Widget _agentTab(ColorScheme colors) => ListView(padding: const EdgeInsets.all(16), children: [
    _introCard(colors, Icons.groups_2_rounded, 'فريق الوكلاء الفرعيين', 'خمسة أدوار متخصصة تعمل بالتتابع على محرك النموذج المحلي، ثم يركّب المنسق النتائج. التتابع يحمي ذاكرة الهاتف من تداخل جلسات الاستدلال.'),
    const SizedBox(height: 14),
    _taskField(colors),
    const SizedBox(height: 12),
    Wrap(spacing: 8, runSpacing: 8, children: const [
      _RoleChip(name: 'Planner', description: 'تفكيك المهمة'),
      _RoleChip(name: 'Researcher', description: 'الفجوات والمعرفة'),
      _RoleChip(name: 'Engineer', description: 'التنفيذ'),
      _RoleChip(name: 'Reviewer', description: 'النقد والمراجعة'),
      _RoleChip(name: 'Verifier', description: 'معايير الإثبات'),
    ]),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: _busy ? null : () => _run('team'), icon: const Icon(Icons.play_arrow_rounded), label: const Text('تشغيل فريق الوكلاء')),
    if (_busy) ...[const SizedBox(height: 12), const LinearProgressIndicator(), const SizedBox(height: 6), const Text('يعمل الوكلاء بالتتابع على النموذج المحلي…')],
    if (_error != null) _errorCard(colors),
    if (_output.isNotEmpty) _outputCard(colors, _output.first),
    const SizedBox(height: 14),
    _metricRow(colors),
  ]);

  Widget _activityTab(ColorScheme colors) => ListView(padding: const EdgeInsets.all(16), children: [
    _introCard(colors, Icons.loop_rounded, 'Loop Engineering', 'دورة محدودة: Engineer → Reviewer → Verifier. يسجل كل دور مدته ونتيجته، ويعرض الفشل بدلاً من الادعاء بالنجاح. الحد الأقصى ثلاث دورات.'),
    const SizedBox(height: 14),
    _taskField(colors),
    const SizedBox(height: 10),
    FilledButton.icon(onPressed: _busy ? null : () => _run('loop'), icon: const Icon(Icons.refresh_rounded), label: const Text('بدء دورة الهندسة')),
    const SizedBox(height: 16),
    _metricsPanel(colors),
    const SizedBox(height: 12),
    _eventTimeline(colors),
    if (_output.isNotEmpty) _outputCard(colors, _output.first),
  ]);

  Widget _overthinkerTab(ColorScheme colors) => ListView(padding: const EdgeInsets.all(16), children: [
    _introCard(colors, Icons.psychology_alt_rounded, 'Overthinker · مراجعة متعددة المراحل', 'ثلاث جولات بحد أقصى: حل أولي، مراجعة نقدية، ثم تحقق نهائي. لا يعرض التفكير الداخلي الخاص؛ يعرض خلاصة التحقق والافتراضات والنتيجة المحسنة.'),
    const SizedBox(height: 14),
    _taskField(colors),
    const SizedBox(height: 10),
    FilledButton.icon(onPressed: _busy ? null : () => _run('overthinker'), icon: const Icon(Icons.auto_awesome_rounded), label: const Text('تحليل ومراجعة حتى 3 جولات')),
    if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
    if (_error != null) _errorCard(colors),
    if (_output.isNotEmpty) _outputCard(colors, _output.first),
    const SizedBox(height: 12),
    _metricsPanel(colors),
  ]);

  Widget _vaultGraphTab(ColorScheme colors) => ListView(padding: const EdgeInsets.all(16), children: [
    _introCard(colors, Icons.hub_outlined, 'Obsidian محلي + شبكة تفاعلات الوكلاء', 'دفتر Markdown محلي بروابط [[ويكي]] ووسوم وبحث. الرسم يعرض الملاحظات وروابطها وكل التفاعلات المحفوظة ضمن سجل آخر 400 حدث، مع جلسات التشغيل والأدوار وحالات النجاح والفشل؛ إنه مخطط علاقات وتشغيل وليس أوزان شبكة عصبية مدرّبة.'),
    const SizedBox(height: 14),
    Row(children: [
      Expanded(child: TextField(controller: _search, onChanged: _refreshNotes, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث في دفتر المعرفة', border: OutlineInputBorder()))),
      const SizedBox(width: 8),
      IconButton.filled(tooltip: 'ملاحظة جديدة', onPressed: () => _editNote(), icon: const Icon(Icons.add)),
    ]),
    const SizedBox(height: 12),
    FutureBuilder<ObsidianGraph>(
      future: _vault.graph(),
      builder: (context, snapshot) {
        final graph = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        return _KnowledgeNetwork(colors: colors, notes: graph?.notes ?? const [], edges: graph?.edges ?? const {}, events: _events);
      },
    ),
    const SizedBox(height: 14),
    Row(children: [
      Expanded(child: Text('الملاحظات المحلية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
      Text('${_notes.length} ملاحظة', style: Theme.of(context).textTheme.labelMedium),
    ]),
    if (_loadingNotes) const LinearProgressIndicator(),
    for (final note in _notes) Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${note.tags.map((t) => '#$t').join(' ')}  ·  ${note.links.length} روابط', maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => _editNote(note),
        trailing: IconButton(tooltip: 'حذف الملاحظة', icon: const Icon(Icons.delete_outline), onPressed: () async {
          await _vault.delete(note.id);
          await _refreshNotes(_search.text);
          if (mounted) setState(() {});
        }),
      ),
    ),
    if (_notes.isEmpty && !_loadingNotes) const Padding(padding: EdgeInsets.all(18), child: Text('دفتر المعرفة فارغ. أنشئ ملاحظة واربطها باستخدام [[اسم الملاحظة]].')),
  ]);

  Widget _taskField(ColorScheme colors) => TextField(
    controller: _task, minLines: 2, maxLines: 4,
    decoration: InputDecoration(
      labelText: 'المهمة المطلوبة', hintText: 'صف الهدف والقيود ومعيار النجاح…',
      filled: true, fillColor: colors.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  Widget _introCard(ColorScheme colors, IconData icon, String title, String subtitle) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: colors.onPrimaryContainer)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45)),
      ])),
    ])),
  );

  Widget _outputCard(ColorScheme colors, String text) => Card(
    color: colors.surfaceContainerLow,
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.task_alt_rounded, size: 18), const SizedBox(width: 8), const Expanded(child: Text('آخر نتيجة')), IconButton(tooltip: 'حفظ في Obsidian', onPressed: () => _saveResult(text), icon: const Icon(Icons.bookmark_add_outlined, size: 18)), IconButton(tooltip: 'نسخ النتيجة', onPressed: () => Clipboard.setData(ClipboardData(text: text)), icon: const Icon(Icons.copy, size: 18))]),
      SelectableText(text, style: const TextStyle(height: 1.45)),
    ])),
  );

  Widget _errorCard(ColorScheme colors) => Card(color: colors.errorContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: TextStyle(color: colors.onErrorContainer))));

  Widget _metricRow(ColorScheme colors) => Row(children: [
    Expanded(child: _metric(colors, 'أدوار منفذة', '${_events.where((e) => e.status == CollaborationStatus.completed).length}', Icons.check_circle_outline)),
    const SizedBox(width: 8),
    Expanded(child: _metric(colors, 'إخفاقات', '${_events.where((e) => e.status == CollaborationStatus.failed).length}', Icons.error_outline)),
    const SizedBox(width: 8),
    Expanded(child: _metric(colors, 'متوسط الزمن', '${_averageDuration()} ms', Icons.speed_outlined)),
  ]);

  Widget _metricsPanel(ColorScheme colors) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('مؤشرات الأداء الفعلية', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), _metricRow(colors),
    const SizedBox(height: 10),
    SizedBox(height: 100, child: CustomPaint(size: const Size(double.infinity, 100), painter: _PerformancePainter(events: _events, color: colors.primary, grid: colors.outlineVariant))),
    Builder(builder: (context) {
      final finished = _events.where((e) =>
        e.status == CollaborationStatus.completed || e.status == CollaborationStatus.failed).toList();
      final successful = finished.where((e) => e.status == CollaborationStatus.completed).length;
      final rate = finished.isEmpty ? 0 : (successful * 100 / finished.length).round();
      final runs = _events.map((e) => e.runId).where((id) => id.isNotEmpty).toSet().length;
      final durations = finished.map((e) => e.duration.inMilliseconds).toList()..sort();
      final p95 = durations.isEmpty ? 0 : durations[((durations.length - 1) * .95).round()];
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('نجاح الأدوار: $rate%  ·  جلسات مسجلة: $runs  ·  P95: $p95 ms\\nزمن كل دور بالميلي ثانية — القياسات الفعلية المسجلة فقط.',
          style: Theme.of(context).textTheme.labelSmall),
      );
    }),
  ]);

  Widget _metric(ColorScheme colors, String title, String value, IconData icon) => Card(
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), child: Column(children: [
      Icon(icon, size: 19, color: colors.primary), const SizedBox(height: 6),
      Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
    ])),
  );

  int _averageDuration() {
    if (_events.isEmpty) return 0;
    return (_events.fold<int>(0, (sum, e) => sum + e.duration.inMilliseconds) / _events.length).round();
  }

  Widget _eventTimeline(ColorScheme colors) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('سجل تفاعلات الوكلاء', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    for (final event in _events.reversed.take(40)) Card(
      child: ListTile(
        dense: true,
        leading: Icon(event.status == CollaborationStatus.completed ? Icons.check_circle_outline : event.status == CollaborationStatus.failed ? Icons.error_outline : Icons.circle_outlined,
          color: event.status == CollaborationStatus.completed ? Colors.green : event.status == CollaborationStatus.failed ? colors.error : colors.outline),
        title: Text('${event.actor} · ${event.action}', maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${event.duration.inMilliseconds} ms · ${event.detail}', maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    ),
  ]);

  @override
  void dispose() {
    _tabs.dispose(); _task.dispose(); _search.dispose();
    super.dispose();
  }
}

class _RoleChip extends StatelessWidget {
  final String name;
  final String description;
  const _RoleChip({required this.name, required this.description});
  @override Widget build(BuildContext context) => Chip(avatar: const Icon(Icons.circle, size: 8), label: Text('$name · $description'));
}

class _KnowledgeNetwork extends StatelessWidget {
  final ColorScheme colors;
  final List<ObsidianNote> notes;
  final Map<String, List<String>> edges;
  final List<CollaborationEvent> events;
  const _KnowledgeNetwork({required this.colors, required this.notes, required this.edges, required this.events});

  @override
  Widget build(BuildContext context) {
    final noteNodes = notes.map((n) => (id: n.id, label: n.title, kind: 'note')).toList();
    // Telemetry is capped at 400 persisted events by the lab. Draw every event
    // retained in that audit window rather than silently dropping all but 24.
    final recordedEvents = events.reversed.take(400).toList();
    final eventActors = recordedEvents.map((e) => e.actor).toSet().toList();
    final agentNodes = eventActors.map((actor) => (id: 'agent:' + actor, label: actor, kind: 'agent')).toList();
    final runIds = recordedEvents.map((e) => e.runId).where((id) => id.isNotEmpty).toSet().toList();
    final runNodes = runIds.map((id) => (
      id: 'run:' + id,
      label: 'جلسة ' + id.substring(id.length > 6 ? id.length - 6 : 0),
      kind: 'run',
    )).toList();
    final eventNodes = recordedEvents.asMap().entries.map((entry) {
      final e = entry.value;
      final state = e.status == CollaborationStatus.completed
          ? 'OK'
          : e.status == CollaborationStatus.failed ? 'ERR' : 'WAIT';
      return (id: 'event:' + e.id, label: '[' + state + '] ' + (entry.key + 1).toString() + '. ' + e.actor + ' · ' + e.action, kind: 'event');
    }).toList();
    final nodes = [...noteNodes, ...runNodes, ...agentNodes, ...eventNodes];
    if (nodes.isEmpty) {
      return Container(height: 220, alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
        child: const Text('ستظهر العقد بعد إنشاء الملاحظات أو تشغيل الوكلاء.'));
    }

    final ids = nodes.map((n) => n.id).toSet();
    final links = <(String, String)>[];
    for (final entry in edges.entries) {
      for (final target in entry.value) {
        if (ids.contains(entry.key) && ids.contains(target)) links.add((entry.key, target));
      }
    }
    for (final event in recordedEvents) {
      final eventId = 'event:' + event.id;
      final agentId = 'agent:' + event.actor;
      final runId = 'run:' + event.runId;
      if (ids.contains(eventId) && ids.contains(agentId)) links.add((agentId, eventId));
      if (ids.contains(eventId) && ids.contains(runId)) links.add((runId, eventId));
    }
    for (var i = 1; i < recordedEvents.length; i++) {
      final previous = recordedEvents[i - 1];
      final current = recordedEvents[i];
      if (previous.runId == current.runId) {
        links.add(('event:' + previous.id, 'event:' + current.id));
      }
    }

    final rows = math.max(
      math.max(recordedEvents.length, runNodes.length) * 36.0 + 80,
      noteNodes.length * 46.0 + 80,
    );
    final graphHeight = math.max(330.0, rows);
    return Container(
      height: 330,
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.outlineVariant)),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: InteractiveViewer(
        constrained: false,
        minScale: .35, maxScale: 2.5, boundaryMargin: const EdgeInsets.all(80),
        child: CustomPaint(
          size: Size(940, graphHeight),
          painter: _NetworkPainter(nodes: nodes, links: links, colors: colors),
        ),
      )),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final List<({String id, String label, String kind})> nodes;
  final List<(String, String)> links;
  final ColorScheme colors;
  const _NetworkPainter({required this.nodes, required this.links, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <String, Offset>{};
    var noteIndex = 0, runIndex = 0, agentIndex = 0, eventIndex = 0;
    for (final node in nodes) {
      late final Offset position;
      switch (node.kind) {
        case 'note':
          position = Offset(90, 42 + noteIndex * 46.0);
          noteIndex++;
          break;
        case 'run':
          position = Offset(300, 42 + runIndex * 36.0);
          runIndex++;
          break;
        case 'agent':
          position = Offset(510, 70 + agentIndex * 130.0);
          agentIndex++;
          break;
        default:
          position = Offset(760, 42 + eventIndex * 36.0);
          eventIndex++;
      }
      positions[node.id] = position;
    }

    final line = Paint()..color = colors.primary.withOpacity(.34)..strokeWidth = 1.25;
    for (final link in links) {
      final a = positions[link.$1], b = positions[link.$2];
      if (a != null && b != null) {
        canvas.drawLine(a, b, line);
        canvas.drawCircle(Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2), 1.8, Paint()..color = colors.primary);
      }
    }

    for (final node in nodes) {
      final p = positions[node.id]!;
      final isAgent = node.kind == 'agent';
      final isRun = node.kind == 'run';
      final isEvent = node.kind == 'event';
      final failed = isEvent && node.label.startsWith('[ERR]');
      final radius = isAgent ? 17.0 : isRun ? 12.0 : isEvent ? 7.0 : 12.0;
      final nodeColor = failed ? colors.error : isAgent ? colors.tertiary : isRun ? colors.secondary : colors.primary;
      final fillColor = failed ? colors.errorContainer : isAgent ? colors.tertiaryContainer : isRun ? colors.secondaryContainer : colors.primaryContainer;
      final textColor = failed ? colors.onErrorContainer : isAgent ? colors.onTertiaryContainer : isRun ? colors.onSecondaryContainer : colors.onPrimaryContainer;
      canvas.drawCircle(p, radius + 4, Paint()..color = nodeColor.withOpacity(.09));
      canvas.drawCircle(p, radius, Paint()..color = fillColor);
      final label = node.label.length > 23 ? node.label.substring(0, 22) + '…' : node.label;
      final text = TextPainter(
        text: TextSpan(text: label, style: TextStyle(
          color: textColor, fontSize: isEvent ? 7 : 9, fontWeight: FontWeight.w600,
        )),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        textAlign: TextAlign.center,
      )..layout(maxWidth: isEvent ? 160 : 180);
      text.paint(canvas, Offset(p.dx - text.width / 2, p.dy + radius + 3));
    }
  }

  @override bool shouldRepaint(covariant _NetworkPainter old) => old.nodes != nodes || old.links != links || old.colors != colors;
}

class _PerformancePainter extends CustomPainter {
  final List<CollaborationEvent> events;
  final Color color;
  final Color grid;
  const _PerformancePainter({required this.events, required this.color, required this.grid});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = grid.withOpacity(.4)..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final data = events.reversed.take(30).toList();
    if (data.isEmpty) return;
    final maxDuration = data.map((e) => e.duration.inMilliseconds).fold<int>(1, (a, b) => a > b ? a : b).toDouble();
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1 ? size.width / 2 : size.width * i / (data.length - 1);
      final y = size.height - (data[i].duration.inMilliseconds / maxDuration) * (size.height - 8) - 4;
      points.add(Offset(x, y));
    }
    final paint = Paint()..color = color..strokeWidth = 2.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) { path.lineTo(point.dx, point.dy); }
    canvas.drawPath(path, paint);
    for (final point in points) { canvas.drawCircle(point, 3.2, Paint()..color = color); }
  }

  @override bool shouldRepaint(covariant _PerformancePainter old) => old.events != events || old.color != color || old.grid != grid;
}
