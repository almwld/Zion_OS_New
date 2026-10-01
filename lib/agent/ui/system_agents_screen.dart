import 'package:flutter/material.dart';
import '../system/system_agent.dart';
import '../core/agent_models.dart';
import '../system/system_agent_tool.dart';
import '../core/agent_runtime.dart';

class SystemAgentsScreen extends StatefulWidget {
  const SystemAgentsScreen({super.key});
  @override State<SystemAgentsScreen> createState() => _SystemAgentsScreenState();
}

class _SystemAgentsScreenState extends State<SystemAgentsScreen> {
  late final AgentRuntime _runtime;
  late final SystemAgentCoordinator _coordinator;
  String? _running;
  String _report = 'اختر وكيلاً لبدء تشخيص محلي.';

  @override
  void initState() {
    super.initState();
    _runtime = AgentRuntime();
    _runtime.orchestrator.tools.register(SystemAgentTool());
    _coordinator = SystemAgentCoordinator(runtime: _runtime);
  }

  Future<void> _run(SystemAgentDefinition agent) async {
    if (_running != null) return;
    setState(() { _running = agent.id; _report = 'جاري تشغيل ${agent.name}...'; });
    final plan = _coordinator.planFor(agent.id);
    final tool = _runtime.orchestrator.tools.getTool(plan.steps.first.tool);
    final result = tool == null
        ? AgentResult.error(agent.id, 'أداة التشخيص غير متاحة.')
        : await tool.execute(plan.steps.first.params).then((r) =>
            AgentResult(success: r.success, task: agent.name, steps: [r], report: r.data?.toString() ?? r.summary, error: r.error));
    if (!mounted) return;
    setState(() { _running = null; _report = result.success ? (result.report ?? 'اكتمل التشخيص.') : (result.error ?? 'فشل التشخيص.'); });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070B08),
    appBar: AppBar(title: const Text('Zion System Agents'), backgroundColor: const Color(0xFF0B120E)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('وكلاء النظام', style: TextStyle(color: Color(0xFF00FF41), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('وكلاء تشخيص محلي؛ لا تنفيذ هجومي ولا فحص أهداف خارجية.', style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 16),
        for (final agent in SystemAgentRegistry.definitions)
          Card(
            color: const Color(0xFF101812),
            child: ListTile(
              leading: Icon(_icon(agent.kind), color: const Color(0xFF00FF41)),
              title: Text(agent.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(agent.description, style: const TextStyle(color: Colors.white54)),
              trailing: _running == agent.id
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(onPressed: _running == null ? () => _run(agent) : null, icon: const Icon(Icons.play_arrow, color: Color(0xFF00FF41))),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF0B120E),
          child: Padding(padding: const EdgeInsets.all(12), child: SelectableText(_report, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace'))),
        ),
      ],
    ),
  );

  IconData _icon(SystemAgentKind kind) => switch (kind) {
    SystemAgentKind.system => Icons.settings,
    SystemAgentKind.performance => Icons.speed,
    SystemAgentKind.network => Icons.wifi,
    SystemAgentKind.security => Icons.shield,
  };

  @override void dispose() { _coordinator.dispose(); super.dispose(); }
}
