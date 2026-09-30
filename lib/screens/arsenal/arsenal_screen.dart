import 'package:flutter/material.dart';
import '../../core/arsenal/arsenal_service.dart';
import '../../core/arsenal/arsenal_registry.dart';
import '../../security/core/authorization_policy.dart';

class ArsenalScreen extends StatefulWidget {
  const ArsenalScreen({super.key});
  @override State<ArsenalScreen> createState() => _ArsenalScreenState();
}

class _ArsenalScreenState extends State<ArsenalScreen> {
  final ArsenalService _service = ArsenalService();
  ArsenalRegistry _registry = ArsenalRegistry();
  bool _loading = true;

  @override void initState() { super.initState(); _refresh(); }
  Future<void> _refresh() async {
    setState(() => _loading = true);
    final registry = await _service.refresh();
    if (!mounted) return;
    setState(() { _registry = registry; _loading = false; });
  }

  Future<void> _run(ArsenalTool tool) async {
    final controller = TextEditingController();
    final arguments = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tool.name),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Arguments', hintText: 'مثال: -c id')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim().isEmpty ? <String>[] : controller.text.trim().split(RegExp(r'\s+'))), child: const Text('تشغيل')),
        ],
      ),
    );
    if (arguments == null) return;
    final result = await _service.execute(
      toolId: tool.id, arguments: arguments, actor: 'arsenal-ui',
      scope: AuthorizationScope(target: 'local-device', mode: SecurityMode.defensive, expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)), allowedActions: <String>{tool.id}),
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tool.name + ' — ' + result.status),
        content: SingleChildScrollView(child: SelectableText([if (result.stdout.isNotEmpty) result.stdout, if (result.stderr.isNotEmpty) result.stderr, if (result.reason != null) result.reason!].join('\n'))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
      ),
    );
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Arsenal'), actions: [IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(padding: const EdgeInsets.all(12), children: [_summary(), for (final category in ArsenalCategory.values) _category(category)]),
    ),
  );

  Widget _summary() {
    final available = _registry.tools.where((tool) => tool.availability == ArsenalAvailability.available).length;
    return Card(child: ListTile(leading: const Icon(Icons.security), title: const Text('Arsenal Runtime'), subtitle: Text(_registry.tools.length.toString() + ' أدوات • ' + available.toString() + ' متاحة فعليًا')));
  }

  Widget _category(ArsenalCategory category) {
    final tools = _registry.byCategory(category);
    if (tools.isEmpty) return const SizedBox.shrink();
    return Card(margin: const EdgeInsets.only(top: 10), child: ExpansionTile(title: Text(category.name.toUpperCase()), children: [
      for (final tool in tools) ListTile(title: Text(tool.name), subtitle: Text(tool.reason ?? tool.availability.name.toUpperCase()), trailing: tool.availability == ArsenalAvailability.available ? IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => _run(tool)) : Chip(label: Text(tool.availability.name.toUpperCase()))),
    ]));
  }
}
