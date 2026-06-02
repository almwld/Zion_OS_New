import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/doctor/doctor_details_screen.dart';
import 'package:sehatak/presentation/screens/chat/chat_screen.dart';
import 'package:sehatak/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:sehatak/presentation/screens/auth/login_screen.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});
  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedSpecialty = 'الكل';
  String _sortBy = 'التقييم';
  bool _showAvailableOnly = false;
  bool _isLoading = false;

  final List<Map<String, String>> _specialties = const [
    {'icon': '🫀', 'name': 'الكل'}, {'icon': '👨‍⚕️', 'name': 'عام'}, {'icon': '🫀', 'name': 'قلب'},
    {'icon': '🫁', 'name': 'صدرية'}, {'icon': '🧠', 'name': 'أعصاب'}, {'icon': '🦴', 'name': 'عظام'},
    {'icon': '👶', 'name': 'أطفال'}, {'icon': '👩‍🦰', 'name': 'جلدية'}, {'icon': '👁️', 'name': 'عيون'},
    {'icon': '🦷', 'name': 'أسنان'}, {'icon': '🧘', 'name': 'نفسية'}, {'icon': '🤰', 'name': 'نسائية'},
    {'icon': '🩺', 'name': 'أنف وأذن'}, {'icon': '🩻', 'name': 'أشعة'},
  ];

  final List<Map<String, dynamic>> _allDoctors = [
    {'id': '1', 'name': 'د. عائشة رحمن', 'specialty': 'عام', 'subspecialty': 'باطنية عامة', 'experience': '12+ سنة', 'rating': 4.9, 'reviews': 128, 'fee': '500', 'available': true, 'online': true, 'patients': '5,000+', 'nextAvailable': 'اليوم 3:00 م'},
    {'id': '2', 'name': 'د. حسن رضا', 'specialty': 'عام', 'subspecialty': 'طب الأسرة', 'experience': '8+ سنة', 'rating': 4.8, 'reviews': 235, 'fee': '300', 'available': true, 'online': true, 'patients': '3,200+', 'nextAvailable': 'اليوم 4:30 م'},
    {'id': '3', 'name': 'د. عثمان خان', 'specialty': 'قلب', 'subspecialty': 'قسطرة قلبية', 'experience': '10+ سنة', 'rating': 4.7, 'reviews': 312, 'fee': '1000', 'available': true, 'online': true, 'patients': '8,000+', 'nextAvailable': 'اليوم 5:00 م'},
    {'id': '4', 'name': 'د. سارة أحمد', 'specialty': 'قلب', 'subspecialty': 'قلب أطفال', 'experience': '7+ سنة', 'rating': 4.8, 'reviews': 156, 'fee': '1200', 'available': false, 'online': false, 'patients': '2,500+', 'nextAvailable': 'غداً 11:00 ص'},
    {'id': '5', 'name': 'د. عمران شيخ', 'specialty': 'صدرية', 'subspecialty': 'أمراض تنفسية', 'experience': '9+ سنة', 'rating': 4.6, 'reviews': 189, 'fee': '900', 'available': true, 'online': true, 'patients': '4,000+', 'nextAvailable': 'اليوم 6:00 م'},
    {'id': '6', 'name': 'د. نادية حسين', 'specialty': 'أعصاب', 'subspecialty': 'الجلطات الدماغية', 'experience': '11+ سنة', 'rating': 4.9, 'reviews': 201, 'fee': '1500', 'available': true, 'online': false, 'patients': '6,000+', 'nextAvailable': 'اليوم 2:00 م'},
    {'id': '7', 'name': 'د. كمال أحمد', 'specialty': 'عظام', 'subspecialty': 'مفاصل صناعية', 'experience': '15+ سنة', 'rating': 4.6, 'reviews': 98, 'fee': '1200', 'available': false, 'online': false, 'patients': '10,000+', 'nextAvailable': 'بعد غد'},
    {'id': '8', 'name': 'د. فاطمة صديقي', 'specialty': 'أطفال', 'subspecialty': 'حديثي الولادة', 'experience': '7+ سنة', 'rating': 4.9, 'reviews': 167, 'fee': '600', 'available': true, 'online': true, 'patients': '7,000+', 'nextAvailable': 'اليوم 2:30 م'},
    {'id': '9', 'name': 'د. عائشة ملك', 'specialty': 'جلدية', 'subspecialty': 'جلدية تجميلية', 'experience': '6+ سنة', 'rating': 4.9, 'reviews': 189, 'fee': '800', 'available': false, 'online': false, 'patients': '4,500+', 'nextAvailable': 'غداً 10:00 ص'},
    {'id': '10', 'name': 'د. عمر فاروق', 'specialty': 'عيون', 'subspecialty': 'شبكية', 'experience': '13+ سنة', 'rating': 4.7, 'reviews': 145, 'fee': '1000', 'available': true, 'online': true, 'patients': '9,000+', 'nextAvailable': 'اليوم 7:00 م'},
    {'id': '11', 'name': 'د. زهرة طارق', 'specialty': 'أسنان', 'subspecialty': 'تقويم أسنان', 'experience': '5+ سنة', 'rating': 4.5, 'reviews': 112, 'fee': '700', 'available': true, 'online': false, 'patients': '2,000+', 'nextAvailable': 'اليوم 3:30 م'},
    {'id': '12', 'name': 'د. بلال محمود', 'specialty': 'نفسية', 'subspecialty': 'طب نفسي للكبار', 'experience': '8+ سنة', 'rating': 4.8, 'reviews': 134, 'fee': '1000', 'available': true, 'online': true, 'patients': '3,500+', 'nextAvailable': 'اليوم 5:30 م'},
    {'id': '13', 'name': 'د. سناء طارق', 'specialty': 'نسائية', 'subspecialty': 'ولادة', 'experience': '10+ سنة', 'rating': 4.9, 'reviews': 278, 'fee': '800', 'available': true, 'online': false, 'patients': '12,000+', 'nextAvailable': 'اليوم 1:00 م'},
    {'id': '14', 'name': 'د. راشد علي', 'specialty': 'أنف وأذن', 'subspecialty': 'جراحة الرأس والرقبة', 'experience': '14+ سنة', 'rating': 4.6, 'reviews': 167, 'fee': '900', 'available': false, 'online': false, 'patients': '11,000+', 'nextAvailable': 'غداً 9:00 ص'},
  ];

  List<Map<String, dynamic>> get _filteredDoctors {
    var list = _allDoctors;
    if (_selectedSpecialty != 'الكل') list = list.where((d) => d['specialty'] == _selectedSpecialty).toList();
    if (_showAvailableOnly) list = list.where((d) => d['available'] == true).toList();
    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      list = list.where((d) => d['name'].toLowerCase().contains(q) || d['specialty'].toLowerCase().contains(q)).toList();
    }
    if (_sortBy == 'التقييم') list.sort((a, b) => (b['rating'] as double).compareTo(a['rating']));
    if (_sortBy == 'السعر') list.sort((a, b) => int.parse(a['fee']).compareTo(int.parse(b['fee'])));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final doctors = _filteredDoctors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأطباء', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: () => _showSortSheet(context)),
          IconButton(icon: Icon(_showAvailableOnly ? Icons.filter_alt : Icons.filter_alt_outlined, color: _showAvailableOnly ? AppColors.primary : null), onPressed: () => setState(() => _showAvailableOnly = !_showAvailableOnly)),
        ],
      ),
      body: Column(children: [
        // شريط البحث
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2540) : AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'ابحث عن طبيب...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchCtrl.clear(); setState(() {}); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                filled: true, fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // التخصصات
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _specialties.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (c, i) {
              final s = _specialties[i];
              final sel = _selectedSpecialty == s['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedSpecialty = s['name']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : (isDark ? const Color(0xFF1A2540) : AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(12),
                    border: sel ? Border.all(color: AppColors.primary) : null,
                    boxShadow: sel ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)] : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(s['icon']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(s['name']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.darkGrey)),
                  ]),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // العدد والترتيب
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Text('${doctors.length} طبيب', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            GestureDetector(onTap: () => _showSortSheet(context), child: Row(children: [Text('ترتيب: $_sortBy', style: const TextStyle(fontSize: 11, color: AppColors.grey)), const SizedBox(width: 4), const Icon(Icons.swap_vert, size: 16, color: AppColors.grey)])),
          ]),
        ),

        const SizedBox(height: 8),

        // قائمة الأطباء
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: doctors.length,
            itemBuilder: (_, i) {
              final d = doctors[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2540) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                  border: Border.all(color: isDark ? const Color(0xFF2D3A54) : Colors.transparent),
                ),
                child: Row(children: [
                  // صورة الطبيب
                  Stack(children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.8), AppColors.primaryDark.withOpacity(0.9)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Text(d['name'][0] + d['name'][d['name'].length - 2], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                    ),
                    if (d['online'])
                      Positioned(bottom: 2, right: 2, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                  ]),
                  const SizedBox(width: 14),

                  // معلومات الطبيب
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        if (d['available'])
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text('متاح', style: TextStyle(fontSize: 9, color: AppColors.success))),
                      ]),
                      const SizedBox(height: 3),
                      Text('${d['subspecialty']} • ${d['experience']}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                      const SizedBox(height: 6),
                      Row(children: [
                        _starRow(d['rating']),
                        const SizedBox(width: 4),
                        Text('${d['reviews']} تقييم', style: const TextStyle(fontSize: 10, color: AppColors.darkGrey)),
                        const SizedBox(width: 10),
                        const Icon(Icons.people, size: 12, color: AppColors.grey),
                        const SizedBox(width: 2),
                        Text(d['patients'], style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                        const Spacer(),
                        Text('${d['fee']} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
                      ]),
                    ]),
                  ),

                  const SizedBox(width: 8),

                  // أزرار
                  Column(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: IconButton(icon: const Icon(Icons.chat, color: AppColors.info, size: 18), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(doctorName: d['name']))), padding: EdgeInsets.zero),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: IconButton(icon: const Icon(Icons.calendar_today, color: AppColors.primary, size: 16), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctorId: d['id']))), padding: EdgeInsets.zero),
                    ),
                  ]),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('ترتيب حسب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(title: const Text('التقييم (الأعلى)'), leading: const Icon(Icons.star, color: AppColors.amber), trailing: _sortBy == 'التقييم' ? const Icon(Icons.check, color: AppColors.primary) : null, onTap: () { setState(() => _sortBy = 'التقييم'); Navigator.pop(context); }),
          ListTile(title: const Text('السعر (الأقل)'), leading: const Icon(Icons.attach_money, color: AppColors.success), trailing: _sortBy == 'السعر' ? const Icon(Icons.check, color: AppColors.primary) : null, onTap: () { setState(() => _sortBy = 'السعر'); Navigator.pop(context); }),
          ListTile(title: const Text('الأحدث'), leading: const Icon(Icons.access_time, color: AppColors.info), onTap: () { Navigator.pop(context); }),
        ]),
      ),
    );
  }

  Widget _starRow(double rating) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(i < rating.floor() ? Icons.star : (rating - i > 0 ? Icons.star_half : Icons.star_border), color: AppColors.amber, size: 14)));
  }
}
