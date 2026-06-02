import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class BloodDonationScreen extends StatelessWidget {
  const BloodDonationScreen({super.key});

  final List<Map<String, dynamic>> _donors = const [
    {'name': 'أحمد محمد', 'blood': 'O+', 'city': 'صنعاء', 'available': true, 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'},
    {'name': 'فاطمة علي', 'blood': 'A+', 'city': 'صنعاء', 'available': true, 'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'},
    {'name': 'محمد حسن', 'blood': 'B+', 'city': 'تعز', 'available': true, 'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100'},
    {'name': 'سارة عمر', 'blood': 'O-', 'city': 'عدن', 'available': true, 'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التبرع بالدم', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.error.withOpacity(0.2))),
            child: Column(children: [
              const Icon(Icons.bloodtype, color: AppColors.error, size: 48),
              const SizedBox(height: 8),
              const Text('أنقذ حياة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.error)),
              const Text('تبرع بالدم اليوم', style: TextStyle(color: AppColors.darkGrey)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.volunteer_activism), label: const Text('سجل كمتبرع'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.search), label: const Text('ابحث عن متبرع'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.error))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          // فصائل الدم
          Text('فصائل الدم المتوفرة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _bloodType('O+', '45 كيس', AppColors.success),
            _bloodType('A+', '32 كيس', AppColors.info),
            _bloodType('B+', '28 كيس', AppColors.warning),
            _bloodType('AB+', '15 كيس', AppColors.purple),
            _bloodType('O-', '8 كيس', AppColors.error),
          ]),
          const SizedBox(height: 16),
          Text('متبرعون متاحون', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ..._donors.where((d) => d['available']).map((d) => Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundImage: NetworkImage(d['image'])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text('${d['city']} • فصيلة ${d['blood']}', style: const TextStyle(fontSize: 10, color: AppColors.grey))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Text('متاح', style: TextStyle(color: AppColors.success, fontSize: 10))),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _bloodType(String type, String amount, Color color) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)), Text(amount, style: TextStyle(fontSize: 9, color: color))]));
}
