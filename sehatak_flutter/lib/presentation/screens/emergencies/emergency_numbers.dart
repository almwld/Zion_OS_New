import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/nearby/nearby_screen.dart';
import 'package:sehatak/presentation/screens/first_aid/first_aid_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyNumbers extends StatelessWidget {
  const EmergencyNumbers({super.key});

  final List<Map<String, dynamic>> _numbers = const [
    {'name': 'إسعاف', 'number': '1122', 'icon': Icons.local_hospital, 'color': AppColors.error},
    {'name': 'شرطة', 'number': '15', 'icon': Icons.local_police, 'color': AppColors.info},
    {'name': 'مطافئ', 'number': '16', 'icon': Icons.fire_truck, 'color': AppColors.orange},
    {'name': 'إنقاذ', 'number': '1122', 'icon': Icons.medical_services, 'color': AppColors.teal},
    {'name': 'إسعاف إدهي', 'number': '115', 'icon': Icons.medical_services, 'color': AppColors.purple},
    {'name': 'إسعاف شيبا', 'number': '1020', 'icon': Icons.local_hospital, 'color': AppColors.success},
  ];

  final List<Map<String, dynamic>> _hospitals = const [
    {'name': 'مستشفى الثورة العام', 'number': '01-222222', 'city': 'صنعاء', 'distance': '2.5 كم'},
    {'name': 'مستشفى الكويت الجامعي', 'number': '01-333333', 'city': 'صنعاء', 'distance': '4.1 كم'},
    {'name': 'المستشفى العسكري', 'number': '01-777777', 'city': 'صنعاء', 'distance': '5.8 كم'},
    {'name': 'مستشفى آزال', 'number': '01-555555', 'city': 'صنعاء', 'distance': '3.2 كم'},
  ];

  void _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطوارئ', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // SOS
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 50),
              const SizedBox(height: 8),
              const Text('طوارئ - SOS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('اضغط باستمرار لمدة 3 ثوانٍ', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 16),
              GestureDetector(
                onLongPress: () => _call('1122'),
                child: Container(width: 100, height: 100, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red, blurRadius: 20)]), child: const Center(child: Text('SOS', style: TextStyle(color: Color(0xFFD32F2F), fontSize: 28, fontWeight: FontWeight.bold)))),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          // أرقام الطوارئ
          Text('أرقام الطوارئ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.1, crossAxisSpacing: 10, mainAxisSpacing: 10, children: _numbers.map((n) => GestureDetector(
            onTap: () => _call(n['number']),
            child: Container(decoration: BoxDecoration(color: (n['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: (n['color'] as Color).withOpacity(0.2))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(n['icon'], color: n['color'], size: 30), const SizedBox(height: 4), Text(n['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(n['number'], style: TextStyle(color: n['color'], fontWeight: FontWeight.bold, fontSize: 16))])),
          )).toList()),
          const SizedBox(height: 20),
          // مستشفيات قريبة
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('مستشفيات قريبة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyScreen(type: 'hospitals'))), child: const Text('عرض الكل ›')),
          ]),
          ..._hospitals.map((h) => Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]),
            child: Row(children: [
              const Icon(Icons.local_hospital, color: AppColors.error, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(h['name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)), Text('${h['city']} • ${h['distance']}', style: const TextStyle(fontSize: 10, color: AppColors.grey))])),
              IconButton(icon: const Icon(Icons.call, color: AppColors.success), onPressed: () => _call(h['number'])),
              IconButton(icon: const Icon(Icons.navigation, color: AppColors.primary), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyScreen()))),
            ]),
          )),
          const SizedBox(height: 16),
          // زر الإسعافات الأولية
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstAidScreen())),
            icon: const Icon(Icons.medical_services), label: const Text('دليل الإسعافات الأولية'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 14)),
          )),
        ]),
      ),
    );
  }
}
