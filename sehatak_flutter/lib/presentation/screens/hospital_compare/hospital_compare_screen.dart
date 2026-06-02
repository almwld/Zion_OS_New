import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class HospitalCompareScreen extends StatefulWidget {
  const HospitalCompareScreen({super.key});
  @override
  State<HospitalCompareScreen> createState() => _HospitalCompareScreenState();
}

class _HospitalCompareScreenState extends State<HospitalCompareScreen> {
  final Set<int> _sel = {};
  final List<Map<String, dynamic>> _hospitals = const [
    {'name': 'مستشفى الثورة', 'beds': '500', 'doctors': '200', 'emergency': true, 'icu': true, 'rating': 4.5, 'price': 'غالي'},
    {'name': 'مستشفى الكويت', 'beds': '400', 'doctors': '180', 'emergency': true, 'icu': true, 'rating': 4.7, 'price': 'متوسط'},
    {'name': 'مستشفى آزال', 'beds': '150', 'doctors': '80', 'emergency': true, 'icu': false, 'rating': 4.2, 'price': 'رخيص'},
    {'name': 'المستشفى العسكري', 'beds': '600', 'doctors': '250', 'emergency': true, 'icu': true, 'rating': 4.8, 'price': 'متوسط'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مقارنة المستشفيات', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_sel.length >= 2)
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: [
            const DataColumn(label: Text('الميزة', style: TextStyle(fontWeight: FontWeight.bold))),
            ..._sel.map((i) => DataColumn(label: Text(_hospitals[i]['name']))),
          ], rows: [
            _row('التقييم', 'rating', Icons.star),
            _row('الأسرة', 'beds', Icons.bed),
            _row('الأطباء', 'doctors', Icons.person),
            _row('طوارئ', 'emergency', Icons.warning, isBool: true),
            _row('عناية', 'icu', Icons.monitor_heart, isBool: true),
            _row('التكلفة', 'price', Icons.money),
          ])),
        const SizedBox(height: 16),
        Text('اختر للمقارنة (${_sel.length}/2+)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        for (var i = 0; i < _hospitals.length; i++) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _sel.contains(i) ? AppColors.primary : Colors.transparent, width: 2)), child: Row(children: [
          const Icon(Icons.local_hospital, color: AppColors.error, size: 28), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_hospitals[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text('${_hospitals[i]['beds']} سرير • ${_hospitals[i]['doctors']} طبيب', style: const TextStyle(fontSize: 10, color: AppColors.grey))])),
          Checkbox(value: _sel.contains(i), activeColor: AppColors.primary, onChanged: (v) => setState(() { if (v!) _sel.add(i); else _sel.remove(i); })),
        ])),
      ])),
    );
  }

  DataRow _row(String l, String k, IconData i, {bool isBool = false}) => DataRow(cells: [
    DataCell(Row(children: [Icon(i, size: 16, color: AppColors.primary), const SizedBox(width: 6), Text(l, style: const TextStyle(fontSize: 12))])),
    ..._sel.map((si) { final v = _hospitals[si][k]; return DataCell(isBool ? Icon(v ? Icons.check : Icons.close, color: v ? AppColors.success : AppColors.error, size: 18) : Text(v.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))); }),
  ]);
}
