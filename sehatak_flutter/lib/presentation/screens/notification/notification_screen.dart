import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<Map<String, dynamic>> _notifications = const [
    {'title': 'تذكير بموعد', 'body': 'لديك موعد مع د. علي المولد غداً الساعة 10:30 ص', 'time': 'منذ 30 دقيقة', 'icon': Icons.calendar_today, 'read': false},
    {'title': 'وصفة طبية جاهزة', 'body': 'الوصفة الطبية الخاصة بك جاهزة للتحميل', 'time': 'منذ ساعتين', 'icon': Icons.receipt_long, 'read': false},
    {'title': 'نتيجة تحليل', 'body': 'نتيجة تحليل السكر التراكمي متوفرة الآن', 'time': 'منذ 5 ساعات', 'icon': Icons.science, 'read': true},
    {'title': 'عرض خاص', 'body': 'خصم 30% على الباقة الذهبية', 'time': 'منذ يوم', 'icon': Icons.card_giftcard, 'read': true},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)), actions: [TextButton(onPressed: () {}, child: const Text('تعليم الكل', style: TextStyle(fontSize: 12)))],),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _notifications.length,
        itemBuilder: (_, i) {
          final n = _notifications[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n['read'] ? Colors.white : AppColors.primary.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
            ),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: (n['read'] ? Colors.grey : AppColors.primary).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(n['icon'], color: n['read'] ? Colors.grey : AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(n['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: n['read'] ? AppColors.darkGrey : AppColors.primary))), if (!n['read']) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))]),
                const SizedBox(height: 3),
                Text(n['body'], style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                const SizedBox(height: 4),
                Text(n['time'], style: const TextStyle(fontSize: 9, color: AppColors.grey)),
              ])),
            ]),
          );
        },
      ),
    );
  }
}
