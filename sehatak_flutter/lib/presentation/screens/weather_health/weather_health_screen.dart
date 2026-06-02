import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class WeatherHealthScreen extends StatelessWidget {
  const WeatherHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطقس وصحتك', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('صنعاء', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text('اليوم، 1 مايو', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                const Column(children: [Text('☀️', style: TextStyle(fontSize: 48)), Text('مشمس', style: TextStyle(color: Colors.white70, fontSize: 12))]),
              ]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _w('الحرارة', '28°', '🌡️'), _w('الرطوبة', '45%', '💧'), _w('الرياح', '12 كم/س', '💨'),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Text('تأثير الطقس على صحتك', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _tip('☀️', 'حرارة مرتفعة', 'اشرب الماء بكثرة وتجنب التعرض للشمس', AppColors.warning),
          _tip('💧', 'رطوبة منخفضة', 'استخدم مرطب البشرة واشرب السوائل', AppColors.info),
          _tip('🌿', 'حبوب لقاح متوسطة', 'مرضى الحساسية: تناول أدويتك', AppColors.success),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.04), borderRadius: BorderRadius.circular(14)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 نصائح اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), SizedBox(height: 8),
            Text('• أفضل وقت للرياضة: قبل 10 ص أو بعد 5 م', style: TextStyle(fontSize: 12)),
            Text('• ارتدِ ملابس قطنية فاتحة اللون', style: TextStyle(fontSize: 12)),
            Text('• ضع واقي شمس قبل الخروج بـ 30 دقيقة', style: TextStyle(fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _w(String label, String value, String emoji) => Column(children: [Text(emoji, style: const TextStyle(fontSize: 20)), const SizedBox(height: 2), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9))]);
  Widget _tip(String emoji, String t, String d, Color c) => Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.15))), child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 24)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: c)), Text(d, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey))]))]));
}
