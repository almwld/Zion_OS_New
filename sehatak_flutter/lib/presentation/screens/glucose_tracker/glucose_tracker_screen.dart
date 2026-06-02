import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class GlucoseTrackerScreen extends StatefulWidget {
  const GlucoseTrackerScreen({super.key});
  @override
  State<GlucoseTrackerScreen> createState() => _GlucoseTrackerScreenState();
}

class _GlucoseTrackerScreenState extends State<GlucoseTrackerScreen> {
  List<Map<String, dynamic>> _readings = [
    {'time': 'قبل الفطور', 'value': 95, 'status': 'طبيعي'},
    {'time': 'بعد الفطور', 'value': 140, 'status': 'مرتفع'},
    {'time': 'قبل الغداء', 'value': 88, 'status': 'طبيعي'},
    {'time': 'بعد الغداء', 'value': 155, 'status': 'مرتفع'},
    {'time': 'قبل العشاء', 'value': 102, 'status': 'طبيعي'},
    {'time': 'بعد العشاء', 'value': 180, 'status': 'عالي'},
  ];
  final _value = TextEditingController();
  String _time = 'قبل الفطور';

  Color _c(String s) => s == 'طبيعي' ? AppColors.success : s == 'مرتفع' ? AppColors.warning : AppColors.error;

  void _add() {
    if (_value.text.isEmpty) return;
    setState(() => _readings.insert(0, {'time': _time, 'value': int.parse(_value.text), 'status': int.parse(_value.text) < 110 ? 'طبيعي' : int.parse(_value.text) < 140 ? 'مرتفع' : 'عالي'}));
    _value.clear(); Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع السكر', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade700]), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          const Text('متوسط السكر التراكمي', style: TextStyle(color: Colors.white70)),
          Text('${(_readings.fold(0, (s, r) => s + (r['value'] as int)) / (_readings.length * 18.0)).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
        ])),
        const SizedBox(height: 16),
        Text('قراءات اليوم', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        for (final r in _readings) Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.bloodtype, color: AppColors.error, size: 20), const SizedBox(width: 8), Expanded(child: Text(r['time'], style: const TextStyle(fontWeight: FontWeight.w500))), Text('${r['value']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primary)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _c(r['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(r['status'], style: TextStyle(fontSize: 9, color: _c(r['status']))))])),
      ])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField(value: _time, items: ['قبل الفطور','بعد الفطور','قبل الغداء','بعد الغداء','قبل العشاء','بعد العشاء'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _time = v!)),
          const SizedBox(height: 10),
          TextField(controller: _value, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القراءة', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _add, child: const Text('إضافة')))
        ]))),
        backgroundColor: AppColors.primary, icon: const Icon(Icons.add), label: const Text('إضافة قراءة'),
      ),
    );
  }
}
