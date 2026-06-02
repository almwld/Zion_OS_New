import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});
  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final Set<String> _selected = {};
  String _result = '';

  void _check() {
    final k = _selected.toList()..sort();
    String r = 'رجاء استشر الطبيب للتشخيص الدقيق.';
    if (k.contains('صداع') && k.contains('حمى')) r = 'قد تكون مصاباً بالإنفلونزا. ننصح بالراحة.';
    if (k.contains('ألم صدر') && k.contains('ضيق تنفس')) r = '⚠️ حالة طارئة! توجه لأقرب مستشفى.';
    if (k.contains('ألم بطن') && k.contains('إسهال')) r = 'قد يكون تسمم غذائي.';
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فحص الأعراض', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: const Text('⚠️ هذه الأداة للمساعدة فقط وليست بديلاً عن الاستشارة الطبية', style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(height: 14),
          Text('اختر الأعراض', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _section('رأس', ['صداع', 'دوخة', 'طنين', 'ألم عين', 'احتقان أنف']),
          _section('صدر', ['ألم صدر', 'ضيق تنفس', 'خفقان', 'سعال', 'بلغم']),
          _section('بطن', ['ألم بطن', 'غثيان', 'إسهال', 'إمساك', 'حرقة']),
          _section('عام', ['حمى', 'تعب', 'فقدان وزن', 'تعرق ليلي']),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _check,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('تحليل الأعراض'),
            )),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.info.withOpacity(0.2))), child: Row(children: [const Icon(Icons.info, color: AppColors.info, size: 20), const SizedBox(width: 8), Expanded(child: Text(_result, style: const TextStyle(fontSize: 13, height: 1.4)))])),
            ],
          ],
        ]),
      ),
    );
  }

  Widget _section(String title, List<String> symptoms) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 4),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: symptoms.map((s) {
          return FilterChip(
            label: Text(s, style: const TextStyle(fontSize: 11)),
            selected: _selected.contains(s),
            selectedColor: AppColors.primary.withOpacity(0.2),
            checkmarkColor: AppColors.primary,
            onSelected: (v) {
              setState(() {
                if (v!) {
                  _selected.add(s);
                } else {
                  _selected.remove(s);
                }
                _result = '';
              });
            },
          );
        }).toList(),
      ),
    ]);
  }
}
