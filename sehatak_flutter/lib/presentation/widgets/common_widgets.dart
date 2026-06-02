import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

/// بطاقة طبيب محسنة
class DoctorCard extends StatelessWidget {
  final String name, specialty, experience;
  final double rating;
  final int reviews;
  final VoidCallback onTap;
  final String? imageUrl;
  final bool isAvailable;
  final String? fee;

  const DoctorCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.experience,
    this.rating = 4.5,
    this.reviews = 100,
    required this.onTap,
    this.imageUrl,
    this.isAvailable = true,
    this.fee,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(children: [
          // صورة الطبيب
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: imageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultAvatar()))
                : _defaultAvatar(),
          ),
          const SizedBox(width: 12),
          // معلومات الطبيب
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                if (isAvailable) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Text('متاح', style: TextStyle(fontSize: 9, color: AppColors.success))),
              ]),
              const SizedBox(height: 2),
              Text(specialty, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text(experience, style: const TextStyle(color: AppColors.darkGrey, fontSize: 10)),
              const SizedBox(height: 4),
              Row(children: [
                _starRow(rating),
                const SizedBox(width: 4),
                Text('$reviews تقييم', style: const TextStyle(fontSize: 10, color: AppColors.darkGrey)),
                const Spacer(),
                if (fee != null) Text('$fee ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              ]),
            ]),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left, color: AppColors.grey, size: 20),
        ]),
      ),
    );
  }

  Widget _defaultAvatar() => const Center(child: Icon(Icons.person, color: Colors.white, size: 28));

  Widget _starRow(double rating) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(i < rating.floor() ? Icons.star : (rating - i > 0 ? Icons.star_half : Icons.star_border), color: AppColors.amber, size: 13)));
  }
}

/// شريط بحث محسن
class CustomSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final TextEditingController? controller;

  const CustomSearchBar({super.key, this.hint = 'بحث...', this.onTap, this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
          ),
          filled: true,
          fillColor: AppColors.surfaceContainerLow.withOpacity(0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        ),
      ),
    );
  }
}

/// بطاقة خدمة سريعة محسنة
class QuickServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickServiceCard({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

/// شريط تسجيل دخول
class LoginPromptBar extends StatelessWidget {
  final VoidCallback onTap;
  const LoginPromptBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 10)],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مرحباً بك في منصة صحتك', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          SizedBox(height: 2),
          Text('سجل دخولك للاستفادة من جميع الخدمات', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), elevation: 0),
          child: const Text('تسجيل', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

/// بطاقة عرض رئيسية
class HeroBannerCard extends StatelessWidget {
  final VoidCallback onTap;
  const HeroBannerCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00796B), Color(0xFF004D40)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF00796B).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(children: [
          Positioned(left: 0, top: 0, child: Opacity(opacity: 0.1, child: Icon(Icons.health_and_safety, size: 120, color: Colors.white))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('منصة صحتك، أولويتنا', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('رعاية موثوقة في أي وقت وأي مكان', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.explore, size: 18),
              label: const Text('استكشف الآن'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// بطاقة منشور مجتمع
class CommunityPostCard extends StatelessWidget {
  final String user, avatar, topic, content, time;
  final int replies, likes;
  final Color color;
  final VoidCallback onTap;

  const CommunityPostCard({super.key, required this.user, required this.avatar, required this.topic, required this.content, required this.time, required this.replies, required this.likes, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.1), child: Text(avatar, style: const TextStyle(fontSize: 15))),
            const SizedBox(width: 8),
            Expanded(child: Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(4)), child: Text(topic, style: TextStyle(fontSize: 9, color: color))),
          ]),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.grey), const SizedBox(width: 4), Text('$replies', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
            const SizedBox(width: 14),
            const Icon(Icons.favorite_border, size: 14, color: AppColors.grey), const SizedBox(width: 4), Text('$likes', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
            const Spacer(),
            Text(time, style: const TextStyle(fontSize: 9, color: AppColors.grey)),
          ]),
        ]),
      ),
    );
  }
}
