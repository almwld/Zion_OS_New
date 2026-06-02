import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});
  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  final List<Map<String, dynamic>> _week = const [
    {'day': 'سبت', 'hours': 7.5}, {'day': 'أحد', 'hours': 6.2}, {'day': 'إثنين', 'hours': 8.0},
    {'day': 'ثلاثاء', 'hours': 5.5}, {'day': 'أربعاء', 'hours': 7.0}, {'day': 'خميس', 'hours': 7.8}, {'day': 'جمعة', 'hours': 8.2},
  ];

  double get _avg => _week.fold(0.0, (s, d) => s + (d['hours'] as double)) / _week.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع النوم', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.bedtime, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              const Text('نوم الليلة الماضية', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('7.5', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)), const Text(' ساعة', style: TextStyle(color: Colors.white70, fontSize: 18))]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: const Text('😊 نوم جيد', style: TextStyle(color: Colors.white))),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [_stat('متوسط', '${_avg.toStringAsFixed(1)} س', Icons.bed), const SizedBox(width: 8), _stat('أفضل يوم', 'الجمعة', Icons.star), const SizedBox(width: 8), _stat('الهدف', '8 ساعات', Icons.flag)]),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]), height: 160, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: _week.map((d) => Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Text('${(d['hours'] as double).toStringAsFixed(0)}س', style: const TextStyle(fontSize: 9)), const SizedBox(height: 4), Container(width: 26, height: (d['hours'] as double) * 14, decoration: BoxDecoration(color: (d['hours'] as double) >= 8 ? AppColors.success : (d['hours'] as double) >= 6 ? AppColors.info : AppColors.error, borderRadius: BorderRadius.circular(6))), const SizedBox(height: 4), Text(d['day'], style: const TextStyle(fontSize: 9, color: AppColors.grey))]))).toList()),),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(14)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💤 نصائح لنوم أفضل', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 8),
            Text('• نم واستيقظ في نفس الوقت يومياً', style: TextStyle(fontSize: 12)),
            Text('• تجنب الكافيين قبل النوم بـ 6 ساعات', style: TextStyle(fontSize: 12)),
            Text('• أبعد الهاتف قبل النوم بنصف ساعة', style: TextStyle(fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]), child: Column(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(label, style: const TextStyle(fontSize: 9, color: AppColors.grey))])));
}
