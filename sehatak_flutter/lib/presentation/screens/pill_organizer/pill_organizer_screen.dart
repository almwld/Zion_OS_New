import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class PillOrganizerScreen extends StatefulWidget {
  const PillOrganizerScreen({super.key});
  @override
  State<PillOrganizerScreen> createState() => _PillOrganizerScreenState();
}

class _PillOrganizerScreenState extends State<PillOrganizerScreen> {
  int _day = 0;
  final List<String> _days = ['سبت', 'أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
  final List<List<Map<String, dynamic>>> _pills = [
    [{'name': 'أملوديبين 5mg', 'time': 'صباح', 'taken': true}, {'name': 'فيتامين د', 'time': 'ظهر', 'taken': true}],
    [{'name': 'أملوديبين 5mg', 'time': 'صباح', 'taken': true}, {'name': 'أوميبرازول 40mg', 'time': 'صباح', 'taken': true}],
    [{'name': 'أملوديبين 5mg', 'time': 'صباح', 'taken': true}, {'name': 'فيتامين د', 'time': 'ظهر', 'taken': false}],
    [{'name': 'أملوديبين 5mg', 'time': 'صباح', 'taken': false}, {'name': 'أوميبرازول 40mg', 'time': 'صباح', 'taken': false}],
    [{'name': 'أملوديبين 5mg', 'time': 'صباح', 'taken': true}, {'name': 'فيتامين د', 'time': 'ظهر', 'taken': true}],
    [{'name': 'أملوديبين 5mg', 'time': 'صباح', 'taken': true}, {'name': 'أوميبرازول 40mg', 'time': 'صباح', 'taken': false}],
    [{'name': 'أملوديبين 5mg', 'time': 'صباح', 'taken': true}, {'name': 'فيتامين د', 'time': 'ظهر', 'taken': false}, {'name': 'سيتريزين 10mg', 'time': 'مساء', 'taken': true}],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('منظم الأدوية', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)), child: Row(children: List.generate(7, (i) => Expanded(child: GestureDetector(
          onTap: () => setState(() => _day = i),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _day == i ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(_days[i], style: TextStyle(color: _day == i ? Colors.white : AppColors.darkGrey, fontWeight: FontWeight.bold, fontSize: 12)), if (_pills[i].every((p) => p['taken'])) const Icon(Icons.check, color: Colors.white, size: 14)]))))))),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.calendar_today, color: Colors.white, size: 28), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_days[_day], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text('${_pills[_day].length} أدوية', style: const TextStyle(color: Colors.white70))])), Text('${_pills[_day].where((p) => p['taken']).length}/${_pills[_day].length}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))])),
          const SizedBox(height: 14),
          for (final p in _pills[_day]) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: p['taken'] ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1), shape: BoxShape.circle), child: Icon(p['taken'] ? Icons.check : Icons.schedule, color: p['taken'] ? AppColors.success : AppColors.warning, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)), Text(p['time'], style: const TextStyle(fontSize: 10, color: AppColors.grey))])), Checkbox(value: p['taken'], activeColor: AppColors.success, onChanged: (v) => setState(() => p['taken'] = v))])),
        ]))),
      ]),
    );
  }
}
