import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class ShareHealthScreen extends StatefulWidget {
  const ShareHealthScreen({super.key});
  @override
  State<ShareHealthScreen> createState() => _ShareHealthScreenState();
}

class _ShareHealthScreenState extends State<ShareHealthScreen> {
  bool _history = true, _tests = true, _prescriptions = false, _reports = true;
  final _email = TextEditingController(), _msg = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مشاركة الملف الصحي', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.info.withOpacity(0.2))), child: const Row(children: [Icon(Icons.security, color: AppColors.info, size: 28), SizedBox(width: 10), Expanded(child: Text('مشاركة آمنة ومشفرة لبياناتك الصحية', style: TextStyle(fontSize: 12)))])),
        const SizedBox(height: 16),
        Text('اختر ما تريد مشاركته', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _sw('السجل الطبي', 'أمراض، حساسية، تطعيمات', Icons.folder_shared, _history, (v) => setState(() => _history = v)),
        _sw('التحاليل', 'نتائج تحاليل وأشعة', Icons.science, _tests, (v) => setState(() => _tests = v)),
        _sw('الوصفات', 'وصفات حالية وسابقة', Icons.receipt_long, _prescriptions, (v) => setState(() => _prescriptions = v)),
        _sw('التقارير', 'تقارير PDF', Icons.description, _reports, (v) => setState(() => _reports = v)),
        const SizedBox(height: 16),
        TextField(controller: _email, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'بريد الطبيب', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 10),
        TextField(controller: _msg, maxLines: 2, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'رسالة (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت المشاركة بنجاح'), backgroundColor: AppColors.success)); }, icon: const Icon(Icons.send), label: const Text('مشاركة'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)))),
      ])),
    );
  }

  Widget _sw(String t, String s, IconData i, bool v, Function(bool) cb) => Card(child: SwitchListTile(secondary: Icon(i, color: AppColors.primary), title: Text(t, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)), subtitle: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.grey)), value: v, activeColor: AppColors.primary, onChanged: cb));
}
