import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});
  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  int _steps = 6420;
  int _goal = 10000;

  @override
  Widget build(BuildContext context) {
    final progress = (_steps / _goal).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(title: const Text('عداد الخطوات', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Stack(alignment: Alignment.center, children: [
                SizedBox(width: 170, height: 170, child: CircularProgressIndicator(value: progress, strokeWidth: 14, backgroundColor: Colors.white24, color: Colors.white, strokeCap: StrokeCap.round)),
                Column(children: [const Text('🚶', style: TextStyle(fontSize: 36)), const SizedBox(height: 4), Text('$_steps', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)), const Text('خطوة', style: TextStyle(color: Colors.white70, fontSize: 14))]),
              ]),
              const SizedBox(height: 12),
              Text('الهدف: $_goal خطوة', style: const TextStyle(color: Colors.white70)),
              Text('متبقي: ${_goal - _steps} خطوة', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [_s('سعرات', '245', '🔥', AppColors.error), const SizedBox(width: 10), _s('مسافة', '4.8 كم', '📍', AppColors.info), const SizedBox(width: 10), _s('دقائق', '45', '⏱️', AppColors.success)]),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.success.withOpacity(0.2))), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💪 فوائد المشي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), SizedBox(height: 6),
            Text('• يحرق الدهون ويساعد في إنقاص الوزن', style: TextStyle(fontSize: 12)),
            Text('• يحسن صحة القلب والأوعية الدموية', style: TextStyle(fontSize: 12)),
            Text('• 10,000 خطوة = 400 سعرة حرارية تقريباً', style: TextStyle(fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _s(String label, String value, String emoji, Color color) => Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 24)), const SizedBox(height: 4), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey))])));
}
