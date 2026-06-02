import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class CalorieCalculatorScreen extends StatefulWidget {
  const CalorieCalculatorScreen({super.key});
  @override
  State<CalorieCalculatorScreen> createState() => _CalorieCalculatorScreenState();
}

class _CalorieCalculatorScreenState extends State<CalorieCalculatorScreen> {
  final List<Map<String, dynamic>> _foods = const [
    {'name': 'رز أبيض (كوب)', 'cal': 206, 'icon': '🍚'},
    {'name': 'دجاج مشوي (صدر)', 'cal': 165, 'icon': '🍗'},
    {'name': 'خبز (رغيف)', 'cal': 275, 'icon': '🍞'},
    {'name': 'بيض مسلوق', 'cal': 78, 'icon': '🥚'},
    {'name': 'موز', 'cal': 105, 'icon': '🍌'},
    {'name': 'تفاح', 'cal': 95, 'icon': '🍎'},
    {'name': 'لبن (كوب)', 'cal': 61, 'icon': '🥛'},
    {'name': 'مكسرات (حفنة)', 'cal': 173, 'icon': '🥜'},
    {'name': 'سمك مشوي', 'cal': 200, 'icon': '🐟'},
    {'name': 'سلطة خضراء', 'cal': 35, 'icon': '🥗'},
    {'name': 'تمر (حبة)', 'cal': 23, 'icon': '🌴'},
    {'name': 'عصير برتقال', 'cal': 112, 'icon': '🍊'},
  ];

  final List<Map<String, dynamic>> _selected = [];
  String _query = '';

  int get _total => _selected.fold(0, (s, f) => s + (f['cal'] as int));

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty ? _foods : _foods.where((f) => (f['name'] as String).contains(_query)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة السعرات', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.success, AppColors.teal]), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            const Text('إجمالي السعرات', style: TextStyle(color: Colors.white70)), Text('$_total', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
            LinearProgressIndicator(value: (_total / 2000).clamp(0.0, 1.0), backgroundColor: Colors.white24, color: Colors.white, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(hintText: 'ابحث عن طعام...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: AppColors.surfaceContainerLow, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        ),
        if (_selected.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Wrap(spacing: 6, children: _selected.map((f) => Chip(label: Text('${f['name']} (${f['cal']})'), onDeleted: () => setState(() => _selected.remove(f)))).toList())),
        Expanded(
          child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: filtered.length, itemBuilder: (ctx, i) {
            final f = filtered[i];
            return ListTile(
              leading: Text(f['icon'], style: const TextStyle(fontSize: 28)),
              title: Text(f['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('${f['cal']} سعرة', style: const TextStyle(color: AppColors.primary)),
              trailing: ElevatedButton(onPressed: () => setState(() => _selected.add(f)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)), child: const Text('+', style: TextStyle(fontSize: 18))),
            );
          }),
        ),
      ]),
    );
  }
}
