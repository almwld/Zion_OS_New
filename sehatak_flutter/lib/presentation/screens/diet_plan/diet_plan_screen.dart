import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});
  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  String _goal = 'تخسيس';
  final Map<String, List<Map<String, String>>> _meals = {
    'تخسيس': [
      {'meal': 'فطور', 'food': 'بيضتان + خبز أسمر + خيار', 'cal': '250', 'icon': '🍳'},
      {'meal': 'غداء', 'food': 'صدر دجاج + سلطة', 'cal': '350', 'icon': '🍗'},
      {'meal': 'عشاء', 'food': 'سمك مشوي + خضار', 'cal': '300', 'icon': '🐟'},
      {'meal': 'خفيفة', 'food': 'تفاحة + مكسرات', 'cal': '150', 'icon': '🍎'},
    ],
    'بناء عضل': [
      {'meal': 'فطور', 'food': '4 بيضات + شوفان + موز', 'cal': '450', 'icon': '🍳'},
      {'meal': 'غداء', 'food': 'دجاج 200g + رز بني', 'cal': '600', 'icon': '🍗'},
      {'meal': 'عشاء', 'food': 'تونة + بطاطا حلوة', 'cal': '500', 'icon': '🐟'},
      {'meal': 'خفيفة', 'food': 'سموذي بروتين', 'cal': '350', 'icon': '🥤'},
    ],
    'صحي متوازن': [
      {'meal': 'فطور', 'food': 'توست أسمر + جبنة + خضار', 'cal': '300', 'icon': '🍞'},
      {'meal': 'غداء', 'food': 'سمك/دجاج + رز + سلطة', 'cal': '450', 'icon': '🍛'},
      {'meal': 'عشاء', 'food': 'شوربة عدس + بيضة', 'cal': '300', 'icon': '🍜'},
      {'meal': 'خفيفة', 'food': 'فواكه + لبن', 'cal': '200', 'icon': '🍓'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final meals = _meals[_goal]!;
    final total = meals.fold(0, (s, m) => s + int.parse(m['cal']!));
    return Scaffold(
      appBar: AppBar(title: const Text('خطة غذائية', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: ['تخسيس', 'بناء عضل', 'صحي متوازن'].map((g) => Expanded(child: GestureDetector(onTap: () => setState(() => _goal = g), child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _goal == g ? AppColors.primary : AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)), child: Text(g, textAlign: TextAlign.center, style: TextStyle(color: _goal == g ? Colors.white : AppColors.darkGrey, fontWeight: FontWeight.bold, fontSize: 12)))))).toList()),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.success, AppColors.teal]), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.local_fire_department, color: Colors.white, size: 32), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('إجمالي السعرات', style: TextStyle(color: Colors.white70)), Text('$total سعرة', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]))])),
          const SizedBox(height: 14),
          for (final m in meals)
            Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Row(children: [
                Text(m['icon']!, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text(m['meal']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)), child: Text('${m['cal']} سعرة', style: const TextStyle(fontSize: 10, color: AppColors.primary)))]),
                  Text(m['food']!, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey)),
                ])),
              ]),
            ),
        ]),
      ),
    );
  }
}
