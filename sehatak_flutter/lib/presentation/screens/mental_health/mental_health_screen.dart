import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/stress_meter/stress_meter_screen.dart';
import 'package:sehatak/presentation/screens/chat/chat_screen.dart';

class MentalHealthScreen extends StatelessWidget {
  const MentalHealthScreen({super.key});

  final List<Map<String, dynamic>> _services = const [
    {'name': 'استشارة نفسية', 'icon': Icons.psychology, 'desc': 'جلسات فردية مع أخصائي', 'price': 'من 200 ر.ي', 'color': AppColors.purple},
    {'name': 'علاج معرفي سلوكي', 'icon': Icons.self_improvement, 'desc': 'جلسات CBT متخصصة', 'price': 'من 250 ر.ي', 'color': AppColors.info},
    {'name': 'تأمل واسترخاء', 'icon': Icons.spa, 'desc': 'تمارين تنفس وتأمل', 'price': 'مجاناً', 'color': AppColors.teal},
    {'name': 'مقياس الاكتئاب', 'icon': Icons.assessment, 'desc': 'اختبار PHQ-9', 'price': 'مجاناً', 'color': AppColors.warning},
    {'name': 'دعم فوري', 'icon': Icons.sos, 'desc': 'خط ساخن للدعم النفسي', 'price': 'مجاناً', 'color': AppColors.error},
    {'name': 'مجموعات دعم', 'icon': Icons.group, 'desc': 'جلسات جماعية أسبوعية', 'price': 'من 50 ر.ي', 'color': AppColors.success},
  ];

  final List<Map<String, dynamic>> _doctors = const [
    {'name': 'د. سارة العامري', 'specialty': 'استشارية طب نفسي', 'rating': 4.9, 'reviews': 340, 'price': '300', 'image': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=100'},
    {'name': 'د. بلال محمود', 'specialty': 'أخصائي علاج نفسي', 'rating': 4.8, 'reviews': 134, 'price': '250', 'image': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=100'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصحة النفسية', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.shade300, Colors.purple.shade700]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.psychology, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              const Text('صحتي النفسية', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('صحّتك النفسية تهمنا.. أنت لست وحدك 🤍', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StressMeterScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple), child: const Text('اختبر مستوى التوتر')),
            ]),
          ),
          const SizedBox(height: 16),
          Text('خدماتنا', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.95,
            children: _services.map((s) => GestureDetector(
              onTap: () { if (s['name'] == 'استشارة نفسية') Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())); if (s['name'] == 'مقياس الاكتئاب') Navigator.push(context, MaterialPageRoute(builder: (_) => const StressMeterScreen())); },
              child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(s['icon'], color: s['color'], size: 36), const SizedBox(height: 6), Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center), Text(s['desc'], style: const TextStyle(fontSize: 9, color: AppColors.grey), textAlign: TextAlign.center), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (s['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(4)), child: Text(s['price'], style: TextStyle(fontSize: 9, color: s['color'])))])),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('أخصائيونا', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ..._doctors.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
            child: Row(children: [
              CircleAvatar(radius: 24, backgroundImage: NetworkImage(d['image'])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(d['specialty'], style: const TextStyle(fontSize: 10, color: AppColors.grey)), Row(children: [const Icon(Icons.star, color: AppColors.amber, size: 14), Text(' ${d['rating']} (${d['reviews']})', style: const TextStyle(fontSize: 10))])])),
              Column(children: [Text('${d['price']} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 4), ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())), style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), minimumSize: Size.zero), child: const Text('استشر', style: TextStyle(fontSize: 10)))]),
            ]),
          )),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.error.withOpacity(0.25))), child: Row(children: [const Icon(Icons.sos, color: AppColors.error, size: 32), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تحتاج مساعدة فورية؟', style: TextStyle(fontWeight: FontWeight.bold)), Text('خط الدعم النفسي متاح 24/7', style: TextStyle(fontSize: 12, color: AppColors.grey))])), ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('اتصل الآن'))])),
        ]),
      ),
    );
  }
}
