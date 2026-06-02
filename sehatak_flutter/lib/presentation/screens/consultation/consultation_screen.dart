import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/chat/chat_screen.dart';
import 'package:sehatak/presentation/screens/doctor/doctors_list_screen.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});
  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الاستشارات', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.medical_services, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              const Text('استشارات طبية', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('تحدث مع طبيب مختص بكل سهولة', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())), icon: const Icon(Icons.chat), label: const Text('دردشة'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsListScreen())), icon: const Icon(Icons.person_search), label: const Text('اختر طبيب'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          // أنواع الاستشارات
          Text('أنواع الاستشارات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _consultType('💬', 'استشارة نصية', 'تحدث مع الطبيب عبر المحادثة', 'من 100 ر.ي', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
          _consultType('📹', 'استشارة فيديو', 'مكالمة فيديو مباشرة', 'من 200 ر.ي', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
          _consultType('📞', 'مكالمة صوتية', 'مكالمة صوتية سريعة', 'من 150 ر.ي', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
          _consultType('🏥', 'زيارة منزلية', 'طبيب يزورك في منزلك', 'من 500 ر.ي', () {}),
        ]),
      ),
    );
  }

  Widget _consultType(String icon, String title, String desc, String price, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.grey))])),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Icon(Icons.arrow_back_ios, size: 14, color: AppColors.grey),
        ]),
      ),
    );
  }
}
