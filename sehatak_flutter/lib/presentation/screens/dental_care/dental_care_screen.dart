import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class DentalCareScreen extends StatelessWidget {
  const DentalCareScreen({super.key});

  final List<Map<String, dynamic>> _services = const [
    {'name': 'فحص أسنان', 'price': '100', 'time': '30 د', 'icon': '🦷', 'color': AppColors.primary},
    {'name': 'تنظيف أسنان', 'price': '200', 'time': '45 د', 'icon': '🪥', 'color': AppColors.info},
    {'name': 'حشو عصب', 'price': '500', 'time': '60 د', 'icon': '🔧', 'color': AppColors.error},
    {'name': 'تقويم أسنان', 'price': '5000', 'time': '12-18 شهر', 'icon': '😬', 'color': AppColors.purple},
    {'name': 'تبييض أسنان', 'price': '800', 'time': '45 د', 'icon': '✨', 'color': AppColors.amber},
    {'name': 'زراعة أسنان', 'price': '3000', 'time': 'جلسات', 'icon': '🏗️', 'color': AppColors.success},
    {'name': 'خلع ضرس', 'price': '300', 'time': '30 د', 'icon': '🦷', 'color': AppColors.warning},
    {'name': 'تركيبات', 'price': '1500', 'time': '3 جلسات', 'icon': '👄', 'color': AppColors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طب الأسنان', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade200, Colors.blue.shade700]), borderRadius: BorderRadius.circular(16)), child: const Row(children: [Text('🦷', style: TextStyle(fontSize: 52)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('صحة أسنانك', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text('ابتسامة صحية = ثقة أكبر', style: TextStyle(color: Colors.white70, fontSize: 13))]))])),
          const SizedBox(height: 16),
          Row(children: [_stat('10 خدمات', Icons.medical_services, AppColors.primary), const SizedBox(width: 8), _stat('خصم 33%', Icons.discount, AppColors.success), const SizedBox(width: 8), _stat('4.8 ★', Icons.star, AppColors.amber)]),
          const SizedBox(height: 16),
          Text('خدماتنا', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final s in _services) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: (s['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(s['icon'], style: const TextStyle(fontSize: 22)))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text('⏱ ${s['time']}', style: const TextStyle(fontSize: 10, color: AppColors.grey))])), Text('${s['price']} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))])),
        ]),
      ),
    );
  }

  Widget _stat(String l, IconData i, Color c) => Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Row(children: [Icon(i, color: c, size: 18), const SizedBox(width: 6), Text(l, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c))])));
}
