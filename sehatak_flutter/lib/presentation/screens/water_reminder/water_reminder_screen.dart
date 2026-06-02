import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class WaterReminderScreen extends StatefulWidget {
  const WaterReminderScreen({super.key});
  @override
  State<WaterReminderScreen> createState() => _WaterReminderScreenState();
}

class _WaterReminderScreenState extends State<WaterReminderScreen> {
  int _glasses = 4, _goal = 8, _size = 250;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تذكير شرب الماء', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade600]), borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Stack(alignment: Alignment.center, children: [
                SizedBox(width: 160, height: 160, child: CircularProgressIndicator(value: _glasses / _goal, strokeWidth: 14, backgroundColor: Colors.white24, color: Colors.white, strokeCap: StrokeCap.round)),
                Column(children: [const Text('💧', style: TextStyle(fontSize: 36)), Text('$_glasses/$_goal', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const Text('كوب', style: TextStyle(color: Colors.white70, fontSize: 12))]),
              ]),
              const SizedBox(height: 8),
              Text('${_glasses * _size} مل / ${_goal * _size} مل', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _add('كوب صغير', '🥛', 1), _add('كوب متوسط', '🥤', 2), _add('زجاجة', '🍶', 4),
          ]),
          const SizedBox(height: 20),
          Text('سجل اليوم', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ...List.generate(_glasses, (i) => Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.water_drop, color: Colors.blue), const SizedBox(width: 8), Text('كوب ${i + 1} - $_size مل', style: const TextStyle(fontWeight: FontWeight.w500)), const Spacer(), const Text('✓', style: TextStyle(color: AppColors.success))]))),
          if (_glasses == 0) const Center(child: Text('لم تشرب الماء اليوم بعد!', style: TextStyle(color: AppColors.grey))),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(14)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 فوائد شرب الماء', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 6),
            Text('• يحسن وظائف الكلى', style: TextStyle(fontSize: 12)),
            Text('• ينشط الدورة الدموية', style: TextStyle(fontSize: 12)),
            Text('• يحسن نضارة البشرة', style: TextStyle(fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _add(String label, String emoji, int g) => GestureDetector(
    onTap: () => setState(() => _glasses = (_glasses + g).clamp(0, _goal)),
    child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 36)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 11))]),
  );
}
