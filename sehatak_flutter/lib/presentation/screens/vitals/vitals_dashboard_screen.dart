import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/blood_pressure/blood_pressure_screen.dart';
import 'package:sehatak/presentation/screens/glucose_tracker/glucose_tracker_screen.dart';
import 'package:sehatak/presentation/screens/weight_tracker/weight_tracker_screen.dart';
import 'package:sehatak/presentation/screens/health_tools/heart_rate_screen.dart';
import 'package:sehatak/presentation/screens/sleep_tracker/sleep_tracker_screen.dart';
import 'package:sehatak/presentation/screens/step_counter/step_counter_screen.dart';
import 'package:sehatak/presentation/screens/health_tools/bmi_calculator_screen.dart';

class VitalsDashboardScreen extends StatelessWidget {
  const VitalsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المؤشرات الحيوية', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _vital('ضغط الدم', '128/82', 'mmHg', Icons.monitor_heart, AppColors.error, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodPressureScreen()))),
            const SizedBox(width: 10),
            _vital('السكر', '127', 'mg/dL', Icons.bloodtype, AppColors.info, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlucoseTrackerScreen()))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _vital('الوزن', '72.5', 'kg', Icons.monitor_weight, AppColors.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightTrackerScreen()))),
            const SizedBox(width: 10),
            _vital('النبض', '72', 'bpm', Icons.favorite, AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HeartRateScreen()))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _vital('النوم', '7.5', 'ساعة', Icons.bedtime, AppColors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepTrackerScreen()))),
            const SizedBox(width: 10),
            _vital('الخطوات', '6,420', 'خطوة', Icons.directions_walk, AppColors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StepCounterScreen()))),
          ]),
          const SizedBox(height: 10),
          _vital('BMI', '23.7', 'kg/m²', Icons.calculate, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BMICalculatorScreen()))),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.warning.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.warning_amber, color: AppColors.warning), SizedBox(width: 6), Text('تنبيهات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
            const SizedBox(height: 8), const Text('• الضغط الانبساطي مرتفع قليلاً (82)', style: TextStyle(fontSize: 11)),
            const Text('• السكر بعد الأكل مرتفع (180)', style: TextStyle(fontSize: 11)),
            const Text('• 3,580 خطوة متبقية للهدف', style: TextStyle(fontSize: 11)),
          ])),
        ]),
      ),
    );
  }

  Widget _vital(String label, String value, String unit, IconData icon, Color color, VoidCallback onTap) => Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color, size: 20), const Spacer(), const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.grey)]), const SizedBox(height: 8), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)), Text('$unit  $label', style: const TextStyle(fontSize: 10, color: AppColors.grey))]))));
}
