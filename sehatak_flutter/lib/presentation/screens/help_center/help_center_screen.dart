import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {'q': 'كيف أحجز موعداً؟', 'a': 'اذهب إلى قسم الأطباء، اختر التخصص والطبيب، ثم اختر التاريخ والوقت.'},
    {'q': 'كيف أطلب دواء؟', 'a': 'اذهب إلى الصيدلية، ابحث عن الدواء، أضف للسلة وأكمل الطلب.'},
    {'q': 'هل يمكنني إلغاء موعد؟', 'a': 'نعم، اذهب إلى مواعيدي واضغط إلغاء قبل 24 ساعة من الموعد.'},
    {'q': 'هل بياناتي آمنة؟', 'a': 'نعم، جميع بياناتك مشفرة ومحمية بأعلى معايير الأمان.'},
    {'q': 'كم تكلفة الاشتراك؟', 'a': 'الباقة الأساسية مجانية. الذهبية 4,900 ر.ي/شهر. البلاتينية 12,900 ر.ي/شهر.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مركز المساعدة', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(decoration: InputDecoration(hintText: 'ابحث في الأسئلة الشائعة...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: AppColors.surfaceContainerLow, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
        const SizedBox(height: 16),
        Text('الأسئلة الشائعة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        for (final f in _faqs) Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]), child: ExpansionTile(title: Text(f['q']!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)), children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: Text(f['a']!, style: const TextStyle(fontSize: 12, color: AppColors.darkGrey)))])),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          const Icon(Icons.headset_mic, color: Colors.white, size: 40), const SizedBox(height: 8),
          const Text('لم تجد إجابتك؟', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('فريق الدعم جاهز لمساعدتك', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn('اتصل', Icons.call), _btn('راسلنا', Icons.email), _btn('دردشة', Icons.chat),
          ]),
        ])),
      ])),
    );
  }

  Widget _btn(String l, IconData i) => Column(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(i, color: Colors.white, size: 20)), const SizedBox(height: 4), Text(l, style: const TextStyle(color: Colors.white, fontSize: 10))]);
}
