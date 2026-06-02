import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class CheckupReminderScreen extends StatefulWidget {
  const CheckupReminderScreen({super.key});
  @override
  State<CheckupReminderScreen> createState() => _CheckupReminderScreenState();
}

class _CheckupReminderScreenState extends State<CheckupReminderScreen> {
  final List<Map<String, dynamic>> _checks = const [
    {'name': 'فحص السكر', 'freq': 'كل 6 أشهر', 'next': '15 يوليو 2026', 'done': false, 'icon': Icons.bloodtype, 'color': AppColors.info},
    {'name': 'قياس الضغط', 'freq': 'شهرياً', 'next': '1 يونيو 2026', 'done': true, 'icon': Icons.monitor_heart, 'color': AppColors.primary},
    {'name': 'فحص الكوليسترول', 'freq': 'سنوياً', 'next': '10 سبتمبر 2026', 'done': false, 'icon': Icons.science, 'color': AppColors.warning},
    {'name': 'فحص الأسنان', 'freq': 'كل 6 أشهر', 'next': '20 أغسطس 2026', 'done': false, 'icon': Icons.masks, 'color': AppColors.teal},
    {'name': 'فحص العيون', 'freq': 'سنوياً', 'next': '5 ديسمبر 2026', 'done': false, 'icon': Icons.visibility, 'color': AppColors.purple},
    {'name': 'تطعيم الإنفلونزا', 'freq': 'سنوياً', 'next': '15 أكتوبر 2026', 'done': false, 'icon': Icons.vaccines, 'color': AppColors.success},
  ];

  @override
  Widget build(BuildContext context) {
    final done = _checks.where((c) => c['done']).length;
    return Scaffold(
      appBar: AppBar(title: const Text('تذكير الفحوصات', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          Text('$done/${_checks.length}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Text('فحص مكتمل', style: TextStyle(color: Colors.white70)),
          LinearProgressIndicator(value: done / _checks.length, backgroundColor: Colors.white24, color: Colors.white, minHeight: 5, borderRadius: BorderRadius.circular(3)),
        ])),
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: _checks.length, itemBuilder: (c, i) {
          final ch = _checks[i];
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]), child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: (ch['color'] as Color).withOpacity(0.08), shape: BoxShape.circle), child: Icon(ch['icon'], color: ch['color'], size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ch['name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)), Text('${ch['freq']} • القادم: ${ch['next']}', style: const TextStyle(fontSize: 9, color: AppColors.grey))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: ch['done'] ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(ch['done'] ? 'تم' : 'قادم', style: TextStyle(fontSize: 9, color: ch['done'] ? AppColors.success : AppColors.warning))),
          ]));
        })),
      ]),
    );
  }
}
