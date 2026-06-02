import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class AlternativeMedicineScreen extends StatelessWidget {
  const AlternativeMedicineScreen({super.key});

  final List<Map<String, dynamic>> _treatments = const [
    {'name': 'الحجامة', 'desc': 'علاج تقليدي لتنشيط الدورة الدموية', 'price': '150', 'color': AppColors.error},
    {'name': 'الوخز بالإبر', 'desc': 'علاج صيني لتسكين الآلام', 'price': '200', 'color': AppColors.primary},
    {'name': 'الأعشاب الطبية', 'desc': 'وصفات طبيعية من الأعشاب', 'price': '100', 'color': AppColors.success},
    {'name': 'المساج العلاجي', 'desc': 'تدليك لتخفيف التوتر', 'price': '180', 'color': AppColors.purple},
    {'name': 'العلاج بالطاقة', 'desc': 'جلسات طاقة لموازنة الجسم', 'price': '250', 'color': AppColors.teal},
    {'name': 'العلاج المائي', 'desc': 'جلسات علاج بالماء الساخن', 'price': '220', 'color': AppColors.info},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطب البديل', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.success, AppColors.teal]), borderRadius: BorderRadius.circular(16)), child: const Column(children: [Text('🌿', style: TextStyle(fontSize: 48)), SizedBox(height: 8), Text('الطب البديل والتكميلي', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text('علاجات طبيعية مكملة للطب الحديث', style: TextStyle(color: Colors.white70, fontSize: 12))])),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
            children: _treatments.map((t) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.eco, color: t['color'], size: 36),
                  const SizedBox(height: 8),
                  Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(t['desc'], style: const TextStyle(fontSize: 9, color: AppColors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (t['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(6)), child: Text('${t['price']} ر.ي', style: TextStyle(fontSize: 10, color: t['color'], fontWeight: FontWeight.bold))),
                ]),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.05), borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(Icons.info, color: AppColors.warning), SizedBox(width: 8), Expanded(child: Text('استشر طبيبك قبل تجربة أي علاج بديل', style: TextStyle(fontSize: 12)))])),
        ]),
      ),
    );
  }
}
