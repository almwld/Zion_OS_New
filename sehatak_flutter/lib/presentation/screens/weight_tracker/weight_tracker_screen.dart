import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});
  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  double _current = 72.5, _target = 68.0, _height = 175;
  List<Map<String, dynamic>> _history = [
    {'date': '1 مايو', 'weight': 72.5}, {'date': '15 أبريل', 'weight': 73.2}, {'date': '1 أبريل', 'weight': 74.0},
  ];
  final _weightCtrl = TextEditingController();

  void _add() {
    if (_weightCtrl.text.isEmpty) return;
    setState(() { _history.insert(0, {'date': 'اليوم', 'weight': double.parse(_weightCtrl.text)}); _current = double.parse(_weightCtrl.text); });
    _weightCtrl.clear(); Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الوزن', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.success, AppColors.teal]), borderRadius: BorderRadius.circular(16)), child: Column(children: [const Text('وزنك الحالي', style: TextStyle(color: Colors.white70)), Text('$_current', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)), const Text('كجم', style: TextStyle(color: Colors.white70)), const SizedBox(height: 8), Text('🎯 الهدف: $_target كجم', style: const TextStyle(color: Colors.white70))])),
        const SizedBox(height: 14),
        Row(children: [
          _stat('خسرت', '${_history.isNotEmpty ? _history.last['weight'] : 0}', Icons.trending_down, AppColors.success), const SizedBox(width: 8),
          _stat('متبقي', '${(_current - _target).toStringAsFixed(1)}', Icons.flag, AppColors.warning), const SizedBox(width: 8),
          _stat('BMI', (_current / ((_height / 100) * (_height / 100))).toStringAsFixed(1), Icons.monitor_weight, AppColors.info),
        ]),
        const SizedBox(height: 16),
        Text('سجل الوزن', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        for (final h in _history) Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Text('⚖️', style: TextStyle(fontSize: 24)), const SizedBox(width: 10), Expanded(child: Text(h['date'], style: const TextStyle(fontWeight: FontWeight.w500))), Text('${h['weight']} كجم', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16))])),
      ])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن الجديد (كجم)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _add, child: const Text('حفظ')))
        ]))),
        backgroundColor: AppColors.primary, icon: const Icon(Icons.add), label: const Text('تسجيل وزن'),
      ),
    );
  }

  Widget _stat(String l, String v, IconData i, Color c) => Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(i, color: c, size: 20), const SizedBox(height: 4), Text(v, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: c)), Text(l, style: const TextStyle(fontSize: 10, color: AppColors.grey))])));
}
