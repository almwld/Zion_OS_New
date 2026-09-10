import 'package:flutter/material.dart';

import '../../ai/neural_analyzer.dart';
import '../../core/runtime/professional_runtime_controller.dart';

/// Professional local command-intelligence console.
/// It analyses and predicts commands but never executes predictions.
class RuntimeIntelligenceApp extends StatefulWidget {
  const RuntimeIntelligenceApp({super.key});

  @override
  State<RuntimeIntelligenceApp> createState() => _RuntimeIntelligenceAppState();
}

class _RuntimeIntelligenceAppState extends State<RuntimeIntelligenceApp> {
  final _controller = ProfessionalRuntimeController();
  final _input = TextEditingController();
  NeuralAnalysisResult? _analysis;
  List<String> _completion = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _input.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _inspect() async {
    final command = _input.text.trim();
    if (command.isEmpty) return;
    setState(() => _busy = true);
    final result = await _controller.inspectCommand(command);
    if (mounted) {
      setState(() {
        _analysis = result;
        _completion = _controller.autocomplete(command);
        _busy = false;
      });
    }
  }

  Future<void> _clear() async {
    await _controller.clearHistory();
    if (mounted) setState(() { _analysis = null; _completion = const []; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runtime Intelligence'),
        actions: [IconButton(onPressed: _clear, icon: const Icon(Icons.delete_sweep))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Neural Analyzer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('تحليل محلي للأمر قبل التنفيذ. لا يتم تنفيذ أي اقتراح تلقائيًا.'),
                const SizedBox(height: 14),
                TextField(
                  controller: _input,
                  onChanged: (value) => setState(() => _completion = _controller.autocomplete(value)),
                  onSubmitted: (_) => _inspect(),
                  decoration: InputDecoration(
                    labelText: 'الأمر',
                    hintText: 'اكتب أمرًا للفحص',
                    suffixIcon: IconButton(onPressed: _busy ? null : _inspect, icon: const Icon(Icons.search)),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_completion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: _completion.map((item) => ActionChip(label: Text(item), onPressed: () { _input.text = item; _input.selection = TextSelection.collapsed(offset: item.length); })).toList()),
                ],
              ]),
            ),
          ),
          if (_analysis != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('مستوى المخاطر: ${_analysis!.riskLevel}/100', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_analysis!.requiresConfirmation ? 'يتطلب مراجعة وتأكيدًا قبل التنفيذ.' : 'لا يتطلب تأكيدًا إضافيًا وفق القواعد المحلية.'),
                  const Divider(height: 24),
                  ..._analysis!.suggestions.map((s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $s'))),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Command Predictor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('اقتراحات مبنية على سجل الأوامر المحلي فقط.'),
                const SizedBox(height: 12),
                if (_controller.predictions.isEmpty)
                  const Text('لا توجد تنبؤات كافية بعد.')
                else
                  ..._controller.predictions.map((p) => ListTile(dense: true, leading: const Icon(Icons.auto_awesome), title: Text(p.command), subtitle: Text('${(p.confidence * 100).toStringAsFixed(0)}% • ${p.reason}'), onTap: () { _input.text = p.command; })),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
