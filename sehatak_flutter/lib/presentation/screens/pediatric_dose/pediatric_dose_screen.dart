import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class PediatricDoseScreen extends StatefulWidget {
  const PediatricDoseScreen({super.key});
  @override
  State<PediatricDoseScreen> createState() => _PediatricDoseScreenState();
}

class _PediatricDoseScreenState extends State<PediatricDoseScreen> {
  double _weight = 15;
  String _selectedMed = 'باراسيتامول';

  Map<String, dynamic> _getMed(String name) {
    final meds = <String, Map<String, dynamic>>{
      'باراسيتامول': {'dose': 15, 'unit': 'mg/kg', 'freq': 'كل 6 ساعات', 'max': 60, 'color': AppColors.primary, 'desc': 'خافض حرارة ومسكن ألم'},
      'ايبوبروفين': {'dose': 10, 'unit': 'mg/kg', 'freq': 'كل 8 ساعات', 'max': 40, 'color': AppColors.error, 'desc': 'مضاد التهاب وخافض حرارة'},
      'اموكسيسيلين': {'dose': 50, 'unit': 'mg/kg', 'freq': 'كل 8 ساعات', 'max': 150, 'color': AppColors.success, 'desc': 'مضاد حيوي واسع المجال'},
      'سيتريزين': {'dose': 0.25, 'unit': 'mg/kg', 'freq': 'مرة يومياً', 'max': 0.5, 'color': AppColors.info, 'desc': 'مضاد حساسية'},
      'أزيثرومايسين': {'dose': 10, 'unit': 'mg/kg', 'freq': 'مرة يومياً', 'max': 30, 'color': AppColors.warning, 'desc': 'مضاد حيوي'},
      'كيتوتيفين': {'dose': 0.05, 'unit': 'mg/kg', 'freq': 'مرتين يومياً', 'max': 0.1, 'color': AppColors.purple, 'desc': 'واقي من أزمات الربو'},
      'مونتيلوكاست': {'dose': 4, 'unit': 'mg', 'freq': 'مساءً', 'max': 5, 'color': AppColors.teal, 'desc': 'للربو والحساسية'},
      'ديكساميثازون': {'dose': 0.15, 'unit': 'mg/kg', 'freq': 'كل 6 ساعات', 'max': 0.6, 'color': AppColors.orange, 'desc': 'كورتيزون للحالات الشديدة'},
    };
    return meds[name] ?? meds['باراسيتامول']!;
  }

  List<String> get _drugNames => ['باراسيتامول', 'ايبوبروفين', 'اموكسيسيلين', 'سيتريزين', 'أزيثرومايسين', 'كيتوتيفين', 'مونتيلوكاست', 'ديكساميثازون'];

  @override
  Widget build(BuildContext context) {
    final med = _getMed(_selectedMed);
    final singleDose = (med['dose'] as double) * _weight;
    final maxDaily = (med['max'] as double) * _weight;

    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة جرعات الأطفال', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.shade300, Colors.pink.shade400]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.child_care, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              const Text('حاسبة جرعات الأطفال', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('احسب الجرعة حسب الوزن', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Text('اختر الدواء', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: _drugNames.map((k) {
            final m = _getMed(k);
            return ChoiceChip(
              label: Text(k, style: const TextStyle(fontSize: 11)),
              selected: _selectedMed == k,
              selectedColor: m['color'],
              labelStyle: TextStyle(color: _selectedMed == k ? Colors.white : AppColors.darkGrey),
              onSelected: (_) => setState(() => _selectedMed = k),
            );
          }).toList()),
          const SizedBox(height: 10),
          Text(med['desc'], style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          const SizedBox(height: 16),
          Text('وزن الطفل', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Container(
            margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الوزن'), Text('${_weight.toInt()} كجم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary))]),
              Slider(value: _weight, min: 2, max: 60, activeColor: AppColors.primary, onChanged: (v) => setState(() => _weight = v)),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: (med['color'] as Color).withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: (med['color'] as Color).withOpacity(0.2))),
            child: Column(children: [
              Text(_selectedMed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _doseCard('الجرعة الواحدة', '${singleDose.toStringAsFixed(1)} mg', Icons.medication, med['color']),
                _doseCard('الحد الأقصى', '${maxDaily.toStringAsFixed(1)} mg', Icons.warning, AppColors.warning),
              ]),
              const SizedBox(height: 10),
              Text('التكرار: ${med['freq']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _doseCard(String label, String value, IconData icon, Color color) {
    return Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 4), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey))]);
  }
}
