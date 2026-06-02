import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class HealthChallengesScreen extends StatefulWidget {
  const HealthChallengesScreen({super.key});
  @override
  State<HealthChallengesScreen> createState() => _HealthChallengesScreenState();
}

class _HealthChallengesScreenState extends State<HealthChallengesScreen> {
  int _points = 1250;
  String _filter = 'الكل';

  final List<Map<String, dynamic>> _challenges = [
    {'title': 'تحدي 10,000 خطوة', 'desc': 'امشِ 10,000 خطوة يومياً لمدة 30 يوماً', 'duration': '30 يوم', 'participants': '1,245', 'reward': '500 نقطة', 'color': AppColors.success, 'progress': 0.45, 'status': 'جاري', 'category': 'رياضة'},
    {'title': 'تحدي شرب الماء', 'desc': 'اشرب 8 أكواب ماء يومياً', 'duration': '21 يوم', 'participants': '2,340', 'reward': '300 نقطة', 'color': AppColors.info, 'progress': 0.70, 'status': 'جاري', 'category': 'تغذية'},
    {'title': 'تحدي الإقلاع عن التدخين', 'desc': '30 يوم بدون تدخين', 'duration': '30 يوم', 'participants': '890', 'reward': '1000 نقطة', 'color': AppColors.error, 'progress': 0.20, 'status': 'جاري', 'category': 'صحة'},
    {'title': 'تحدي النوم المبكر', 'desc': 'نم قبل الساعة 10 مساءً', 'duration': '7 أيام', 'participants': '1,560', 'reward': '150 نقطة', 'color': AppColors.teal, 'progress': 1.0, 'status': 'مكتمل', 'category': 'نوم'},
    {'title': 'تحدي الأكل الصحي', 'desc': '5 وجبات صحية يومياً', 'duration': '10 أيام', 'participants': '4,200', 'reward': '400 نقطة', 'color': AppColors.amber, 'progress': 0.30, 'status': 'جاري', 'category': 'تغذية'},
    {'title': 'تحدي التأمل', 'desc': '10 دقائق تأمل يومياً', 'duration': '21 يوم', 'participants': '2,100', 'reward': '350 نقطة', 'color': AppColors.purple, 'progress': 0.55, 'status': 'جاري', 'category': 'نفسية'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'الكل' ? _challenges : _challenges.where((c) => c['category'] == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('التحديات الصحية', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.emoji_events), onPressed: () {})]),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.amber, AppColors.orange]), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [const Icon(Icons.emoji_events, color: Colors.white, size: 44), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('نقاطك', style: TextStyle(color: Colors.white70, fontSize: 13)), Text('$_points نقطة', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), const Text('4 تحديات مكتملة', style: TextStyle(color: Colors.white70, fontSize: 11))])), Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)), child: const Text('ذهبي', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)))]),
        ),
        SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: 6, separatorBuilder: (_, __) => const SizedBox(width: 4), itemBuilder: (ctx, i) {
          final cats = ['الكل', 'رياضة', 'تغذية', 'صحة', 'نوم', 'نفسية'];
          final sel = _filter == cats[i];
          return ChoiceChip(label: Text(cats[i], style: const TextStyle(fontSize: 10)), selected: sel, selectedColor: AppColors.primary, labelStyle: TextStyle(color: sel ? Colors.white : null), onSelected: (v) => setState(() => _filter = v! ? cats[i] : 'الكل'));
        })),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (ctx, i) {
            final c = filtered[i];
            final prog = c['progress'] as double;
            return Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: c['status'] == 'مكتمل' ? Border.all(color: AppColors.success, width: 1.5) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: (c['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Center(child: Icon(c['category'] == 'رياضة' ? Icons.directions_walk : c['category'] == 'تغذية' ? Icons.restaurant : Icons.favorite, color: c['color'], size: 22))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(c['desc'], style: const TextStyle(fontSize: 10, color: AppColors.grey))])),
                  if (c['status'] == 'مكتمل') const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                ]),
                const SizedBox(height: 8),
                Row(children: [Text('${(prog * 100).toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c['status'] == 'مكتمل' ? AppColors.success : c['color'])), const SizedBox(width: 8), Expanded(child: LinearProgressIndicator(value: prog, backgroundColor: AppColors.surfaceContainerLow, color: c['status'] == 'مكتمل' ? AppColors.success : c['color'], minHeight: 6, borderRadius: BorderRadius.circular(3)))]),
                const SizedBox(height: 8),
                Row(children: [
                  Row(children: [const Icon(Icons.people, size: 12, color: AppColors.grey), const SizedBox(width: 2), Text(c['participants'], style: const TextStyle(fontSize: 9, color: AppColors.grey))]),
                  const Spacer(),
                  Row(children: [const Icon(Icons.timer, size: 12, color: AppColors.grey), const SizedBox(width: 2), Text(c['duration'], style: const TextStyle(fontSize: 9, color: AppColors.grey))]),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(c['reward'], style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 10))),
                ]),
              ]),
            );
          }),
        ),
      ]),
    );
  }
}
