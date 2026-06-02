import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class HomeLabScreen extends StatefulWidget {
  const HomeLabScreen({super.key});
  @override
  State<HomeLabScreen> createState() => _HomeLabScreenState();
}

class _HomeLabScreenState extends State<HomeLabScreen> {
  final Set<String> _sel = {};
  final List<Map<String, dynamic>> _tests = const [
    {'name': 'تحليل CBC', 'price': '150', 'dur': '4 ساعات', 'prep': 'لا يحتاج صيام', 'icon': '🩸', 'color': AppColors.error},
    {'name': 'سكر صائم', 'price': '80', 'dur': '2 ساعة', 'prep': 'صيام 8 س', 'icon': '💉', 'color': AppColors.info},
    {'name': 'دهون ثلاثية', 'price': '200', 'dur': '6 ساعات', 'prep': 'صيام 12 س', 'icon': '🧪', 'color': AppColors.warning},
    {'name': 'فيتامين د', 'price': '250', 'dur': '24 ساعة', 'prep': 'لا يحتاج', 'icon': '☀️', 'color': AppColors.amber},
    {'name': 'تحليل بول', 'price': '60', 'dur': '1 ساعة', 'prep': 'عينة صباحية', 'icon': '🧫', 'color': AppColors.teal},
    {'name': 'فيروسات كبد', 'price': '400', 'dur': '48 ساعة', 'prep': 'لا يحتاج', 'icon': '🦠', 'color': AppColors.primary},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فحص منزلي', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.home_work, color: Colors.white, size: 32), SizedBox(width: 10), Expanded(child: Text('فحوصات في منزلك', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))])),
        Expanded(
          child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: _tests.length, itemBuilder: (c, i) {
            final t = _tests[i];
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]), child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: (t['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(t['icon'], style: const TextStyle(fontSize: 22)))),
              const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(t['dur'], style: const TextStyle(fontSize: 10, color: AppColors.grey)), Text(t['prep'], style: const TextStyle(fontSize: 9, color: AppColors.warning))])),
              Column(children: [Text('${t['price']} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)), Checkbox(value: _sel.contains(t['name']), activeColor: AppColors.primary, onChanged: (v) => setState(() { if (v!) _sel.add(t['name']); else _sel.remove(t['name']); }))]),
            ]));
          }),
        ),
        if (_sel.isNotEmpty) Container(padding: const EdgeInsets.all(14), color: Colors.white, child: Row(children: [Text('${_sel.length} فحوصات', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.send), label: const Text('طلب الفحص'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary))])),
      ]),
    );
  }
}
