import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/vision_test/vision_test_screen.dart';

class EyeCareScreen extends StatelessWidget {
  const EyeCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طب العيون', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.indigo.shade300, Colors.indigo.shade700]), borderRadius: BorderRadius.circular(16)), child: const Row(children: [Text('👁️', style: TextStyle(fontSize: 52)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('صحة عيونك', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text('الفحص الدوري يحمي بصرك', style: TextStyle(color: Colors.white70, fontSize: 13))]))])),
          const SizedBox(height: 16),
          Text('اختبارات العين', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _test('اختبار حدة البصر', 'اختبر قوة نظرك', Icons.visibility, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisionTestScreen()))),
          _test('اختبار عمى الألوان', 'اكتشف صعوبة تمييز الألوان', Icons.palette, AppColors.purple, () {}),
          _test('فحص جفاف العين', 'اكتشف أعراض الجفاف', Icons.water_drop, AppColors.teal, () {}),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(14)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('👓 نصائح للعناية بالعيون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(height: 10),
            Text('• قاعدة 20-20-20: كل 20 د، انظر 20 قدم، 20 ثانية', style: TextStyle(fontSize: 12)),
            Text('• ارتدِ نظارات شمسية واقية', style: TextStyle(fontSize: 12)),
            Text('• افحص عينيك سنوياً', style: TextStyle(fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _test(String t, String d, IconData i, Color c, VoidCallback tap) => GestureDetector(
    onTap: tap,
    child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: c, size: 22)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(d, style: const TextStyle(fontSize: 10, color: AppColors.grey, height: 1.3))])), const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 32)])),
  );
}
