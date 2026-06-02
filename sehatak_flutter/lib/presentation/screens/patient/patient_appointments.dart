import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/chat/chat_screen.dart';
import 'package:sehatak/presentation/screens/doctor/doctors_list_screen.dart';

class PatientAppointments extends StatefulWidget {
  const PatientAppointments({super.key});
  @override
  State<PatientAppointments> createState() => _PatientAppointmentsState();
}

class _PatientAppointmentsState extends State<PatientAppointments> {
  String _tab = 'القادمة';

  final List<Map<String, dynamic>> _upcoming = [
    {'doctor': 'د. علي المولد', 'specialty': 'باطنية وأطفال', 'date': '15 مايو', 'time': '10:30 ص', 'type': 'فيديو', 'image': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=100'},
    {'doctor': 'د. حسن رضا', 'specialty': 'طبيب عام', 'date': '18 مايو', 'time': '2:00 م', 'type': 'حضوري', 'image': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=100'},
    {'doctor': 'د. فاطمة صديقي', 'specialty': 'أطفال', 'date': '22 مايو', 'time': '9:00 ص', 'type': 'فيديو', 'image': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=100'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مواعيدي', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)), child: Row(children: [_t('القادمة', _tab == 'القادمة'), _t('السابقة', _tab == 'السابقة')])),
        Expanded(
          child: _tab == 'القادمة'
              ? ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _upcoming.length, itemBuilder: (ctx, i) {
                  final a = _upcoming[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                    child: Column(children: [
                      Row(children: [
                        CircleAvatar(radius: 24, backgroundImage: NetworkImage(a['image'])),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a['doctor'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(a['specialty'], style: const TextStyle(fontSize: 10, color: AppColors.grey)), Text('${a['date']} • ${a['time']}', style: const TextStyle(fontSize: 10, color: AppColors.primary))])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: a['type'] == 'فيديو' ? AppColors.info.withOpacity(0.1) : AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(a['type'], style: TextStyle(fontSize: 9, color: a['type'] == 'فيديو' ? AppColors.info : AppColors.success))),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('إلغاء'))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('تعديل'))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())), icon: const Icon(Icons.message, size: 14), label: const Text('محادثة'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary))),
                      ]),
                    ]),
                  );
                })
              : const Center(child: Text('لا توجد مواعيد سابقة', style: TextStyle(color: AppColors.grey))),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsListScreen())), backgroundColor: AppColors.primary, icon: const Icon(Icons.add), label: const Text('حجز جديد')),
    );
  }

  Widget _t(String t, bool s) => Expanded(child: GestureDetector(onTap: () => setState(() => _tab = t), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: s ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Text(t, textAlign: TextAlign.center, style: TextStyle(color: s ? Colors.white : AppColors.darkGrey, fontWeight: FontWeight.bold, fontSize: 13)))));
}
