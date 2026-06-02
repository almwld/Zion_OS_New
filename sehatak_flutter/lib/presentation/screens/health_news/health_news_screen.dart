import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class HealthNewsScreen extends StatelessWidget {
  const HealthNewsScreen({super.key});

  final List<Map<String, dynamic>> _news = const [
    {'title': 'حملة تطعيم شلل الأطفال', 'source': 'وزارة الصحة', 'time': 'منذ ساعتين', 'summary': 'أطلقت وزارة الصحة حملة وطنية لتطعيم الأطفال ضد شلل الأطفال', 'icon': '💉', 'color': AppColors.primary, 'urgent': true},
    {'title': 'تحذير من موجة حر', 'source': 'الأرصاد', 'time': 'منذ 4 ساعات', 'summary': 'تحذير من ارتفاع درجات الحرارة ونصائح للوقاية من ضربات الشمس', 'icon': '🌡️', 'color': AppColors.error, 'urgent': true},
    {'title': 'افتتاح مركز طبي جديد', 'source': 'منصة صحتك', 'time': 'منذ 6 ساعات', 'summary': 'افتتاح مركز صحي متكامل في صنعاء يخدم 50 ألف نسمة', 'icon': '🏥', 'color': AppColors.success, 'urgent': false},
    {'title': 'دراسة: فوائد المشي', 'source': 'جامعة صنعاء', 'time': 'منذ 12 ساعة', 'summary': 'دراسة تؤكد أن المشي 30 دقيقة يومياً يقلل أمراض القلب بنسبة 30%', 'icon': '🚶', 'color': AppColors.info, 'urgent': false},
    {'title': 'نقص دواء الضغط', 'source': 'نقابة الصيادلة', 'time': 'أمس', 'summary': 'تحذير من نقص بعض أدوية الضغط في الصيدليات', 'icon': '⚠️', 'color': AppColors.warning, 'urgent': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أخبار صحية', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () {})]),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _news.length,
        itemBuilder: (context, idx) {
          final n = _news[idx];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: n['urgent'] ? Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: (n['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(n['icon'], style: const TextStyle(fontSize: 22)))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (n['urgent']) Container(margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('عاجل', style: TextStyle(color: AppColors.error, fontSize: 8, fontWeight: FontWeight.bold))),
                Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(n['summary'], style: const TextStyle(fontSize: 11, color: AppColors.darkGrey, height: 1.3)),
                const SizedBox(height: 6),
                Row(children: [Text(n['source'], style: const TextStyle(fontSize: 9, color: AppColors.primary)), const SizedBox(width: 8), Text(n['time'], style: const TextStyle(fontSize: 9, color: AppColors.grey)), const Spacer(), const Icon(Icons.share, size: 14, color: AppColors.grey), const SizedBox(width: 8), const Icon(Icons.bookmark_border, size: 14, color: AppColors.grey)]),
              ])),
            ]),
          );
        },
      ),
    );
  }
}
