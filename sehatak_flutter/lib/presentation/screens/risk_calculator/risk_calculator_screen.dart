import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class RiskCalculatorScreen extends StatefulWidget {
  const RiskCalculatorScreen({super.key});
  @override
  State<RiskCalculatorScreen> createState() => _RiskCalculatorScreenState();
}

class _RiskCalculatorScreenState extends State<RiskCalculatorScreen> {
  int _age = 40;
  bool _smoker = false, _diabetic = false, _hypertensive = false, _obese = false, _family = false;

  String get _level {
    int s = 0;
    if (_age > 45) s += 2; if (_smoker) s += 3; if (_diabetic) s += 3;
    if (_hypertensive) s += 2; if (_obese) s += 2; if (_family) s += 1;
    return s <= 3 ? 'منخفض' : s <= 7 ? 'متوسط' : 'مرتفع';
  }

  Color get _color => _level == 'منخفض' ? AppColors.success : _level == 'متوسط' ? AppColors.warning : AppColors.error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة خطر الأمراض', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [_color.withOpacity(0.7), _color]), borderRadius: BorderRadius.circular(16)), child: Column(children: [const Text('مستوى الخطر', style: TextStyle(color: Colors.white70)), Text(_level, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)), const Text('للأمراض القلبية', style: TextStyle(color: Colors.white70, fontSize: 11))])),
          const SizedBox(height: 16),
          _s('العمر', _age.toDouble(), 20, 80, (v) => setState(() => _age = v.toInt())),
          _sw('التدخين', _smoker, (v) => setState(() => _smoker = v)),
          _sw('السكري', _diabetic, (v) => setState(() => _diabetic = v)),
          _sw('ضغط الدم', _hypertensive, (v) => setState(() => _hypertensive = v)),
          _sw('السمنة', _obese, (v) => setState(() => _obese = v)),
          _sw('تاريخ عائلي', _family, (v) => setState(() => _family = v)),
          Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: _color.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: _color.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 توصيات', style: TextStyle(fontWeight: FontWeight.bold, color: _color)), const SizedBox(height: 8),
            if (_smoker) const Text('• أقلع عن التدخين', style: TextStyle(fontSize: 12)),
            const Text('• مارس الرياضة 30 دقيقة يومياً', style: TextStyle(fontSize: 12)),
            const Text('• تناول غذاءً صحياً متوازناً', style: TextStyle(fontSize: 12)),
            const Text('• قم بفحص دوري سنوي', style: TextStyle(fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _s(String l, double v, double min, double max, Function(double) cb) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text('${v.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))]), Slider(value: v, min: min, max: max, activeColor: AppColors.primary, onChanged: cb)]));
  Widget _sw(String l, bool v, Function(bool) cb) => Container(margin: const EdgeInsets.only(bottom: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: SwitchListTile(title: Text(l, style: const TextStyle(fontWeight: FontWeight.w500)), value: v, activeColor: AppColors.primary, onChanged: cb));
}
