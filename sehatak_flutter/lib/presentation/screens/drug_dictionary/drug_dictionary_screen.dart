import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class DrugDictionaryScreen extends StatefulWidget {
  const DrugDictionaryScreen({super.key});
  @override
  State<DrugDictionaryScreen> createState() => _DrugDictionaryScreenState();
}

class _DrugDictionaryScreenState extends State<DrugDictionaryScreen> {
  String _query = '';
  
  final List<Map<String, String>> _drugs = const [
    {'name': 'باراسيتامول', 'cat': 'مسكن ألم', 'dose': '500-1000mg كل 6-8 س', 'preg': 'آمن'},
    {'name': 'ايبوبروفين', 'cat': 'مضاد التهاب', 'dose': '200-400mg كل 6-8 س', 'preg': 'غير آمن'},
    {'name': 'اموكسيسيلين', 'cat': 'مضاد حيوي', 'dose': '500mg كل 8 س', 'preg': 'آمن نسبياً'},
    {'name': 'اوميبرازول', 'cat': 'مضاد حموضة', 'dose': '20-40mg يومياً', 'preg': 'باستشارة'},
    {'name': 'ميتفورمين', 'cat': 'خافض سكر', 'dose': '500-850mg مع الأكل', 'preg': 'باستشارة'},
    {'name': 'سيتريزين', 'cat': 'مضاد حساسية', 'dose': '10mg يومياً', 'preg': 'باستشارة'},
    {'name': 'ديكلوفيناك', 'cat': 'مضاد التهاب', 'dose': '50mg كل 8 س', 'preg': 'غير آمن'},
    {'name': 'ازيثرومايسين', 'cat': 'مضاد حيوي', 'dose': '500mg يومياً 3 أيام', 'preg': 'باستشارة'},
    {'name': 'ليفوثيروكسين', 'cat': 'هرمون درقي', 'dose': '25-100mcg صباحاً', 'preg': 'آمن'},
    {'name': 'فيتامين د', 'cat': 'مكمل', 'dose': '1000-4000 IU يومياً', 'preg': 'آمن'},
    {'name': 'وارفارين', 'cat': 'مميع دم', 'dose': '2-5mg يومياً', 'preg': 'غير آمن'},
    {'name': 'كلوبيدوجريل', 'cat': 'مضاد صفائح', 'dose': '75mg يومياً', 'preg': 'باستشارة'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty ? _drugs : _drugs.where((d) => d['name']!.contains(_query) || d['cat']!.contains(_query)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('قاموس الأدوية', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(hintText: 'ابحث عن دواء...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: AppColors.surfaceContainerLow, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        ),
        Expanded(
          child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: filtered.length, itemBuilder: (ctx, i) {
            final d = filtered[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('💊', style: TextStyle(fontSize: 20)))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(d['cat']!, style: TextStyle(fontSize: 10, color: AppColors.primary)),
                  Text('الجرعة: ${d['dose']}', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                  Text('الحمل: ${d['preg']}', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                ])),
              ]),
            );
          }),
        ),
      ]),
    );
  }
}
