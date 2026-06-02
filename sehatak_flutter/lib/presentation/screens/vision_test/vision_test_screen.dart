import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class VisionTestScreen extends StatefulWidget {
  const VisionTestScreen({super.key});
  @override
  State<VisionTestScreen> createState() => _VisionTestScreenState();
}

class _VisionTestScreenState extends State<VisionTestScreen> {
  int _q = 0, _score = 0;
  bool _done = false;

  final List<Map<String, dynamic>> _qs = const [
    {'q': 'ما الرقم الذي تراه؟', 'img': '6', 'ans': ['9', '6', '8', '0'], 'correct': 1},
    {'q': 'ما الحرف الذي تراه؟', 'img': 'E', 'ans': ['E', 'F', 'B', 'P'], 'correct': 0},
    {'q': 'ما الرقم الذي تراه؟', 'img': '8', 'ans': ['3', '6', '8', '0'], 'correct': 2},
    {'q': 'ما الحرف الذي تراه؟', 'img': 'C', 'ans': ['G', 'O', 'C', 'Q'], 'correct': 2},
    {'q': 'ما الرقم الذي تراه؟', 'img': '5', 'ans': ['2', '5', '3', '7'], 'correct': 1},
  ];

  void _answer(int a) {
    if (_qs[_q]['correct'] == a) _score++;
    if (_q < _qs.length - 1) setState(() => _q++); else setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return Scaffold(appBar: AppBar(title: const Text('فحص النظر')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(_score >= 4 ? Icons.visibility : Icons.visibility_off, size: 80, color: _score >= 4 ? AppColors.success : AppColors.warning),
      const SizedBox(height: 20), Text('النتيجة: $_score/${_qs.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      Text(_score >= 4 ? '👁️ نظرك جيد!' : '⚠️ ننصح بمراجعة طبيب', style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 30), ElevatedButton(onPressed: () => setState(() { _q = 0; _score = 0; _done = false; }), child: const Text('إعادة')),
    ])));

    final q = _qs[_q];
    return Scaffold(
      appBar: AppBar(title: const Text('فحص النظر', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        LinearProgressIndicator(value: _q / _qs.length, backgroundColor: AppColors.surfaceContainerLow, color: AppColors.primary, minHeight: 6, borderRadius: BorderRadius.circular(3)),
        const SizedBox(height: 20), Text('سؤال ${_q + 1} من ${_qs.length}', style: const TextStyle(color: AppColors.grey)),
        const SizedBox(height: 30),
        Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.05), border: Border.all(color: AppColors.primary, width: 3)), child: Center(child: Text(q['img'], style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: AppColors.primary)))),
        const SizedBox(height: 30), Text(q['q'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...(q['ans'] as List).asMap().entries.map((e) => Container(margin: const EdgeInsets.only(bottom: 8), width: double.infinity, child: ElevatedButton(onPressed: () => _answer(e.key), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.dark, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.outlineVariant))), child: Text(e.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))),
      ])),
    );
  }
}
