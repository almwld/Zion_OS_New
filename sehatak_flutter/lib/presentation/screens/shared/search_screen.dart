import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final List<String> _recent = ['طبيب قلب', 'باراسيتامول', 'مستشفى الثورة', 'تحليل دم'];
  final List<String> _trending = ['كورونا', 'ضغط الدم', 'فيتامين د', 'حساسية', 'سكري'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _ctrl, autofocus: true, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'ابحث...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.white60)))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('عمليات بحث سابقة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), TextButton(onPressed: () {}, child: const Text('مسح الكل'))]),
        Wrap(spacing: 6, children: _recent.map((s) => Chip(label: Text(s), onDeleted: () {})).toList()),
        const SizedBox(height: 20),
        Text('الأكثر بحثاً', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Wrap(spacing: 6, children: _trending.map((t) => ActionChip(label: Text(t), onPressed: () {})).toList()),
        const SizedBox(height: 20),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.5, children: [
          _cat('أطباء', Icons.person_search, AppColors.primary),
          _cat('أدوية', Icons.medication, AppColors.success),
          _cat('مستشفيات', Icons.local_hospital, AppColors.info),
          _cat('تحاليل', Icons.science, AppColors.purple),
          _cat('صيدليات', Icons.local_pharmacy, AppColors.teal),
          _cat('مقالات', Icons.article, AppColors.orange),
        ]),
      ])),
    );
  }

  Widget _cat(String t, IconData i, Color c) => Container(decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: c, size: 20), const SizedBox(width: 8), Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w500))]));
}
