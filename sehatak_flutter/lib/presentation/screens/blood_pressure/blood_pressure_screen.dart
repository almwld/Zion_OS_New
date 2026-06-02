import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/core/services/patient_data_service.dart';

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});
  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  final _data = PatientDataService();
  List<Map<String, dynamic>> _readings = [];
  final _sys = TextEditingController(), _dia = TextEditingController(), _pulse = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    await _data.init();
    setState(() => _readings = [
      {'date': '1 مايو', 'sys': 128, 'dia': 82, 'pulse': 72, 'time': 'صباحاً', 'status': 'طبيعي'},
      {'date': '28 أبريل', 'sys': 135, 'dia': 88, 'pulse': 75, 'time': 'مساءً', 'status': 'مرتفع'},
    ]);
  }

  Color _c(String s) => s == 'مثالي' ? AppColors.success : s == 'طبيعي' ? AppColors.info : s == 'مرتفع' ? AppColors.warning : AppColors.error;

  void _add() {
    if (_sys.text.isEmpty || _dia.text.isEmpty) return;
    setState(() => _readings.insert(0, {
      'date': 'اليوم', 'sys': int.parse(_sys.text), 'dia': int.parse(_dia.text),
      'pulse': int.tryParse(_pulse.text) ?? 0, 'time': 'الآن',
      'status': int.parse(_sys.text) < 120 ? 'مثالي' : int.parse(_sys.text) < 130 ? 'طبيعي' : int.parse(_sys.text) < 140 ? 'مرتفع' : 'عالي',
    }));
    _sys.clear(); _dia.clear(); _pulse.clear(); Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ضغط الدم', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          const Text('آخر قراءة', style: TextStyle(color: Colors.white70)), const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [const Text('الانقباضي', style: TextStyle(color: Colors.white70, fontSize: 11)), Text('${_readings.isNotEmpty ? _readings.first['sys'] : "-"}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))]),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('/', style: TextStyle(color: Colors.white38, fontSize: 36))),
            Column(children: [const Text('الانبساطي', style: TextStyle(color: Colors.white70, fontSize: 11)), Text('${_readings.isNotEmpty ? _readings.first['dia'] : "-"}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))]),
          ]),
          if (_readings.isNotEmpty) Text('نبض: ${_readings.first['pulse']} bpm', style: const TextStyle(color: Colors.white70)),
        ])),
        const SizedBox(height: 14),
        Text('سجل القراءات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        for (final r in _readings) Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]), child: Row(children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: _c(r['status']), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${r['date']} • ${r['time']}', style: const TextStyle(fontWeight: FontWeight.w500)), Text('نبض: ${r['pulse']} bpm', style: const TextStyle(fontSize: 10, color: AppColors.grey))])),
          Text('${r['sys']}/${r['dia']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _c(r['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(r['status'], style: TextStyle(fontSize: 9, color: _c(r['status'])))),
        ])),
      ])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _sys, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الانقباضي', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _dia, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الانبساطي', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _pulse, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'النبض', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _add, child: const Text('إضافة قراءة')))
        ]))),
        backgroundColor: AppColors.primary, icon: const Icon(Icons.add), label: const Text('إضافة قراءة'),
      ),
    );
  }
}
