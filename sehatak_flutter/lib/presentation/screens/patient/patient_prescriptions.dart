import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/pharmacy/pharmacy_screen.dart';
import 'package:sehatak/presentation/screens/medication/medication_reminder_screen.dart';

class PatientPrescriptions extends StatefulWidget {
  const PatientPrescriptions({super.key});
  @override
  State<PatientPrescriptions> createState() => _PatientPrescriptionsState();
}

class _PatientPrescriptionsState extends State<PatientPrescriptions> {
  String _tab = 'نشطة';

  final List<Map<String, dynamic>> _active = [
    {'doctor': 'د. علي المولد', 'date': '1 مايو 2026', 'diagnosis': 'ارتفاع ضغط الدم', 'meds': ['أملوديبين 5mg - حبة يومياً', 'هيدروكلوروثيازيد 25mg'], 'duration': '3 أشهر', 'notes': 'تجنب الأطعمة المالحة'},
    {'doctor': 'د. عائشة ملك', 'date': '25 أبريل 2026', 'diagnosis': 'حساسية جلدية', 'meds': ['سيتريزين 10mg', 'مرهم هيدروكورتيزون'], 'duration': 'أسبوعين'},
    {'doctor': 'د. فاطمة صديقي', 'date': '18 أبريل 2026', 'diagnosis': 'التهاب حلق', 'meds': ['أموكسيسيلين 500mg', 'باراسيتامول 500mg'], 'duration': '7 أيام'},
  ];

  final List<Map<String, dynamic>> _past = [
    {'doctor': 'د. حسن رضا', 'date': '10 مارس 2026', 'diagnosis': 'التهاب معوي', 'meds': ['ميترونيدازول 500mg']},
    {'doctor': 'د. عثمان خان', 'date': '5 فبراير 2026', 'diagnosis': 'خفقان قلب', 'meds': ['بروبرانولول 40mg']},
  ];

  @override
  Widget build(BuildContext context) {
    final list = _tab == 'نشطة' ? _active : _past;
    return Scaffold(
      appBar: AppBar(title: const Text('الوصفات الطبية', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})]),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)), child: Row(children: [
          _tabBtn('نشطة', _tab == 'نشطة'), _tabBtn('سابقة', _tab == 'سابقة'),
        ])),
        Expanded(
          child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: list.length, itemBuilder: (ctx, i) {
            final p = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [CircleAvatar(radius: 22, backgroundColor: AppColors.primary.withOpacity(0.08), child: const Icon(Icons.person, color: AppColors.primary, size: 20)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['doctor'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text('${p['date']} • ${p['duration'] ?? "منتهية"}', style: const TextStyle(fontSize: 10, color: AppColors.grey))])), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _tab == 'نشطة' ? AppColors.success.withOpacity(0.1) : AppColors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(_tab == 'نشطة' ? 'نشطة' : 'منتهية', style: TextStyle(fontSize: 9, color: _tab == 'نشطة' ? AppColors.success : AppColors.grey)))]),
                const Divider(height: 16),
                Text('التشخيص: ${p['diagnosis']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ...(p['meds'] as List).map((m) => Container(margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.04), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.medication, size: 14, color: AppColors.primary), const SizedBox(width: 6), Text(m, style: const TextStyle(fontSize: 11))]))),
                if (p['notes'] != null) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.06), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.info, size: 14, color: AppColors.warning), const SizedBox(width: 6), Text(p['notes'], style: const TextStyle(fontSize: 10))])),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('تحميل PDF'))),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyScreen())), icon: const Icon(Icons.local_pharmacy, size: 16), label: const Text('طلب الأدوية'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary))),
                ]),
              ]),
            );
          }),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationReminderScreen())), backgroundColor: AppColors.primary, icon: const Icon(Icons.alarm), label: const Text('تذكير الأدوية')),
    );
  }

  Widget _tabBtn(String title, bool sel) => Expanded(child: GestureDetector(onTap: () => setState(() => _tab = title), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: sel ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: sel ? Colors.white : AppColors.darkGrey, fontWeight: FontWeight.bold, fontSize: 13)))));
}
