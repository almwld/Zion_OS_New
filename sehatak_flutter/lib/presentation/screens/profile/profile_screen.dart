import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/settings/settings_screen.dart';
import 'package:sehatak/presentation/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _avatarUrl;
  bool _isUploading = false;

  void _pickImage() {
    setState(() => _isUploading = true);
    
    // محاكاة تحميل مع Shimmer
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _avatarUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم تحديث الصورة الشخصية'), backgroundColor: AppColors.success),
      );
    });
  }

  void _removeImage() {
    setState(() {
      _avatarUrl = null;
      _isUploading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إزالة الصورة الشخصية'), backgroundColor: AppColors.warning),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // بطاقة الملف الشخصي
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              // صورة الملف الشخصي
              Stack(children: [
                _isUploading
                    ? _shimmerAvatar()
                    : _avatarUrl != null
                        ? CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(_avatarUrl!),
                            backgroundColor: Colors.white24,
                          )
                        : const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white24,
                            child: Text('أح', style: TextStyle(fontSize: 36, color: Colors.white)),
                          ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _avatarUrl != null ? _removeImage : _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _avatarUrl != null ? AppColors.error : AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        _avatarUrl != null ? Icons.delete : Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('أحمد محمد', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('ahmed@email.com', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Text('📱 +967 777 123 456', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: const Text('عضو منذ 2024', style: TextStyle(color: Colors.white, fontSize: 11))),
            ]),
          ),
          const SizedBox(height: 20),

          // إحصائيات
          Row(children: [
            _statCard('النقاط', '1,250', Icons.stars, AppColors.amber),
            const SizedBox(width: 10),
            _statCard('المستوى', 'ذهبي', Icons.workspace_premium, AppColors.success),
            const SizedBox(width: 10),
            _statCard('الزيارات', '12', Icons.history, AppColors.info),
          ]),
          const SizedBox(height: 22),

          // نشاطي الصحي
          Text('نشاطي الصحي', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _menuItem(Icons.calendar_month_rounded, 'مواعيدي', '3 مواعيد قادمة', () {}),
          _menuItem(Icons.receipt_long, 'وصفاتي', '3 وصفات نشطة', () {}),
          _menuItem(Icons.science_rounded, 'تحاليلي', '6 فحوصات', () {}),
          _menuItem(Icons.description_outlined, 'تقاريري', '7 تقارير', () {}),
          _menuItem(Icons.history, 'سجل الزيارات', '5 زيارات', () {}),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('تسجيل الخروج'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _shimmerAvatar() {
    return Container(
      width: 100, height: 100,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 6), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey))])),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4), elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primary, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.grey)),
        trailing: const Icon(Icons.arrow_back_ios, size: 12, color: AppColors.grey),
        onTap: onTap,
      ),
    );
  }
}
