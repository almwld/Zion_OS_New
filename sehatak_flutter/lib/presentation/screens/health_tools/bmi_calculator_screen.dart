import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class BMICalculatorScreen extends StatefulWidget {
  const BMICalculatorScreen({super.key});
  @override
  State<BMICalculatorScreen> createState() => _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends State<BMICalculatorScreen> {
  double _height = 170, _weight = 70;
  int _age = 25;
  bool _isMale = true;

  double get _bmi => _weight / ((_height / 100) * (_height / 100));

  String get _category {
    if (_bmi < 18.5) return 'نقص وزن';
    if (_bmi < 25) return 'وزن طبيعي';
    if (_bmi < 30) return 'زيادة وزن';
    return 'سمنة';
  }

  Color get _color {
    if (_bmi < 18.5) return AppColors.warning;
    if (_bmi < 25) return AppColors.success;
    if (_bmi < 30) return AppColors.amber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة BMI', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            _gender('ذكر', Icons.male, _isMale, () => setState(() => _isMale = true)),
            const SizedBox(width: 10),
            _gender('أنثى', Icons.female, !_isMale, () => setState(() => _isMale = false)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: _color.withOpacity(0.2))),
            child: Column(children: [
              const Text('مؤشر كتلة الجسم', style: TextStyle(color: AppColors.grey)),
              Text(_bmi.toStringAsFixed(1), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _color)),
              Text(_category, style: TextStyle(fontSize: 18, color: _color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('الوزن المثالي: ${(_height - 100) * 0.9} - ${(_height - 100) * 1.1} كجم', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
            ]),
          ),
          _slider('الطول (سم)', _height, 100, 220, (v) => setState(() => _height = v)),
          _slider('الوزن (كجم)', _weight, 30, 200, (v) => setState(() => _weight = v)),
          _slider('العمر', _age.toDouble(), 1, 120, (v) => setState(() => _age = v.toInt())),
        ]),
      ),
    );
  }

  Widget _gender(String label, IconData icon, bool sel, VoidCallback tap) => Expanded(child: GestureDetector(onTap: tap, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: sel ? AppColors.primary.withOpacity(0.08) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: sel ? AppColors.primary : AppColors.outlineVariant)), child: Column(children: [Icon(icon, size: 40, color: sel ? AppColors.primary : AppColors.grey), const SizedBox(height: 8), Text(label, style: TextStyle(color: sel ? AppColors.primary : AppColors.grey, fontWeight: FontWeight.bold))]))));

  Widget _slider(String label, double value, double min, double max, Function(double) cb) => Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text('${value.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary))]), Slider(value: value, min: min, max: max, activeColor: AppColors.primary, onChanged: cb)]));
}
