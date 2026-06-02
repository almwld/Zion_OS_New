import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/lab/labs_list_screen.dart';
import 'package:sehatak/presentation/screens/medical_reports/medical_reports_screen.dart';

class PatientMedicalHistory extends StatefulWidget {
  const PatientMedicalHistory({super.key});
  @override
  State<PatientMedicalHistory> createState() => _PatientMedicalHistoryState();
}

class _PatientMedicalHistoryState extends State<PatientMedicalHistory> {
  String _tab = 'تحاليل';

  final List<Map<String, dynamic>> _tests = [
    {'name': 'تعداد دم كامل CBC', 'date': '10 مايو 2026', 'status': 'مكتمل', 'result': 'طبيعي', 'doctor': 'د. حسن رضا', 'price': '800'},
    {'name': 'دهون ثلاثية', 'date': '5 مايو 2026', 'status': 'مكتمل', 'result': 'مرتفع', 'doctor': 'د. عثمان خان', 'price': '1200'},
    {'name': 'سكر تراكمي HbA1c', 'date': '20 أبريل 2026', 'status': 'قيد الانتظار', 'result': 'قيد المعالجة', 'doctor': 'د. حسن رضا', 'price': '900'},
    {'name': 'فيتامين د', 'date': '15 أبريل 2026', 'status': 'مكتمل', 'result': 'منخفض', 'doctor': 'د. عائشة ملك', 'price': '350'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحاليل والأشعة', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: () {})]),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)), child: Row(children: [
          _tabBtn('تحاليل', _tab == 'تحاليل'), _tabBtn('أشعة', _tab == 'أشعة'),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [
          _stat('الكل', '4', AppColors.primary), const SizedBox(width: 8),
          _stat('مكتمل', '3', AppColors.success), const SizedBox(width: 8),
          _stat('قيد الانتظار', '1', AppColors.warning),
        ])),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _tests.length, itemBuilder: (ctx, i) {
            final t = _tests[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('🧪', style: TextStyle(fontSize: 20)))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${t['doctor']} • ${t['date']}', style: const TextStyle(fontSize: 9, color: AppColors.grey)),
                  Text('${t['price']} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: t['status'] == 'مكتمل' ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(t['status'], style: TextStyle(fontSize: 8, color: t['status'] == 'مكتمل' ? AppColors.success : AppColors.warning))),
                  const SizedBox(height: 4),
                  if (t['result'] != null) Text(t['result'], style: TextStyle(fontSize: 9, color: t['result'] == 'طبيعي' ? AppColors.success : AppColors.warning)),
                ]),
              ]),
            );
          }),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabsListScreen())),
        backgroundColor: AppColors.primary, icon: const Icon(Icons.add), label: const Text('حجز فحص'),
      ),
    );
  }

  Widget _tabBtn(String t, bool s) => Expanded(child: GestureDetector(onTap: () => setState(() => _tab = t), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: s ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Text(t, textAlign: TextAlign.center, style: TextStyle(color: s ? Colors.white : AppColors.darkGrey, fontWeight: FontWeight.bold, fontSize: 13)))));
  Widget _stat(String l, String v, Color c) => Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Column(children: [Text(v, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: c)), Text(l, style: const TextStyle(fontSize: 9, color: AppColors.grey))])));
}
