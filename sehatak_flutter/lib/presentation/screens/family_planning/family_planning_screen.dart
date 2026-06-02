import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class FamilyPlanningScreen extends StatelessWidget {
  const FamilyPlanningScreen({super.key});

  final List<Map<String, dynamic>> _methods = const [
    {'name': 'حبوب منع الحمل', 'effectiveness': '99%', 'duration': 'شهري', 'color': AppColors.primary, 'desc': 'تؤخذ يومياً في نفس الوقت'},
    {'name': 'اللولب', 'effectiveness': '99.5%', 'duration': '5-10 سنوات', 'color': AppColors.info, 'desc': 'جهاز صغير يوضع في الرحم'},
    {'name': 'الحقن', 'effectiveness': '99%', 'duration': '3 أشهر', 'color': AppColors.success, 'desc': 'حقنة كل 3 أشهر'},
    {'name': 'الواقي الذكري', 'effectiveness': '98%', 'duration': 'استخدام واحد', 'color': AppColors.warning, 'desc': 'يحمي من الأمراض المنقولة'},
    {'name': 'الغرسة', 'effectiveness': '99.9%', 'duration': '3-5 سنوات', 'color': AppColors.purple, 'desc': 'تزرع تحت جلد الذراع'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظيم الأسرة', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.purple.shade400]), borderRadius: BorderRadius.circular(16)), child: const Column(children: [Icon(Icons.family_restroom, color: Colors.white, size: 40), SizedBox(height: 8), Text('استشارات تنظيم الأسرة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text('اختر الوسيلة المناسبة لك', style: TextStyle(color: Colors.white70, fontSize: 12))])),
        const SizedBox(height: 16),
        Text('وسائل منع الحمل', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        for (final m in _methods) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: (m['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.medical_services, color: m['color'], size: 22)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(m['desc'], style: const TextStyle(fontSize: 10, color: AppColors.grey)), Row(children: [Text('فعالية: ${m['effectiveness']}', style: TextStyle(fontSize: 10, color: m['color'])), const SizedBox(width: 10), Text('المدة: ${m['duration']}', style: const TextStyle(fontSize: 10, color: AppColors.grey))])])), const Icon(Icons.arrow_back_ios, size: 14, color: AppColors.grey)])),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.05), borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(Icons.phone, color: AppColors.info), SizedBox(width: 8), Expanded(child: Text('استشيري طبيبك لاختيار الوسيلة الأنسب', style: TextStyle(fontSize: 12)))])),
      ])),
    );
  }
}
