import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/subscriptions/subscriptions_screen.dart';

class InsuranceCompanies extends StatefulWidget {
  const InsuranceCompanies({super.key});
  @override
  State<InsuranceCompanies> createState() => _InsuranceCompaniesState();
}

class _InsuranceCompaniesState extends State<InsuranceCompanies> {
  String _type = 'الكل';

  final List<Map<String, dynamic>> _companies = [
    {'name': 'جوبيلي للتأمين الصحي', 'type': 'صحي', 'coverage': 'حتى 1,000,000 ر.ي', 'hospitals': '500+', 'rating': 4.7, 'premium': 'من 2,500 ر.ي/شهر', 'color': AppColors.primary},
    {'name': 'أدامجي للتأمين', 'type': 'صحي', 'coverage': 'حتى 800,000 ر.ي', 'hospitals': '400+', 'rating': 4.5, 'premium': 'من 2,000 ر.ي/شهر', 'color': AppColors.info},
    {'name': 'أليانز إي إف يو', 'type': 'عائلي', 'coverage': 'حتى 2,000,000 ر.ي', 'hospitals': '700+', 'rating': 4.8, 'premium': 'من 3,500 ر.ي/شهر', 'color': AppColors.success},
    {'name': 'آي جي آي للتأمين', 'type': 'سفر', 'coverage': 'حتى 500,000 ر.ي', 'hospitals': '200+', 'rating': 4.3, 'premium': 'من 1,500 ر.ي/شهر', 'color': AppColors.teal},
    {'name': 'تي بي إل', 'type': 'صحي', 'coverage': 'حتى 1,500,000 ر.ي', 'hospitals': '600+', 'rating': 4.6, 'premium': 'من 3,000 ر.ي/شهر', 'color': AppColors.purple},
    {'name': 'ستيت لايف', 'type': 'عائلي', 'coverage': 'حتى 5,000,000 ر.ي', 'hospitals': '1000+', 'rating': 4.9, 'premium': 'من 5,000 ر.ي/شهر', 'color': AppColors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _type == 'الكل' ? _companies : _companies.where((c) => c['type'] == _type).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('التأمين الصحي', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.indigo, AppColors.indigo.withOpacity(0.7)]), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('اعثر على أفضل تأمين صحي', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('قارن الخطط ووفر المال', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.indigo), child: const Text('قارن الآن')),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 6), itemBuilder: (ctx, i) {
            final types = ['الكل', 'صحي', 'عائلي', 'سفر'];
            final sel = _type == types[i];
            return ChoiceChip(label: Text(types[i], style: const TextStyle(fontSize: 11)), selected: sel, selectedColor: AppColors.primary, labelStyle: TextStyle(color: sel ? Colors.white : null), onSelected: (v) => setState(() => _type = v! ? types[i] : 'الكل'));
          })),
          const SizedBox(height: 10),
          ...filtered.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
            child: Column(children: [
              Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: (c['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.shield, size: 24, color: AppColors.primary)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Row(children: [const Icon(Icons.star, color: AppColors.amber, size: 14), Text(' ${c['rating']}', style: const TextStyle(fontWeight: FontWeight.bold))])])), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (c['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(c['type'], style: TextStyle(fontSize: 9, color: c['color'])))],),
              const Divider(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _info(Icons.shield, 'التغطية', c['coverage']),
                _info(Icons.local_hospital, 'المستشفيات', c['hospitals']),
                _info(Icons.payments, 'القسط', c['premium']),
              ]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('عرض التفاصيل'))),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) => Column(children: [Icon(icon, color: AppColors.primary, size: 18), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text(label, style: const TextStyle(fontSize: 9, color: AppColors.grey))]);
}
