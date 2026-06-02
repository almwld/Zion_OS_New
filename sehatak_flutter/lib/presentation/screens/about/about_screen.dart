import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFB0C4DE) : AppColors.darkGrey; // أزرق فاتح في الليلي
    final titleColor = isDark ? const Color(0xFF64B5F6) : AppColors.primary; // أزرق فاتح للعناوين

    return Scaffold(
      appBar: AppBar(title: const Text('عن المنصة', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 20),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20)]),
            child: const Icon(Icons.health_and_safety, size: 55, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text('منصة صحتك', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Text('الإصدار 1.0.0', style: TextStyle(fontSize: 13, color: AppColors.primary))),
          const SizedBox(height: 16),
          
          // الوصف
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
            child: Text('منصتك الطبية المتكاملة التي تجمع كل احتياجاتك الصحية في مكان واحد. من استشارة الأطباء إلى طلب الأدوية وحجز المواعيد والتحاليل الطبية.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.7, color: textColor)),
          ),
          const SizedBox(height: 24),

          // مميزات
          _sectionTitle('مميزات المنصة', titleColor),
          const SizedBox(height: 10),
          _featureCard('🩺', 'استشارات طبية', 'تواصل مع أفضل الأطباء عبر المحادثة أو مكالمات الفيديو', textColor),
          _featureCard('💊', 'صيدلية متكاملة', 'اطلب الأدوية واحصل عليها عند باب منزلك', textColor),
          _featureCard('📅', 'حجز المواعيد', 'احجز مواعيدك مع الأطباء بكل سهولة', textColor),
          _featureCard('🔬', 'التحاليل الطبية', 'احجز فحوصاتك المخبرية وتابع نتائجك', textColor),
          _featureCard('📋', 'الملف الصحي', 'سجل طبي كامل لمتابعة حالتك الصحية', textColor),
          _featureCard('🚑', 'الطوارئ والإسعاف', 'أرقام طوارئ وخدمات إسعاف سريعة', textColor),
          _featureCard('🛡️', 'التأمين الصحي', 'قارن واختر أفضل خطط التأمين', textColor),
          _featureCard('🌙', 'الوضع الليلي', 'تصميم مريح للعين في الإضاءة المنخفضة', textColor),
          const SizedBox(height: 24),

          // إحصائيات
          _sectionTitle('بأرقام', titleColor),
          const SizedBox(height: 10),
          Row(children: [
            _statCard('200+', 'طبيب', Icons.person, AppColors.primary),
            const SizedBox(width: 8),
            _statCard('1000+', 'دواء', Icons.medication, AppColors.success),
            const SizedBox(width: 8),
            _statCard('50K+', 'مريض', Icons.people, AppColors.info),
          ]),
          const SizedBox(height: 24),

          // المطور
          _sectionTitle('فريق التطوير', titleColor),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
            child: const ListTile(
              leading: CircleAvatar(radius: 24, backgroundColor: AppColors.primary, child: Text('أح', style: TextStyle(color: Colors.white, fontSize: 20))),
              title: Text('أحمد علي', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('مطور المنصة', style: TextStyle(fontSize: 10, color: AppColors.grey)),
            ),
          ),
          const SizedBox(height: 24),

          // تواصل معنا
          _sectionTitle('تواصل معنا', titleColor),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
            child: Column(children: [
              _contactRow(Icons.email, 'البريد الإلكتروني', 'info@sehatak.com', () => _launch('mailto:info@sehatak.com')),
              const Divider(),
              _contactRow(Icons.phone, 'الهاتف', '+967 777 123 456', () => _launch('tel:+967777123456')),
              const Divider(),
              _contactRow(Icons.language, 'الموقع الإلكتروني', 'www.sehatak.com', () => _launch('https://www.sehatak.com')),
              const Divider(),
              _contactRow(Icons.location_on, 'العنوان', 'شارع الزبيري، صنعاء، اليمن', () {}),
            ]),
          ),
          const SizedBox(height: 20),

          // مواقع التواصل
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _socialIcon(Icons.facebook, AppColors.info, () {}),
            const SizedBox(width: 14),
            _socialIcon(Icons.camera_alt, AppColors.purple, () {}),
            const SizedBox(width: 14),
            _socialIcon(Icons.alternate_email, AppColors.error, () {}),
            const SizedBox(width: 14),
            _socialIcon(Icons.play_circle, AppColors.error, () {}),
          ]),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 10),
          Text('© 2026 منصة صحتك. جميع الحقوق محفوظة.', style: TextStyle(color: AppColors.grey.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 4),
          const Text('تم التطوير في اليمن 🇾🇪', style: TextStyle(color: AppColors.grey, fontSize: 11)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Row(children: [Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color))]);
  }

  Widget _featureCard(String emoji, String title, String desc, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
      child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(desc, style: TextStyle(fontSize: 10, color: AppColors.grey, height: 1.3))]))]),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(14)), child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 6), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey))])));
  }

  Widget _socialIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
    );
  }

  Widget _contactRow(IconData icon, String label, String value, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_back_ios, size: 12, color: AppColors.grey),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
